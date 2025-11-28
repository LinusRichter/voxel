document.addEventListener("DOMContentLoaded", start);

let wasm;
let width = 0;
let height = 0;

let heightMapData;
let colorMapData;

async function start() {
  await initWasm();
  window.addEventListener("resize", handleResize);

  if (!colorMapData) {
    colorMapData = await prepareImage("./images/C1.png");
  }
  if (!heightMapData) {
    heightMapData = await prepareImage("./images/D1.png");
  }

  handleResize();
}

function render() {
  const computeCanvas = wasm.instance.exports.computeCanvas;

  computeCanvas(
    width,
    height,
    colorMapData.ptr,
    colorMapData.width,
    colorMapData.height,
    heightMapData.ptr,
    heightMapData.width,
    heightMapData.height,
  );
}

async function handleResize() {
  const canvas = document.getElementById("canvas");
  width = canvas.clientWidth;
  height = canvas.clientHeight;
  canvas.width = width;
  canvas.height = height;
  render();
}

async function initWasm() {
  const response = await fetch("./zig/zig-out/bin/code.wasm");
  const bytes = await response.arrayBuffer();

  wasm = await WebAssembly.instantiate(bytes, {
    env: {
      writeToCanvas: (ptr) => {
        console.log("JS: " + new Date().toLocaleTimeString());
        const memory = wasm.instance.exports.memory.buffer;
        const array = new Uint8ClampedArray(memory, ptr, width * height * 4);
        const canvas = document.getElementById("canvas");
        const context = canvas.getContext("2d");

        context.putImageData(new ImageData(array, width, height), 0, 0);
        console.log("JS: finished" + new Date().toLocaleTimeString());
      },
      print: (s) =>
        console.log("WASM: " + new Date().toLocaleTimeString() + " " + s),
      printColor: (r, g, b) => console.log(`WASM-COLOR: rgb(${r},${g},${b})`),
    },
  });
}

function prepareImage(path) {
  return new Promise((resolve, reject) => {
    if (!wasm) {
      console.log("result not loaded");
      reject();
    }

    const allocImageBuffer = wasm.instance.exports.allocImageBuffer;

    const img = new Image();
    img.src = path;

    img.onload = () => {
      const offscreenCanvas = new OffscreenCanvas(img.width, img.height);
      const offscreenContext = offscreenCanvas.getContext("2d");
      offscreenContext.drawImage(img, 0, 0);

      const imgData = offscreenContext.getImageData(
        0,
        0,
        img.width,
        img.height,
      );
      const bytes = imgData.data;

      const ptr = allocImageBuffer(bytes.length);
      new Uint8Array(
        wasm.instance.exports.memory.buffer,
        ptr,
        bytes.length,
      ).set(bytes);

      resolve({ ptr, width: img.width, height: img.height });
    };

    img.onerror = () => {
      reject(new Error("Failed to load image"));
    };
  });
}
