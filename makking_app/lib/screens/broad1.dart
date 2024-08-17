import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class Broadcast1 extends StatefulWidget {
  final String broadcastName;
  final String userId;
  final String serverIp;
  final String broadcastId;
  final VoidCallback onLeave;

  Broadcast1({
    required this.broadcastName,
    required this.serverIp,
    required this.broadcastId,
    required this.onLeave,
    required this.userId
  });

  @override
  _Broadcast1State createState() => _Broadcast1State();
}

class _Broadcast1State extends State<Broadcast1> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final ScrollController _scrollController = ScrollController();
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initializePlayer();
    _increaseViewerCount();
  }

  @override
  void dispose() {
    _decreaseViewerCount();
    widget.onLeave();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    final m3u8Url = 'http://${widget.serverIp}:5001/stream/${widget.userId}/output.m3u8'; // m3u8 파일 URL

    _videoPlayerController = VideoPlayerController.network(m3u8Url)
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController!.play(); // 재생 자동 시작
      }).catchError((error) {
        print('Failed to load video: $error');
      });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse(
          'http://${widget.serverIp}:5001/messages/${widget.broadcastName}'));
      if (response.statusCode == 200) {
        List<dynamic> messages = json.decode(response.body);
        List<String> messageList = messages.map((msg) {
          if (msg is Map<String, dynamic> && msg.containsKey('message')) {
            return msg['message'] as String;
          } else {
            return '메시지 없음';
          }
        }).toList();
        setState(() {
          _messages.clear();
          _messages.addAll(messageList);
        });
      } else {
        print('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('http://${widget.serverIp}:5001/messages/${widget.broadcastName}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );
      if (response.statusCode == 200) {
        _fetchMessages().then((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        print('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _increaseViewerCount() async {
    try {
      await http.post(
        Uri.parse('http://${widget.serverIp}:5001/broadcast/${widget.broadcastId}/viewerEnter'),
      );
    } catch (e) {
      print('Failed to increase viewer count: $e');
    }
  }

  Future<void> _decreaseViewerCount() async {
    try {
      await http.post(
        Uri.parse('http://${widget.serverIp}:5001/broadcast/${widget.broadcastId}/viewerExit'),
      );
    } catch (e) {
      print('Failed to decrease viewer count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.broadcastName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _decreaseViewerCount();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Broadcasting Video at the top
          Container(
            height: 200, // Adjust the height to fit your needs
            color: Colors.black,
            child: _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  )
                : Center(child: CircularProgressIndicator()),
          ),
          // Broadcasting Rules
          Container(
            padding: EdgeInsets.all(10),
            child: Text(
              '방송 규칙: 채팅 여러번 치기 금지, 다들 좋은 방방 관람 하세용 ~',
              style: TextStyle(fontSize: 16),
            ),
          ),
          // Chat Window
          Expanded(
            child: Container(
              color: Colors.grey[800],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '채팅',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return ChatMessage(message: _messages[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: '채팅 입력...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 20,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          child: Text('메시지 전송'),
                          onPressed: () {
                            String message = _controller.text;
                            if (message.isNotEmpty) {
                              _sendMessage(message);
                              _controller.clear();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String message;

  ChatMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
