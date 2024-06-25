const express = require("express");
const router = express.Router();
const KakaoUser = require('./kakaoUser'); // Assuming kakaoUser.js is in the same directory

// 사용자 로그인 또는 생성 엔드포인트
// JSON 데이터 파싱 미들웨어
router.use(express.json());

router.post("/loginOrCreateUser", async (req, res) => {
  const { userId, email, name, gender, phoneNumber, accessToken } = req.body;
  try {
    console.log("Received register request:", req.body);

    // 사용자 찾기
    let user = await KakaoUser.findOne({ userId: userId });
    if (user) {
      console.log("User already exists, updating info");

      // 사용자 정보 업데이트
      user.email = email;
      user.name = name;
      user.gender = gender;
      user.phoneNumber = phoneNumber;
      user.accessToken = accessToken;
      await user.save();
    } else {
      console.log("Creating new user");

      // 새 사용자 생성
      user = new KakaoUser({ userId, email, name, gender, phoneNumber, accessToken });
      await user.save();
    }

    console.log("User logged in or created successfully:", user);
    res.status(200).json({ message: "User logged in or created successfully", user: user });
  } catch (error) {
    // 에러 처리
    console.error("Error processing user information:", error);
    res.status(500).json({ error: "Internal Server Error", details: error.message });
  }
});


module.exports = router;
