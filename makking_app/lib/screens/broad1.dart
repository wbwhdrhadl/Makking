import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Broadcast1 extends StatefulWidget {
  final String broadcastName;

  Broadcast1({required this.broadcastName});

  @override
  _Broadcast1State createState() => _Broadcast1State();
}

class _Broadcast1State extends State<Broadcast1> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [];
  final ScrollController _scrollController = ScrollController(); // 스크롤 컨트롤러 추가

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse(
          'http://43.203.251.58:5001/messages/${widget.broadcastName}')); // API 엔드포인트 주소 확인
      if (response.statusCode == 200) {
        List<dynamic> messages = json.decode(response.body); // 메시지 배열 파싱
        List<String> messageList = messages.map((msg) {
          if (msg is Map<String, dynamic> && msg.containsKey('message')) {
            return msg['message'] as String;
          } else {
            return '메시지 없음';
          }
        }).toList();
        setState(() {
          _messages.clear(); // 새 메시지로 리스트를 업데이트
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
        Uri.parse('http://43.203.251.58:5001/messages/${widget.broadcastName}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );
      if (response.statusCode == 200) {
        _fetchMessages().then((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              // 메시지 전송 후 스크롤을 최하단으로 이동
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('방송 화면')),
      body: Stack(
        children: [
          Column(
            children: [
              // Broadcasting Image
              Container(
                height: 200,
                color: Colors.black,
                child: Center(
                  child: Image.asset(
                    'assets/img2.jpeg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
              ),
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
                          controller: _scrollController, // 스크롤 컨트롤러 사용
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
