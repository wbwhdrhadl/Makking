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

  @override
  void initState() {
    super.initState();
    fetchLiveBroadcasts();
  }

  Future<void> fetchLiveBroadcasts() async {
    try {
      final response = await http.get(Uri.parse('http://${widget.serverIp}:5001/broadcasts/live'));
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
          return Card(
            color: Colors.grey[850],
            margin: EdgeInsets.all(10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Broadcast1(broadcastName: broadcast['title']),
                  ),
                );
              },
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: broadcast['profileImage'] != null
                          ? NetworkImage('http://${widget.serverIp}/' + broadcast['profileImage'])
                          : AssetImage('assets/default_profile.png') as ImageProvider,
                    ),
                    title: Text(broadcast['username'] ?? 'Unknown User', style: GoogleFonts.doHyeon(fontSize: 18, color: Colors.white)),
                    subtitle: Text(broadcast['title'], style: GoogleFonts.doHyeon(fontSize: 14, color: Colors.grey[300])),
                    trailing: Text('🔴 ${broadcast['viewers'] ?? 0} viewers', style: GoogleFonts.doHyeon(fontSize: 14, color: Color(0xFF00bfff))),
                  ),
                  Container(
                    height: 150,
                    child: broadcast['thumbnail_url'] != null
                        ? Image.network(
                             () {
                                final imageUrl = 'http://${widget.serverIp}:5001/' + broadcast['thumbnail_url'].replaceAll('\\', '/');
                                print('Loading image from URL: $imageUrl');
                                return imageUrl;
                              }(),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                        : Image.asset('assets/default_thumbnail.png', fit: BoxFit.cover, width: double.infinity),
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

class CustomSearchDelegate extends SearchDelegate {
  final List<dynamic> broadcastList;

  CustomSearchDelegate({required this.broadcastList});

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
      return broadcast['username'].toLowerCase().contains(query.toLowerCase()) ||
          broadcast['title'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final broadcast = results[index];
        return ListTile(
          title: Text(broadcast['title'], style: GoogleFonts.doHyeon(color: Colors.white)),
          subtitle: Text(broadcast['username'], style: GoogleFonts.doHyeon(color: Colors.white)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Broadcast1(broadcastName: broadcast['title']),
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
      return broadcast['username'].toLowerCase().contains(query.toLowerCase()) ||
          broadcast['title'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]['title'], style: GoogleFonts.doHyeon(color: Colors.white)),
          subtitle: Text(suggestions[index]['username'], style: GoogleFonts.doHyeon(color: Colors.white)),
          onTap: () {
            query = suggestions[index]['title'];
            showResults(context);
          },
        );
      },
    );
  }
}
