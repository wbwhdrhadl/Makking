const express = require("express");
const router = express.Router();
const User = require("./kakaoUser");

// 사용자 정보를 저장하는 API
router.post("/saveUser", async (req, res) => {
  const { id, email, name, gender, phoneNumber, accessToken } = req.body;

  console.log("Request received");

  try {
    console.log("Parsed data:", { id, email, name, gender, phoneNumber, accessToken });
    const kakaouser = await User.findOneAndUpdate(
      { kakaoId: id },
      { email, name, gender, phoneNumber, accessToken },
      { upsert: true, new: true }
    );

    console.log("User saved:", kakaouser);
    res.status(200).json({ message: "User information saved successfully", kakaouser });
  } catch (error) {
    console.error("Error saving user information:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});


module.exports = router;
