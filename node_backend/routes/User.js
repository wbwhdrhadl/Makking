const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

// MongoDB User Schema 및 Model 정의
const UserSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
  },
  password: {
    type: String,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
});

// 비밀번호 해싱
UserSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

const User = mongoose.model("User", UserSchema, "user-login");

// 회원가입 API
router.post("/register", async (req, res) => {
  const { username, password, name } = req.body;
  try {
    console.log("Received register request:", req.body);
    let user = await User.findOne({ username });
    if (user) {
      console.log("User already exists");
      return res.status(400).json({ msg: "User already exists" });
    }
    user = new User({ username, password, name });
    await user.save();
    console.log("User registered successfully");
    res.status(201).json({ msg: "User registered successfully" });
  } catch (err) {
    console.error("Error during user registration:", err.message);
    res.status(500).send("Server error");
  }
});

// 로그인 API
router.post("/login", async (req, res) => {
  const { username, password } = req.body;
  try {
    let user = await User.findOne({ username });
    if (!user) {
      return res.status(400).json({ msg: "Invalid credentials" });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ msg: "Invalid credentials" });
    }

    res.json({ msg: "Login successful" });
  } catch (err) {
    console.error("Error during user login:", err.message);
    res.status(500).send("Server error");
  }
});

module.exports = router;
