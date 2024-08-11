import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON processing
import 'package:makking_app/screens/broadcast_start_screen.dart';
import 'package:path/path.dart';

// Placeholder Widgets - Make sure to implement or correct these based on your actual files
import 'face_recognition_screen.dart';
import 'broadcast_screen.dart';
import 'myaccout_screen.dart';
import 'broad1.dart';
import 'broadcast_storage_screen.dart';

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
      home: BroadcastListScreen(userId: 'exampleUserId'), // 예시로 userId 전달
    );
  }
}

class BroadcastListScreen extends StatelessWidget {
  final String userId; // userId 필드 추가

  BroadcastListScreen({required this.userId}); // userId를 생성자에서 받아옴

  final List<LiveStreamTile> broadcastList = [
    LiveStreamTile(
      profileImage: 'assets/img3.jpeg',
      streamerName: '와꾸대장봉준',
      description: '봉준 60만개빵 무창클럽 vs 연합팀 [4경기 점니 3 vs 0 햇살] 스타',
      viewers: 56880,
      thumbnail: 'assets/img2.jpeg',
      broadcastName: '와꾸대장봉준',
      userId: 'exampleUserId', // userId 전달
      onTap: (BuildContext context, String userId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Broadcast1(broadcastName: '와꾸대장봉준'),
          ),
        );
      },
    ),
    LiveStreamTile(
      profileImage: 'assets/img4.jpeg',
      streamerName: '이다군이다은',
      description: '대학교 등교길 같이 탐험 ㄱㄱ',
      viewers: 233,
      thumbnail: 'assets/img1.jpeg',
      broadcastName: '이다군이다은',
      userId: 'exampleUserId', // userId 전달
      onTap: (BuildContext context, String userId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Broadcast1(broadcastName: '이다군이다은'),
          ),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('방송 리스트 화면'),
        actions: [
          IconButton(
            icon: Icon(Icons.video_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BroadcastStartScreen(userId: userId), // userId 전달
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(broadcastList: broadcastList),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: broadcastList
            .map((broadcast) => InkWell(
                  onTap: () => broadcast.onTap(context, userId), // userId 전달
                  child: broadcast,
                ))
            .toList(),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                // Implement home navigation or refresh
              },
            ),
            IconButton(
              icon: Icon(Icons.save), // 저장된 방송 화면 아이콘
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BroadcastStorageScreen(userId: userId), // userId 전달
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(broadcastList: broadcastList),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsScreen(userId: userId), // userId 전달
                  ),
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
  final String broadcastName;
  final String userId; // userId 필드 추가
  final Function(BuildContext, String) onTap; // onTap 함수 수정

  LiveStreamTile({
    required this.profileImage,
    required this.streamerName,
    required this.description,
    required this.viewers,
    required this.thumbnail,
    required this.broadcastName,
    required this.userId, // userId 추가
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: InkWell(
        onTap: () => onTap(context, userId), // userId 전달
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(profileImage),
              ),
              title: Text(streamerName),
              subtitle: Text(description),
              trailing: Text('🔴 $viewers viewers'),
            ),
            Container(
              height: 150,
              child: Image.asset(
                thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.thumb_up),
                    onPressed: () {}, // 좋아요 기능 구현 필요
                  ),
                  Text('Likes'), // 좋아요 수를 보여줄 수 있음
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final List<LiveStreamTile> broadcastList;

  CustomSearchDelegate({required this.broadcastList});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<LiveStreamTile> results = broadcastList.where((broadcast) {
      return broadcast.streamerName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView(
      children: results.map((broadcast) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    Broadcast1(broadcastName: broadcast.broadcastName),
              ),
            );
          },
          child: broadcast,
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<LiveStreamTile> suggestions = broadcastList.where((broadcast) {
      return broadcast.streamerName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index].streamerName),
          onTap: () {
            query = suggestions[index].streamerName;
            showResults(context);
          },
        );
      },
    );
  }
}
