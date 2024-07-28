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

// 정적 파일 서빙 경로 설정 (예: /stream)
const streamDir = path.join(__dirname, "stream");
app.use("/stream", express.static(streamDir));

let ffmpeg;

function startFFmpeg() {
  if (ffmpeg) {
    ffmpeg.kill();
  }

  ffmpeg = spawn("ffmpeg", [
    "-f", "image2pipe",
    "-pix_fmt", "yuv420p",
    "-s", "640x480",
    "-r", "30",
    "-i", "-",
    "-c:v", "libx264",
    "-preset", "veryfast",
    "-tune", "zerolatency",
    "-profile:v", "baseline",
    "-level", "3.1",
    "-bufsize", "2000k",
    "-pix_fmt", "yuv420p",
    "-g", "30",
    "-hls_time", "4",
    "-hls_list_size", "4",
    "-hls_flags", "delete_segments",
    "-f", "hls",
    path.join(streamDir, "output.m3u8")
  ]);

  ffmpeg.stderr.on("data", (data) => {
    console.error(`FFmpeg error: ${data}`);
  });

  ffmpeg.on("close", (code) => {
    console.log(`FFmpeg process exited with code ${code}`);
  });
}

startFFmpeg();

io.on("connection", (socket) => {
  console.log("A new client has connected!");

  socket.on("stream_image", async (imageBase64) => {
    try {
      const response = await axios.post("http://localhost:5003/process_image", { image: imageBase64 });
      console.log("Image processing successful");
      const processedImageBase64 = response.data.processed_image;

      const buffer = Buffer.from(processedImageBase64, "base64");
      if (ffmpeg.stdin.writable) {
        ffmpeg.stdin.write(buffer);
      } else {
        console.error("FFmpeg stdin is not writable, restarting FFmpeg process");
        startFFmpeg();
        ffmpeg.stdin.write(buffer);
      }

      socket.emit("receive_message", processedImageBase64);
    } catch (error) {
      console.error("Error processing image:", error);
      socket.emit("receive_message", `Error processing image: ${error.message}`);
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
