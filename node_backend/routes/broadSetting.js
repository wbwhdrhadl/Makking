const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const multer = require("multer");
const { User, router: UserRouter } = require("./User.js");
const { Message, router: MessageRouter } = require('./broaddetail.js');
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
router.post('/broadcast/setting', upload.fields([{ name: 'thumbnail' }, { name: 'face_image' }]), async (req, res) => {
  try {
    const { user_id, title, is_mosaic_enabled, is_subtitle_enabled } = req.body;
    const thumbnail_url = req.files['thumbnail'] ? req.files['thumbnail'][0].path : null;
    const face_image_url = req.files['face_image'] ? req.files['face_image'][0].path : null; // 얼굴 이미지 경로 저장

    // 방송 데이터 저장
    const newBroadcast = new Broadcast({
      user_id,
      title,
      is_mosaic_enabled,
      is_subtitle_enabled,
      thumbnail_url, // 썸네일 이미지 URL 저장
      face_image_url, // 얼굴 이미지 URL 저장
      is_live: true, // 기본값으로 라이브 상태를 true로 설정
    });

    // newBroadcast 저장 후 broadcast._id를 참조합니다.
    const savedBroadcast = await newBroadcast.save();

    // 메시지 데이터 생성 및 저장
    const message = new Message({
      broadcastId: savedBroadcast._id, // 저장된 방송의 ID 참조
      messages: [
        {
          username: user_id, // user_id 사용
          message: `${title} 방송이 시작되었습니다.`,
        },
      ],
    });
    await message.save();

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

router.get('/stream/:user_id/output.m3u8', async (req, res) => {
  const { user_id } = req.params;

  // 여기서 user_id를 기준으로 방송 정보를 가져옴
  try {
    const broadcast = await Broadcast.findOne({ user_id: user_id });

    if (!broadcast) {
      return res.status(404).send('Broadcast not found');
    }

    // 방송자의 user_id로 파일 경로를 설정
    const filePath = path.join(__dirname, '../stream', broadcast.user_id.toString(), 'output.m3u8');

    res.sendFile(filePath, (err) => {
      if (err) {
        console.error('Error serving m3u8 file:', err);
        res.status(404).send('File not found');
      }
    });
  } catch (error) {
    console.error('Error retrieving broadcast:', error);
    res.status(500).send('Internal Server Error');
  }
});



// 이미지 파일 제공을 위한 라우터
router.get('/uploads/:filename', (req, res) => {
  const filename = req.params.filename;
  const filePath = path.join(__dirname, '../uploads', filename); // 파일 경로 구성

  res.sendFile(filePath, (err) => {
    if (err) {
      console.error(`Error serving file ${filename}:`, err);
      res.status(404).send('File not found');
    }
  });
});

// ObjectId를 안전하게 변환하는 유틸리티 함수
function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id);
}

// 방송의 m3u8 URL 가져오기
router.get('/broadcast/:broadcastId', async (req, res) => {
  try {
    console.log('Received request for broadcast:', req.params.broadcastId);
    const broadcast = await Broadcast.findById(req.params.broadcastId);
    if (!broadcast) {
      console.log('Broadcast not found for id:', req.params.broadcastId);
      return res.status(404).json({ error: 'Broadcast not found' });
    }
    const user = await User.findById(broadcast.user_id); // 방송의 user_id로 사용자 검색
    if (!user) {
      console.log('User not found for user_id:', broadcast.user_id);
      return res.status(404).json({ error: 'User not found' });
    }
    console.log('Broadcast found:', broadcast);
    console.log('User found:', user);
    res.json({ userId: user._id, ...broadcast._doc });
  } catch (error) {
    console.error('Error fetching broadcast:', error);
    res.status(500).json({ error: 'Server error' });
  }
});





// 시청자 수 증가 API
router.post('/broadcast/:id/viewerEnter', async (req, res) => {
  try {
    const broadcastId = req.params.id;
    const broadcast = await Broadcast.findById(broadcastId);
    if (!broadcast) {
      return res.status(404).json({ message: 'Broadcast not found' });
    }

    broadcast.viewers += 1;
    await broadcast.save();
    res.status(200).json({ message: 'Viewer count increased', viewers: broadcast.viewers });
  } catch (error) {
    res.status(500).json({ message: 'Failed to increase viewer count', error });
  }
});

// 시청자 수 감소 API
router.post('/broadcast/:id/viewerExit', async (req, res) => {
  try {
    const broadcastId = req.params.id;
    const broadcast = await Broadcast.findById(broadcastId);
    if (!broadcast) {
      return res.status(404).json({ message: 'Broadcast not found' });
    }

    broadcast.viewers = Math.max(0, broadcast.viewers - 1); // 시청자 수가 음수가 되지 않도록
    await broadcast.save();
    res.status(200).json({ message: 'Viewer count decreased', viewers: broadcast.viewers });
  } catch (error) {
    res.status(500).json({ message: 'Failed to decrease viewer count', error });
  }
});








// 파일 마지막 부분에 Broadcast 모델을 export
module.exports = {
  Broadcast,
  router, // 이미 라우터도 export하고 있는 경우 이렇게 추가
};

