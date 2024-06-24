const mongoose = require("mongoose");

const kakaoUserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  gender: { type: String, required: true },
  phoneNumber: { type: String, required: true },
  userId: { type: String, required: true, unique: true },
});

const kakaoUser = mongoose.model("kakaoUser", kakaoUserSchema, "kakaouser");

module.exports = kakaoUser;
