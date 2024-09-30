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
const { Message, router: MessageRouter, initSocket } = require('./routes/broaddetail.js');

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

const mongoURI = "mongodb://43.201.248.85:27017/makking";
const connection = mongoose.createConnection(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
});

const instance = axios.create({
    baseURL: 'http://43.202.253.68:5003',
    timeout: 120000,  // 타임아웃 시간 설정 (예: 60초)
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
let audioBuffer = [];
let isVideoReady = false;
let isProcessing = false;
const MAX_BUFFER_SIZE = 100;  // 버퍼 크기 제한

function startFFmpeg(userId) {
    const userStreamDir = path.join(streamDir, userId.toString());
    if (!fs.existsSync(userStreamDir)) {
        fs.mkdirSync(userStreamDir, { recursive: true });
        console.log(`Created directory for user: ${userId}`);
    }

    console.log(`userStreamDir: ${userStreamDir}`);  // userStreamDir 값을 출력
    socket.emit('stream_path', { path: userStreamDir });

    const outputFilePath = path.join(userStreamDir, "output.m3u8");
    ffmpeg = spawn("/usr/local/bin/ffmpeg", [
        "-re",
        "-f", "image2pipe",
        "-vcodec", "mjpeg",
        "-pix_fmt", "yuvj420p",
        "-s", "320x240",
        "-r", "5",
        "-i", "-",  // 비디오 프레임 입력
        "-f", "s16le",
        "-ar", "44100",
        "-ac", "2",
        "-i", "-",  // 오디오 입력
        "-shortest", // 오디오와 비디오의 길이를 맞춤
        "-c:v", "libx264",
        "-preset", "ultrafast",
        "-tune", "zerolatency",
        "-profile:v", "baseline",
        "-level", "3.1",
        "-maxrate", "3000k",
        "-bufsize", "6000k",
        "-pix_fmt", "yuv420p",
        "-g", "30",
        "-c:a", "aac", // 오디오 코덱
        "-b:a", "128k", // 오디오 비트레이트
        "-hls_time", "2",
        "-hls_list_size", "20",
        "-hls_flags", "delete_segments",
        "-f", "hls",
        "-threads", "4",
        "-crf", "20",
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
    if (isVideoReady && ffmpeg && ffmpeg.stdin.writable && !isProcessing) {
        isProcessing = true;

        const videoFrame = videoBuffer.shift();
        const audioFrame = audioBuffer.shift(); // 오디오 프레임도 가져옴

        if (videoFrame && audioFrame) {
            try {
                // 비디오와 오디오 프레임을 순차적으로 FFmpeg에 전달
                ffmpeg.stdin.write(videoFrame.frame, (err) => {
                    if (err) {
                        console.error("Error writing video to FFmpeg stdin:", err);
                    } else {
                        console.log("Video frame written to FFmpeg.");
                    }

                    ffmpeg.stdin.write(audioFrame.frame, (err) => {
                        if (err) {
                            console.error("Error writing audio to FFmpeg stdin:", err);
                        } else {
                            console.log("Audio frame written to FFmpeg.");
                        }

                        isProcessing = false;

                        // 버퍼에 남은 프레임이 있을 경우 다음 프레임을 처리
                        if (videoBuffer.length > 0 || audioBuffer.length > 0) {
                            attemptSyncAndStream();
                        } else {
                            isVideoReady = false; // 더 이상 처리할 프레임이 없음을 나타냄
                        }
                    });
                });
            } catch (error) {
                console.error("Failed to write frames to FFmpeg:", error);
                isProcessing = false;
            }
        } else {
            isProcessing = false;
        }
    }
}

async function updateBroadcastStatus(userId, isLive) {
    try {
        // 유저의 가장 최신 방송을 찾아 is_live 상태를 업데이트
        const updatedBroadcast = await Broadcast.findOneAndUpdate(
            { user_id: userId },  // 조건: 해당 유저의 방송
            { is_live: isLive },  // 업데이트할 필드
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
        audioBuffer = [];
        isVideoReady = false;
        console.log("Recording stopped");

        await updateBroadcastStatus(userId, false); // 방송 중지 시 is_live 상태를 false로 업데이트
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

        await updateBroadcastStatus(userId, true); // 방송 시작 시 is_live 상태를 true로 업데이트

        if (!recording) {
            startFFmpeg(userId);
        }

        if (!signedUrlSent && data.signedUrl) {
            try {
                await axios.post("http://43.202.253.68:5003/process_image", { signedUrl: data.signedUrl, isMosaicEnabled: data.isMosaicEnabled });
                console.log("Signed URL successfully sent to model server.");
                signedUrlSent = true;
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

    socket.on("stream_image", async (imageBase64, timestamp) => {
        timestamp = timestamp || Date.now();
        console.log(`Frame received with timestamp: ${timestamp}`);

        try {
            const data = { image: imageBase64 };
            const response = await instance.post("/process_image", data);

            if (response.data.image) {
                videoBuffer.push({ frame: Buffer.from(response.data.image, "base64"), timestamp: timestamp });
            } else {
                videoBuffer.push({ frame: Buffer.from(imageBase64, "base64"), timestamp: timestamp });
            }

            // 버퍼 크기 제한 체크
            if (videoBuffer.length > MAX_BUFFER_SIZE) {
                console.warn("Buffer overflow detected! Clearing the buffer to prevent memory issues.");
                videoBuffer = []; // 버퍼 비우기
            }

            // 타임스탬프를 기준으로 버퍼 정렬
            videoBuffer.sort((a, b) => a.timestamp - b.timestamp);

            isVideoReady = true;
            attemptSyncAndStream();  // 프레임 스트리밍 시도

            // 현재 버퍼 크기 출력
            console.log(`Current video buffer size: ${videoBuffer.length}`);
        } catch (error) {
            console.error("Error processing image:", error);
        }
    });

    socket.on("stream_audio", (audioBase64, timestamp) => {
        timestamp = timestamp || Date.now();
        console.log(`Audio frame received with timestamp: ${timestamp}`);

        const audioFrame = Buffer.from(audioBase64, "base64");
        audioBuffer.push({ frame: audioFrame, timestamp: timestamp });

        if (audioBuffer.length > MAX_BUFFER_SIZE) {
            console.warn("Audio buffer overflow detected! Clearing the buffer to prevent memory issues.");
            audioBuffer = [];
        }

        // 버퍼 정렬 및 스트리밍 시도
        audioBuffer.sort((a, b) => a.timestamp - b.timestamp);
        attemptSyncAndStream();

        console.log(`Current audio buffer size: ${audioBuffer.length}`);
    });

    socket.on("joinRoom", (data) => {
        const { broadcastId, userId } = data;
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
