import 'package:flutter/material.dart';
import 'broadcast_screen.dart';

class FaceRecognitionScreen extends StatelessWidget {
  final String title;

  FaceRecognitionScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face, size: 100),
            SizedBox(height: 20),
            Text('얼굴을 인식해주세요'),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BroadcastScreen()),
                );
              },
              child: Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}
