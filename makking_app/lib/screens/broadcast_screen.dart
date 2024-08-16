import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart';

class BroadcastScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final String userId;
  final String serverIp;

  BroadcastScreen({this.imageBytes, required this.userId, required this.serverIp});

  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  IO.Socket? _socket;
  bool isRecording = false;
  bool isStreaming = false;
  List<String> comments = [];
  int likes = 0;

  TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeCamera();
    initializeVideoPlayer();
    initializeSocket();
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

  void initializeVideoPlayer() {
    String hlsUrl = "http://${widget.serverIp}:5001/stream/output.m3u8";
    _videoPlayerController = VideoPlayerController.network(hlsUrl)
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController!.play();
      });
  }

  void initializeSocket() {
    _socket = IO.io('http://${widget.serverIp}:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.connect();

    // Listen for incoming comments and update the state
    _socket!.on('new_comment', (data) {
      setState(() {
        comments.add(data);
      });
    });

    // Listen for likes updates
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

      // Send the image data to the server
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
    print("User ID: ${widget.userId}"); // 여기에 userId를 출력
    if (isRecording) {//레코딩 시작
      _socket!.emit('stop_recording');
      setState(() {
        isRecording = false;
        isStreaming = false;
      });
      _cameraController?.stopImageStream();
    } else {//레코딩 멈춤
      print("Sending start_recording event with userId: ${widget.userId}");
      _socket!.emit('start_recording', {
         'userId': widget.userId, // userId를 함께 전달
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

  void sendComment() {
    if (_commentController.text.isNotEmpty && _socket != null && _socket!.connected) {
      _socket!.emit('send_comment', _commentController.text);
      _commentController.clear();
    }
  }

  void sendLike() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('send_like');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Broadcasting', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(isRecording ? Icons.stop : Icons.videocam, color: Colors.red),
            onPressed: toggleStreaming,
          ),
          IconButton(
            icon: Icon(Icons.switch_camera, color: Colors.white),
            onPressed: toggleCamera,
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio,
                    child: VideoPlayer(_videoPlayerController!),
                  )
                : (_cameraController != null && _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!)
                    : Center(child: CircularProgressIndicator())),
          ),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(comments[index], style: TextStyle(color: Colors.white)),
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.black54,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "댓글을 입력하세요...",
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.blueAccent),
                        onPressed: sendComment,
                      ),
                      IconButton(
                        icon: Icon(Icons.thumb_up, color: Colors.blueAccent),
                        onPressed: sendLike,
                      ),
                      Text('$likes', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    _socket?.disconnect();
    super.dispose();
  }
}
