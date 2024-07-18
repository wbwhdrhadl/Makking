import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/services.dart';

class BroadcastScreen extends StatefulWidget {
  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  late IOWebSocketChannel _channel;
  static const platform = MethodChannel('com.example.makking_app/ffmpeg');
  bool isStreaming = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    initSocket();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController = CameraController(_cameras.first, ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {});
    } else {
      print("No cameras available");
    }
  }

  void initSocket() {
    _channel = IOWebSocketChannel.connect('ws://172.30.1.13:5001');
    print('Connected to websocket');
  }

  Future<void> startStreaming() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print("Camera is not initialized.");
      return;
    }

    final String rtmpUrl = 'rtmp://172.30.1.13/live/my_stream_key';
    final String command = '-f lavfi -i anullsrc -i video="${_cameraController!.description.name}" -vcodec libx264 -pix_fmt yuv420p -f flv $rtmpUrl';

    try {
      final String result = await platform.invokeMethod('startFFmpeg', {'command': command});
      print(result);
      setState(() {
        isStreaming = true;
      });
    } on PlatformException catch (e) {
      print("Failed to start FFmpeg: '${e.message}'.");
    }
  }

  Future<void> stopStreaming() async {
    // Flutter에서 FFmpeg 종료 로직 추가
    setState(() {
      isStreaming = false;
    });
    _cameraController!.stopImageStream();
    _channel.sink.close();
  }

  @override
  void dispose() {
    _channel.sink.close();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isStreaming ? 'Stop Broadcasting' : 'Start Broadcasting'),
        actions: [
          IconButton(
            icon: Icon(isStreaming ? Icons.stop : Icons.videocam),
            onPressed: isStreaming ? stopStreaming : startStreaming,
          ),
        ],
      ),
      body: Center(
        child: _cameraController!.value.isInitialized
            ? CameraPreview(_cameraController!)
            : const Text('No camera available'),
      ),
    );
  }
}
