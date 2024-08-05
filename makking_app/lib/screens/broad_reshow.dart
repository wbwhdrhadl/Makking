import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BroadReshow extends StatefulWidget {
  final String broadcastName;

  BroadReshow({required this.broadcastName});

  @override
  _BroadReshowState createState() => _BroadReshowState();
}

class _BroadReshowState extends State<BroadReshow> {
  late VideoPlayerController _controller;
  final List<String> _subtitles = [
    "자막 1: 첫 번째 자막입니다.",
    "자막 2: 두 번째 자막입니다.",
    "자막 3: 세 번째 자막입니다."
  ]; // 예시 자막 리스트
  int _currentSubtitleIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('../assets/video1.mp4')
      ..initialize().then((_) {
        setState(() {});
      });

    // 예시로 일정 시간마다 자막 변경
    _controller.addListener(() {
      if (_controller.value.position >= Duration(seconds: 3) &&
          _currentSubtitleIndex == 0) {
        setState(() {
          _currentSubtitleIndex = 1;
        });
      } else if (_controller.value.position >= Duration(seconds: 6) &&
          _currentSubtitleIndex == 1) {
        setState(() {
          _currentSubtitleIndex = 2;
        });
      }
    });
  }

  @override
  void dispose() {
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
        child: Column(
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
        child: Text(
          _subtitles[_currentSubtitleIndex],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: () {
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
