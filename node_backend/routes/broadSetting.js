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
  face_image_url: String, // 얼굴 이미지 URL 추가
  is_live: { type: Boolean, default: false }, // 라이브 여부 필드 추가
  files: [
    {
      file_name: String,
      file_path: String,
      file_type: String, // e.g., 'video', 'thumbnail', 'metadata'
    }
  ]
});

const Broadcast = mongoose.model('Broadcast', broadcastSchema, "broadcast-setting");

// 방송 설정 저장 API
router.post('/broadcast/Setting', upload.fields([{ name: 'thumbnail' }, { name: 'face_image' }]), async (req, res) => {
  try {
    const { user_id, title, is_mosaic_enabled, is_subtitle_enabled } = req.body;
    const thumbnail_url = req.files['thumbnail'] ? req.files['thumbnail'][0].path : null; // 썸네일 이미지 경로 저장
    const face_image_url = req.files['face_image'] ? req.files['face_image'][0].path : null; // 얼굴 이미지 경로 저장

    const newBroadcast = new Broadcast({
      user_id,
      title,
      is_mosaic_enabled,
      is_subtitle_enabled,
      thumbnail_url, // 썸네일 이미지 URL 저장
      face_image_url, // 얼굴 이미지 URL 저장
      is_live: false, // 기본값으로 라이브 상태를 false로 설정
    });

    await newBroadcast.save();

    res.status(200).json({ message: 'Broadcast saved successfully', thumbnail_url, face_image_url });
  } catch (error) {
    res.status(500).json({ message: 'Failed to save broadcast', error });
  }
});

// 라이브 방송 목록 조회 API
router.get('/broadcast/live', async (req, res) => {
  try {
    const broadcasts = await Broadcast.find({ is_live: true });
    res.status(200).json(broadcasts);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch live broadcasts', error });
  }
});

// 방송 라이브 상태 업데이트 API
router.patch('/broadcast/:id/live', async (req, res) => {
  const { id } = req.params;
  const { is_live } = req.body;

  try {
    const broadcast = await Broadcast.findByIdAndUpdate(id, { is_live }, { new: true });
    if (!broadcast) {
      return res.status(404).json({ message: 'Broadcast not found' });
    }
    res.status(200).json({ message: 'Broadcast updated successfully', broadcast });
  } catch (error) {
    res.status(500).json({ message: 'Failed to update broadcast', error });
  }
});

module.exports = router;
