const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const bodyParser = require('body-parser');

// 메시지 스키마 및 모델
const MessageSchema = new mongoose.Schema({
  broadcastName: String,
  messages: [{ message: String, createdAt: { type: Date, default: Date.now } }]
});

const Message = mongoose.model('Message', MessageSchema);

// 모든 메시지 가져오기
router.get('/messages/:broadcastName', async (req, res) => {
    const { broadcastName } = req.params;
  try {
    const messages = await Message.findOne({ broadcastName });
    if (!messages) {
      return res.status(404).send({ error: 'No messages found for this broadcast name' });
    }
    res.send(messages);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

// 새로운 메시지 포스트
router.post('/messages/:broadcastName', async (req, res) => {
  const { broadcastName } = req.params;
  const { message } = req.body;
  console.log(`Received message: ${message} for broadcastName: ${broadcastName}`);
  try {
    const updatedMessage = await Message.findOneAndUpdate(
      { broadcastName },
      { $push: { messages: { message } } },
      { new: true, upsert: true }
    );
    res.send(updatedMessage);
  } catch (error) {
    console.error(error);
    res.status(500).send(error.message);
  }
});

const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/makking';
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("MongoDB 연결 성공"))
  .catch((err) => {
    console.log("MongoDB 연결 오류:", err);
    process.exit(1);
  });

module.exports = router;