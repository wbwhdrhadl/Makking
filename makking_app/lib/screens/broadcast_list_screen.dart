import 'package:flutter/material.dart';
import 'face_recognition_screen.dart';
import 'broadcast_screen.dart';
import 'myaccout_screen.dart';
import 'broad1.dart';
import 'broad2.dart';

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
                  builder: (context) => BroadcastScreen(),
                ), // 동영상 화면으로 이동
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.face_2), // 얼굴 인식 아이콘
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceRecognitionScreen(
                    title: '얼굴 인식 화면',
                  ),
                ), // 얼굴 인식 화면으로 이동
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          LiveStreamTile(
            profileImage: '../assets/img3.jpeg',
            streamerName: '와꾸대장봉준',
            description: '봉준 60만개빵 무창클럽 vs 연합팀 [4경기 점니 3 vs 0 햇살] 스타',
            viewers: 56880,
            thumbnail: '../assets/img2.jpeg',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Broadcast1(),
                ), // 방송 화면으로 이동
              );
            },
          ),
          LiveStreamTile(
            profileImage: '../assets/img4.jpeg',
            streamerName: '이다군이다은',
            description: '대학교 등교길 같이 탐험 ㄱㄱ',
            viewers: 233,
            thumbnail: '../assets/img1.jpeg',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Broadcast2(),
                ), // 방송 화면으로 이동
              );
            },
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
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsScreen(),
                  ), // 동영상 화면으로 이동
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
  final VoidCallback onTap; // onTap 콜백 추가

  LiveStreamTile({
    required this.profileImage,
    required this.streamerName,
    required this.description,
    required this.viewers,
    required this.thumbnail,
    required this.onTap, // onTap 콜백을 생성자에 추가
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: InkWell(
        onTap: onTap, // InkWell의 onTap에 콜백 연결
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
            Container(
              height: 150, // Fixed height for the thumbnail
              child: Image.asset(
                thumbnail,
                fit: BoxFit.cover, // Adjust the image to cover the container
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
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
    // 검색 결과를 여기에 작성합니다.
    return Center(
      child: Text(
        '검색 결과: $query',
        style: TextStyle(fontSize: 24),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // 검색 제안을 여기에 작성합니다.
    List<String> suggestions = [
      '이다군이다은',
      '오킹의 걸어서 땅끝까지',
      '김나영의 논산 논쟁',
    ].where((suggestion) => suggestion.contains(query)).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
