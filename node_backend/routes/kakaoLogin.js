// kakaoLogin.js
const passport = require("passport");
const KakaoStrategy = require("passport-kakao").Strategy;
const User = require("./User"); // User 모델 가져오기

module.exports = function (passport) {
  passport.use(
    new KakaoStrategy(
      {
        clientID: process.env.KAKAO_CLIENT_ID, // 환경 변수 사용
        callbackURL: "http://localhost:8000/auth/kakao/callback",
      },
      function (accessToken, refreshToken, profile, done) {
        User.findOrCreate({ kakaoId: profile.id }, function (err, user) {
          return done(err, user);
        });
      }
    )
  );
};
