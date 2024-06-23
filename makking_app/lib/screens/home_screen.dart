import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'broadcast_list_screen.dart';
import 'login.dart'; // login.dart 파일을 import 합니다.
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 하얀색으로 설정
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: screenWidth * 0.5,
                  height: screenHeight * 0.4,
                  child: Image.asset(
                    'assets/logo.jpeg',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: () {
                    _loginWithKakaoTalk(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/kakao_login.jpeg'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      width: screenWidth * 0.6,
                      height: screenHeight * 0.08,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: () {
                    _loginWithNaver(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/naver_login.jpeg'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      width: screenWidth * 0.6,
                      height: screenHeight * 0.08,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BroadcastListScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    fixedSize: Size(screenWidth * 0.6, screenHeight * 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: Text('비회원으로 계속하기'),
                ),
                SizedBox(height: screenHeight * 0.02),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    fixedSize: Size(screenWidth * 0.6, screenHeight * 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: Text('회원으로 로그인하기'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loginWithKakaoTalk(BuildContext context) async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
      print('카카오톡으로 로그인 성공');
      await _printUserInfo(token);
      Navigator.push(context, MaterialPageRoute(builder: (context) => BroadcastListScreen()));
    } catch (error) {
      print('카카오톡으로 로그인 실패: $error');
      _loginWithKakaoAccount(context);  // Fallback to Kakao account login if KakaoTalk login fails
    }
  }

  Future<void> _loginWithKakaoAccount(BuildContext context) async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      print('카카오 계정으로 로그인 성공');
      await _printUserInfo(token);
    } catch (error) {
      print('카카오 계정으로 로그인 실패: $error');
    }
  }

  // This function needs to be defined
  Future<void> _loginWithNaver(BuildContext context) async {
    // Implement Naver login logic here
    print('Implement Naver login logic!');
  }

  Future<void> _printUserInfo(OAuthToken token) async {
    try {
      User user = await UserApi.instance.me();
      print("사용자 ID: ${user.id}");
      print("이메일: ${user.kakaoAccount?.email}");
      print("이름: ${user.kakaoAccount?.profile?.nickname}");
      print("성별: ${user.kakaoAccount?.gender}");
      print("전화번호: ${user.kakaoAccount?.phoneNumber}");

      // 사용자 정보를 서버로 전송
      await _sendUserInfoToServer(user, token.accessToken);
    } catch (error) {
      print("사용자 정보 요청 실패: $error");
    }
  }

  Future<void> _sendUserInfoToServer(User user, String accessToken) async {
    final url = Uri.parse('http://172.30.1.13:8000/api');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id': user.id,
        'email': user.kakaoAccount?.email,
        'name': user.kakaoAccount?.profile?.nickname,
        'gender': user.kakaoAccount?.gender.toString(),
        'phoneNumber': user.kakaoAccount?.phoneNumber,
        'accessToken': accessToken,
      }),
    );

    if (response.statusCode == 200) {
      print('사용자 정보 서버 저장 성공');
    } else {
      print('사용자 정보 서버 저장 실패: ${response.statusCode}');
    }
  }
}
