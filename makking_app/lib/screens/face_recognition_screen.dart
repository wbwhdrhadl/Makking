import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'broadcast_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class FaceRecognitionScreen extends StatefulWidget {
  final String title;
  final String userId;
  final bool isMosaicEnabled;
  final bool isSubtitleEnabled;
  final String serverIp;
  final File? thumbnailImage;
  final Uint8List? webThumbnailImageBytes;

  FaceRecognitionScreen({
    required this.title,
    required this.userId,
    required this.isMosaicEnabled,
    required this.isSubtitleEnabled,
    required this.serverIp,
    this.thumbnailImage,
    this.webThumbnailImageBytes,
  });

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  Uint8List? imageBytes;
  bool isLoading = false;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    socket = IO.io('http://${widget.serverIp}:5001', <String, dynamic>{
      'transports': ['websocket'],
    });

    socket.on('connect', (_) {
      print('Connected to server');
    });

    socket.on('disconnect', (_) {
      print('Disconnected from server');
    });
  }

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

  Future<void> uploadImageAndBroadcastData() async {
    if (imageBytes == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Step 1: Upload face image to S3 and get the URL
      final uploadUri = Uri.parse('http://${widget.serverIp}:5001/uploadFile');
      final uploadRequest = http.MultipartRequest('POST', uploadUri);

      uploadRequest.files.add(http.MultipartFile.fromBytes(
        'attachment',
        imageBytes!,
        filename: 'face_image.png',
      ));

      final uploadResponse = await uploadRequest.send();
      final responseBody = await uploadResponse.stream.bytesToString();
      final responseJson = json.decode(responseBody);

      if (uploadResponse.statusCode == 200) {
        final String? faceImageUrl = responseJson['url'];

        if (faceImageUrl != null) {
          // Step 2: Generate signed URL and send to server
          await generateAndSendSignedUrl(faceImageUrl);

          // Step 3: Save broadcast settings along with faceImageUrl
          await saveBroadcastData(faceImageUrl);
        } else {
          showErrorDialog('S3에서 이미지 URL을 받지 못했습니다.');
        }
      } else {
        showErrorDialog('이미지 업로드 실패: ${responseJson['message']}');
      }
    } catch (e) {
      showErrorDialog('서버 요청 중 오류 발생: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> generateAndSendSignedUrl(String faceImageUrl) async {
    try {
      // Step 2.1: Generate signed URL
      final signedUrlUri = Uri.parse('http://${widget.serverIp}:5001/generateSignedUrl');
      final signedUrlResponse = await http.post(
        signedUrlUri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'imageUrl': faceImageUrl}),
      );

      if (signedUrlResponse.statusCode == 200) {
        final signedUrlJson = json.decode(signedUrlResponse.body);
        final String? signedUrl = signedUrlJson['signedUrl'];

        if (signedUrl != null) {
          // Step 2.2: Send signed URL to server via Socket.IO
          socket.emit('start_recording', signedUrl);
        } else {
          showErrorDialog('서명된 URL이 없습니다.');
        }
      } else {
        showErrorDialog('서명된 URL 생성 실패');
      }
    } catch (e) {
      showErrorDialog('서명된 URL 생성 중 오류 발생: $e');
    }
  }

  Future<void> saveBroadcastData(String faceImageUrl) async {
    final uri = Uri.parse('http://${widget.serverIp}:5001/broadcast/Setting');
    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = widget.userId;
    request.fields['title'] = widget.title;
    request.fields['is_mosaic_enabled'] = widget.isMosaicEnabled.toString();
    request.fields['is_subtitle_enabled'] = widget.isSubtitleEnabled.toString();
    request.fields['face_image_url'] = faceImageUrl;

    if (widget.thumbnailImage != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'thumbnail',
        widget.thumbnailImage!.path,
      ));
    } else if (widget.webThumbnailImageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'thumbnail',
        widget.webThumbnailImageBytes!,
        filename: 'thumbnail_image.png',
      ));
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseJson = json.decode(responseBody);

      if (response.statusCode == 200) {
        // 데이터를 성공적으로 저장한 후 다음 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BroadcastScreen(
              imageBytes: null,
              userId: widget.userId,
              serverIp: widget.serverIp, // 서버 IP 전달
            ),
          ),
        );
      } else {
        showErrorDialog('방송 설정 저장 실패: ${responseJson['message']}');
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
          title: Text(
            '오류',
            style: GoogleFonts.doHyeon(),
          ),
          content: Text(
            message,
            style: GoogleFonts.doHyeon(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                '확인',
                style: GoogleFonts.doHyeon(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.jua(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.face,
                      size: constraints.maxWidth * 0.3,
                      color: Colors.white,
                    ),
                    SizedBox(height: 20),
                    imageBytes == null
                        ? Text(
                            '이미지를 선택해 주세요.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.doHyeon(color: Colors.white),
                          )
                        : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  imageBytes!,
                                  fit: BoxFit.contain, // 이미지 원본 크기로 표시
                                ),
                              ),
                            ),
                    SizedBox(height: 20),
                    Text(
                      imageBytes == null
                          ? '방송을 하기 위해서는 얼굴인식이 필요합니다.\n정면으로 나온 얼굴 사진 한장을 업로드해주세요.'
                          : '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.doHyeon(color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF749BC2),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: GoogleFonts.gothicA1(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('이미지 선택'),
                      ),
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : uploadImageAndBroadcastData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF749BC2),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: GoogleFonts.gothicA1(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text('방송 시작'),
                      ),
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
