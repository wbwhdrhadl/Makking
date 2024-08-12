const express = require('express');
const router = express.Router();
const axios = require('axios');

router.post('/sendSignedUrl', async (req, res) => {
  const { signedUrl } = req.body;

  if (!signedUrl) {
    return res.status(400).json({ message: 'Signed URL is required' });
  }

  try {
    // 모델 서버에 서명된 URL 전송
    const response = await axios.post('http://localhost:5003/process_image', {
      signedUrl: signedUrl,
    });

    if (response.status === 200) {
      console.log('Signed URL successfully sent to model server.');
      res.status(200).json({ message: 'Signed URL sent successfully.' });
    } else {
      res.status(500).json({ message: 'Failed to send signed URL to model server.' });
    }
  } catch (error) {
    console.error('Error sending signed URL to model server:', error);
    res.status(500).json({ message: 'Error sending signed URL to model server.' });
  }
});

module.exports = router;
