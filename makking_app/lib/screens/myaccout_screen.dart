// UserProfileScreen 코드
import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  // 사용자 정보
  final String username = "John Doe";
  final String email = "johndoe@example.com";
  final String profileImage = "assets/profile_image.jpg"; // 프로필 이미지 파일 경로

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 계정'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(profileImage), // 프로필 이미지 설정
            ),
            SizedBox(height: 20),
            Text(
              username,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              email,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 로그아웃 기능 구현
                // 여기에 로그아웃을 수행하는 코드를 추가하세요.
              },
              child: Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
