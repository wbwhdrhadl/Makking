const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");
const socketIo = require('socket.io');
const axios = require('axios');
require("dotenv").config();

const app = express();
const server = require('http').createServer(app);
const io = socketIo(server);

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

io.on('connection', (socket) => {
  console.log('A new client has connected!');

  socket.on('stream_image', async (imageBase64) => {
    try {
      const response = await axios.post('http://172.30.1.13:5003/process_image', { image: imageBase64 });
      socket.emit('receive_message', response.data.processed_image);
    } catch (error) {
      console.error('Error processing image:', error);
      socket.emit('receive_message', 'Error processing image');
    }
  });

  socket.on('disconnect', () => console.log('Client disconnected'));
});

const mongoURI = process.env.MONGO_URI || 'mongodb://localhost:27017/makking';
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.log("MongoDB connection error:", err));

const PORT = process.env.PORT || 5001;
server.listen(PORT, () => console.log(`Server started on port ${PORT}`));