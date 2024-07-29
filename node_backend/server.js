const express = require("express");
const path = require("path");
const { spawn } = require("child_process");
const cors = require("cors");
const axios = require("axios");
const http = require("http");
const socketIo = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

app.use(cors());
app.use(express.json());

const streamDir = path.join(__dirname, "stream");
app.use("/stream", express.static(streamDir));

let ffmpeg;
let recording = false;
let imageQueue = []; // 이미지를 저장할 큐

function startFFmpeg() {
  const outputFilePath = path.join(streamDir, "output.m3u8");
  ffmpeg = spawn("ffmpeg", [
    "-f", "image2pipe",
    "-vcodec", "mjpeg",
    "-pix_fmt", "yuv420p",
    "-s", "320x240",
    "-r", "4",
    "-i", "-",
    "-c:v", "libx264",
    "-preset", "ultrafast",
    "-tune", "zerolatency",
    "-profile:v", "baseline",
    "-level", "3.1",
    "-maxrate", "3000k",
    "-bufsize", "6000k",
    "-pix_fmt", "yuv420p",
    "-g", "30",
    "-hls_time", "2",
    "-hls_list_size", "20",
    "-hls_flags", "delete_segments",
    "-f", "hls",
    outputFilePath
  ]);

  ffmpeg.stderr.on("data", (data) => {
    console.error(`FFmpeg error: ${data}`);
  });

  ffmpeg.on("close", (code) => {
    console.log(`FFmpeg process exited with code ${code}`);
  });

  recording = true;
  console.log(`Recording started: ${outputFilePath}`);

  // 이미지 전송 타이머 설정
  setInterval(() => {
    if (imageQueue.length > 0) {
      const image = imageQueue.shift();
      if (ffmpeg && ffmpeg.stdin.writable) {
        ffmpeg.stdin.write(image);
      }
    }
  }, 300); // 0.2초 간격으로 이미지 전송
}

function stopFFmpeg() {
  if (ffmpeg) {
    ffmpeg.stdin.end();
    ffmpeg = null;
    recording = false;
    console.log("Recording stopped");
  }
}

io.on("connection", (socket) => {
  console.log("A new client has connected!");

  socket.on("start_recording", () => {
    if (!recording) {
      startFFmpeg();
    }
  });

  socket.on("stop_recording", () => {
    if (recording) {
      stopFFmpeg();
    }
  });

  socket.on("stream_image", async (imageBase64) => {
    try {
      const response = await axios.post("http://localhost:5003/process_image", { image: imageBase64 });
      const processedImageBase64 = response.data.processed_image;
      const buffer = Buffer.from(processedImageBase64, "base64");
      imageQueue.push(buffer); // 처리된 이미지를 큐에 추가
    } catch (error) {
      console.error("Error processing image:", error);
    }
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected");
  });
});

const PORT = process.env.PORT || 5001;
server.listen(PORT, () => {
  console.log(`Server started on port ${PORT}`);
  console.log(`Stream directory: ${streamDir}`);
});
