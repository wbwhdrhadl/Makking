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

app.use(cors({
    origin: "*", // 클라이언트 도메인
    credentials: true, // 세션 쿠키를 허용하기 위해 필요
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());

app.use(expressSession({
    secret: "1234",
    resave: true,
    saveUninitialized: true,
    cookie: { secure: false, httpOnly: true },
}));

const streamDir = path.join(__dirname, "stream");
app.use("/stream", express.static(streamDir));

let ffmpeg;
let recording = false;
let videoBuffer = []; // 비디오 데이터를 저장할 버퍼
let audioBuffer = []; // 오디오 데이터를 저장할 버퍼
let isVideoReady = false;
let isAudioReady = false;

function startFFmpeg(userId) {
    const userStreamDir = path.join(streamDir, userId.toString()); // socket.id 대신 userId를 사용
        if (!fs.existsSync(userStreamDir)) {
            fs.mkdirSync(userStreamDir, { recursive: true });
            console.log(`Created directory for user: ${userId}`);
        }

    const outputFilePath = path.join(userStreamDir, "output.m3u8");
    ffmpeg = spawn("ffmpeg", [
        "-f", "image2pipe",  // 비디오 프레임을 파이프로 입력받음
        "-vcodec", "mjpeg",
        "-pix_fmt", "yuvj420p",
        "-s", "320x240",
        "-r", "3",
        "-i", "-",  // 비디오 입력
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

    ffmpeg.stdout.on("data", (data) => {
        console.log(`FFmpeg output: ${data.toString()}`);
        if (data.toString().includes("Opening 'output.m3u8'")) {
            console.log("FFmpeg has started creating the output.m3u8 file.");
        }
    });

    ffmpeg.stderr.on("data", (data) => {
        console.error(`FFmpeg error: ${data.toString()}`);
    });

    ffmpeg.on('close', (code) => {
        console.log(`FFmpeg process exited with code ${code}`);
        ffmpeg = null; // Ensure to clear the ffmpeg instance after it's closed
    });

    recording = true;
    console.log(`Recording started: ${outputFilePath}`);
}

function attemptSyncAndStream() {
    console.log(`Buffer check: Video = ${videoBuffer.length}, FFmpeg writable = ${ffmpeg && ffmpeg.stdin.writable}`);
    if (isVideoReady && ffmpeg && ffmpeg.stdin.writable) {
        const videoFrame = videoBuffer.shift();

        try {
            if (videoFrame) {
                ffmpeg.stdin.write(videoFrame);
                console.log("Video frame written to FFmpeg.");
            }
        } catch (error) {
            console.error("Failed to write frames to FFmpeg:", error);
        }

        isVideoReady = videoBuffer.length > 0;
    } else {
        console.log(`Cannot sync/stream: Video ready = ${isVideoReady}, FFmpeg stdin writable = ${ffmpeg && ffmpeg.stdin.writable}`);
    }
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

io.on("connection", (socket) => {
    console.log("A new client has connected!");
    let signedUrlSent = false;
    let broadcastId;
    let userId; // userId를 여기에 정의합니다.

    socket.on("start_recording", async (data) => {
        userId = data.userId; // 클라이언트로부터 전달된 userId를 할당합니다.
        console.log("Received data:", userId); // 데이터가 올바르게 전달되고 있는지 확인
        userId = data.userId; // 클라이언트로부터 전달된 userId를 할당합니다.
        if (!userId) {
            console.error("userId is missing in the received data.");
            return;
        }

        if (!recording) {
            broadcastId = new mongoose.Types.ObjectId();
            socket.emit("broadcast_id", broadcastId.toString());
            startFFmpeg(userId); // userId를 사용해 FFmpeg를 시작합니다.
        }

        if (!signedUrlSent && data.signedUrl) {
            try {
                await axios.post("http://localhost:5003/process_image", { signedUrl: data.signedUrl });
                console.log("Signed URL successfully sent to model server.");
                signedUrlSent = true;
            } catch (error) {
                console.error("Error sending signed URL to model server:", error);
            }
        }
    });

    socket.on("stream_image", async (imageBase64) => {
        console.log("Received image for processing.");
        try {
            const response = await axios.post("http://localhost:5003/process_image", { image: imageBase64 });
            if (response.data.image) {
                console.log("Received processed image from model.");
                videoBuffer.push(Buffer.from(response.data.image, "base64"));
                isVideoReady = true;
            } else {
                console.log("No processed image received; using original.");
                videoBuffer.push(Buffer.from(imageBase64, "base64"));
                isVideoReady = true;
            }
            attemptSyncAndStream();
        } catch (error) {
            console.error("Error processing image:", error);
        }
    });

    socket.on("stop_recording", () => {
        if (recording) {
            stopFFmpeg(broadcastId, userId);
            signedUrlSent = false;
        }
    });

    socket.on("disconnect", () => {
        console.log("Client disconnected");
    });
});


// MongoDB connection setup
const mongoURI = "mongodb://localhost:27017/makking";
mongoose.connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => console.log("MongoDB 연결 성공"))
.catch((err) => console.log("MongoDB 연결 오류:", err));

// Route configuration
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

// Server port configuration and start
const PORT = process.env.PORT || 5001;
server.listen(PORT, () => console.log(`서버가 포트 ${PORT}에서 시작되었습니다`));
