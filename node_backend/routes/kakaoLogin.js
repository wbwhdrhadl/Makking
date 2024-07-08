const passport = require("passport");
const KakaoStrategy = require("passport-kakao").Strategy;
const kakaoUser = require("./kakaoUser"); // 수정된 부분
const dotenv = require("dotenv");
const path = require("path");

dotenv.config({ path: path.join(__dirname, '../.env') });

module.exports = () => {
    passport.use(new KakaoStrategy({
        clientID: process.env.KAKAO_ID,
        callbackURL: 'http://43.203.251.58:5001/auth/kakao/callback',
    }, async (accessToken, refreshToken, profile, done) => {
        console.log('Kakao profile:', profile);
        try {
            const exUser = await kakaoUser.findOne({ snsId: profile.id, provider: 'kakao' });
            if (exUser) {
                done(null, exUser);
            } else {
                const newUser = await kakaoUser.create({
                    email: profile._json && profile._json.kakao_account_email,
                    nick: profile.displayName,
                    snsId: profile.id,
                    provider: 'kakao'
                });
                console.log("New user created:", newUser);
                done(null, newUser);
            }
        } catch (error) {
            console.error("Error processing user:", error);
            done(error);
        }
    }));
};
