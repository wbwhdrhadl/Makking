const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// 메시지 스키마 및 모델 - 좋아요 필드 및 시청자 수 필드 추가
const MessageSchema = new mongoose.Schema({
  broadcastId: { type: mongoose.Schema.Types.ObjectId, ref: 'Broadcast', required: true }, // 방송 참조
  broadcastName: { type: String, required: true },
  messages: [{ message: String, createdAt: { type: Date, default: Date.now } }],
  likes: { type: Number, default: 0 }, // 좋아요 필드 추가
  viewers: { type: Number, default: 0 } // 시청자 수 필드 추가
});


const Message = mongoose.model('Message', MessageSchema);


// 모든 메시지 가져오기 - 최신 16개만
router.get('/messages/:broadcastId', async (req, res) => {
  const { broadcastId } = req.params;
  try {
    const messages = await Message.findOne({ broadcastId }, { messages: { $slice: -16 } });
    if (!messages) {
      return res.status(404).send({ error: 'No messages found for this broadcast' });
    }
    res.send(messages.messages); // 최신 16개 메시지 반환
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});


// 새로운 메시지 포스트
router.post('/messages/:broadcastId', async (req, res) => {
  const { broadcastId } = req.params;
  const { message, broadcastName } = req.body;
  console.log(`Received message: ${message} for broadcastId: ${broadcastId}`);
  try {
    const updatedMessage = await Message.findOneAndUpdate(
      { broadcastId },
      { $push: { messages: { message } }, $setOnInsert: { broadcastName, likes: 0, viewers: 0 } },
      { new: true, upsert: true }
    );
    res.send(updatedMessage);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});


// 좋아요 수 업데이트 라우트
router.post('/messages/:broadcastId/like', async (req, res) => {
  const { broadcastId } = req.params;
  try {
    const updatedMessage = await Message.findOneAndUpdate(
      { broadcastId },
      { $inc: { likes: 1 } }, // 좋아요 수 1 증가
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );
    if (!updatedMessage) {
      return res.status(404).send({ error: 'No broadcast found to like' });
    }
    res.send(updatedMessage);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

// 시청자 수 업데이트 라우트
router.post('/messages/:broadcastId/viewers', async (req, res) => {
  const { broadcastId } = req.params;
  try {
    const updatedMessage = await Message.findOneAndUpdate(
      { broadcastId },
      { $inc: { viewers: 1 } }, // 시청자 수 1 증가
      { new: true, upsert: true, setDefaultsOnInsert: true }
    );
    if (!updatedMessage) {
      return res.status(404).send({ error: 'No broadcast found to update viewers' });
    }
    res.send(updatedMessage);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

module.exports = router;
