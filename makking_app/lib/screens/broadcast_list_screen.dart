import 'package:flutter/material.dart';
import 'face_recognition_screen.dart';
import 'broadcast_screen.dart';
import 'myaccout_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broadcasting Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BroadcastListScreen(),
    );
  }
}

class BroadcastListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('방송 리스트 화면'),
        actions: [
          IconButton(
            icon: Icon(Icons.video_library), // 동영상 아이콘 추가
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BroadcastScreen()), // 동영상 화면으로 이동
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications), // 알람 아이콘 추가
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BroadcastScreen()), // 알람 화면으로 이동
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          LiveStreamTile(
            profileImage: '../assets/img1.jpeg',
            streamerName: '와꾸대장봉준',
            description: '봉준 60만개빵 무창클럽 vs 연합팀 [4경기 점니 3 vs 0 햇살] 스타',
            viewers: 56880,
            thumbnail: '../assets/img2.jpeg',
          ),
          LiveStreamTile(
            profileImage: '../assets/img1.jpeg',
            streamerName: '나만의 방송',
            description: '나만의 방송 설명 텍스트',
            viewers: 233,
            thumbnail: '../assets/img1.jpeg',
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                // 홈 버튼 클릭 시 수행할 동작 추가
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                // 검색 버튼 클릭 시 수행할 동작 추가
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          BroadcastScreen()), // 마이 페이지 화면으로 이동
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LiveStreamTile extends StatelessWidget {
  final String profileImage;
  final String streamerName;
  final String description;
  final int viewers;
  final String thumbnail;

  LiveStreamTile({
    required this.profileImage,
    required this.streamerName,
    required this.description,
    required this.viewers,
    required this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(profileImage),
            ),
            title: Text(streamerName),
            subtitle: Text(description),
            trailing: Text('🔴 $viewers'),
          ),
          Image.asset(thumbnail),
        ],
      ),
    );
  }
}
