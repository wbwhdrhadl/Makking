const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const multer = require("multer");

// Multer 설정
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/'); // 파일이 저장될 경로
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname); // 파일 이름 설정
  }
});

const upload = multer({ storage: storage });

// MongoDB Broadcast Schema 및 Model 정의
const broadcastSchema = new mongoose.Schema({
  user_id: String,
  title: String,
  is_mosaic_enabled: Boolean,
  is_subtitle_enabled: Boolean,
  thumbnail_url: String, // 썸네일 이미지 URL 필드 추가
});

const Broadcast = mongoose.model('Broadcast', broadcastSchema, "broadcast-setting");

// 방송 설정 저장 API
router.post('/broadcast/Setting', upload.single('thumbnail'), async (req, res) => {
  try {
    const { user_id, title, is_mosaic_enabled, is_subtitle_enabled } = req.body;
    const thumbnail_url = req.file ? req.file.path : null; // 썸네일 이미지 경로 저장

    const newBroadcast = new Broadcast({
      user_id,
      title,
      is_mosaic_enabled,
      is_subtitle_enabled,
      thumbnail_url, // 썸네일 이미지 URL 저장
    });

    await newBroadcast.save();

    res.status(200).json({ message: 'Broadcast saved successfully', image: thumbnail_url });
  } catch (error) {
    res.status(500).json({ message: 'Failed to save broadcast', error });
  }
});

module.exports = router;
