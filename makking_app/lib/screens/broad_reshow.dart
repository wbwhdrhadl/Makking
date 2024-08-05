import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:http/http.dart' as http;

class BroadReshow extends StatefulWidget {
  final String broadcastName;

  BroadReshow({required this.broadcastName});

  @override
  _BroadReshowState createState() => _BroadReshowState();
}

class _BroadReshowState extends State<BroadReshow> {
  late VideoPlayerController _controller;
  List<Map<String, dynamic>> _subtitles = [];
  int _currentSubtitleIndex = 0;
  bool _subtitlesLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/video1.mp4')
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.addListener(_updateSubtitle);
  }

  Future<void> _loadSubtitles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load the asset file
      final ByteData data = await rootBundle.load('assets/video1.mp4');
      final Uint8List bytes = data.buffer.asUint8List();

      // Send the file to the server
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:5003/transcribe/'),
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
        });
      } else {
        throw Exception('Failed to load subtitles');
      }
    } catch (e) {
      print('Error loading subtitles: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subtitles: $e')),
      );
    }
  }

  void _updateSubtitle() {
    if (!_subtitlesLoaded) return;

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
      appBar: AppBar(
        title: Text(widget.broadcastName),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // 로딩 화면
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_controller.value.isInitialized)
                    AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_controller),
                          _buildSubtitle(),
                          _buildPlayPauseButton(),
                        ],
                      ),
                    ),
                  SizedBox(height: 20),
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
    return GestureDetector(
      onTap: () async {
        if (!_subtitlesLoaded) {
          await _loadSubtitles();
          if (_subtitlesLoaded) {
            setState(() {
              _controller.play();
            });
          }
        } else {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        }
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Icon(
          _controller.value.isPlaying
              ? Icons.pause_circle_filled
              : Icons.play_circle_filled,
          color: Colors.white,
          size: 80,
        ),
      ),
    );
  }
}
