import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Settings',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AccountSettingsScreen(),
    );
  }
}

class AccountSettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('계정 센터'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 뒤로 가기 동작 추가
          },
        ),
      ),
      body: ListView(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.blue[900],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meta',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: 10),
                Text(
                  '광고를 받을 수 있을지는 모르겠지만 광고창임 헤헷.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                SizedBox(height: 10),
                Text(
                  '더 알아보기',
                  style: TextStyle(color: Colors.blue[200], fontSize: 14),
                ),
              ],
            ),
          ),
          // Profile Section
          ListTile(
            leading: CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(
                  '/Users/da-eun/Documents/GitHub/Makking/makking_app/assets/img4.jpeg'), // 프로필 이미지 경로
            ),
            title: Text('프로필'),
            subtitle: Text('이다군이다은'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 프로필 클릭 시 동작 추가
            },
          ),
          Divider(),
          // Linked Environment Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '연결된 환경',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(Icons.share),
            title: Text('여러 프로필에 공유'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 여러 프로필에 공유 클릭 시 동작 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.login),
            title: Text('여러 계정에 로그인'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 여러 계정에 로그인 클릭 시 동작 추가
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '모두 보기',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          Divider(),
          // Account Settings Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '계정 설정',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(Icons.security),
            title: Text('비밀번호 및 보안'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 비밀번호 및 보안 클릭 시 동작 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('개인정보'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 개인정보 클릭 시 동작 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('내 정보 및 권한'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 내 정보 및 권한 클릭 시 동작 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.ad_units),
            title: Text('광고 기본 설정'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 광고 기본 설정 클릭 시 동작 추가
            },
          ),
          ListTile(
            leading: Icon(Icons.verified_user),
            title: Text('프로필 인증 표시'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              // 프로필 인증 표시 클릭 시 동작 추가
            },
          ),
        ],
      ),
    );
  }
}
