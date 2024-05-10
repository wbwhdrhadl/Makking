import 'package:flutter/material.dart';
import 'broadcast_list_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 205, 254, 254),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/makking_tv_broadcast_icon.png', // 새로운 아이콘 경로
              width: 200, // 아이콘 너비
              height: 200, // 아이콘 높이
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // 네이버 로그인 로직 추가
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1EC800), // 초록색 버튼
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                textStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 네모난 모양
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 10),
                  Text('네이버로 계속하기'),
                ],
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // 카카오톡 로그인 로직 추가
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFFE812), // 노란색 버튼
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 17, vertical: 10),
                textStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 네모난 모양
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 10),
                  Text('카카오톡으로 계속하기'),
                ],
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
