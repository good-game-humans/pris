// Configuration
const DATA_PATH = './data';
const POLL_INTERVAL_MS = 1000;
const CURSOR_BLINK_MS = 500;
const FRAME_INTERVAL_MS = 100;

// WASM module interface
interface PrisScreenWasm {
  memory: WebAssembly.Memory;
  init(): void;
  addLine(ptr: number, len: number): void;
  setCursor(visible: boolean): void;
  render(): void;
  getPixelBuffer(): number;
  getBufferSize(): number;
  getScreenWidth(): number;
  getScreenHeight(): number;
  getVersion(): number;
}

let wasm: PrisScreenWasm | null = null;
let canvas: HTMLCanvasElement | null = null;
let ctx: CanvasRenderingContext2D | null = null;
let imageData: ImageData | null = null;
let wasmPixels: Uint8ClampedArray | null = null;
let wasmMemory: Uint8Array | null = null;
let linePtr = 0;
const textEncoder = new TextEncoder();
let currentChunk = 0;
let cursorVisible = true;
let lastCursorToggle = 0;

async function loadWasm(): Promise<PrisScreenWasm> {
  const response = await fetch('./wasm/zig-out/bin/pris-screen.wasm');
  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {});
  return instance.exports as unknown as PrisScreenWasm;
}

function chunkFilename(num: number): string {
  return `${DATA_PATH}/pris-lines-${num.toString().padStart(4, '0')}.txt`;
}

async function fetchChunk(num: number): Promise<string | null> {
  try {
    const response = await fetch(chunkFilename(num));
    if (!response.ok) return null;
    return await response.text();
  } catch {
    return null;
  }
}

function addLineToWasm(line: string): void {
  if (!wasm || !wasmMemory) return;

  // Encode string to UTF-8
  const bytes = textEncoder.encode(line);

  // Write bytes to WASM memory at pre-calculated offset
  wasmMemory.set(bytes, linePtr);

  // Call WASM to add line
  wasm.addLine(linePtr, bytes.length);
}

function processChunk(text: string): void {
  const lines = text.split('\n');
  for (const line of lines) {
    if (line.trim() !== '') {
      addLineToWasm(line);
    }
  }
}

async function pollChunks(): Promise<void> {
  const text = await fetchChunk(currentChunk);
  if (text !== null) {
    processChunk(text);
    currentChunk++;
    // Check for next chunk immediately
    setTimeout(pollChunks, 50);
  } else {
    // Wait and try again
    setTimeout(pollChunks, POLL_INTERVAL_MS);
  }
}

function renderFrame(): void {
  if (!wasm || !ctx || !imageData || !wasmPixels) return;

  const now = performance.now();

  // Toggle cursor
  if (now - lastCursorToggle > CURSOR_BLINK_MS) {
    cursorVisible = !cursorVisible;
    wasm.setCursor(cursorVisible);
    lastCursorToggle = now;
  }

  // Render to pixel buffer
  wasm.render();

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

  // Initialize WASM
  wasm.init();

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
  linePtr = wasm.getBufferSize() + 1024; // Fixed offset after pixel buffer
  imageData = ctx.createImageData(width, height);

  // Start polling for chunks
  pollChunks();

  // Start render loop
  lastCursorToggle = performance.now();
  requestAnimationFrame(renderFrame);
}

init().catch(console.error);
