const express = require("express");
const router = express.Router();
const User = require("./User");

// 사용자 정보를 저장하는 API
router.post("/saveUser", async (req, res) => {
  const { id, email, name, gender, phoneNumber, accessToken } = req.body;

  try {
    // 사용자 정보를 저장 또는 업데이트
    const kakaouser = await User.findOneAndUpdate(
      { kakaoId: id },
      {
        email,
        name,
        gender,
        phoneNumber,
        accessToken,
      },
      { upsert: true, new: true }
    );

    res.status(200).json({ message: "User information saved successfully", user });
  } catch (error) {
    console.error("Error saving user information:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

module.exports = router;