import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart'; // Ensure this import points to your actual login screen file
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 임포트

class RegisterScreen extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Future<void> _register(BuildContext context) async {
    if (_passwordController.text != _confirmPasswordController.text) {
      print('Passwords do not match');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://172.30.1.66:5001/register'), // Use localhost for macOS
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'password': _passwordController.text,
          'name': _nameController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('Registration successful: ${data['msg']}');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                '회원가입 성공',
                style: GoogleFonts.doHyeon(), // Do Hyeon 폰트 적용
              ),
              content: Text(
                '${_usernameController.text}님 회원가입에 성공하였습니다',
                style: GoogleFonts.doHyeon(), // Do Hyeon 폰트 적용
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text('확인', style: GoogleFonts.doHyeon()), // Do Hyeon 폰트 적용
                ),
              ],
            );
          },
        );
      } else {
        print('Registration failed: ${response.body}');
      }
    } catch (e) {
      print('Connection failed: $e');
    }
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
        title: Text('회원가입', style: GoogleFonts.doHyeon(color: Colors.white)), // Do Hyeon 폰트 적용
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '계정 정보를 작성해주세요 !',
              style: GoogleFonts.gothicA1(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ), // Do Hyeon 폰트 적용
            ),
            SizedBox(height: 16),
            _registerTextField(
              controller: _usernameController,
              labelText: '아이디',
            ),
            SizedBox(height: 16),
            _registerTextField(
              controller: _passwordController,
              labelText: '비밀번호',
              obscureText: true,
            ),
            SizedBox(height: 16),
            _registerTextField(
              controller: _confirmPasswordController,
              labelText: '비밀번호 확인',
              obscureText: true,
            ),
            SizedBox(height: 16),
            _registerTextField(
              controller: _nameController,
              labelText: '이름',
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _register(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF54ffa7), // 네온 색상
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: GoogleFonts.jua( // Jua 폰트 적용
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                fixedSize: Size(buttonWidth, buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _registerTextField({
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
          borderSide: BorderSide(color: Color(0xFF54ffa7)), // 포커스 시 네온 색상
        ),
      ),
      style: GoogleFonts.doHyeon(color: Colors.white), // Do Hyeon 폰트 적용
    );
  }
}
