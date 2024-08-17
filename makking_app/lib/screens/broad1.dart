import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart'; // GoogleFonts 추가

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
    required this.userId,
  });

  @override
  _Broadcast1State createState() => _Broadcast1State();
}

class _Broadcast1State extends State<Broadcast1> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final ScrollController _scrollController = ScrollController();
  VideoPlayerController? _videoPlayerController;
  late AnimationController _animationController;
  List<Widget> _floatingHearts = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _initializePlayer();
    _increaseViewerCount();

    // 하트 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _decreaseViewerCount();
    widget.onLeave();
    _videoPlayerController?.dispose();
    _animationController.dispose();
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

  void _addHeart() {
    setState(() {
      _floatingHearts.add(_buildHeart());
    });

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        if (_floatingHearts.isNotEmpty) {
          _floatingHearts.removeAt(0);
        }
      });
    });
  }

  Widget _buildHeart() {
    return Positioned(
      bottom: 0,
      left: Random().nextInt(100).toDouble(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -300 * _animationController.value),
            child: child,
          );
        },
        child: Icon(Icons.favorite, color: Colors.pink, size: 50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.broadcastName,
          style: GoogleFonts.jua( // 구글 폰트 적용
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _decreaseViewerCount();
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Broadcasting Video at the top with adjusted height
              Container(
                height: 300, // 영상 플레이어 높이 조정
                color: Colors.black,
                child: _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController!),
                      )
                    : Center(child: CircularProgressIndicator()),
              ),
              // Chat Window
              Expanded(
                child: Container(
                  color: Colors.grey[850],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '채팅',
                          style: GoogleFonts.doHyeon( // 구글 폰트 적용
                            color: Colors.white,
                            fontSize: 18,
                          ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00bfff),
                              ),
                              child: Text(
                                '메시지 전송',
                                style: GoogleFonts.doHyeon(), // 구글 폰트 적용
                              ),
                              onPressed: () {
                                String message = _controller.text;
                                if (message.isNotEmpty) {
                                  _sendMessage(message);
                                  _controller.clear();
                                }
                              },
                            ),
                            SizedBox(width: 10),
                            IconButton(
                              icon: Icon(Icons.favorite, color: Colors.pink),
                              onPressed: () {
                                _animationController.forward(from: 0.0);
                                _addHeart();
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
          ..._floatingHearts, // 화면에 표시되는 하트들
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
        style: GoogleFonts.doHyeon(color: Colors.white), // 구글 폰트 적용
      ),
    );
  }
}
