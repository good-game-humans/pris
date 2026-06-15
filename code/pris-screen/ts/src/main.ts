// Configuration
let dataPath = './data';
const POLL_INTERVAL_MS = 1000;
const REALTIME_DELAY_MS = 5000;

// Manifest
interface Manifest {
  mode: 'realtime' | 'replay';
  startTime: number;
  duration?: number;
}

// WASM module interface
interface PrisScreenWasm {
  memory: WebAssembly.Memory;
  init(): void;
  initTiming(startMs: bigint, durationMs: bigint, nowMs: bigint): void;
  getWriteBufferPtr(): number;
  getWriteBufferIndex(): number;
  markBufferReady(index: number, len: number): void;
  needsBuffer(): boolean;
  processFrame(nowMs: bigint): void;
  getPixelBuffer(): number;
  getBufferSize(): number;
  getScreenWidth(): number;
  getScreenHeight(): number;
  getMaxChunkSize(): number;
  getKeyframeBufferPtr(): number;
  getKeyframeMaxBytes(): number;
  loadKeyframe(len: number, kfMs: bigint): void;
  hadUnknownColor(): boolean;
  getVersion(): number;
  resetReplay(): void;
}

let wasm: PrisScreenWasm | null = null;
let canvas: HTMLCanvasElement | null = null;
let ctx: CanvasRenderingContext2D | null = null;
let imageData: ImageData | null = null;
let wasmPixels: Uint8ClampedArray | null = null;
let wasmMemory: Uint8Array | null = null;
let currentChunk = 0;
let fetchingChunk = false;
let reachedEnd = false;
let nextFetchMs = 0;
let knownStartTime = 0;
let knownDuration = 0;
let loopCheckPosMs = -1;

async function pollManifest(): Promise<void> {
  try {
    const m: Manifest = await fetch(
      `${dataPath}/manifest.json`,
      { cache: 'no-store' }
    ).then(r => r.json());
    if (m.startTime !== knownStartTime) {
      console.log('New run detected, resetting state');
      knownStartTime = m.startTime;
      currentChunk = 0;
      reachedEnd = false;
      wasm!.initTiming(
        BigInt(m.startTime),
        BigInt(m.duration ?? 0),
        BigInt(m.startTime + (m.mode === 'realtime' ? REALTIME_DELAY_MS : 0))
      );
      if (m.mode === 'realtime') {
        currentChunk = await seekRealtime();
      }
    }
  } catch { /* ignore */ }
}

async function findStartChunk(targetTimeSec: number): Promise<number> {
  try {
    const resp = await fetch(`${dataPath}/chunk-times.txt`, { cache: 'no-store' });
    if (!resp.ok) return 0; // not written yet — don't parse the 404 page
    const text = await resp.text();
    const entries = text.trim().split('\n')
      .filter(line => line.length > 0)
      .map(line => {
        const comma = line.indexOf(',');
        return { chunk: parseInt(line.slice(0, comma)), ts: parseFloat(line.slice(comma + 1)) };
      })
      .filter(e => Number.isFinite(e.chunk) && Number.isFinite(e.ts));
    if (entries.length === 0) return 0;
    let lo = 0, hi = entries.length - 1;
    while (lo < hi) {
      const mid = Math.ceil((lo + hi) / 2);
      if (entries[mid].ts <= targetTimeSec) lo = mid; else hi = mid - 1;
    }
    return entries[lo].chunk;
  } catch {
    return 0;
  }
}

function keyframeFilename(id: number): string {
  return `${dataPath}/keyframe-${id.toString().padStart(8, '0')}.bin`;
}

