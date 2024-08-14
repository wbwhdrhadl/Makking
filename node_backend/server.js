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
const fs = require("fs"); // fs 모듈 추가
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

function startFFmpeg(userId) {
  const userStreamDir = path.join(streamDir, userId.toString());

  if (!fs.existsSync(userStreamDir)) {
    fs.mkdirSync(userStreamDir, { recursive: true }); // 유저별 폴더 생성
    console.log(`Created directory for user: ${userId}`);
  }

  const outputFilePath = path.join(userStreamDir, "output.m3u8");
  ffmpeg = spawn("ffmpeg", [
    "-f", "image2pipe",
    "-vcodec", "mjpeg",
    "-pix_fmt", "yuvj420p",
    "-s", "320x240",
    "-r", "3",
    "-i", "-",
    "-f", "alsa",
    "-i", "hw:0",
    "-c:v", "libx264",
    "-c:a", "aac",
    "-b:a", "128k",
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

  ffmpeg.stdout.on("data", (data) => {
    const message = data.toString();
    console.log(`FFmpeg output: ${message}`);

    // 파일 생성 시작 로그
    if (message.includes("Opening 'output.m3u8'")) {
      console.log("FFmpeg has started creating the output.m3u8 file.");
    }
  });

  ffmpeg.stderr.on("data", (data) => {
    console.error(`FFmpeg error: ${data}`);
  });

  ffmpeg.on("close", (code) => {
    console.log(`FFmpeg process exited with code ${code}`);
  });

  recording = true;
  console.log(`Recording started: ${outputFilePath}`);
}

function stopFFmpeg(broadcastId, userId) {
  if (ffmpeg) {
    ffmpeg.stdin.end();
    ffmpeg = null;
    recording = false;
    videoBuffer = [];
    audioBuffer = [];
    isVideoReady = false;
    isAudioReady = false;
    console.log("Recording stopped");

    const userStreamDir = path.join(streamDir, userId.toString());

    const filesToSave = fs.readdirSync(userStreamDir).map(file => ({
        file_name: file,
        file_path: path.join(userStreamDir, file),
        file_type: 'video' // 이 부분은 파일 타입에 따라 변경 가능
     }));

    // 파일 경로를 저장하고, 라이브 상태를 false로 업데이트
    Broadcast.findByIdAndUpdate(broadcastId, {
      $push: { files: { $each: filesToSave } },
      $set: { is_live: false }
    })
    .then(() => console.log("Files saved to database, broadcast stopped"))
    .catch(err => console.error("Failed to save files to database:", err));
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
  let broadcastId;

  socket.on("start_recording", async (signedUrl) => {
    if (!recording) {
      // 고유한 방송 ID 생성
      broadcastId = new mongoose.Types.ObjectId();

      // 방송을 시작할 때 ID를 클라이언트로 보낼 수도 있음
      socket.emit("broadcast_id", broadcastId.toString());
      startFFmpeg(socket.id); // 클라이언트의 고유 ID를 사용해 폴더 생성
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
      stopFFmpeg(broadcastId); // 방송 ID와 함께 FFmpeg 종료
      signedUrlSent = false;
    }
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected");
  });
});

// MongoDB 연결 설정
const mongoURI = "mongodb://localhost:27017/makking";
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
