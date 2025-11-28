document.addEventListener("DOMContentLoaded", start);

let result;
const width = 1000;
const height = 1000;

async function start() {
  await initWasm();
  //const colorMapImage = await prepareImage("./images/C15.png");
  //const heightMapImage = await prepareImage("./images/D15.png");
  const colorMapImage = await prepareImage("./images/C1.png");
  const heightMapImage = await prepareImage("./images/D1.png");

  const computeCanvas = result.instance.exports.computeCanvas;

  computeCanvas(
    width,
    height,
    colorMapImage.ptr,
    colorMapImage.width,
    colorMapImage.height,
    heightMapImage.ptr,
    heightMapImage.width,
    heightMapImage.height,
  );
}

async function initWasm() {
  const response = await fetch("./zig/zig-out/bin/code.wasm");
  const bytes = await response.arrayBuffer();

  result = await WebAssembly.instantiate(bytes, {
    env: {
      writeToCanvas: (ptr) => {
        console.log("JS: " + new Date().toLocaleTimeString());
        const memory = result.instance.exports.memory.buffer;
        const array = new Uint8ClampedArray(memory, ptr, width * height * 4);
        const canvas = document.getElementById("canvas");
        const context = canvas.getContext("2d");

        context.putImageData(new ImageData(array, width, height), 0, 0);
        console.log("JS: finished" + new Date().toLocaleTimeString());
      },
      print: (s) => console.log("WASM: " + new Date().toLocaleTimeString() + s),
      printColor: (r, g, b) => console.log(`WASM-COLOR: rgb(${r},${g},${b})`),
    },
  });
}

function prepareImage(path) {
  return new Promise((resolve, reject) => {
    if (!result) {
      console.log("result not loaded");
      reject();
    }

    const allocImageBuffer = result.instance.exports.allocImageBuffer;

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
        result.instance.exports.memory.buffer,
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
