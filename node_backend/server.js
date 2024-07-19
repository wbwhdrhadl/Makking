const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
const socketIo = require('socket.io');
const axios = require('axios');
const path = require("path");
require("dotenv").config();

const app = express();
const server = require('http').createServer(app);
const io = socketIo(server);

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const { spawn } = require('child_process');

// 정적 파일 서빙 경로 설정 (예: /stream)
const streamDir = path.join(__dirname, "stream");
app.use("/stream", express.static(streamDir));

// FFmpeg 프로세스를 시작합니다. HLS 스트리밍 설정
const ffmpeg = spawn("ffmpeg", [
  "-i", "-", // 입력을 표준 입력(stdin)에서 받습니다.
  "-c:v", "libx264", // 비디오 코덱 설정
  "-profile:v", "baseline", // 비디오 프로파일 설정
  "-bufsize", "6000k", // 버퍼 크기 설정
  "-pix_fmt", "yuv420p", // 픽셀 포맷 설정
  "-flags", "-global_header", // 헤더 플래그 설정
  "-hls_time", "10", // HLS 세그먼트 길이
  "-hls_list_size", "0", // HLS 플레이리스트 크기 설정
  "-f", "hls", // 포맷을 HLS로 설정
  path.join(streamDir, "output.m3u8") // 절대 경로로 설정
]);

io.on("connection", (socket) => {
  console.log("A new client has connected!");

  socket.on("stream_image", (imageBase64) => {
    // 받은 이미지를 이미지 처리 서버로 전송
    axios.post("http://localhost:5003/process_image", { image: imageBase64 })
      .then(response => {
        console.log("Image processing successful");
        const processedImageBase64 = response.data.processed_image;

        // 모자이크 처리된 이미지를 FFmpeg로 전송
        const buffer = Buffer.from(processedImageBase64, "base64");
        ffmpeg.stdin.write(buffer);

        // 클라이언트로 모자이크 처리된 이미지 전송
        socket.emit("receive_message", processedImageBase64);
      })
      .catch(error => {
        console.error("Error processing image:", error);
        socket.emit("receive_message", "Error processing image");
      });
  });

  socket.on("disconnect", () => console.log("Client disconnected"));
});


const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/makking';
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("MongoDB connection error:", err));

const PORT = process.env.PORT || 5001;
server.listen(PORT, () => console.log(`Server started on port ${PORT}`));
