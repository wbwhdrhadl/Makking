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
let imageQueue = []; // 이미지를 저장할 큐

function startFFmpeg() {
  const outputFilePath = path.join(streamDir, "output.m3u8");
  ffmpeg = spawn("ffmpeg", [
      "-f", "image2pipe",        // 이미지 데이터를 파이프 입력으로 받음
      "-vcodec", "mjpeg",        // 입력 비디오 코덱을 MJPEG로 설정
      "-pix_fmt", "yuvj420p",    // 픽셀 포맷을 YUV 4:2:0으로 설정 (JPEG는 yuvj420p)
      "-s", "1280x720",          // 해상도를 1280x720으로 설정 (더 나은 화질을 위해)
      "-r", "4",                // 프레임 레이트를 30fps로 설정
      "-i", "-",                 // 입력을 파이프로 받음
      "-c:v", "libx264",         // 출력 비디오 코덱을 H.264로 설정
      "-preset", "ultrafast",    // 인코딩 속도 우선의 설정
      "-tune", "zerolatency",    // 지연 시간을 최소화하기 위한 튜닝
      "-profile:v", "baseline",  // H.264 프로파일을 baseline으로 설정 (호환성)
      "-level", "3.1",           // H.264 레벨을 3.1로 설정
      "-maxrate", "3000k",       // 최대 비트레이트를 3000kbps로 설정
      "-bufsize", "6000k",       // 버퍼 크기를 6000kbps로 설정
      "-pix_fmt", "yuv420p",     // 출력 픽셀 포맷을 YUV 4:2:0으로 설정
      "-g", "30",                // GOP 크기를 60으로 설정 (두 번째 키프레임 간의 프레임 수)
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

  // 이미지 전송 타이머 설정
  setInterval(() => {
    if (imageQueue.length > 0) {
      const image = imageQueue.shift();
      if (ffmpeg && ffmpeg.stdin.writable) {
        ffmpeg.stdin.write(image);
      }
    }
  }, 300); // 0.3초 간격으로 이미지 전송
}

function stopFFmpeg() {
  if (ffmpeg) {
    ffmpeg.stdin.end();
    ffmpeg = null;
    recording = false;
    console.log("Recording stopped");
  }
}

let lastReceivedImage = null; // 최근 수신된 이미지 데이터를 저장할 변수

io.on("connection", (socket) => {
  console.log("A new client has connected!");

  let signedUrlSent = false; // 녹화 시작 시 한 번만 서명된 URL을 전송하기 위한 플래그

  socket.on("start_recording", async (signedUrl) => {
    if (!recording) {
      startFFmpeg();
    }

    if (!signedUrlSent && signedUrl) {
      try {
        // 모델 서버에 서명된 URL을 한 번만 전송
        const response = await axios.post("http://localhost:5003/process_image", {
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
      // 이미지를 처리하기 위해 다른 서버로 전송
      const response = await axios.post("http://localhost:5003/process_image", {
        image: imageBase64,
      });

      let buffer;
      if (response.data.image) {
        // 처리된 이미지의 Base64 데이터를 받아 디코딩
        const processedImageBase64 = response.data.image;
        buffer = Buffer.from(processedImageBase64, "base64");
      } else {
        // 얼굴이 탐지되지 않았으면 원본 이미지를 그대로 사용
        buffer = Buffer.from(imageBase64, "base64");
        console.log("얼굴이 탐지되지 않아 원본 이미지를 사용합니다.");
      }

      // 디코딩된 이미지를 FFmpeg로 전송
      if (ffmpeg && ffmpeg.stdin.writable) {
        ffmpeg.stdin.write(buffer);
      }
    } catch (error) {
      console.error("Error processing image:", error);
    }
  });


  socket.on("stop_recording", () => {
    if (recording) {
      stopFFmpeg();
      signedUrlSent = false; // 녹화 중지 시 서명된 URL 전송 여부 초기화
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
