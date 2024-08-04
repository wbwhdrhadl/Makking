import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'broadcast_screen.dart';

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

    final uri = Uri.parse('http://localhost:5001/uploadFile'); // Express 서버 주소
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
        'attachment',
        imageBytes!,
        filename: 'upload.png',
      ));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseJson = json.decode(responseBody);

      if (response.statusCode == 200) {
        final imageUrl = responseJson['url'];
        await processImage(imageUrl);
      } else {
        showErrorDialog('이미지 업로드 실패: ${responseJson['message']}');
      }
    } catch (e) {
      showErrorDialog('이미지 업로드 중 오류 발생: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> processImage(String imageUrl) async {
    final uri =
        Uri.parse('http://localhost:8000/processImage'); // FastAPI 서버 주소
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'image_url': imageUrl}),
    );

    if (response.statusCode == 200) {
      final responseJson = json.decode(response.body);
      final processedImage = base64Decode(responseJson['image']);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BroadcastScreen(imageBytes: processedImage),
        ),
      );
    } else {
      showErrorDialog('이미지 처리 실패: ${response.body}');
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
