const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");

// NaverUser 모델 정의
const naverUserSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  email: { type: String, unique: true, sparse: true },
  name: { type: String, required: true },
  gender: { type: String, required: true },
  phoneNumber: { type: String, sparse: true },
  accessToken: { type: String, required: true }
});

const NaverUser = mongoose.model("NaverUser", naverUserSchema, "naveruser");

// 네이버 로그인 또는 사용자 생성 API
router.post("/naverlogin", async (req, res) => {
  const { userId, email, name, gender, phoneNumber, accessToken } = req.body;

  try {
    console.log("Received login request:", req.body);

    // 사용자 찾기
    console.log("Attempting to find user with userId:", userId);
    let user = await NaverUser.findOne({ userId: userId });

    if (user) {
      console.log("User already exists, updating info");

      // 사용자 정보 업데이트
      user.email = email;
      user.name = name;
      user.gender = gender;
      user.phoneNumber = phoneNumber;
      user.accessToken = accessToken;

      console.log("Attempting to save updated user info");
      await user.save();
      console.log("User info updated successfully");
    } else {
      console.log("Creating new user");

      // 새 사용자 생성
      user = new NaverUser({ userId, email, name, gender, phoneNumber, accessToken });

      console.log("Attempting to save new user");
      await user.save();
      console.log("New user created successfully");
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
