import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart'; // Ensure this import points to your actual login screen file
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 임포트
import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data'; // ByteData를 위해 추가
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterScreen extends StatefulWidget {
  final String serverIp; // serverIp를 받도록 수정

  RegisterScreen({required this.serverIp}); // 생성자에 serverIp 추가

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  io.File? _profileImage; // 모바일에서 사용될 File
  Uint8List? _webProfileImageBytes; // 웹에서 사용될 이미지의 바이트 데이터를 저장

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    if (kIsWeb) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webProfileImageBytes = bytes;
        });
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = io.File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _register(BuildContext context) async {
    if (_passwordController.text != _confirmPasswordController.text) {
      print('Passwords do not match');
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://${widget.serverIp}:5001/register'), // serverIp 사용
      );

      request.fields['username'] = _usernameController.text;
      request.fields['password'] = _passwordController.text;
      request.fields['name'] = _nameController.text;

      if (kIsWeb) {
        if (_webProfileImageBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'profileImage',
            _webProfileImageBytes!,
            filename: 'profile_image.png',
          ));
        }
      } else {
        if (_profileImage != null) {
          request.files.add(await http.MultipartFile.fromPath('profileImage', _profileImage!.path));
        }
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        print('Registration successful');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: Text('회원가입 성공', style: GoogleFonts.doHyeon(color: Color(0xFF54ffa7))),
              content: Text('${_usernameController.text}님 회원가입에 성공하였습니다', style: GoogleFonts.doHyeon(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LoginScreen(serverIp: widget.serverIp)), // serverIp 전달
                    );
                  },
                  child: Text('확인', style: GoogleFonts.doHyeon(color: Color(0xFF54ffa7))),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Color(0xFF54ffa7), width: 2),
              ),
            );
          },
        );
      } else {
        print('Registration failed: ${response.reasonPhrase}');
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
        title: Text('회원가입', style: GoogleFonts.doHyeon(color: Colors.white)),
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
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  backgroundImage: _getImageProvider(),
                  child: _profileImage == null && _webProfileImageBytes == null
                      ? Icon(Icons.camera_alt, color: Colors.white, size: 50)
                      : null,
                ),
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
                  backgroundColor: Color(0xFF54ffa7),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: GoogleFonts.jua(fontSize: 17, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  ImageProvider<Object>? _getImageProvider() {
    if (kIsWeb && _webProfileImageBytes != null) {
      return MemoryImage(_webProfileImageBytes!);
    } else if (!kIsWeb && _profileImage != null) {
      return FileImage(_profileImage!);
    }
    return null;
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
        labelStyle: GoogleFonts.doHyeon(color: Colors.white),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF54ffa7)),
        ),
      ),
      style: GoogleFonts.doHyeon(color: Colors.white),
    );
  }
}
