import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'broadcast_list_screen.dart';
import 'login.dart'; // login.dart 파일을 import 합니다.

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String accessToken = '';
  String tokenType = '';
  String refreshToken = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                _loginButton(
                  imagePath: 'assets/kakao_login.jpeg',
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  onPressed: () => _loginWithKakaoTalk(context),
                ),
                SizedBox(height: screenHeight * 0.02),
                _loginButton(
                  imagePath: 'assets/naver_login.jpeg',
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  onPressed: _loginWithNaver,
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

  Widget _loginButton({required String imagePath, required double screenWidth, required double screenHeight, required Function() onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: screenWidth * 0.6,
          height: screenHeight * 0.08,
        ),
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

  void _loginWithNaver() async {
    try {
      final NaverLoginResult user = await FlutterNaverLogin.logIn();
      NaverAccessToken res = await FlutterNaverLogin.currentAccessToken;

      setState(() {
        accessToken = res.accessToken;  // accessToken을 상태에 저장
        tokenType = res.tokenType;      // tokenType을 상태에 저장
        refreshToken = res.refreshToken;// refreshToken을 상태에 저장
      });

      String id = user.account.id;      // ID 정보 추출
      String email = user.account.email;// 이메일 정보 추출
      String name = user.account.name;  // 이름 정보 추출
      String tel = user.account.mobile
          .replaceAll('+82', '0')
          .replaceAll('-', '')
          .replaceAll(' ', '')
          .replaceAll('+', '');
      String sex = user.account.gender; // 성별 정보 추출

      print('$email, $name, $tel, $sex');

      // 사용자 정보를 서버로 전송
      await _sendNaverUserInfoToServer(
        id,
        email,
        name,
        sex,
        tel,
        accessToken // 액세스 토큰을 문자열로 전달
      );
    } catch (error) {
      print('naver login error $error');
    }
  }

  Future<void> _sendNaverUserInfoToServer(
    String userId, String email, String name, String gender, String phoneNumber, String accessToken
  ) async {
    try {
      final response = await http.post(
        Uri.parse('http://172.30.1.13:5001/naverlogin'), // Ensure this is your server's actual API address
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'userId': userId,
          'email': email,
          'name': name,
          'gender': gender,
          'phoneNumber': phoneNumber,
          'accessToken': accessToken,
        }),
      );

      if (response.statusCode == 200) {
        print('User info sent to server successfully.');
      } else {
        print('Failed to send user info to server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending user info to server: $e');
    }
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
    final url = Uri.parse('http://172.30.1.13:5001/kakaologin');

    String? email = user.kakaoAccount?.email;
    String? name = user.kakaoAccount?.profile?.nickname;
    String? phoneNumber = user.kakaoAccount?.phoneNumber;
    String genderStr = user.kakaoAccount?.gender?.toString().split('.').last ?? "Not specified";

    Map<String, dynamic> userData = {
      'userId': user.id.toString(),
      'email': email ?? "No email provided",
      'name': name ?? "No name provided",
      'gender': genderStr,
      'phoneNumber': phoneNumber ?? "No phone number provided",
      'accessToken': accessToken,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        print('사용자 정보 서버 저장 성공');
      } else {
        print('사용자 정보 서버 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('서버와의 통신 중 오류 발생: $e');
    }
  }
}
