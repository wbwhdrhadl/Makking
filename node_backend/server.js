const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
require("dotenv").config();

const app = express();

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const mongoURI = process.env.MONGO_URI;
mongoose.connect(mongoURI, {

})
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("MongoDB connection error:", err));

// 라우터 설정
const s3Router = require("./routes/s3.js");
const userRouter = require("./routes/User.js");
const kakaoUserRouter = require("./routes/kakaoUser.js");
const kakaoLoginRouter = require("./routes/kakaoLogin.js");

app.use("/", s3Router);
app.use("/", userRouter);
app.use("/", kakaoUserRouter);
app.use("/", kakaoLoginRouter);

const PORT = 5001;
app.listen(PORT, "0.0.0.0", () => console.log(`Server started on port ${PORT}`));
