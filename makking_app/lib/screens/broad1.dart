import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _Broadcast1State extends State<Broadcast1> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  VideoPlayerController? _videoPlayerController;
  late AnimationController _animationController;
  List<Widget> _floatingHearts = [];
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setLandscapeMode();
    _fetchMessages();
    _initializePlayer();
    _increaseViewerCount();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _setPortraitMode();
    _decreaseViewerCount();
    widget.onLeave();
    _videoPlayerController?.dispose();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _isKeyboardVisible = bottomInset > 0.0;
    });

    if (_isKeyboardVisible) {
      _disableOrientationLock();
    } else {
      _setLandscapeMode();
    }
  }

  void _setLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  void _setPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _disableOrientationLock() {
    SystemChrome.setPreferredOrientations([]);
  }

  Future<void> _initializePlayer() async {
    final m3u8Url = 'http://${widget.serverIp}:5001/stream/${widget.userId}/output.m3u8';

    _videoPlayerController = VideoPlayerController.network(m3u8Url)
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController!.play();
      }).catchError((error) {
        print('Failed to load video: $error');
      });
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse('http://${widget.serverIp}:5001/messages/${widget.broadcastName}'));
      if (response.statusCode == 200) {
        List<dynamic> messages = json.decode(response.body);
        List<Map<String, String>> messageList = messages.map<Map<String, String>>((msg) {
          return {
            'username': msg['username'] ?? 'Unknown User',
            'message': msg['message']?.toString() ?? '메시지 없음',
          };
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
    final List<Color> heartColors = [
      Colors.pink,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.blue
    ];

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
        child: Icon(
          Icons.favorite,
          color: heartColors[Random().nextInt(heartColors.length)],
          size: 50,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          _videoPlayerController != null && _videoPlayerController!.value.isInitialized
              ? Positioned.fill(
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                )
              : Center(child: CircularProgressIndicator()),

          if (!_isKeyboardVisible)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.35,
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        '채팅',
                        style: GoogleFonts.doHyeon(
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
                          final message = _messages[index];
                          return ChatMessage(
                            message: '${message['username']} | ${message['message']}',
                          );
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
                              style: TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '채팅 입력...',
                                hintStyle: TextStyle(fontSize: 14),
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
                          SizedBox(width: 5),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF66a1ff),
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            ),
                            child: Text(
                              '전송',
                              style: GoogleFonts.doHyeon(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            onPressed: () {
                              String message = _controller.text;
                              if (message.isNotEmpty) {
                                _sendMessage(message);
                                _controller.clear();
                              }
                            },
                          ),
                          SizedBox(width: 5),
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

          if (_isKeyboardVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '채팅 입력...',
                          hintStyle: TextStyle(fontSize: 14),
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
                    SizedBox(width: 5),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF66a1ff),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      ),
                      child: Text(
                        '전송',
                        style: GoogleFonts.doHyeon(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () {
                        String message = _controller.text;
                        if (message.isNotEmpty) {
                          _sendMessage(message);
                          _controller.clear();
                        }
                      },
                    ),
                    SizedBox(width: 5),
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
            ),
          ..._floatingHearts,
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
        style: GoogleFonts.doHyeon(color: Colors.white),
      ),
    );
  }
}
