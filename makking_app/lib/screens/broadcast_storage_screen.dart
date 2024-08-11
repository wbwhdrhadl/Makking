import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'face_recognition_screen.dart';
import 'broadcast_screen.dart';
import 'myaccout_screen.dart';
import 'broad1.dart';
import 'broad_reshow.dart';
import 'broadcast_list_screen.dart';
import 'broadcast_storage_screen.dart';

class BroadcastStorageScreen extends StatelessWidget {
  final String userId; // userId 필드 추가

  BroadcastStorageScreen({required this.userId}); // userId를 생성자에서 받아옴

  final List<LiveStreamTile> broadcastList = [
    LiveStreamTile(
      profileImage: 'assets/daeun.jpeg',
      streamerName: '다은이와 아윤이의 지난방송',
      description: '아윤이가 연애를 한다 ?',
      viewers: 56880,
      thumbnail: 'assets/ayuni.jpeg',
      broadcastName: '아융이와다은이',
      onTap: (BuildContext context, String userId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BroadReshow(broadcastName: 'example', userId: userId),
          ),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('지난 방송 다시보기'),
        actions: [
          IconButton(
            icon: Icon(Icons.video_library),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BroadReshow(broadcastName: 'example', userId: userId),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.face_2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceRecognitionScreen(
                    title: '얼굴 인식 화면',
                    userId: userId, // userId 전달
                    isMosaicEnabled: false, // 예시 값 설정
                    isSubtitleEnabled: false, // 예시 값 설정
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate:
                    CustomSearchDelegate(broadcastList: broadcastList, userId: userId),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: broadcastList
            .map((broadcast) => InkWell(
                  onTap: () => broadcast.onTap(context, userId),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BroadReshow(broadcastName: 'example', userId: userId),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BroadReshow(broadcastName: 'example', userId: userId),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate:
                      CustomSearchDelegate(broadcastList: broadcastList, userId: userId),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AccountSettingsScreen(userId: userId), // userId 전달
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
  final Function(BuildContext, String) onTap;

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
      child: InkWell(
        onTap: () {
          incrementViewers();
          widget.onTap(context, widget.broadcastName);
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
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.grey[600],
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
                            Text('$likes likes'),
                          ],
                        ),
                        Text(
                          '🔴 $viewers viewers',
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  CustomSearchDelegate({required this.broadcastList, required this.userId});

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
                builder: (context) => BroadReshow(
                  broadcastName: broadcast.broadcastName,
                  userId: userId,
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
