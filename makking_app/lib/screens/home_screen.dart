import 'package:flutter/material.dart';
import 'broadcast_list_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 254, 255, 209),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              '../assets/logo.png', // 새로운 아이콘 경로
              width: 200, // 아이콘 너비
              height: 200, // 아이콘 높이
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // 카카오 로그인 로직 추가 (나중에 구현)
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // 패딩 제거
                minimumSize: Size(150, 50), // 최소 사이즈 설정
              ),
              child: Image.asset(
                'assets/kakao_login_button.png', // 이미지 파일 경로
                fit: BoxFit.cover, // 이미지를 버튼 크기에 맞게 조정
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // 네이버 로그인 로직 추가 (나중에 구현)
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // 패딩 제거
                minimumSize: Size(150, 50), // 최소 사이즈 설정
              ),
              child: Image.asset(
                'assets/naver_login.png', // 이미지 파일 경로
                fit: BoxFit.cover, // 이미지를 버튼 크기에 맞게 조정
              ),
            ),
            SizedBox(height: 20),
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
                backgroundColor: Colors.black, // 버튼 색상
                foregroundColor: Colors.white, // 글자색 설정
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                textStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 네모난 모양
                ),
              ),
              child: Text('비회원으로 계속하기'),
            ),
          ],
        ),
      ),
    );
  }
}
