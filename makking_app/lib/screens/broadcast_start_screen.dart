import 'package:flutter/material.dart';
import 'face_recognition_screen.dart'; // FaceRecognitionScreen 임포트

class BroadcastStartScreen extends StatefulWidget {
  @override
  _BroadcastStartScreenState createState() => _BroadcastStartScreenState();
}

class _BroadcastStartScreenState extends State<BroadcastStartScreen> {
  bool isMosaicEnabled = false;
  bool isSubtitleEnabled = false;
  TextEditingController titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('방송 시작 환경설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Makking만의 방송 환경을 설정해보세요!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: '방송 제목',
                ),
              ),
              SizedBox(height: 24),
              SwitchListTile(
                title: Text('유해물질 모자이크'),
                value: isMosaicEnabled,
                onChanged: (bool value) {
                  setState(() {
                    isMosaicEnabled = value;
                  });
                },
              ),
              SwitchListTile(
                title: Text('자막 설정'),
                value: isSubtitleEnabled,
                onChanged: (bool value) {
                  setState(() {
                    isSubtitleEnabled = value;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FaceRecognitionScreen(title: '얼굴 인식 화면'),
                    ),
                  );
                },
                child: Text('다음'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
