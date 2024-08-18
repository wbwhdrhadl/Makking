const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { User, router: UserRouter } = require('./User.js');

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

let io;

function initSocket(socketIo) {
  io = socketIo;
}

// 메시지 가져오기 라우트
router.post('/messages/:broadcastId', async (req, res) => {
  const { broadcastId } = req.params;
  const { message, username } = req.body;

  try {
    // 유저 ID 기반으로 name을 조회
    console.log('Fetching user with ID:', username);
    const user = await User.findById(username).select('name');

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    console.log('User found:', user);
    const userName = user.name;

    // 메시지를 데이터베이스에 저장
    const updatedMessage = await Message.findOneAndUpdate(
      { broadcastId: new mongoose.Types.ObjectId(broadcastId) },
      {
        $push: { messages: { message, username: userName, createdAt: new Date() } },
        $setOnInsert: { likes: 0 },
      },
      { new: true, upsert: true }
    );

    console.log('Updated message:', updatedMessage.messages);

    // 해당 방송 방에 메시지를 전송
    io.to(broadcastId).emit('receiveMessage', updatedMessage.messages);

    res.send(updatedMessage);
  } catch (error) {
    console.error('Error while updating message:', error);
    res.status(500).send({ error: error.message });
  }
});

// 메시지 불러오기
router.get('/messages/:broadcastId', async (req, res) => {
  const { broadcastId } = req.params;

  try {
    const messages = await Message.findOne({ broadcastId: new mongoose.Types.ObjectId(broadcastId) });
    res.json(messages.messages);
  } catch (error) {
    console.error('Error while fetching messages:', error);
    res.status(500).send({ error: error.message });
  }
});



// 좋아요 수 업데이트 라우트
router.post('/messages/:broadcastId/like', async (req, res) => {
  const { userId } = req.body;
  const { broadcastId } = req.params;

  // ObjectId 유효성 검사
  if (!mongoose.isValidObjectId(broadcastId)) {
    return res.status(400).send({ error: 'Invalid broadcastId format' });
  }

  try {
    const message = await Message.findOne({ broadcastId: new mongoose.Types.ObjectId(broadcastId) });

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

module.exports = {
  Message,
  router,
  initSocket,
};
