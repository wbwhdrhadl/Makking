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

function startFFmpeg() {
  const outputFilePath = path.join(streamDir, "output.m3u8");
  ffmpeg = spawn("ffmpeg", [
    "-color_range", "jpeg",
    "-f", "image2pipe",
    "-pix_fmt", "yuv420p",
    "-s", "640x480",
    "-r", "10",
    "-i", "-",
    "-c:v", "libx264",
    "-preset", "veryfast",
    "-tune", "zerolatency",
    "-profile:v", "baseline",
    "-level", "3.1",
    "-bufsize", "2000k",
    "-pix_fmt", "yuv420p",
    "-g", "30",
    "-hls_time", "1",           // Set segment duration to 1 second
    "-hls_list_size", "5",      // Keep only the last 5 segments in the playlist
    "-hls_flags", "delete_segments", // Automatically delete old segments
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
      if (ffmpeg && ffmpeg.stdin.writable) {
        ffmpeg.stdin.write(buffer);
      } else {
        console.error("FFmpeg stdin is not writable");
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
