const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
const WebSocket = require('ws');
const axios = require('axios');
require("dotenv").config();

const app = express();

app.use(cors()); // CORS 설정 추가
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// WebSocket 서버 설정
const wss = new WebSocket.Server({ port: 5002 }); // WebSocket 포트를 5002로 설정

wss.on('connection', function connection(ws) {
  console.log('A new client connected!');

  ws.on('message', async function incoming(message) {
    console.log('received: %s', message);

    // FastAPI 서버로 HTTP 요청을 보내 이미지 처리
    try {
      const response = await axios.post('http://172.30.1.13:5003/process_image', {
        image: message
      });
      // 처리된 이미지 데이터를 클라이언트로 전송
      ws.send(response.data.processed_image);
    } catch (error) {
      console.error('Error processing image:', error);
    }
  });

  ws.send('Hello! Message from server.');
});

const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/makking';
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("MongoDB 연결 성공"))
  .catch((err) => console.log("MongoDB 연결 오류:", err));

// 라우터 설정
const chatRouter = require("./routes/broaddata.js");
const s3Router = require("./routes/s3.js");
const userRouter = require("./routes/User.js");
const kakaoUserRouter = require("./routes/kakaoUser.js");

app.use("/", chatRouter);
app.use("/", s3Router);
app.use("/", kakaoUserRouter);
app.use("/", userRouter);

// Express 서버 포트 설정
const PORT = 5001;
app.listen(PORT, "0.0.0.0", () => console.log(`서버가 포트 ${PORT}에서 시작되었습니다`));
