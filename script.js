document.addEventListener("DOMContentLoaded", start);
document.addEventListener("keydown", inputs);

let wasm;
let context;

let mapPointer = null;

let px = 0;
let py = 0;

async function start() {
  await init();

  await createMapPointer("./images/C15.png", "./images/D15.png");

  requestAnimationFrame(runGame);
}

function inputs(e) {
  if (e.key == "w") {
    py -= 5;
  }

  if (e.key == "s") {
    py += 5;
  }

  if (e.key == "a") {
    px -= 5;
  }

  if (e.key == "d") {
    px += 5;
  }
}

let prevTimestamp = 0;
function runGame(timestamp) {
  const canvasElem = document.getElementById("canvas");

  document.getElementById("fps").innerText = `${(
    Math.round((1000.0 / (timestamp - prevTimestamp)) * 100) / 100
  ).toFixed(2)} FPS`;

  prevTimestamp = timestamp;

  if (
    canvasElem.width != canvasElem.clientWidth ||
    canvasElem.height != canvasElem.clientHeight
  ) {
    canvasElem.width = canvasElem.clientWidth;
    canvasElem.height = canvasElem.clientHeight;
  }

  if (mapPointer) {
    const ptr = wasm.instance.exports.computeCanvas(
      px,
      py,
      canvasElem.width,
      canvasElem.height,
      mapPointer,
    );

    const array = new Uint8ClampedArray(
      wasm.instance.exports.memory.buffer,
      ptr,
      canvas.width * canvas.height * 4,
    );

    context.putImageData(
      new ImageData(array, canvas.width, canvas.height),
      0,
      0,
    );
  }

  requestAnimationFrame(runGame);
}

async function init() {
  const response = await fetch("./zig/zig-out/bin/code.wasm");
  const bytes = await response.arrayBuffer();
  const canvas = document.getElementById("canvas");
  context = canvas.getContext("2d");

  wasm = await WebAssembly.instantiate(bytes, {
    env: {
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

      const ptr = wasm.instance.exports.allocImageBuffer(bytes.length);
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

async function createMapPointer(colorMapPath, heightMapPath) {
  const colorMapData = await prepareImage(colorMapPath);
  const heightMapData = await prepareImage(heightMapPath);

  if (
    colorMapData.width != heightMapData.width ||
    colorMapData.height != heightMapData.height
  ) {
    console.log("different dimensions height-map and color-map");
    return;
  }

  mapPointer = wasm.instance.exports.createMap(
    colorMapData.width,
    colorMapData.height,
    colorMapData.ptr,
    heightMapData.ptr,
  );
}