// Prime the screen from the latest keyframe at or before targetTimeSec, so a
// fresh connect shows a full screen immediately. Returns the keyframe's stream
// time (seconds) if one was loaded, else null.
async function primeFromKeyframe(targetTimeSec: number): Promise<number | null> {
  if (!wasm || !wasmMemory) return null;
  try {
    const resp = await fetch(`${dataPath}/keyframes.txt`, { cache: 'no-store' });
    if (!resp.ok) return null;
    const entries = (await resp.text()).trim().split('\n')
      .filter(l => l.length > 0)
      .map(l => {
        const comma = l.indexOf(',');
        return { id: parseInt(l.slice(0, comma)), ts: parseFloat(l.slice(comma + 1)) };
      });
    let best: { id: number; ts: number } | null = null;
    for (const e of entries) {
      if (e.ts <= targetTimeSec) best = e; else break; // entries are time-ordered
    }
    if (!best) return null;
    const kfResp = await fetch(keyframeFilename(best.id), { cache: 'no-store' });
    if (!kfResp.ok) return null;
    const bytes = new Uint8Array(await kfResp.arrayBuffer());
    const len = Math.min(bytes.length, wasm.getKeyframeMaxBytes());
    wasmMemory.set(bytes.subarray(0, len), wasm.getKeyframeBufferPtr());
    wasm.loadKeyframe(len, BigInt(Math.round(best.ts * 1000)));
    return best.ts;
  } catch {
    return null;
  }
}

async function seekReplay(durationMs: number): Promise<number> {
  const posMs = (Date.now() - knownStartTime) % durationMs;
  const targetSec = (knownStartTime + posMs) / 1000;
  const kfTs = await primeFromKeyframe(targetSec);
  return findStartChunk(kfTs ?? targetSec);
}

async function checkReplayLoop(): Promise<void> {
  if (!wasm || !reachedEnd || knownDuration === 0) return;
  const posMs = (Date.now() - knownStartTime) % knownDuration;
  if (loopCheckPosMs >= 0 && posMs < loopCheckPosMs) {
    wasm.resetReplay();
    reachedEnd = false;
    currentChunk = await seekReplay(knownDuration);
  }
  loopCheckPosMs = posMs;
}

// Realtime connect: prime from a keyframe if available and replay the delta
// forward from it (the WASM skips lines already in the keyframe); otherwise
// start at the 5s-delayed point.
async function seekRealtime(): Promise<number> {
  const targetTimeSec = (Date.now() - REALTIME_DELAY_MS) / 1000;
  const kfTs = await primeFromKeyframe(targetTimeSec);
  return await findStartChunk(kfTs ?? targetTimeSec);
}

async function loadWasm(src: string): Promise<PrisScreenWasm> {
  const response = await fetch(src);
  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {});
  return instance.exports as unknown as PrisScreenWasm;
}

function chunkFilename(num: number): string {
  return `${dataPath}/pris-lines-${num.toString().padStart(8, '0')}.txt`;
}

async function fetchAndFillBuffer(): Promise<void> {
  if (!wasm || fetchingChunk || reachedEnd) return;
  if (!wasm.needsBuffer()) return;

  fetchingChunk = true;

  try {
    const response = await fetch(chunkFilename(currentChunk), { cache: 'no-store' });
    if (!response.ok) {
      // No chunk available yet — back off briefly before retrying.
      nextFetchMs = Date.now() + POLL_INTERVAL_MS;
      fetchingChunk = false;
      return;
    }

    const text = await response.text();
    const bytes = new TextEncoder().encode(text);

    // Check for end signal
    if (text.includes('-=END=-')) {
      reachedEnd = true;
    }

    // Get buffer from WASM and write to it
    const bufferIndex = wasm.getWriteBufferIndex();
    const bufferPtr = wasm.getWriteBufferPtr();
    const maxSize = wasm.getMaxChunkSize();

    const writeLen = Math.min(bytes.length, maxSize);
    wasmMemory!.set(bytes.subarray(0, writeLen), bufferPtr);
    wasm.markBufferReady(bufferIndex, writeLen);

    currentChunk++;
    nextFetchMs = 0; // data was available — keep fetching to fill buffers
  } catch {
    nextFetchMs = Date.now() + POLL_INTERVAL_MS; // back off on error
  }

  fetchingChunk = false;
}

