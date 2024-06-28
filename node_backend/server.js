const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
const socketIo = require('socket.io');
const axios = require('axios');
const http = require('http');
require("dotenv").config();

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// MongoDB 연결 설정
const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/makking';
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log("MongoDB 연결 성공"))
.catch((err) => console.log("MongoDB 연결 오류:", err));

// Socket.IO 이벤트 핸들러
io.on('connection', (socket) => {
  console.log('A new client has connected!');

  socket.on('stream_image', (imageBase64) => {
    axios.post('http://172.30.1.13:5003/process_image', {
      image: imageBase64
    })
    .then(response => {
      console.log('Image processing successful');
      socket.emit('receive_message', response.data.processed_image);
    })
    .catch(error => {
      console.error('Error processing image:', error);
      socket.emit('receive_message', 'Error processing image');
    });
  });

  socket.on('disconnect', () => console.log('Client disconnected'));
});

// 라우터 설정
const chatRouter = require("./routes/broaddata.js");
const s3Router = require("./routes/s3.js");
const userRouter = require("./routes/User.js");
const kakaoUserRouter = require("./routes/kakaoUser.js");

app.use("/", chatRouter);
app.use("/", s3Router);
app.use("/", kakaoUserRouter);
app.use("/", userRouter);

const PORT = process.env.PORT || 5001;
server.listen(PORT, "0.0.0.0", () => console.log(`서버가 포트 ${PORT}에서 시작되었습니다`));
