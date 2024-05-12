import 'package:flutter/material.dart';
import 'dart:typed_data'; // Uint8List를 사용하기 위해 추가
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'broadcast_screen.dart'; // BroadcastScreen 임포트

class FaceRecognitionScreen extends StatefulWidget {
  final String title;

  FaceRecognitionScreen({required this.title});

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  Uint8List? imageBytes;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        imageBytes = bytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.face, size: 100),
            SizedBox(height: 20),
            imageBytes == null
                ? Text('이미지를 선택해 주세요.')
                : Image.memory(imageBytes!), // 메모리에서 이미지를 불러와 표시
            SizedBox(height: 20),
            Text('방송을 하기 위해서는 얼굴인식이 필요합니다. 정면으로 나온 얼굴 사진 한장을 업로드해주세요.'),
            ElevatedButton(
              onPressed: pickImage,
              child: Text('찾기'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (imageBytes == null) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('알림'),
                        content: Text('사진을 업로드해주세요.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('확인'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BroadcastScreen()),
                  );
                }
              },
              child: Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}
