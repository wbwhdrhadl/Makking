import 'dart:convert';
import 'package:flutter/material.dart';
import 'broadcast_start_screen.dart';
import 'face_recognition_screen.dart';
import 'broad1.dart';
import 'broadcast_storage_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_settings_screen.dart';
import 'package:http/http.dart' as http;

class BroadcastListScreen extends StatefulWidget {
  final String userId;
  final String serverIp;

  BroadcastListScreen({required this.userId, required this.serverIp});

  @override
  _BroadcastListScreenState createState() => _BroadcastListScreenState();
}

class _BroadcastListScreenState extends State<BroadcastListScreen> {
  late Future<List<LiveStreamTile>> liveBroadcasts;

  @override
  void initState() {
    super.initState();
    liveBroadcasts = fetchLiveBroadcasts(widget.serverIp);
  }

  Future<List<LiveStreamTile>> fetchLiveBroadcasts(String serverIp) async {
    final response = await http.get(Uri.parse('http://$serverIp/broadcast/live'));

    if (response.statusCode == 200) {
      final List<dynamic> broadcastData = json.decode(response.body);
      return broadcastData.map((data) {
        return LiveStreamTile(
          profileImage: 'assets/default_profile_image.jpeg', // 기본 이미지 사용
          streamerName: data['title'],
          description: '라이브 방송 중', // 기본 설명
          viewers: 0, // 조회수는 서버에서 제공하지 않는 경우 기본값 설정
          thumbnail: data['thumbnail_url'] ?? 'assets/default_thumbnail.jpeg', // 기본 썸네일
          broadcastName: data['title'],
          userId: data['user_id'],
          serverIp: serverIp,
          onTap: (context, userId, serverIp) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Broadcast1(broadcastName: data['title']),
              ),
            );
          },
        );
      }).toList();
    } else {
      throw Exception('Failed to load live broadcasts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('라이브 방송', style: GoogleFonts.jua(fontSize: 24, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.video_library, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BroadcastStartScreen(userId: widget.userId, serverIp: widget.serverIp),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFF00bfff)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(broadcastList: [], userId: widget.userId, serverIp: widget.serverIp),
              );
            },
          ),
        ],
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<LiveStreamTile>>(
        future: liveBroadcasts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView(
              children: snapshot.data!,
            );
          } else {
            return Center(child: Text('No live broadcasts available.'));
          }
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
                    builder: (context) => BroadcastStorageScreen(userId: widget.userId, serverIp: widget.serverIp),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.search, color: Color(0xFF00bfff)),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(broadcastList: [], userId: widget.userId, serverIp: widget.serverIp),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person, color: Color(0xFF00bfff)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsScreen(userId: widget.userId, serverIp: widget.serverIp),
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
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      margin: EdgeInsets.all(10),
      child: InkWell(
        onTap: () => onTap(context, userId, serverIp),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(profileImage),
              ),
              title: Text(streamerName, style: GoogleFonts.doHyeon(fontSize: 18, color: Colors.white)),
              subtitle: Text(description, style: GoogleFonts.doHyeon(fontSize: 14, color: Colors.grey[300])),
              trailing: Text('🔴 $viewers viewers', style: GoogleFonts.doHyeon(fontSize: 14, color: Color(0xFF00bfff))),
            ),
            Container(
              height: 150,
              child: Image.network(
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
                    icon: Icon(Icons.thumb_up, color: Color(0xFF00bfff)),
                    onPressed: () {},
                  ),
                  Text('Likes', style: GoogleFonts.doHyeon(fontSize: 14, color: Colors.white)),
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
  final String userId;
  final String serverIp;

  CustomSearchDelegate({required this.broadcastList, required this.userId, required this.serverIp});

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
                builder: (context) => Broadcast1(broadcastName: broadcast.broadcastName),
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
          title: Text(suggestions[index].streamerName, style: GoogleFonts.doHyeon(color: Colors.white)),
          onTap: () {
            query = suggestions[index].streamerName;
            showResults(context);
          },
        );
      },
    );
  }
}
