import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String message;

  ChatMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(message, style: TextStyle(color: Colors.white)),
    );
  }
}
