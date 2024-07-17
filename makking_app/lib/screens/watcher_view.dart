import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WatcherView extends StatefulWidget {
  @override
  _WatcherViewState createState() => _WatcherViewState();
}

class _WatcherViewState extends State<WatcherView> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
      'http://172.30.1.13:8080/hls/stream.m3u8', // HLS URL
    )..initialize().then((_) {
      setState(() {});
      _controller.play();
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
        title: Text('Watch Stream'),
      ),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
