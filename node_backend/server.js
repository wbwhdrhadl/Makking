const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
const socketIo = require('socket.io');
const axios = require('axios');
require("dotenv").config();
const cookieParser = require("cookie-parser");
const expressSession = require("express-session");
const MemoryStore = require("memorystore")(expressSession);
const app = express();
const server = require('http').createServer(app);
const io = socketIo(server);

app.use(cors({
  origin: "*", // 클라이언트 도메인
  credentials: true // 세션 쿠키를 허용하기 위해 필요
}));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.use(cookieParser());

app.use(
  expressSession({
    secret: "1234",
    resave: true,
    saveUninitialized: true,
    cookie: { secure: false, httpOnly: true } 

  })
);

// MongoDB 연결 설정
const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/makking';
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("MongoDB 연결 성공"))
  .catch((err) => console.log("MongoDB 연결 오류:", err));

// Socket.IO 핸들링
io.on('connection', (socket) => {
  console.log('새로운 클라이언트가 연결되었습니다!');

  socket.on('stream_image', (imageBase64) => {
    axios.post('http://172.30.1.13:5003/process_image', {
      image: imageBase64
    })
    .then(response => {
      console.log('이미지 처리 성공');
      socket.emit('receive_message', response.data.processed_image);
    })
    .catch(error => {
      console.error('이미지 처리 오류:', error);
      socket.emit('receive_message', '이미지 처리 오류');
    });
  });

  socket.on('disconnect', () => console.log('클라이언트 연결 해제'));
});

// 라우터 설정
const chatRouter = require("./routes/broaddata.js");
const s3Router = require("./routes/s3.js");
const userRouter = require("./routes/User.js");
const kakaoUserRouter = require("./routes/kakaoUser.js");
const naverLoginRouter = require('./routes/naverUser.js'); // 경로는 실제 파일 위치에 따라 다를 수 있습니다.

app.use('/', naverLoginRouter);
app.use("/", chatRouter);
app.use("/", s3Router);
app.use("/", kakaoUserRouter);
app.use("/", userRouter);


// 포트 설정 및 서버 시작
const PORT = process.env.PORT || 5001;
server.listen(PORT, () => console.log(`서버가 포트 ${PORT}에서 시작되었습니다`));
