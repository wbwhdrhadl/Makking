import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'broadcast_screen.dart';

class FaceRecognitionScreen extends StatefulWidget {
  final String title;
  final String userId;
  final bool isMosaicEnabled;
  final bool isSubtitleEnabled;

  FaceRecognitionScreen({
    required this.title,
    required this.userId,
    required this.isMosaicEnabled,
    required this.isSubtitleEnabled,
  });

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

    final uri = Uri.parse('http://192.168.1.115:5001/uploadFile'); // Express 서버 주소
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
        await sendBroadcastDataToServer(imageUrl); // 서버로 데이터 전송
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

  Future<void> sendBroadcastDataToServer(String imageUrl) async {
    final uri = Uri.parse('http://192.168.1.115:5001/broadcast/Setting'); // 백엔드 API 엔드포인트
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'title': widget.title,
          'is_mosaic_enabled': widget.isMosaicEnabled,
          'is_subtitle_enabled': widget.isSubtitleEnabled,
          'image_url': imageUrl,
        }),
      );

      if (response.statusCode == 200) {
        final responseJson = json.decode(response.body);

        // 여기서 받은 응답의 이미지 URL을 처리합니다.
        final String? receivedImageUrl = responseJson['image'];

        if (receivedImageUrl != null) {
          // 이미지를 사용하는 다른 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BroadcastScreen(
                imageBytes: null, // 이미지는 사용하지 않으므로 null로 설정
                userId: widget.userId,
              ),
            ),
          );
        } else {
          showErrorDialog('이미지 URL이 없습니다.');
        }
      } else {
        showErrorDialog('이미지 처리 실패: ${response.body}');
      }
    } catch (e) {
      showErrorDialog('서버 요청 중 오류 발생: $e');
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
