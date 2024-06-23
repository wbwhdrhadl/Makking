import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'broadcast_list_screen.dart';
import 'login.dart'; // login.dart 파일을 import 합니다.
import 'package:http/http.dart' as http;
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as FlutterSecureStorage;
import 'package:url_launcher/url_launcher.dart';

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
                    _loginWithKakao(context);
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

Future<void> _loginWithKakao(BuildContext context) async {
  // 카카오 로그인 페이지 URL
  final url = Uri.parse('http://localhost:8080/login/kakao');
  // 웹뷰나 외부 브라우저를 통해 URL 열기
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    _showErrorDialog(context, '로그인 페이지를 열 수 없습니다.');
  }
}


    // This function needs to be defined
      Future<void> _loginWithNaver(BuildContext context) async {
        // Implement Naver login logic here
        print('Implement Naver login logic!');
      }

    void _showErrorDialog(BuildContext context, String message) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Login Error'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }