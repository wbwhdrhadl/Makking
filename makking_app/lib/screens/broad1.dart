import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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

class _Broadcast1State extends State<Broadcast1> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  VideoPlayerController? _videoPlayerController;
  late AnimationController _animationController;
  late IO.Socket socket;
  final Map<String, Color> userColors = {}; // 유저별 색상 저장
  final List<Color> neonColors = [Colors.pinkAccent, Colors.blueAccent, Colors.greenAccent, Colors.purpleAccent, Colors.orangeAccent];

  bool _isKeyboardVisible = false; // 키보드 표시 여부 확인
  List<Widget> _floatingHearts = []; // 하트 애니메이션 위젯 리스트

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setLandscapeMode();
    _initializePlayer();
    _increaseViewerCount();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _fetchMessages(); // 기존 채팅 불러오기
    _connectToSocket();
  }

  @override
  void dispose() {
    _setPortraitMode();
    _decreaseViewerCount();
    widget.onLeave();
    _videoPlayerController?.dispose();
    _animationController.dispose();
    socket.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _connectToSocket() {
    socket = IO.io('http://${widget.serverIp}:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      print('Connected to server');
      socket.emit('joinRoom', {'broadcastId': widget.broadcastId, 'userId': widget.userId});
    });

    socket.on('receiveMessage', (data) {
      print('Received message data: $data'); // 데이터 구조 확인

      if (data is List) {
        for (var messageData in data) {
          String username = messageData['username'] ?? 'Unknown User'; // 'username' 필드를 사용

          // 유저별 색상을 랜덤하게 설정, 이미 설정된 유저는 기존 색상 유지
          if (!userColors.containsKey(username)) {
            userColors[username] = neonColors[Random().nextInt(neonColors.length)];
          }

          setState(() {
            _messages.add({
              'username': username,
              'message': messageData['message'] ?? '메시지 없음',
            });
          });
        }
        _scrollToBottom();
      } else {
        print('Unexpected data format: $data');
      }
    });

    socket.onDisconnect((_) => print('Disconnected from server'));
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse('http://${widget.serverIp}:5001/messages/${widget.broadcastId}'));
      if (response.statusCode == 200) {
        List<dynamic> messages = json.decode(response.body);
        setState(() {
          _messages.clear(); // 기존 메시지를 초기화하여 중복 방지
          for (var msg in messages) {
            String username = msg['username'] ?? 'Unknown User'; // name 필드를 사용

            if (!userColors.containsKey(username)) {
              userColors[username] = neonColors[Random().nextInt(neonColors.length)];
            }

            _messages.add({
              'username': username,
              'message': msg['message'] ?? '메시지 없음',
            });
          }
        });
        // 메시지가 모두 로드된 후 스크롤을 아래로 이동
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (error) {
      print('Error fetching messages: $error');
    }
  }


  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _isKeyboardVisible = bottomInset > 0.0;
    });
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

  Future<void> _initializePlayer() async {
    try {
      final response = await http.get(
        Uri.parse('http://${widget.serverIp}:5001/broadcast/${widget.broadcastId}'),
      );

      if (response.statusCode == 200) {
        final broadcastData = json.decode(response.body);

        if (broadcastData.containsKey('userId')) {
          final broadcastingUserId = broadcastData['userId'];
          final m3u8Url = 'http://${widget.serverIp}:5001/stream/$broadcastingUserId/output.m3u8';

          _videoPlayerController = VideoPlayerController.network(m3u8Url)
            ..initialize().then((_) {
              setState(() {});
              _videoPlayerController!.play();
            }).catchError((error) {
              print('Failed to load video: $error');
            });
        }
      }
    } catch (error) {
      print('Error fetching broadcast information: $error');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String message) async {
    final url = Uri.parse('http://${widget.serverIp}:5001/messages/${widget.broadcastId}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'message': message,
        'username': widget.userId,
      }),
    );
    _controller.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                      ? Positioned.fill(
                          child: AspectRatio(
                            aspectRatio: _videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController!),
                          ),
                        )
                      : Center(child: CircularProgressIndicator()),
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
                                final username = message['username']!;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '$username: ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: userColors[username], // 유저별 랜덤 네온 색상
                                                ),
                                              ),
                                              TextSpan(
                                                text: message['message'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ..._floatingHearts,
                ],
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
    );
  }
}
