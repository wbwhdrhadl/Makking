const express = require('express');
const fetch = require('node-fetch');
const jwt = require('jsonwebtoken');

const app = express();

app.get('/auth/kakao/callback', async (req, res) => {
  const { code } = req.query; // 카카오로부터 받은 인가 코드
  try {
    const tokenResponse = await fetch('https://kauth.kakao.com/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: `grant_type=authorization_code&client_id=${process.env.KAKAO_CLIENT_ID}&redirect_uri=${process.env.KAKAO_REDIRECT_URI}&code=${code}`
    });

    const tokenJson = await tokenResponse.json();
    const accessToken = tokenJson.access_token;

    const userInfoResponse = await fetch('https://kapi.kakao.com/v2/user/me', {
      headers: {
        Authorization: `Bearer ${accessToken}`
      }
    });

    const userInfo = await userInfoResponse.json();

    const userToken = jwt.sign({
      id: userInfo.id, // 사용자 고유 ID
      email: userInfo.kakao_account.email // 사용자 이메일
    }, 'your_jwt_secret');

    res.json({ token: userToken }); // 클라이언트에 JWT 전송
  } catch (error) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
