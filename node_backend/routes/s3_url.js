const express = require('express');
const AWS = require('aws-sdk');
const router = express.Router();

AWS.config.update({
    accessKeyId: process.env.ID,
    secretAccessKey: process.env.SECRET,
    region: process.env.MYREGION
});

const s3 = new AWS.S3();

router.use(express.json());

router.post('/generateSignedUrl', (req, res) => {
    const { imageUrl } = req.body;

    // S3 버킷과 객체 키를 추출
    const bucketName = process.env.BUCKET_NAME;
    const objectKey = imageUrl.split(`${bucketName}/`)[1];

    const params = {
        Bucket: bucketName,
        Key: objectKey,
        Expires: 60 * 5, // URL 만료 시간 (5분)
    };

    s3.getSignedUrl('getObject', params, (err, url) => {
        if (err) {
            return res.status(500).json({ message: 'Signed URL 생성 실패', error: err });
        }
        res.json({ signedUrl: url });
    });
});

module.exports = router;
