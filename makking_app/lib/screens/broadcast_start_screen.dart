import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Google Fonts 패키지 임포트

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
  File? _thumbnailImage;
  Uint8List? _webThumbnailImageBytes;

  Future<void> _pickThumbnailImage() async {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(files[0]);
          reader.onLoadEnd.listen((event) {
            setState(() {
              _webThumbnailImageBytes = reader.result as Uint8List?;
            });
          });
        }
      });
    } else {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _thumbnailImage = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _startBroadcast() async {
  try {
    // 서버로 데이터 전송 로직 추가
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://localhost:5001/broadcast/Setting'),
    );

    request.fields['user_id'] = widget.userId;
    request.fields['title'] = titleController.text;
    request.fields['is_mosaic_enabled'] = isMosaicEnabled.toString();
    request.fields['is_subtitle_enabled'] = isSubtitleEnabled.toString();

    if (kIsWeb) {
      if (_webThumbnailImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'thumbnail',
          _webThumbnailImageBytes!,
          filename: 'thumbnail_image.png',
        ));
      }
    } else {
      if (_thumbnailImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'thumbnail',
          _thumbnailImage!.path,
        ));
      }
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      print('Broadcast settings saved successfully');
      
      // FaceRecognitionScreen으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FaceRecognitionScreen(
            userId: widget.userId,
            isMosaicEnabled: isMosaicEnabled,
            isSubtitleEnabled: isSubtitleEnabled,
            title: titleController.text,
          ),
        ),
      );
    } else {
      print('Failed to save broadcast settings: ${response.reasonPhrase}');
    }
  } catch (e) {
    print('Error: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('방송 시작하기', style: GoogleFonts.jua(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '썸네일',
              style: GoogleFonts.doHyeon(
                fontSize: 20,
                color: Color(0xFF749BC2),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: _pickThumbnailImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  image: _thumbnailImage != null || _webThumbnailImageBytes != null
                      ? DecorationImage(
                          image: _thumbnailImage != null
                              ? FileImage(_thumbnailImage!)
                              : MemoryImage(_webThumbnailImageBytes!) as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _thumbnailImage == null && _webThumbnailImageBytes == null
                    ? Center(
                        child: Icon(
                          Icons.add_photo_alternate,
                          color: Colors.white,
                          size: 50,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: '방송 제목',
                labelStyle: GoogleFonts.doHyeon(
                  color: Color(0xFF749BC2),
                  fontSize: 20, // 더 큰 글씨 크기
                  fontWeight: FontWeight.bold, // 두꺼운 글씨체
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF749BC2)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF749BC2)),
                ),
              ),
              style: GoogleFonts.doHyeon(
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                '유해물질 모자이크',
                style: GoogleFonts.doHyeon(color: Colors.white),
              ),
              value: isMosaicEnabled,
              onChanged: (bool value) {
                setState(() {
                  isMosaicEnabled = value;
                });
              },
              activeColor: Color(0xFF749BC2),
            ),
            SwitchListTile(
              title: Text(
                '자막 설정',
                style: GoogleFonts.doHyeon(color: Colors.white),
              ),
              value: isSubtitleEnabled,
              onChanged: (bool value) {
                setState(() {
                  isSubtitleEnabled = value;
                });
              },
              activeColor: Color(0xFF749BC2),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _startBroadcast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF749BC2),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: GoogleFonts.jua(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('방송 시작'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
