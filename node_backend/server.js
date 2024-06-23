const cors = require("cors");
const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
require("dotenv").config();

const app = express();

app.use(cors()); // CORS 설정
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const mongoURI = process.env.MONGO_URI;
mongoose
  .connect(mongoURI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("MongoDB connection error:", err));

// 라우터 설정
const s3Router = require("./routes/s3.js");
const userRouter = require("./routes/User.js");
const kakaoLoginRouter = require('./routes/kakaoLogin.js'); // 카카오 로그인 라우터 가져오기

app.use("/", s3Router);
app.use("/", userRouter);
app.use("/", kakaoLoginRouter); // 카카오 로그인 라우터 사용

// 새로운 라우터 추가
const saveUserRouter = require('./routes/saveUser.js'); // 사용자 정보를 저장하는 라우터
app.use("/api", saveUserRouter); // 새로운 라우터 사용

const PORT = 8000;
app.listen(PORT, "0.0.0.0", () =>
  console.log(`Server started on port ${PORT}`)
);
