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
      console.log("Username already exists");
      return res.status(400).json({ msg: "Username already exists" });
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
    req.session.user = {
      id:username,
      pw:password,
      authorized:true,
    };
    console.log("cookie입니다.")
    console.log(req.session.cookie)
    console.log("user입니다.")
    console.log(req.session.user)

    res.json({ msg: "Login successful" });
  } catch (err) {
    console.error("Error during user login:", err.message);
    res.status(500).send("Server error");
  }
});

router.get("/logout", async (req, res) => {
  console.log("로그아웃을 하면 다시 로그인 후 이용하여야합니다.");

  if(req.session.user) {
    console.log("로그아웃중입니다.")
    req.session.destroy((err) => {
      if(err) {
        console.log("세션 삭제시에 에러가 발생하였습니다.");
        return err;
      }
      console.log("세션이 삭제되었습니다.");

    })
  }
  else {
    console.log("비회원 이용중입니다.")
  }
})

router.get("/session", async (req, res) => {
  console.log("cookie입니다.")
  console.log(req.session.cookie)
  console.log("user입니다.")
  console.log(req.session.user)
  
})

module.exports = router;
