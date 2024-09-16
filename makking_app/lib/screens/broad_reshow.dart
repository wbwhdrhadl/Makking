import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:http/http.dart' as http;

class BroadReshow extends StatefulWidget {
  final String broadcastName;
  final String userId; // Add userId as a required parameter
  final String serverIp; // serverIp 필드 추가

  BroadReshow(
      {required this.broadcastName,
      required this.userId,
      required this.serverIp}); // Update constructor

  @override
  _BroadReshowState createState() => _BroadReshowState();
}

class _BroadReshowState extends State<BroadReshow> {
  late VideoPlayerController _controller;
  List<Map<String, dynamic>> _subtitles = [];
  int _currentSubtitleIndex = 0;
  bool _subtitlesLoaded = false;
  bool _isLoading = false;
  bool _showSubtitles = false;
  bool _isGeneratingSubtitles = false; // Track subtitle generation state
  bool _isMouseOver = false; // Track mouse hover state
  bool _isPlaying = false; // Track video playback state

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/prevideo.mp4')
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(() {
      _updateSubtitle();
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    });
  }

  Future<void> _loadSubtitles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load the asset file
      final ByteData data = await rootBundle.load('assets/prevideo.mp4');
      final Uint8List bytes = data.buffer.asUint8List();

      // Send the file to the server
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5003/process-and-analyze/'),
      )..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: 'video1.mp4'),
        );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseBody);
        setState(() {
          _subtitles =
              List<Map<String, dynamic>>.from(jsonResponse['transcript']);
          _subtitlesLoaded = true;
          _isLoading = false;
          _isGeneratingSubtitles =
              false; // Update the state after generating subtitles
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('자막 생성 완료!')),
        );
      } else {
        throw Exception('Failed to load subtitles');
      }
    } catch (e) {
      print('Error loading subtitles: $e');
      setState(() {
        _isLoading = false;
        _isGeneratingSubtitles = false; // Update the state if there is an error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subtitles: $e')),
      );
    }
  }

  void _updateSubtitle() {
    if (!_subtitlesLoaded || !_showSubtitles) return;

    final position = _controller.value.position.inSeconds;
    for (int i = 0; i < _subtitles.length; i++) {
      final subtitle = _subtitles[i];
      if (position >= subtitle['start'] && position <= subtitle['end']) {
        setState(() {
          _currentSubtitleIndex = i;
        });
        break;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateSubtitle);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv, color: Colors.greenAccent, size: 30),
            SizedBox(width: 10),
            Text(
              widget.broadcastName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white, // 글자 색상을 흰색으로 설정
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_controller.value.isInitialized)
              Expanded(
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _isMouseOver = true;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _isMouseOver = false;
                    });
                  },
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.greenAccent, width: 6),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                spreadRadius: 5,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _controller.value.size.width,
                              height: _controller.value.size.height,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: VideoPlayer(_controller),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_showSubtitles) _buildSubtitle(),
                      if (_isMouseOver || _isPlaying) _buildPlayPauseButton(),
                    ],
                  ),
                ),
              ),
            if (!_controller.value.isInitialized) CircularProgressIndicator(),
            SizedBox(height: 20),
            _buildActionButtons(),
            if (_isGeneratingSubtitles)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('자막 생성 중입니다. 잠시만 기다려 주세요.',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    if (_subtitles.isEmpty || _currentSubtitleIndex >= _subtitles.length) {
      return SizedBox.shrink();
    }

    final subtitle = _subtitles[_currentSubtitleIndex];
    final speakerInfo = subtitle['speaker'];
    final text = subtitle['text'];

    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            if (speakerInfo != null)
              Text(
                speakerInfo,
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - 30, // Center horizontally
      top: MediaQuery.of(context).size.height / 2 - 30, // Center vertically
      child: GestureDetector(
        onTap: () async {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 60,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            setState(() {
              _isGeneratingSubtitles = true; // Show loading indicator
              _showSubtitles = true;
            });
            await _loadSubtitles(); // Load subtitles if the user chooses to generate them
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // 버튼 모서리를 둥글게
            ),
            padding:
                EdgeInsets.symmetric(vertical: 16, horizontal: 32), // 여유 있는 패딩
            elevation: 12, // 버튼의 그림자 깊이
            shadowColor: Colors.black.withOpacity(0.2), // 은은한 그림자 색상
            backgroundColor: Colors.tealAccent.shade400, // 세련된 민트색
          ),
          child: Text(
            '자막 생성하기',
            style: TextStyle(
              fontSize: 18, // 텍스트 크기
              fontWeight: FontWeight.w600, // 약간 굵게
              color: Colors.black87, // 텍스트 색상: 검은색에 가까운 회색
              letterSpacing: 1.2, // 글자 사이 간격
            ),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
