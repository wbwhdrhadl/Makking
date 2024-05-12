import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broadcasting Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Broadcast2(),
    );
  }
}

class Broadcast2 extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

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
                    '/Users/da-eun/Documents/GitHub/Makking/makking_app/assets/img1.jpeg',
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
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          children: [
                            ChatMessage(message: '안녕하세요'),
                            ChatMessage(message: '좋아요!'),
                            ChatMessage(message: '방송 재밌네요!'),
                            ChatMessage(message: '다음 방송 언제인가요?'),
                            ChatMessage(message: '이 채팅 좋네요!'),
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
                            IconButton(
                              icon: Icon(Icons.send, color: Colors.blue),
                              onPressed: () {
                                // Add functionality to send the message
                                String message = _controller.text;
                                // Clear the input field
                                _controller.clear();
                                // Handle the message sending logic
                                print('Message sent: $message');
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
