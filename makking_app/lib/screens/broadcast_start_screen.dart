import 'package:flutter/material.dart';
import 'face_recognition_screen.dart';

class BroadcastStartScreen extends StatefulWidget {
  final String userId;

  BroadcastStartScreen({required this.userId});

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
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: '방송 제목'),
              ),
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
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FaceRecognitionScreen(
                        title: titleController.text,
                        userId: widget.userId, // userId 전달
                        isMosaicEnabled: isMosaicEnabled,
                        isSubtitleEnabled: isSubtitleEnabled,
                      ),
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
