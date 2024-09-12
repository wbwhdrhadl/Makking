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
const fs = require("fs");
const { spawn } = require("child_process");
const { GridFSBucket } = require("mongodb");
const { Broadcast, router: broadSettingRouter } = require("./routes/broadSetting.js");
const { Message, router: MessageRouter, initSocket} = require('./routes/broaddetail.js');

app.use('/stream', express.static(path.join(__dirname, 'stream')));
app.use(cors({
    origin: "*",
    credentials: true,
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

const mongoURI = "mongodb://localhost:27017/makking";
const connection = mongoose.createConnection(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
});

let gfs;
connection.once('open', () => {
    gfs = new mongoose.mongo.GridFSBucket(connection.db, {
        bucketName: "uploads"
    });
    console.log("GridFS 연결 성공");
});

mongoose.connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
.then(() => console.log("MongoDB 연결 성공"))
.catch((err) => console.log("MongoDB 연결 오류:", err));

const streamDir = path.join(__dirname, "stream");
app.use("/stream", express.static(streamDir));

let ffmpeg;
let recording = false;
let videoBuffer = [];
let isVideoReady = false;

function startFFmpeg(userId) {
    const userStreamDir = path.join(streamDir, userId.toString());
    if (!fs.existsSync(userStreamDir)) {
        fs.mkdirSync(userStreamDir, { recursive: true });
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
        "-c:v", "h264_qsv",
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
        "-threads", "4",  // 스레드 사용 설정
        "-crf", "28",  // 품질-속도 균형 설정
        outputFilePath
    ]);

    ffmpeg.stdout.on("data", (data) => {
        console.log(`FFmpeg output: ${data.toString()}`);
    });

    ffmpeg.stderr.on("data", (data) => {
        console.error(`FFmpeg error: ${data.toString()}`);
    });

    ffmpeg.on('close', (code) => {
        console.log(`FFmpeg process exited with code ${code}`);
        ffmpeg = null;
    });

    recording = true;
    console.log(`Recording started: ${outputFilePath}`);
}

function attemptSyncAndStream() {
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
    }
}

async function updateBroadcastStatus(userId, isLive) {
    try {
        // 유저의 가장 최신 방송을 찾아 is_live 상태를 업데이트
        const updatedBroadcast = await Broadcast.findOneAndUpdate(
            { user_id: userId },  // 조건: 해당 유저의 방송
            { is_live: true },  // 업데이트할 필드
            { sort: { createdAt: -1 }, new: true }  // 최신 순으로 정렬하여 가장 최신 방송을 찾음
        );

        if (updatedBroadcast) {
            console.log(`Broadcast ${updatedBroadcast._id} is now ${isLive ? "live" : "not live"}.`);
        } else {
            console.error("Broadcast not found for this user.");
        }
    } catch (error) {
        console.error("Error updating broadcast status:", error);
    }
}

async function stopFFmpeg(userId) {
    if (ffmpeg) {
        ffmpeg.stdin.end();
        ffmpeg = null;
        recording = false;
        videoBuffer = [];
        isVideoReady = false;
        console.log("Recording stopped");

        try {
            const updatedBroadcast = await Broadcast.findOneAndUpdate(
                { user_id: userId },
                { is_live: false },
                { sort: { createdAt: -1 }, new: true }  // 최신 방송을 업데이트하도록 정렬 추가
            );

            if (updatedBroadcast) {
                console.log(`Broadcast ${updatedBroadcast._id} is now not live.`);
            } else {
                console.error("Broadcast not found for this user.");
            }
        } catch (error) {
            console.error("Error updating broadcast status:", error);
        }
    }
}

