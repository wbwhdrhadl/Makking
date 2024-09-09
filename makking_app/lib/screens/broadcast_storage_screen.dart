import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'face_recognition_screen.dart';
import 'broadcast_screen.dart';
import 'account_settings_screen.dart';
import 'broad1.dart';
import 'broad_reshow.dart';
import 'broadcast_list_screen.dart';
import 'broadcast_storage_screen.dart';

class BroadcastStorageScreen extends StatelessWidget {
  final String userId;
  final String serverIp;

  BroadcastStorageScreen({required this.userId, required this.serverIp});

  final List<LiveStreamTile> broadcastList = [
    LiveStreamTile(
      profileImage: 'assets/daeun.jpeg',
      streamerName: '다은이와 아윤이의 지난방송',
      description: '아윤이가 연애를 한다 ?',
      viewers: 56880,
      thumbnail: 'assets/ayuni.jpeg',
      broadcastName: '아융이와다은이',
      userId: 'exampleUserId',
      serverIp: '192.168.1.115',
      onTap: (BuildContext context, String userId, String serverIp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BroadReshow(
                broadcastName: 'example', userId: userId, serverIp: serverIp),
          ),
        );
      },
    ),
    LiveStreamTile(
      profileImage: 'assets/na.jpeg',
      streamerName: 'makking의 인터뷰',
      description: 'makking 앱은 무엇인가요?',
      viewers: 56880,
      thumbnail: 'assets/na.jpeg',
      broadcastName: '인터뷰tv',
      userId: 'exampleUserId',
      serverIp: '192.168.1.115',
      onTap: (BuildContext context, String userId, String serverIp) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BroadReshow(
                broadcastName: 'example', userId: userId, serverIp: serverIp),
          ),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '지난 방송 다시보기',
          style: TextStyle(
            color: Colors.white, // 글자색을 흰색으로 설정
            fontWeight: FontWeight.bold, // 글씨 두께를 Bold로 설정
          ),
        ),
        backgroundColor: Colors.black, // 배경색을 검정색으로 설정
        actions: [
          IconButton(
            icon: Icon(Icons.video_library, color: Colors.white), // 아이콘 색상 변경
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BroadReshow(
                      broadcastName: 'example',
                      userId: userId,
                      serverIp: serverIp),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.face_2, color: Colors.white), // 아이콘 색상 변경
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceRecognitionScreen(
                    title: '얼굴 인식 화면',
                    userId: userId,
                    isMosaicEnabled: false,
                    serverIp: serverIp,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.white), // 아이콘 색상 변경
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(
                  broadcastList: broadcastList,
                  userId: userId,
                  serverIp: serverIp,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black, // 배경색을 검정색으로 설정
        child: ListView(
          children: broadcastList
              .map((broadcast) => InkWell(
                    onTap: () => broadcast.onTap(context, userId, serverIp),
                    child: broadcast,
                  ))
              .toList(),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black, // 배경색을 검정색으로 설정
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Color(0xFF00bfff)), // 아이콘 색상 변경
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.save, color: Color(0xFF00bfff)), // 아이콘 색상 변경
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BroadReshow(
                        broadcastName: 'example',
                        userId: userId,
                        serverIp: serverIp),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.search, color: Color(0xFF00bfff)), // 아이콘 색상 변경
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(
                    broadcastList: broadcastList,
                    userId: userId,
                    serverIp: serverIp,
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person, color: Color(0xFF00bfff)), // 아이콘 색상 변경
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsScreen(
                      userId: userId,
                      serverIp: serverIp,
                    ),
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

class LiveStreamTile extends StatefulWidget {
  final String profileImage;
  final String streamerName;
  final String description;
  final int viewers;
  final String thumbnail;
  final String broadcastName;
  final String userId;
  final String serverIp;
  final Function(BuildContext, String, String) onTap;

  LiveStreamTile({
    required this.profileImage,
    required this.streamerName,
    required this.description,
    required this.viewers,
    required this.thumbnail,
    required this.broadcastName,
    required this.userId,
    required this.serverIp,
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
      var response = await http.get(Uri.parse(
          'http://${widget.serverIp}:5001/messages/${widget.broadcastName}'));
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
          'http://${widget.serverIp}:5001/messages/${widget.broadcastName}/like'));
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
          'http://${widget.serverIp}:5001/messages/${widget.broadcastName}/viewers'));
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
      color: Colors.grey[900], // 카드 배경을 어둡게 설정
      margin: EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white), // 카드 테두리를 흰색으로 설정
      ),
      elevation: 5,
      child: InkWell(
        onTap: () {
          incrementViewers();
          widget.onTap(context, widget.userId, widget.serverIp);
        },
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.horizontal(left: Radius.circular(12)),
                  image: DecorationImage(
                    image: AssetImage(widget.thumbnail),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.streamerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white, // 텍스트 색상을 흰색으로 변경
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.grey[400], // 설명 텍스트를 밝은 회색으로 변경
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.thumb_up, color: Colors.blue),
                              onPressed: incrementLikes,
                            ),
                            Text('$likes likes',
                                style: TextStyle(
                                    color: Colors.white)), // 텍스트 색상 변경
                          ],
                        ),
                        Text(
                          '🔴 $viewers viewers',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white), // 텍스트 색상 변경
                        ),
                      ],
                    ),
                  ],
                ),
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
  final String userId;
  final String serverIp;

  CustomSearchDelegate(
      {required this.broadcastList,
      required this.userId,
      required this.serverIp});

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black, // AppBar 배경색을 검정색으로 설정
        iconTheme: IconThemeData(color: Colors.white), // 아이콘 색상 흰색으로 설정
        titleTextStyle:
            TextStyle(color: Colors.white, fontSize: 20), // 검색어 텍스트 색상 흰색으로 설정
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey), // 검색창 힌트 텍스트 색상
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: Colors.white), // 아이콘 색상 변경
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
      icon: Icon(Icons.arrow_back, color: Colors.white), // 아이콘 색상 변경
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
                builder: (context) => BroadReshow(
                  broadcastName: broadcast.broadcastName,
                  userId: userId,
                  serverIp: serverIp,
                ),
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
          title: Text(suggestions[index].streamerName,
              style: TextStyle(color: Colors.white)), // 텍스트 색상 변경
          onTap: () {
            query = suggestions[index].streamerName;
            showResults(context);
          },
        );
      },
    );
  }
}
