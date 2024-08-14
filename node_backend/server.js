const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
const socketIo = require("socket.io");
const axios = require("axios");
require("dotenv").config();
const cookieParser = require("cookie-parser");
const expressSession = require("express-session");
const MemoryStore = require("memorystore")(expressSession);
const app = express();
const server = require("http").createServer(app);
const io = socketIo(server);
const path = require("path");
const { spawn } = require("child_process");

app.use(
  cors({
    origin: "*", // 클라이언트 도메인
    credentials: true, // 세션 쿠키를 허용하기 위해 필요
  })
);
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());

app.use(
  expressSession({
    secret: "1234",
    resave: true,
    saveUninitialized: true,
    cookie: { secure: false, httpOnly: true },
  })
);

const streamDir = path.join(__dirname, "stream");
app.use("/stream", express.static(streamDir));

let ffmpeg;
let recording = false;
let videoBuffer = []; // 비디오 데이터를 저장할 버퍼
let audioBuffer = []; // 오디오 데이터를 저장할 버퍼
let isVideoReady = false;
let isAudioReady = false;

function startFFmpeg() {
  const outputFilePath = path.join(streamDir, "output.m3u8");
  ffmpeg = spawn("ffmpeg", [
      "-f", "image2pipe",        // 이미지 데이터를 파이프 입력으로 받음
      "-vcodec", "mjpeg",        // 입력 비디오 코덱을 MJPEG로 설정
      "-pix_fmt", "yuvj420p",    // 픽셀 포맷을 YUV 4:2:0으로 설정 (JPEG는 yuvj420p)
      "-s", "320x240",           // 해상도를 320x240으로 설정
      "-r", "3",                 // 프레임 레이트를 3fps로 설정
      "-i", "-",                 // 입력을 파이프로 받음
      "-f", "alsa",              // 오디오 입력을 알사(또는 다른 오디오 장치)로 설정
      "-i", "hw:0",
      "-c:v", "libx264",         // 출력 비디오 코덱을 H.264로 설정
      "-c:a", "aac",             // 출력 오디오 코덱을 AAC로 설정
      "-b:a", "128k",            // 오디오 비트레이트를 128kbps로 설정
      "-preset", "ultrafast",    // 인코딩 속도 우선의 설정
      "-tune", "zerolatency",    // 지연 시간을 최소화하기 위한 튜닝
      "-profile:v", "baseline",  // H.264 프로파일을 baseline으로 설정 (호환성)
      "-level", "3.1",           // H.264 레벨을 3.1로 설정
      "-maxrate", "3000k",       // 최대 비트레이트를 3000kbps로 설정
      "-bufsize", "6000k",       // 버퍼 크기를 6000kbps로 설정
      "-pix_fmt", "yuv420p",     // 출력 픽셀 포맷을 YUV 4:2:0으로 설정
      "-g", "30",                // GOP 크기를 30으로 설정 (두 번째 키프레임 간의 프레임 수)
      "-hls_time", "2",          // HLS 세그먼트 길이를 2초로 설정
      "-hls_list_size", "20",    // HLS 목록 크기를 20으로 설정
      "-hls_flags", "delete_segments",  // 이전 HLS 세그먼트를 삭제하여 디스크 공간을 절약
      "-f", "hls",               // 출력 포맷을 HLS로 설정
      outputFilePath             // 출력 파일 경로
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
    videoBuffer = [];
    audioBuffer = [];
    isVideoReady = false;
    isAudioReady = false;
    console.log("Recording stopped");
  }
}

function attemptSyncAndStream() {
  if (isVideoReady && isAudioReady && ffmpeg && ffmpeg.stdin.writable) {
    const videoFrame = videoBuffer.shift();
    const audioFrame = audioBuffer.shift();

    // 동기화된 비디오 프레임과 오디오 데이터를 ffmpeg로 전송
    ffmpeg.stdin.write(videoFrame);
    ffmpeg.stdin.write(audioFrame);

    isVideoReady = videoBuffer.length > 0;
    isAudioReady = audioBuffer.length > 0;
  }
}

io.on("connection", (socket) => {
  console.log("A new client has connected!");

  let signedUrlSent = false;

  socket.on("start_recording", async (signedUrl) => {
    if (!recording) {
      startFFmpeg();
    }

    if (!signedUrlSent && signedUrl) {
      try {
        // 모델 서버에 서명된 URL을 전송
        await axios.post("http://localhost:5003/process_image", {
          signedUrl: signedUrl,
        });
        console.log("Signed URL successfully sent to model server.");
        signedUrlSent = true;
      } catch (error) {
        console.error("Error sending signed URL to model server:", error);
      }
    }
  });

  socket.on("stream_image", async (imageBase64) => {
    try {
      const response = await axios.post("http://localhost:5003/process_image", {
        image: imageBase64,
      });

      let buffer;
      if (response.data.image) {
        const processedImageBase64 = response.data.image;
        buffer = Buffer.from(processedImageBase64, "base64");
      } else {
        buffer = Buffer.from(imageBase64, "base64");
        console.log("얼굴이 탐지되지 않아 원본 이미지를 사용합니다.");
      }

      videoBuffer.push(buffer);
      isVideoReady = true;
      attemptSyncAndStream();
    } catch (error) {
      console.error("Error processing image:", error);
    }
  });

  socket.on("stream_audio", async (audioDataBase64) => {
    try {
      const buffer = Buffer.from(audioDataBase64, "base64");
      audioBuffer.push(buffer);
      isAudioReady = true;
      attemptSyncAndStream();
    } catch (error) {
      console.error("Error processing audio:", error);
    }
  });

  socket.on("stop_recording", () => {
    if (recording) {
      stopFFmpeg();
      signedUrlSent = false;
    }
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected");
  });
});

// MongoDB 연결 설정
const mongoURI ="mongodb://localhost:27017/makking";
mongoose
  .connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("MongoDB 연결 성공"))
  .catch((err) => console.log("MongoDB 연결 오류:", err));

// 라우터 설정
const chatRouter = require("./routes/broaddetail.js");
const broadSettingRouter = require("./routes/broadSetting.js");
const s3URLPassRouter = require("./routes/s3_url_pass.js");
const s3URLCreateRouter = require("./routes/s3_url_create.js");
const s3Router = require("./routes/s3.js");
const userRouter = require("./routes/User.js");
const kakaoUserRouter = require("./routes/kakaoUser.js");
const naverLoginRouter = require("./routes/naverUser.js");

app.use("/", s3URLPassRouter);
app.use("/", s3URLCreateRouter);
app.use("/", naverLoginRouter);
app.use("/", broadSettingRouter);
app.use("/", chatRouter);
app.use("/", s3Router);
app.use("/", kakaoUserRouter);
app.use("/", userRouter);

// 포트 설정 및 서버 시작
const PORT = process.env.PORT || 5001;
server.listen(PORT, () =>
  console.log(`서버가 포트 ${PORT}에서 시작되었습니다`)
);
