const express = require('express');
const router = express.Router();
const bodyParser = require('body-parser');
const multer = require("multer");
const fs = require('fs');
const path = require('path');
const env = require("dotenv").config({ path: "./.env" });

router.use(bodyParser.json());
router.use(bodyParser.urlencoded({ extended: false }));
router.use(express.json());
router.use(express.urlencoded({ extended: true }));

// 환경 변수 확인
console.log('ID:', process.env.ID);
console.log('SECRET:', process.env.SECRET);
console.log('BUCKET_NAME:', process.env.BUCKET_NAME);
console.log('MYREGION:', process.env.MYREGION);

const AWS = require('aws-sdk');
const ID = process.env.ID;
const SECRET = process.env.SECRET;
const BUCKET_NAME = process.env.BUCKET_NAME;
const MYREGION = process.env.MYREGION;

const s3 = new AWS.S3({ accessKeyId: ID, secretAccessKey: SECRET, region: MYREGION });

var storage = multer.memoryStorage(); // Use memory storage instead of disk storage
var upload = multer({ storage: storage });

router.get('/', function (req, res) {
  res.render('upload');
});

router.post('/uploadFile', upload.single('attachment'), function (req, res) {
  if (!req.file) {
    return res.status(400).send('No file uploaded.');
  }

  const uploadFile = (file) => {
    const params = {
      Bucket: BUCKET_NAME,
      Key: `${Date.now()}__${file.originalname}`,
      Body: file.buffer,
      ContentType: file.mimetype,
    };

    s3.upload(params, function (err, data) {
      if (err) {
        console.error('S3 Upload Error:', err);
        return res.status(500).send('S3 Upload Error');
      }
      console.log(`File uploaded successfully. ${data.Location}`);
      res.status(200).send({ message: 'File uploaded successfully', url: data.Location });
    });
  };

  try {
    uploadFile(req.file);
  } catch (err) {
    console.error('Upload Error:', err);
    res.status(500).send('Internal Server Error');
  }
});

module.exports = router;
