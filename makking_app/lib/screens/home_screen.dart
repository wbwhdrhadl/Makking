import 'package:flutter/material.dart';
import 'broadcast_list_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 하얀색으로 설정
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 500, // 로고의 너비
              height: 500, // 로고의 높이
              child: Image.asset(
                'makking_app/assets/logo.jpeg',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 10), // 로고와 버튼 사이 간격
            SizedBox(
              width: 300, // 버튼의 너비
              height: 60, // 버튼의 높이
              child: Image.asset(
                '../assets/kakao_login.jpeg',
                fit: BoxFit.scaleDown, // 이미지를 균일한 크기로 조정
              ),
            ),
            SizedBox(height: 10), // 버튼 간 간격
            SizedBox(
              width: 300, // 버튼의 너비
              height: 60, // 버튼의 높이
              child: Image.asset(
                '../assets/naver_login.jpeg',
                fit: BoxFit.scaleDown, // 이미지를 균일한 크기로 조정
              ),
            ),
            SizedBox(height: 10), // 버튼 간 간격
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
                fixedSize: Size(300, 60), // 버튼의 크기
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
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
