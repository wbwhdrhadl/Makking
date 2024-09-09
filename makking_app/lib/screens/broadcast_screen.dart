import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class BroadcastScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final String userId;
  final String serverIp;
  final bool isMosaicEnabled;

  BroadcastScreen({this.imageBytes, required this.userId, required this.serverIp, required this.isMosaicEnabled});

  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  IO.Socket? _socket;
  bool isRecording = false;
  bool isStreaming = false;
  List<String> comments = [];
  int likes = 0;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setLandscapeMode();
    initializeCamera();
    initializeSocket();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setPortraitMode();
    _cameraController?.dispose();
    _socket?.disconnect();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    setState(() {
      _isKeyboardVisible = bottomInset > 0.0;
    });
  }

  void _setLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  void _setPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController = CameraController(_cameras.first, ResolutionPreset.max, enableAudio: true);
      await _cameraController!.initialize();
      setState(() {});
    } else {
      print("No cameras available");
    }
  }

  void initializeSocket() {
    _socket = IO.io('http://${widget.serverIp}:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.connect();

    _socket!.on('new_comment', (data) {
      setState(() {
        comments.add(data);
      });
    });

    _socket!.on('like_update', (data) {
      setState(() {
        likes = data;
      });
    });
  }

  void startStreaming() {
    if (_cameraController?.value.isInitialized ?? false) {
      _cameraController!.startImageStream((CameraImage image) {
        if (!isStreaming) {
          setState(() => isStreaming = true);
          processImage(image);
        }
      });
    }
  }

  Future<void> processImage(CameraImage image) async {
    var img = await compute(convertYUV420toImage, image);
    if (img != null && _socket != null && _socket!.connected) {
      final resizedImg = imglib.copyResize(img, width: 640, height: 480);
      List<int> jpg = imglib.encodeJpg(resizedImg, quality: 70);
      String imageBase64 = base64Encode(Uint8List.fromList(jpg));

      _socket!.emit('stream_image', imageBase64);
    }
    setState(() => isStreaming = false);
  }

  static imglib.Image? convertYUV420toImage(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final imglib.Image img = imglib.Image(width, height);

      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvPixelStride = image.planes[1].bytesPerPixel!;
      for (int y = 0; y < height; y++) {
        final int uvY = y >> 1;
        for (int x = 0; x < width; x++) {
          final int uvX = x >> 1;
          final int uvIndex = uvY * uvRowStride + uvX * uvPixelStride;
          final int index = y * width + x;

          final int yp = image.planes[0].bytes[index];
          final int up = image.planes[1].bytes[uvIndex];
          final int vp = image.planes[2].bytes[uvIndex];

          int r = (yp + 1.402 * (vp - 128)).toInt();
          int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).toInt();
          int b = (yp + 1.772 * (up - 128)).toInt();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          img.data[index] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }
      return img;
    } catch (e) {
      print("Error converting YUV420toImage: $e");
      return null;
    }
  }

  void toggleStreaming() {
    if (isRecording) {
      _socket!.emit('stop_recording');
      setState(() {
        isRecording = false;
        isStreaming = false;
      });
      _cameraController?.stopImageStream();
    } else {
      _socket!.emit('start_recording', {
        'userId': widget.userId,
        'isMosaicEnabled': widget.isMosaicEnabled,  // 모자이크 여부 전달
      });
      setState(() {
        isRecording = true;
      });
      startStreaming();
    }
  }

  void toggleCamera() async {
    if (_cameras.isEmpty) return;

    CameraDescription newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != _cameraController?.description.lensDirection,
      orElse: () => _cameras.first,
    );

    await _cameraController?.dispose();
    _cameraController = CameraController(newCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (isRecording) startStreaming();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _cameraController != null && _cameraController!.value.isInitialized
              ? Positioned.fill(
                  child: CameraPreview(_cameraController!),
                )
              : Center(child: CircularProgressIndicator()),

          // 채팅창
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.35,
              color: Colors.black.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '채팅',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(comments[index], style: TextStyle(color: Colors.white)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 녹화 버튼 및 카메라 전환 버튼을 화면 오른쪽에 배치
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3, // 화면 중간쯤 위치
            right: 10,
            child: Column(
              children: [
                IconButton(
                  icon: Icon(isRecording ? Icons.stop : Icons.videocam, color: Colors.red, size: 36),
                  onPressed: toggleStreaming,
                ),
                SizedBox(height: 10),
                IconButton(
                  icon: Icon(Icons.switch_camera, color: Colors.white, size: 36),
                  onPressed: toggleCamera,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}