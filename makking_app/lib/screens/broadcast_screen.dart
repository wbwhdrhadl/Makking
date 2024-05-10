import 'package:flutter/material.dart';
import '../widgets/chat_message.dart';
import '../widgets/filter_button.dart';

class BroadcastScreen extends StatefulWidget {
  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  int selectedFaceIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('방송 화면')),
      body: Stack(
        children: [
          // Camera Preview Placeholder
          Container(color: Colors.grey[900]),
          Align(
            alignment: Alignment.topRight,
            child: Column(
              children: [
                Text('채팅', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: ListView(
                    children: [
                      ChatMessage(message: '안녕하세요'),
                      ChatMessage(message: '좋아요!'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterButton(label: '필터1'),
                FilterButton(label: '필터2'),
                FilterButton(label: '필터3'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
