const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");

const broadcastSchema = new mongoose.Schema({
  user_id: String,  // 유저를 식별할 수 있는 필드 추가
  title: String,
  is_mosaic_enabled: Boolean,
  is_subtitle_enabled: Boolean,
  image_url: String,
});

const Broadcast = mongoose.model('Broadcast', broadcastSchema, "broadcast-setting");

router.post('/broadcast/Setting', async (req, res) => {
  try {
    const { user_id, title, is_mosaic_enabled, is_subtitle_enabled, image_url } = req.body;

    const newBroadcast = new Broadcast({
      user_id,  // 유저 ID 추가
      title,
      is_mosaic_enabled,
      is_subtitle_enabled,
      image_url,
    });

    await newBroadcast.save();

    res.status(200).json({ message: 'Broadcast saved successfully',image: image_url  });
  } catch (error) {
    res.status(500).json({ message: 'Failed to save broadcast', error });
  }
});

module.exports = router;