function renderFrame(): void {
  if (!wasm || !ctx || !imageData || !wasmPixels) return;

  const now = Date.now();

  // Keep buffers full: fetch back-to-back while chunks are available, backing
  // off (POLL_INTERVAL_MS) only when a fetch finds no chunk yet.
  if (wasm.needsBuffer() && !fetchingChunk && now >= nextFetchMs) {
    fetchAndFillBuffer();
  }

  // Let WASM process lines and render
  wasm.processFrame(BigInt(now));

  // Copy from WASM memory to ImageData
  imageData.data.set(wasmPixels);

  // Draw to canvas
  ctx.putImageData(imageData, 0, 0);

  // Schedule next frame
  requestAnimationFrame(renderFrame);
}

async function init(): Promise<void> {
  // Resolve WASM path from canvas data attribute
  const canvasEl = document.getElementById('terminal') as HTMLCanvasElement;
  dataPath = canvasEl.dataset.dataPath ?? './data';
  const wasmSrc = canvasEl.dataset.wasmSrc ?? './wasm/zig-out/bin/pris-screen-120x40.wasm';

  // Load WASM
  wasm = await loadWasm(wasmSrc);
  console.log('WASM loaded, version:', wasm.getVersion());
  setInterval(() => {
    if (wasm?.hadUnknownColor()) console.warn('pris-screen: unrecognised ANSI color encountered');
  }, 5000);

  // Initialize WASM
  wasm.init();

  // Memory view — needed by the keyframe prime during the realtime seek below.
  wasmMemory = new Uint8Array(wasm.memory.buffer);

  // Fetch manifest
  let manifest: Manifest;
  try {
    manifest = await fetch(`${dataPath}/manifest.json`, { cache: 'no-store' }).then(r => r.json());
    console.log('Manifest loaded:', manifest);
  } catch {
    // Default to realtime mode with current time as start
    manifest = { mode: 'realtime', startTime: Date.now() };
    console.log('No manifest, using realtime mode');
  }
  knownStartTime = manifest.startTime;

  // Initialize timing and seek to the right position.
  if (manifest.mode === 'realtime') {
    wasm.initTiming(BigInt(manifest.startTime), BigInt(0), BigInt(manifest.startTime + REALTIME_DELAY_MS));
    currentChunk = await seekRealtime();
    console.log('Starting from chunk', currentChunk);
  } else {
    knownDuration = manifest.duration ?? 0;
    wasm.initTiming(BigInt(manifest.startTime), BigInt(knownDuration), BigInt(manifest.startTime));
    currentChunk = await seekReplay(knownDuration);
    console.log('Starting from chunk', currentChunk);
    setInterval(checkReplayLoop, 1000);
  }

  // Set up canvas
  canvas = canvasEl;
  canvas.width = wasm.getScreenWidth();
  canvas.height = wasm.getScreenHeight();
  function fitCanvas(): void {
    const pad = 16;
    const container = document.getElementById('screen') ?? document.body;
    const maxWidthAttr = canvas!.dataset.maxWidth;
    const fitScale = Math.min(
      (container.clientWidth - pad * 2) / canvas!.width,
      (container.clientHeight - pad * 2) / canvas!.height
    );
    const scale = maxWidthAttr
      ? Math.min(fitScale, (parseInt(maxWidthAttr, 10) + pad * 2) / canvas!.width)
      : fitScale;
    canvas!.style.width = `${Math.floor(canvas!.width * scale)}px`;
    canvas!.style.height = `${Math.floor(canvas!.height * scale)}px`;
  }
  fitCanvas();
  window.addEventListener('resize', fitCanvas);
  ctx = canvas.getContext('2d');

  if (!ctx) {
    console.error('Failed to get canvas context');
    return;
  }

  // Create reusable ImageData and WASM memory views
  const width = wasm.getScreenWidth();
  const height = wasm.getScreenHeight();
  const ptr = wasm.getPixelBuffer();
  const size = width * height * 4;
  wasmPixels = new Uint8ClampedArray(wasm.memory.buffer, ptr, size);
  imageData = ctx.createImageData(width, height);

  // Poll manifest for new runs
  setInterval(pollManifest, 10_000);

  // Start render loop
  requestAnimationFrame(renderFrame);
}

init().catch(console.error);
