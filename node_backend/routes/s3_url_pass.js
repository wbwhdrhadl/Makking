const express = require('express');
const router = express.Router();
const axios = require('axios');

router.post('/sendSignedUrl', async (req, res) => {
  const { signedUrl, isMosaicEnabled } = req.body; // isMosaicEnabled도 받아옴

  if (!signedUrl) {
    return res.status(400).json({ message: 'Signed URL is required' });
  }

  try {
    // 모델 서버에 서명된 URL과 isMosaicEnabled 전송
    const response = await axios.post('http://3.36.104.253:5003/process_image', {
      signedUrl: signedUrl,
      isMosaicEnabled: isMosaicEnabled, // 모자이크 여부도 함께 전송
    });

    if (response.status === 200) {
      console.log('Signed URL and mosaic flag successfully sent to model server.');
      res.status(200).json({ message: 'Signed URL and mosaic flag sent successfully.' });
    } else {
      res.status(500).json({ message: 'Failed to send signed URL and mosaic flag to model server.' });
    }
  } catch (error) {
    console.error('Error sending signed URL and mosaic flag to model server:', error);
    res.status(500).json({ message: 'Error sending signed URL and mosaic flag to model server.' });
  }
});


module.exports = router;
