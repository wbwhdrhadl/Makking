import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'broadcast_start_screen.dart'; // BroadcastStartScreen을 임포트
import 'broadcast_list_screen.dart'; // BroadcastListScreen을 임포트
import 'register_screen.dart'; // RegisterScreen을 임포트
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 임포트

class LoginScreen extends StatelessWidget {
  final String serverIp;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginScreen({required this.serverIp}) {
      // 서버 IP 로그 출력
      print('Server IP: $serverIp');
    }

  Future<void> _login(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse('http://$serverIp:5001/login'), // 전달받은 serverIp 사용
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'password': _usernameController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? userId = data['userId'] as String?;

        if (userId != null) {
          print('Login successful: ${data['msg']}');

          final userInfoResponse = await http.get(
            Uri.parse('http://$serverIp:5001/user/$userId'), // 전달받은 serverIp 사용
          );

          if (userInfoResponse.statusCode == 200) {
            final userInfo = jsonDecode(userInfoResponse.body);
            final String? imageUrl = userInfo['image_url'];

            await _saveSessionData(userId, _usernameController.text, _passwordController.text, imageUrl);
            _showWelcomeDialog(context, _usernameController.text, userId);
          } else {
            print('Failed to load user information.');
            _showDialog(context, 'Failed to load user information.');
          }
        } else {
          print('Login failed: userId is missing or null');
          _showDialog(context, 'Login failed: userId is missing or null.');
        }
      } else {
        print('Login failed: ${response.body}');
        _showDialog(context, 'Login failed: ${response.body}');
      }
    } catch (e) {
      print('Connection failed: $e');
      _showDialog(context, 'Server connection failed.');
    }
  }

  Future<void> _saveSessionData(String userId, String username, String password, String? imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId); // userId 저장
    await prefs.setString('username', username);
    await prefs.setString('password', password);

    if (imageUrl != null) {
      await prefs.setString('profileImageUrl', imageUrl);
    }
  }

  void _showWelcomeDialog(BuildContext context, String username, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black, // 팝업창 배경색을 검정색으로 설정
          title: Text(
            '환영합니다',
            style: GoogleFonts.doHyeon(color: Color(0xFF54ffa7)), // Do Hyeon 폰트와 네온 색상 적용
          ),
          content: Text(
            '$username님 환영합니다',
            style: GoogleFonts.doHyeon(color: Colors.white), // Do Hyeon 폰트와 흰색 텍스트 적용
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '확인',
                style: GoogleFonts.doHyeon(color: Color(0xFF54ffa7)), // Do Hyeon 폰트와 네온 색상 적용
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BroadcastListScreen(userId: userId, serverIp: serverIp), // BroadcastListScreen으로 userId와 serverIp 전달
                  ),
                );
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // 팝업창 모서리를 둥글게 설정
            side: BorderSide(color: Color(0xFF54ffa7), width: 2), // 네온 색상으로 경계선 설정
          ),
        );
      },
    );
  }

  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black, // 팝업창 배경색을 검정색으로 설정
          title: Text(
            '알림',
            style: GoogleFonts.doHyeon(color: Color(0xFF54ffa7)), // Do Hyeon 폰트와 네온 색상 적용
          ),
          content: Text(
            message,
            style: GoogleFonts.doHyeon(color: Colors.white), // Do Hyeon 폰트와 흰색 텍스트 적용
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                '확인',
                style: GoogleFonts.doHyeon(color: Color(0xFF54ffa7)), // Do Hyeon 폰트와 네온 색상 적용
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // 팝업창 모서리를 둥글게 설정
            side: BorderSide(color: Color(0xFF54ffa7), width: 2), // 네온 색상으로 경계선 설정
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double buttonWidth = screenWidth * 0.6;
    double buttonHeight = screenHeight * 0.08;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: screenWidth * 0.5,
                height: screenHeight * 0.35, // 높이 조정
                child: Image.asset(
                  'assets/logo.jpeg', // 로고 이미지 경로
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              _loginTextField(
                controller: _usernameController,
                labelText: '아이디',
              ),
              SizedBox(height: screenHeight * 0.02),
              _loginTextField(
                controller: _passwordController,
                labelText: '비밀번호',
                obscureText: true,
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (bool? value) {},
                    activeColor: Colors.blue,
                  ),
                  Text('계정 기억하기', style: GoogleFonts.doHyeon(color: Colors.white)), // Do Hyeon 폰트 적용
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
              ElevatedButton(
                onPressed: () => _login(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF54ffa7),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: GoogleFonts.jua( // Jua 폰트 적용
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  fixedSize: Size(buttonWidth, buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('로그인'),
              ),
              SizedBox(height: screenHeight * 0.02),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegisterScreen(serverIp: serverIp), // RegisterScreen으로 이동
                    ),
                  );
                },
                child: Text(
                  '아직 회원이 아니신가요?',
                  style: GoogleFonts.doHyeon(color: Colors.grey), // Do Hyeon 폰트 적용
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.doHyeon(color: Colors.white), // Do Hyeon 폰트 적용
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF54ffa7)),
        ),
      ),
      style: GoogleFonts.doHyeon(color: Colors.white), // Do Hyeon 폰트 적용
    );
  }
}
