const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
require("dotenv").config();

const app = express();

app.use(cors()); // CORS 설정 추가
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/makking';
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("MongoDB 연결 성공"))
  .catch((err) => console.log("MongoDB 연결 오류:", err));

// 라우터 설정
const chatRouter = require("./routes/chat.js"); 
const s3Router = require("./routes/s3.js");
const kakaoUserRouter = require("./routes/kakaoUser.js");
const kakaoLoginRouter = require("./routes/kakaoLogin.js");
const userRouter = require("./routes/User.js");
// chat.js의 경로 확인

app.use("/", chatRouter);
app.use("/", s3Router);
app.use("/", kakaoUserRouter);
app.use("/", userRouter);
app.use("/", kakaoLoginRouter); 


const PORT = 5001;
app.listen(PORT, "0.0.0.0", () => console.log(`서버가 포트 ${PORT}에서 시작되었습니다`));
