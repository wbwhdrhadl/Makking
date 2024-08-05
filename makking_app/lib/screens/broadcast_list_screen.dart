import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON processing
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:makking_app/screens/broadcast_start_screen.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Placeholder Widgets - Make sure to implement or correct these based on your actual files
import 'face_recognition_screen.dart';
import 'broadcast_screen.dart';
import 'myaccout_screen.dart';
import 'broad1.dart';
import 'speech.dart'; // Add this import
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
      home: BroadcastListScreen(),
    );
  }
}

// (Remaining code unchanged)

class BroadcastListScreen extends StatelessWidget {
  final List<LiveStreamTile> broadcastList = [
    LiveStreamTile(
      profileImage: 'assets/img3.jpeg',
      streamerName: '와꾸대장봉준',
      description: '봉준 60만개빵 무창클럽 vs 연합팀 [4경기 점니 3 vs 0 햇살] 스타',
      viewers: 56880,
      thumbnail: 'assets/img2.jpeg',
      broadcastName: '와꾸대장봉준',
      onTap: (BuildContext context) {
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
      onTap: (BuildContext context) {
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
                MaterialPageRoute(builder: (context) => BroadcastStartScreen()),
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
                  onTap: () => broadcast.onTap(context),
                  child: broadcast,
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SpeechScreen()),
          );
        },
        child: Icon(Icons.mic),
        tooltip: '화자 분석하기',
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
                    builder: (context) => BroadcastStorageScreen(),
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
                    builder: (context) => AccountSettingsScreen(),
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

// (Remaining code unchanged)

class LiveStreamTile extends StatefulWidget {
  final String profileImage;
  final String streamerName;
  final String description;
  final int viewers;
  final String thumbnail;
  final String broadcastName;
  final Function(BuildContext) onTap;

  LiveStreamTile({
    required this.profileImage,
    required this.streamerName,
    required this.description,
    required this.viewers,
    required this.thumbnail,
    required this.broadcastName,
    required this.onTap,
  });

  @override
  _LiveStreamTileState createState() => _LiveStreamTileState();
}

class _LiveStreamTileState extends State<LiveStreamTile> {
  int likes = 0;
  int viewers = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      var response = await http.get(
          Uri.parse('http://localhost:5001/messages/${widget.broadcastName}'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          likes = data['likes'] ?? 0;
          viewers = data['viewers'] ?? widget.viewers;
        });
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void incrementLikes() async {
    try {
      var response = await http.post(Uri.parse(
          'http://localhost:5001/messages/${widget.broadcastName}/like'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          likes = data['likes'];
        });
      } else {
        print('Failed to increment likes');
      }
    } catch (e) {
      print('Error incrementing likes: $e');
    }
  }

  void incrementViewers() async {
    try {
      var response = await http.post(Uri.parse(
          'http://localhost:5001/messages/${widget.broadcastName}/viewers'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          viewers = data['viewers'];
        });
      } else {
        print('Failed to increment viewers');
      }
    } catch (e) {
      print('Error incrementing viewers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          incrementViewers();
          widget.onTap(context);
        },
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(widget.profileImage),
              ),
              title: Text(widget.streamerName),
              subtitle: Text(widget.description),
              trailing: Text('🔴 $viewers viewers'),
            ),
            Container(
              height: 150,
              child: Image.asset(
                widget.thumbnail,
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
                    onPressed: incrementLikes,
                  ),
                  Text('$likes likes'),
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
