import 'package:flutter/material.dart';
import 'broadcast_list_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색을 하얀색으로 설정
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 화면의 너비와 높이를 얻기 위해 MediaQuery를 사용합니다.
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: screenWidth * 0.5, // 로고의 너비를 화면 너비의 50%로 설정
                  height: screenHeight * 0.4, // 로고의 높이를 화면 높이의 40%로 설정
                  child: Image.asset(
                    'assets/logo.jpeg',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // 로고와 버튼 사이 간격
                SizedBox(
                  width: screenWidth * 0.6, // 버튼의 너비를 화면 너비의 60%로 설정
                  height: screenHeight * 0.08, // 버튼의 높이를 화면 높이의 8%로 설정
                  child: Image.asset(
                    'assets/kakao_login.jpeg',
                    fit: BoxFit.scaleDown, // 이미지를 균일한 크기로 조정
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // 버튼 간 간격
                SizedBox(
                  width: screenWidth * 0.6, // 버튼의 너비를 화면 너비의 60%로 설정
                  height: screenHeight * 0.08, // 버튼의 높이를 화면 높이의 8%로 설정
                  child: Image.asset(
                    'assets/naver_login.jpeg',
                    fit: BoxFit.scaleDown, // 이미지를 균일한 크기로 조정
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // 버튼 간 간격
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
                    fixedSize: Size(screenWidth * 0.6,
                        screenHeight * 0.08), // 버튼의 크기를 화면의 크기에 맞게 설정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                  child: Text('비회원으로 계속하기'),
                ),
                SizedBox(height: screenHeight * 0.02), // 버튼 간 간격
                ElevatedButton(
                  onPressed: () {
                    // 여기에 회원으로 로그인하기 버튼의 동작을 정의합니다.
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    fixedSize: Size(screenWidth * 0.6,
                        screenHeight * 0.08), // 버튼의 크기를 화면의 크기에 맞게 설정
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
}
