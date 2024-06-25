const mongoose = require("mongoose");

const kakaoUserSchema = new mongoose.Schema({
  email: { type: String, unique: true, sparse: true },
  name: { type: String, required: true },
  gender: { type: String, required: true },
  phoneNumber: { type: String, sparse: true },
  userId: { type: String, required: true, unique: true },
  accessToken: { type: String, required: true }
});



const kakaoUser = mongoose.model("kakaoUser", kakaoUserSchema, "kakaouser");