io.on("connection", (socket) => {
    let signedUrlSent = false;
    let userId;
    let recordingInProgress = false;

    socket.on("start_recording", async (data) => {
        if (recordingInProgress) {
            console.log("Recording is already in progress, ignoring start request.");
            return; // 이미 녹화 중이라면 더 이상 실행하지 않음
        }
        recordingInProgress = true; // 녹화 시작 상태로 설정

        userId = data.userId;
        const isMosaicEnabled = data.isMosaicEnabled;

        console.log("Received data:", data);  // 데이터를 모두 출력
        console.log("Received userId:", userId);
        console.log("isMosaicEnabled:", isMosaicEnabled);

        if (isMosaicEnabled) {
                console.log("모자이크가 활성화되었습니다.");
            }

        if (!userId) {
            console.error("userId가 누락되었습니다.");
            recordingInProgress = false;
            return;
        }

        updateBroadcastStatus(userId, true); // 방송 시작 시 is_live 상태를 true로 업데이트

        if (!recording) {
            startFFmpeg(userId);
        }

        if (!signedUrlSent && data.signedUrl) {
            try {
                await axios.post("http://localhost:5003/process_image", { signedUrl: data.signedUrl, isMosaicEnabled: data.isMosaicEnabled });
                console.log("Signed URL successfully sent to model server.");
                signedUrlSent = true
            } catch (error) {
                console.error("Error sending signed URL to model server:", error);
            }
        }
    });

    socket.on("stop_recording", () => {
        if (!recordingInProgress) {
            console.log("No recording in progress, ignoring stop request.");
            return; // 녹화 중이 아닌 경우 중지 처리 무시
        }
        recordingInProgress = false; // 녹화 중지 상태로 설정

        if (recording) {
            stopFFmpeg(userId);
            signedUrlSent = false;
        }
    });

    socket.on("stream_image", async (imageBase64) => {
        try {
            const response = await axios.post("http://localhost:5003/process_image", { image: imageBase64 });
            if (response.data.image) {
                videoBuffer.push(Buffer.from(response.data.image, "base64"));
                isVideoReady = true;
            } else {
                videoBuffer.push(Buffer.from(imageBase64, "base64"));
                isVideoReady = true;
            }
            attemptSyncAndStream();
        } catch (error) {
            console.error("Error processing image:", error);
        }
    });

    socket.on("joinRoom", (data) => {
        broadcastId = data.broadcastId;
        userId = data.userId;
        socket.join(broadcastId); // 사용자를 특정 방송 방에 추가
        console.log(`User ${userId} joined room ${broadcastId}`);
      });

      // 사용자가 채팅 메시지를 전송
      socket.on("sendMessage", async (data) => {
        console.log('Received message data:', data);
        const { broadcastId, message, username } = data;

        try {
          const updatedMessage = await Message.findOneAndUpdate(
            { broadcastId: new mongoose.Types.ObjectId(broadcastId) },
            { $push: { messages: { message, username, createdAt: new Date() } }, $setOnInsert: { likes: 0 } },
            { new: true, upsert: true }
          );

          console.log('Updated message:', updatedMessage.messages);
          io.to(broadcastId).emit("receiveMessage", updatedMessage.messages);
        } catch (error) {
          console.error("Error while updating message:", error);
        }
      });

    socket.on("disconnect", () => {
        console.log("Client disconnected");
    });
});


// Route 설정
const s3URLPassRouter = require("./routes/s3_url_pass.js");
const s3URLCreateRouter = require("./routes/s3_url_create.js");
const s3Router = require("./routes/s3.js");
const { router: userRouter } = require("./routes/User");
const kakaoUserRouter = require("./routes/kakaoUser.js");
const naverLoginRouter = require("./routes/naverUser.js");

initSocket(io);

app.use("/", s3URLPassRouter);
app.use("/", MessageRouter);
app.use("/", s3URLCreateRouter);
app.use("/", naverLoginRouter);
app.use("/", broadSettingRouter);
app.use("/", s3Router);
app.use("/", kakaoUserRouter);
app.use("/", userRouter);

const PORT = process.env.PORT || 5001;
server.listen(PORT, () => console.log(`서버가 포트 ${PORT}에서 시작되었습니다`));
