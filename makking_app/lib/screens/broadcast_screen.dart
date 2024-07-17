import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_socket_io/flutter_socket_io.dart';
import 'package:flutter_socket_io/socket_io_manager.dart';
import 'dart:convert';

class BroadcastScreen extends StatefulWidget {
  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  MediaStream? _localStream;
  final SocketIOManager _socketIOManager = SocketIOManager();
  SocketIO? _socket;
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
    _socket = _socketIOManager.createSocketIO(
      'http://172.30.1.13', // 서버 주소
      '/',
    );
    _socket!.init();
    _socket!.connect();
  }

  Future<void> startStreaming() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print("Camera is not initialized.");
      return;
    }

    final String rtmpUrl = 'rtmp://172.30.1.13/live/my_stream_key';
    final String command = '-f lavfi -i anullsrc -f dshow -i video="${_cameraController!.description.name}" -vcodec libx264 -pix_fmt yuv420p -preset ultrafast -tune zerolatency -f flv $rtmpUrl';

    // FFmpeg 실행
    _flutterFFmpeg.execute(command).then((rc) {
      print('FFmpeg process exited with rc $rc');
    });

    setState(() {
      isStreaming = true;
    });

    // 예시: 이미지 스트리밍
    _cameraController!.startImageStream((CameraImage image) {
      // 이미지 데이터 처리 및 소켓 전송
      List<int> imageData = image.planes[0].bytes;
      String base64Image = base64Encode(imageData);

      _socket!.emit('stream_image', [base64Image]); // 서버로 이미지 데이터 전송
    });
  }

  Future<void> stopStreaming() async {
    _flutterFFmpeg.cancel();
    setState(() {
      isStreaming = false;
    });

    _cameraController!.stopImageStream();
  }

  @override
  void dispose() {
    _socket!.disconnect();
    _socketIOManager.dispose();
    _cameraController?.dispose();
    _localStream?.dispose();
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
