import 'package:flutter/material.dart';
import 'broadcast_start_screen.dart';
import 'face_recognition_screen.dart';
import 'broad1.dart';
import 'broadcast_storage_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'broadcast_storage_screen.dart';
import 'account_settings_screen.dart';

class BroadcastListScreen extends StatelessWidget {
  final String userId;
  final String serverIp;

  BroadcastListScreen({required this.userId, required this.serverIp});

  final List<LiveStreamTile> broadcastList = [
    LiveStreamTile(
      profileImage: 'assets/img3.jpeg',
      streamerName: '와꾸대장봉준',
      description: '봉준 60만개빵 무창클럽 vs 연합팀 [4경기 점니 3 vs 0 햇살] 스타',
      viewers: 56880,
      thumbnail: 'assets/img2.jpeg',
      broadcastName: '와꾸대장봉준',
      userId: 'exampleUserId',
      serverIp: '192.168.1.115',
      onTap: (BuildContext context, String userId, String serverIp) {
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
      userId: 'exampleUserId',
      serverIp: '192.168.1.115',
      onTap: (BuildContext context, String userId, String serverIp) {
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
        title: Text('라이브 방송', style: GoogleFonts.jua(fontSize: 24, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.video_library, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BroadcastStartScreen(userId: userId, serverIp: serverIp),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFF00bfff)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(broadcastList: broadcastList, userId: userId, serverIp: serverIp),
              );
            },
          ),
        ],
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: broadcastList
            .map((broadcast) => InkWell(
                  onTap: () => broadcast.onTap(context, userId, serverIp),
                  child: broadcast,
                ))
            .toList(),
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
                    builder: (context) => BroadcastStorageScreen(userId: userId, serverIp: serverIp),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.search, color: Color(0xFF00bfff)),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(broadcastList: broadcastList, userId: userId, serverIp: serverIp),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person, color: Color(0xFF00bfff)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AccountSettingsScreen(userId: userId,serverIp: serverIp),
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
