import 'package:flutter/material.dart';
import 'dart:typed_data'; // Uint8List를 사용하기 위해 추가
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import 'package:http/http.dart' as http; // Import http package
import 'broadcast_screen.dart'; // BroadcastScreen 임포트

class FaceRecognitionScreen extends StatefulWidget {
  final String title;

  FaceRecognitionScreen({required this.title});

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  Uint8List? imageBytes;
  bool isLoading = false;

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

  Future<void> uploadImage() async {
    if (imageBytes == null) return;

    setState(() {
      isLoading = true;
    });

    final uri = Uri.parse('http://43.203.251.58:5001/uploadFile');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'attachment', // 필드 이름을 'attachment'로 변경
        imageBytes!,
        filename: 'upload.png',
      ));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        // Successfully uploaded
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BroadcastScreen()),
        );
      } else {
        // Handle the error
        showErrorDialog('이미지 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      showErrorDialog('이미지 업로드 중 오류 발생: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('오류'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.face, size: constraints.maxWidth * 0.3),
                    SizedBox(height: 20),
                    imageBytes == null
                        ? Text('이미지를 선택해 주세요.', textAlign: TextAlign.center)
                        : Image.memory(imageBytes!),
                    SizedBox(height: 20),
                    Text(
                      '방송을 하기 위해서는 얼굴인식이 필요합니다. 정면으로 나온 얼굴 사진 한장을 업로드해주세요.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: pickImage,
                      child: Text('찾기'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : uploadImage,
                      child:
                          isLoading ? CircularProgressIndicator() : Text('다음'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
