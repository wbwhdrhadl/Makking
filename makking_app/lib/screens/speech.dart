import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON processing
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'result.dart'; // 결과 페이지 import

class SpeechScreen extends StatefulWidget {
  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  FilePickerResult? _audioFileResult;
  bool _isLoading = false;
  String _uploadStatus = '';

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null) {
        setState(() {
          _audioFileResult = result;
        });
      }
    } catch (e) {
      print("Error picking audio file: $e");
    }
  }

  Future<void> _uploadAudio(BuildContext context) async {
    if (_audioFileResult == null) return;

    setState(() {
      _isLoading = true;
      _uploadStatus = '';
    });

    try {
      // Get the file path for different platforms
      String? filePath;
      if (kIsWeb) {
        // Web doesn't have a file path
        filePath = null;
      } else if (Platform.isAndroid || Platform.isIOS) {
        filePath = _audioFileResult!.files.single.path;
      }

      if (filePath == null && !kIsWeb) {
        print('Unsupported platform');
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5003/transcribe/'),
      );

      if (kIsWeb) {
        // Handle web file upload
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _audioFileResult!.files.single.bytes!,
          filename: _audioFileResult!.files.single.name,
        ));
      } else {
        // Handle mobile file upload
        request.files.add(await http.MultipartFile.fromPath('file', filePath!));
      }

      request.fields['num_speakers'] = '2'; // Optional: Number of speakers
      var response = await request.send();

      if (response.statusCode == 200) {
        var data = await response.stream.bytesToString();
        print('File uploaded successfully: $data');

        if (mounted) {
          setState(() {
            _isLoading = false;
            _uploadStatus = '';
          });

          // 데이터를 ResultScreen으로 전달
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ResultScreen(transcript: jsonDecode(data)['transcript']),
            ),
          );
        }
      } else {
        print('Failed to upload file: ${response.statusCode}');
        setState(() {
          _uploadStatus = '파일 업로드 실패: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error uploading file: $e');
      setState(() {
        _uploadStatus = '파일 업로드 오류: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('화자 분석하기'),
        backgroundColor: const Color.fromARGB(255, 179, 160, 212),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 8,
                shadowColor:
                    const Color.fromARGB(255, 32, 23, 48).withOpacity(0.5),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.audiotrack,
                        size: 100,
                        color: const Color.fromARGB(255, 163, 146, 193),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _pickAudio,
                        icon: Icon(Icons.folder_open),
                        label: Text('오디오 파일 선택'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 206, 205, 208),
                          padding: EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 15.0),
                          textStyle: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _audioFileResult != null
                          ? Text(
                              '선택된 파일: ${_audioFileResult!.files.single.name}',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              '선택된 파일 없음',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _uploadAudio(context), // context 전달
                        icon: Icon(Icons.cloud_upload),
                        label: Text('업로드'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 255, 255, 255),
                          padding: EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 15.0),
                          textStyle: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                        ),
                      ),
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: CircularProgressIndicator(),
                        ),
                      if (_uploadStatus.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Text(
                            _uploadStatus,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                              color: _uploadStatus.contains('성공')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
