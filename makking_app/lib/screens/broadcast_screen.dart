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
      home: BroadcastScreen(),
    );
  }
}

class BroadcastScreen extends StatelessWidget {
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
                    '../assets/img2.jpeg',
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
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Filter Buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                color: Colors.black54,
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilterButton(
                      label: '필터적용',
                      imagePath: '../assets/img3.jpeg',
                    ),
                    FilterButton(
                      label: '필터적용',
                      imagePath: '../assets/img4.jpeg',
                    ),
                    FilterButton(
                      label: '필터적용',
                      imagePath: '../assets/img3.jpeg',
                    ),
                  ],
                ),
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

class FilterButton extends StatelessWidget {
  final String label;
  final String imagePath;

  FilterButton({required this.label, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(imagePath),
          radius: 20, // Adjust the radius as needed
        ),
        SizedBox(
            height: 5), // Add some spacing between the image and the button
        ElevatedButton(
          onPressed: () {
            // Add filter functionality here
          },
          child: Text(label),
        ),
      ],
    );
  }
}
