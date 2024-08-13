const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const multer = require("multer"); // Multer 패키지 추가
const fs = require('fs');
const path = require('path');

// uploads 디렉터리 확인 및 생성
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}

// Multer 설정
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/'); // 파일이 저장될 경로
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname); // 파일 이름 설정
  }
});

// 파일 필터링: 이미지만 허용
const upload = multer({ 
  storage: storage,
  fileFilter: function (req, file, cb) {
    const fileTypes = /jpeg|jpg|png|gif/;
    const extname = fileTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = fileTypes.test(file.mimetype) || file.mimetype === 'application/octet-stream';

    console.log('File Original Name:', file.originalname);
    console.log('File MIME Type:', file.mimetype);
    console.log('File Extension Name:', extname);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only images are allowed!'));
    }
  }
});



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
  profileImage: {
    type: String, // 프로필 이미지 경로
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
router.post("/register", upload.single('profileImage'), async (req, res) => {
  const { username, password, name } = req.body;
  const profileImage = req.file ? req.file.path : null;

  try {
    console.log("Received register request:", req.body);
    let user = await User.findOne({ username });
    if (user) {
      console.log("Username already exists");
      return res.status(400).json({ msg: "Username already exists" });
    }
    user = new User({ username, password, name, profileImage });
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
      id: username,
      pw: password,
      authorized: true,
    };

    console.log("cookie입니다.");
    console.log(req.session.cookie);
    console.log("user입니다.");
    console.log(req.session.user);
    console.log('User ID:', user._id); // Add this line for debugging
    // user._id 추가 반환
    res.json({
      msg: "Login successful",
      userId: user._id,  // MongoDB의 _id를 userId로 반환
    });
  } catch (err) {
    console.error("Error during user login:", err.message);
    res.status(500).send("Server error");
  }
});


router.get('/user/:userId', async (req, res) => {
  try {
      const userId = req.params.userId;
      console.log(`Fetching user with ID: ${userId}`);
      
      const user = await User.findById(userId);
      
      if (!user) {
          console.log('User not found');
          return res.status(404).json({ msg: 'User not found' });
      }

      console.log('User found:', user);
      
      res.json({
          username: user.username,
          image_url: user.profileImage,
      });
  } catch (error) {
      console.error('Error fetching user:', error);
      res.status(500).json({ msg: 'Server error' });
  }
});


// 정적 파일 제공을 위한 경로 설정
router.use('/uploads', express.static(path.join(__dirname, 'uploads')));

module.exports = router;
