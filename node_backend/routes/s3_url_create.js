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

    // URL에서 버킷 이름 이후의 경로 (objectKey) 추출
    try {
        const url = new URL(imageUrl);
        const bucketName = process.env.BUCKET_NAME;
        const objectKey = url.pathname.slice(1);  // URL의 경로에서 leading '/' 제거

        console.log("Extracted Object Key:", objectKey); // 디버그 출력

        if (!objectKey) {
            return res.status(400).json({ message: "Object key 추출 실패", error: "Object key가 없습니다." });
        }

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
    } catch (err) {
        return res.status(400).json({ message: "Invalid URL", error: err.message });
    }
});

module.exports = router;
