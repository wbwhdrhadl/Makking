const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// 메시지 스키마 및 모델 - username 필드와 시간 필드 추가
const MessageSchema = new mongoose.Schema({
  broadcastId: { type: mongoose.Schema.Types.ObjectId, ref: 'Broadcast', required: true },
  messages: [
    {
      username: { type: String, required: true },
      message: { type: String, required: true },
      createdAt: { type: Date, default: Date.now },
    },
  ],
  likes: { type: Number, default: 0 },
  likedBy: [{ type: String }],
});

const Message = mongoose.model('Message', MessageSchema);

// 메시지 가져오기 라우트
router.get('/messages/:broadcastId', async (req, res) => {
  try {
    const broadcastId = new mongoose.Types.ObjectId(req.params.broadcastId); // ObjectId로 변환
    const messages = await Message.findOne({ broadcastId }, { messages: { $slice: -16 } });

    if (!messages) {
      return res.status(404).send({ error: 'No messages found for this broadcast' });
    }
    res.send(messages.messages);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

// 새로운 메시지 포스트
router.post('/messages/:broadcastId', async (req, res) => {
  const { message, username } = req.body;
  try {
    const broadcastId = mongoose.Types.ObjectId(req.params.broadcastId); // ObjectId로 변환
    const updatedMessage = await Message.findOneAndUpdate(
      { broadcastId },
      { $push: { messages: { message, username, createdAt: new Date() } }, $setOnInsert: { likes: 0 } },
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
  const { userId } = req.body;
  try {
    const broadcastId = new mongoose.Types.ObjectId(req.params.broadcastId); // ObjectId로 변환
    const message = await Message.findOne({ broadcastId });

    if (!message) {
      return res.status(404).send({ error: 'No broadcast found to like' });
    }

    const userIndex = message.likedBy.indexOf(userId);

    if (userIndex === -1) {
      message.likes += 1;
      message.likedBy.push(userId);
    } else {
      message.likes -= 1;
      message.likedBy.splice(userIndex, 1);
    }

    await message.save();
    res.send({ likes: message.likes, likedBy: message.likedBy });
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

module.exports = router;
