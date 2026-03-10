// Configuration
const DATA_PATH = './data';
const POLL_INTERVAL_MS = 100;

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

async function loadWasm(): Promise<PrisScreenWasm> {
  const response = await fetch('./wasm/zig-out/bin/pris-screen.wasm');
  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {});
  return instance.exports as unknown as PrisScreenWasm;
}

function chunkFilename(num: number): string {
  return `${DATA_PATH}/pris-lines-${num.toString().padStart(4, '0')}.txt`;
}

async function fetchAndFillBuffer(): Promise<void> {
  if (!wasm || fetchingChunk || reachedEnd) return;
  if (!wasm.needsBuffer()) return;

  fetchingChunk = true;

  try {
    const response = await fetch(chunkFilename(currentChunk));
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

  // Fill buffers if needed
  if (wasm.needsBuffer() && !fetchingChunk) {
    fetchAndFillBuffer();
  }

  // Let WASM process lines and render
  wasm.processFrame(BigInt(Date.now()));

  // Copy from WASM memory to ImageData
  imageData.data.set(wasmPixels);

  // Draw to canvas
  ctx.putImageData(imageData, 0, 0);

  // Schedule next frame
  requestAnimationFrame(renderFrame);
}

async function init(): Promise<void> {
  // Load WASM
  wasm = await loadWasm();
  console.log('WASM loaded, version:', wasm.getVersion());
  setInterval(() => {
    if (wasm?.hadUnknownColor()) console.warn('pris-screen: unrecognised ANSI color encountered');
  }, 5000);

  // Initialize WASM
  wasm.init();

  // Fetch manifest
  let manifest: Manifest;
  try {
    manifest = await fetch(`${DATA_PATH}/manifest.json`).then(r => r.json());
    console.log('Manifest loaded:', manifest);
  } catch {
    // Default to realtime mode with current time as start
    manifest = { mode: 'realtime', startTime: Date.now() };
    console.log('No manifest, using realtime mode');
  }

  // Initialize timing
  wasm.initTiming(
    BigInt(manifest.startTime),
    BigInt(manifest.duration ?? 0),
    BigInt(Date.now())
  );

  // Set up canvas
  canvas = document.getElementById('terminal') as HTMLCanvasElement;
  canvas.width = wasm.getScreenWidth();
  canvas.height = wasm.getScreenHeight();
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

  // Start render loop
  requestAnimationFrame(renderFrame);
}

init().catch(console.error);
