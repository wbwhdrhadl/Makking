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
    "-f",
    "image2pipe",
    "-vcodec",
    "mjpeg",
    "-pix_fmt",
    "yuv420p",
    "-s",
    "320x240",
    "-r",
    "5",
    "-i",
    "-",
    "-c:v",
    "libx264",
    "-preset",
    "ultrafast",
    "-tune",
    "zerolatency",
    "-profile:v",
    "baseline",
    "-level",
    "3.1",
    "-maxrate",
    "3000k",
    "-bufsize",
    "6000k",
    "-pix_fmt",
    "yuv420p",
    "-g",
    "30",
    "-hls_time",
    "2",
    "-hls_list_size",
    "20",
    "-hls_flags",
    "delete_segments",
    "-f",
    "hls",
    outputFilePath,
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
      const response = await axios.post("http://localhost:5003/process_image", {
        image: imageBase64,
      });
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

// MongoDB 연결 설정
const mongoURI = process.env.MONGO_URI || "mongodb://localhost:27017/makking";
mongoose
  .connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("MongoDB 연결 성공"))
  .catch((err) => console.log("MongoDB 연결 오류:", err));

// Socket.IO 핸들링
io.on("connection", (socket) => {
  console.log("새로운 클라이언트가 연결되었습니다!");

  socket.on("stream_image", (imageBase64) => {
    axios
      .post("http://43.203.251.58:5003/process_image", {
        image: imageBase64,
      })
      .then((response) => {
        console.log("이미지 처리 성공");
        socket.emit("receive_message", response.data.processed_image);
      })
      .catch((error) => {
        console.error("이미지 처리 오류:", error);
        socket.emit("receive_message", "이미지 처리 오류");
      });
  });

  socket.on("disconnect", () => console.log("클라이언트 연결 해제"));
});

// 라우터 설정
const chatRouter = require("./routes/broaddetail.js");
const broadSettingRouter = require("./routes/broadSetting.js");
const s3Router = require("./routes/s3.js");
const userRouter = require("./routes/User.js");
const kakaoUserRouter = require("./routes/kakaoUser.js");
const naverLoginRouter = require("./routes/naverUser.js"); // 경로는 실제 파일 위치에 따라 다를 수 있습니다.

app.use("/", naverLoginRouter);
app.use("/", chatRouter);
app.use("/", s3Router);
app.use("/", kakaoUserRouter);
app.use("/", userRouter);
app.use("/", broadSettingRouter);

// 포트 설정 및 서버 시작
const PORT = process.env.PORT || 5001;
server.listen(PORT, () =>
  console.log(`서버가 포트 ${PORT}에서 시작되었습니다`)
);
