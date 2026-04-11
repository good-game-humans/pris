// Configuration
const DATA_PATH = './data';
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
  hadUnknownColor(): boolean;
  getVersion(): number;
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
let lastFetchAttemptMs = 0;
let knownStartTime = 0;

async function pollManifest(): Promise<void> {
  try {
    const m: Manifest = await fetch(
      `${DATA_PATH}/manifest.json`,
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
        const targetTimeSec = (Date.now() - REALTIME_DELAY_MS) / 1000;
        currentChunk = await findStartChunk(targetTimeSec);
      }
    }
  } catch { /* ignore */ }
}

async function findStartChunk(targetTimeSec: number): Promise<number> {
  try {
    const text = await fetch(`${DATA_PATH}/chunk-times.txt`, { cache: 'no-store' }).then(r => r.text());
    const entries = text.trim().split('\n')
      .filter(line => line.length > 0)
      .map(line => {
        const comma = line.indexOf(',');
        return { chunk: parseInt(line.slice(0, comma)), ts: parseFloat(line.slice(comma + 1)) };
      });
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

async function loadWasm(src: string): Promise<PrisScreenWasm> {
  const response = await fetch(src);
  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {});
  return instance.exports as unknown as PrisScreenWasm;
}

function chunkFilename(num: number): string {
  return `${DATA_PATH}/pris-lines-${num.toString().padStart(8, '0')}.txt`;
}

async function fetchAndFillBuffer(): Promise<void> {
  if (!wasm || fetchingChunk || reachedEnd) return;
  if (!wasm.needsBuffer()) return;

  fetchingChunk = true;

  try {
    const response = await fetch(chunkFilename(currentChunk), { cache: 'no-store' });
    if (!response.ok) {
      // No more chunks available yet
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
  } catch {
    // Fetch failed, will retry
  }

  fetchingChunk = false;
}

function renderFrame(): void {
  if (!wasm || !ctx || !imageData || !wasmPixels) return;

  const now = Date.now();

  // Fill buffers if needed, throttled by POLL_INTERVAL_MS
  if (wasm.needsBuffer() && !fetchingChunk && now - lastFetchAttemptMs >= POLL_INTERVAL_MS) {
    lastFetchAttemptMs = now;
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
  const wasmSrc = canvasEl.dataset.wasmSrc ?? './wasm/zig-out/bin/pris-screen-120x40.wasm';

  // Load WASM
  wasm = await loadWasm(wasmSrc);
  console.log('WASM loaded, version:', wasm.getVersion());
  setInterval(() => {
    if (wasm?.hadUnknownColor()) console.warn('pris-screen: unrecognised ANSI color encountered');
  }, 5000);

  // Initialize WASM
  wasm.init();

  // Fetch manifest
  let manifest: Manifest;
  try {
    manifest = await fetch(`${DATA_PATH}/manifest.json`, { cache: 'no-store' }).then(r => r.json());
    console.log('Manifest loaded:', manifest);
  } catch {
    // Default to realtime mode with current time as start
    manifest = { mode: 'realtime', startTime: Date.now() };
    console.log('No manifest, using realtime mode');
  }
  knownStartTime = manifest.startTime;

  // Initialize timing
  wasm.initTiming(
    BigInt(manifest.startTime),
    BigInt(manifest.duration ?? 0),
    BigInt(manifest.startTime + (manifest.mode === 'realtime' ? REALTIME_DELAY_MS : 0))
  );

  // In realtime mode, seek to the chunk closest to now - REALTIME_DELAY_MS
  if (manifest.mode === 'realtime') {
    const targetTimeSec = (Date.now() - REALTIME_DELAY_MS) / 1000;
    currentChunk = await findStartChunk(targetTimeSec);
    console.log('Starting from chunk', currentChunk);
  }

  // Set up canvas
  canvas = canvasEl;
  canvas.width = wasm.getScreenWidth();
  canvas.height = wasm.getScreenHeight();
  function fitCanvas(): void {
    const pad = 16;
    const maxWidthAttr = canvas!.dataset.maxWidth;
    const fitScale = Math.min(
      (window.innerWidth - pad * 2) / canvas!.width,
      (window.innerHeight - pad * 2) / canvas!.height
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
  wasmMemory = new Uint8Array(wasm.memory.buffer);
  imageData = ctx.createImageData(width, height);

  // Poll manifest for new runs
  setInterval(pollManifest, 10_000);

  // Start render loop
  requestAnimationFrame(renderFrame);
}

init().catch(console.error);
