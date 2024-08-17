const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// 메시지 스키마 및 모델 - username 필드와 시간 필드 추가
const MessageSchema = new mongoose.Schema({
  broadcastId: { type: mongoose.Schema.Types.ObjectId, ref: 'Broadcast', required: true },
  messages: [
    {
      username: { type: String, required: true }, // username 필드 추가
      message: { type: String, required: true },
      createdAt: { type: Date, default: Date.now }, // 시간 필드 추가
    },
  ],
  likes: { type: Number, default: 0 },
  likedBy: [{ type: String }], // 각 사용자가 좋아요를 눌렀는지 확인하는 배열 추가
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
    res.send(messages.messages);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

// 새로운 메시지 포스트
router.post('/messages/:broadcastId', async (req, res) => {
  const { broadcastId } = req.params;
  const { message, username } = req.body;
  try {
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

// 좋아요 수 업데이트 라우트 (토글 기능 추가)
router.post('/messages/:broadcastId/like', async (req, res) => {
  const { broadcastId } = req.params;
  const { userId } = req.body; // 클라이언트에서 userId를 받아옴

  try {
    const message = await Message.findOne({ broadcastId });

    if (!message) {
      return res.status(404).send({ error: 'No broadcast found to like' });
    }

    const userIndex = message.likedBy.indexOf(userId);

    if (userIndex === -1) {
      // 사용자가 아직 좋아요를 누르지 않은 경우
      message.likes += 1;
      message.likedBy.push(userId);
    } else {
      // 사용자가 이미 좋아요를 누른 경우 (좋아요 취소)
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
