const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const multer = require("multer");
const { User, router: UserRouter } = require("./User.js");
const path = require('path');



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
  viewers: { type: Number, default: 0 }, // 시청자 수 추가
  is_live: { type: Boolean, default: true }, // 라이브 여부 필드 추가
  files: [
    {
      file_name: String,
      file_path: String,
      file_type: String, // e.g., 'video', 'thumbnail', 'metadata'
    }
  ]}, {
     timestamps: true // createdAt과 updatedAt 필드를 자동으로 추가
   });

const Broadcast = mongoose.model('Broadcast', broadcastSchema, "broadcast-setting");

// 방송 설정 저장 API
router.post('/broadcast/Setting', upload.fields([{ name: 'thumbnail' }, { name: 'face_image' }]), async (req, res) => {
  try {
    const { user_id, title, is_mosaic_enabled, is_subtitle_enabled } = req.body;
    const thumbnail_url = req.files['thumbnail'] ? req.files['thumbnail'][0].filename : null;
    const face_image_url = req.files['face_image'] ? req.files['face_image'][0].path : null; // 얼굴 이미지 경로 저장

    const newBroadcast = new Broadcast({
      user_id,
      title,
      is_mosaic_enabled,
      is_subtitle_enabled,
      thumbnail_url, // 썸네일 이미지 URL 저장
      face_image_url, // 얼굴 이미지 URL 저장
      is_live: true, // 기본값으로 라이브 상태를 false로 설정
    });

    await newBroadcast.save();

    res.status(200).json({ message: 'Broadcast saved successfully', thumbnail_url, face_image_url });
  } catch (error) {
    res.status(500).json({ message: 'Failed to save broadcast', error });
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

// 서버측 API 구현 (routes/broadSetting.js)
router.get('/broadcasts/live', async (req, res) => {
  try {
    const liveBroadcasts = await Broadcast.find({ is_live: true }).sort({ createdAt: -1 });

    // 각각의 방송에 대해 사용자 정보를 조회하여 병합
    const broadcastsWithUserInfo = await Promise.all(liveBroadcasts.map(async (broadcast) => {
      const user = await User.findById(broadcast.user_id);
      return {
        ...broadcast.toObject(),
        username: user ? user.name : 'Unknown User',
        profileImage: user ? user.profileImage : null,
      };
    }));

    res.status(200).json(broadcastsWithUserInfo);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch live broadcasts', error });
  }
});


// 이미지 파일 제공을 위한 라우터
router.get('/uploads/:filename', (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(__dirname, '../uploads', filename); // 현재 경로

  // 파일 경로를 로그로 출력하여 확인
  console.log('Serving file from:', filePath);

  res.sendFile(filePath, (err) => {
    if (err) {
      console.error(`Error serving file ${filename}:`, err);
      res.status(404).send("File not found");
    }
  });
});





// 파일 마지막 부분에 Broadcast 모델을 export
module.exports = {
  Broadcast,
  router, // 이미 라우터도 export하고 있는 경우 이렇게 추가
};

