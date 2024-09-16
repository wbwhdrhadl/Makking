import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'broadcast_start_screen.dart';
import 'broadcast_storage_screen.dart';
import 'account_settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'broad1.dart';

class BroadcastListScreen extends StatefulWidget {
  final String userId;
  final String serverIp;

  BroadcastListScreen({required this.userId, required this.serverIp});

  @override
  _BroadcastListScreenState createState() => _BroadcastListScreenState();
}

class _BroadcastListScreenState extends State<BroadcastListScreen> {
  List<dynamic> broadcastList = [];
  Set<String> likedBroadcasts = Set<String>();

  @override
  void initState() {
    super.initState();
    fetchLiveBroadcasts();
  }

  Future<void> fetchLiveBroadcasts() async {
    try {
      final response = await http
          .get(Uri.parse('http://${widget.serverIp}:5001/broadcasts/live'));
      if (response.statusCode == 200) {
        setState(() {
          broadcastList = json.decode(response.body);
        });
      } else {
        print('Failed to load broadcasts');
      }
    } catch (e) {
      print('Error fetching live broadcasts: $e');
    }
  }

  Future<void> likeBroadcast(String broadcastId) async {
    try {
      final response = await http.post(
        Uri.parse('http://${widget.serverIp}:5001/messages/$broadcastId/like'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': widget.userId}), // userId 전송
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          if (likedBroadcasts.contains(broadcastId)) {
            likedBroadcasts.remove(broadcastId); // 좋아요 취소
          } else {
            likedBroadcasts.add(broadcastId); // 좋아요 추가
          }
          // 좋아요 수를 업데이트
          final broadcastIndex =
              broadcastList.indexWhere((b) => b['_id'] == broadcastId);
          if (broadcastIndex != -1) {
            broadcastList[broadcastIndex]['likes'] = responseData['likes'];
          }
        });
      } else {
        print('Failed to like/unlike broadcast');
      }
    } catch (e) {
      print('Error liking/unliking broadcast: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('라이브 방송',
            style: GoogleFonts.jua(fontSize: 24, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.video_library, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BroadcastStartScreen(
                      userId: widget.userId, serverIp: widget.serverIp),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFF00bfff)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(broadcastList: broadcastList),
              );
            },
          ),
        ],
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: broadcastList.length,
        itemBuilder: (context, index) {
          final broadcast = broadcastList[index];
          final isLiked = likedBroadcasts.contains(broadcast['_id']);
          return Card(
            color: Colors.grey[850],
            margin: EdgeInsets.all(10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Broadcast1(
                      broadcastName: broadcast['title'],
                      userId: widget.userId,
                      serverIp: widget.serverIp,
                      broadcastId: broadcast['_id'], // broadcastId 전달
                      onLeave: () {
                        // 방송을 나갈 때 처리할 로직
                      },
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: broadcast['profileImage'] != null
                          ? NetworkImage('http://${widget.serverIp}:5001/' +
                              broadcast['profileImage'].replaceAll('\\', '/'))
                          : AssetImage('assets/default_profile.png')
                              as ImageProvider,
                    ),
                    title: Text(broadcast['username'] ?? 'Unknown User',
                        style: GoogleFonts.doHyeon(
                            fontSize: 18, color: Colors.white)),
                    subtitle: Text(broadcast['title'],
                        style: GoogleFonts.doHyeon(
                            fontSize: 14,
                            color: Color.fromARGB(255, 255, 255, 255))),
                  ),
                  Container(
                    height: 150,
                    child: broadcast['thumbnail_url'] != null
                        ? Image.network(
                            'http://${widget.serverIp}:5001/' +
                                broadcast['thumbnail_url']
                                    .replaceAll('\\', '/'),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Image.asset('assets/default_thumbnail.png',
                            fit: BoxFit.cover, width: double.infinity),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.thumb_up,
                            color: isLiked
                                ? Color(0xFF00bfff)
                                : Colors.white, // 좋아요 여부에 따라 색상 변경
                          ),
                          onPressed: () {
                            likeBroadcast(broadcast['_id']);
                          },
                        ),
                        Text('${broadcast['likes'] ?? 0}',
                            style: GoogleFonts.doHyeon(
                                fontSize: 14, color: Colors.white)), // 좋아요 수 표시
                        Text('🔴 ${broadcast['viewers'] ?? 0} viewers',
                            style: GoogleFonts.doHyeon(
                                fontSize: 14, color: Color(0xFF00bfff))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Color(0xFF00bfff)),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.save, color: Color(0xFF00bfff)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BroadcastStorageScreen(
                        userId: widget.userId, serverIp: widget.serverIp),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.search, color: Color(0xFF00bfff)),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(broadcastList: broadcastList),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person, color: Color(0xFF00bfff)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsScreen(
                        userId: widget.userId, serverIp: widget.serverIp),
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

class CustomSearchDelegate extends SearchDelegate {
  final List<dynamic> broadcastList;

  CustomSearchDelegate({required this.broadcastList});

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
        hintStyle: TextStyle(
            color: const Color.fromARGB(255, 255, 255, 255)), // 검색창 힌트 텍스트 색상
        filled: true,
        fillColor: Colors.black, // 검색창 배경을 검정색으로 설정
        border: InputBorder.none, // 검색창의 기본 테두리 제거
        contentPadding: EdgeInsets.all(10), // 검색창 내부 여백 조정
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  TextStyle? get searchFieldStyle => TextStyle(
        color: Colors.white, // 검색 텍스트 색상을 흰색으로 설정
        fontSize: 18, // 원하는 경우 폰트 크기도 설정
      );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, color: Colors.white),
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
      icon: Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    List<dynamic> results = broadcastList.where((broadcast) {
      return broadcast['username']
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          broadcast['title'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final broadcast = results[index];
        return ListTile(
          title: Text(broadcast['title'],
              style: GoogleFonts.doHyeon(color: Colors.white)),
          subtitle: Text(broadcast['username'],
              style: GoogleFonts.doHyeon(color: Colors.white)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Broadcast1(
                  broadcastName: broadcast['title'],
                  userId: broadcast['user_id'],
                  serverIp: broadcast['serverIp'],
                  broadcastId: broadcast['_id'],
                  onLeave: () {
                    // 방송을 나갈 때 처리할 로직
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    List<dynamic> suggestions = broadcastList.where((broadcast) {
      return broadcast['username']
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          broadcast['title'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]['title'],
              style: GoogleFonts.doHyeon(color: Colors.white)),
          subtitle: Text(suggestions[index]['username'],
              style: GoogleFonts.doHyeon(color: Colors.white)),
          onTap: () {
            query = suggestions[index]['title'];
            showResults(context);
          },
        );
      },
    );
  }
}
