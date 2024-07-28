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
  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  VideoPlayerController? _videoPlayerController;
  IO.Socket? _socket;
  bool isProcessingImage = false;

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
      _cameraController = CameraController(_cameras.first, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      setState(() {});
    } else {
      print("No cameras available");
    }
  }

  void initializeVideoPlayer() {
    String hlsUrl = "http://172.20.10.10:5001/stream/output.m3u8";
    _videoPlayerController = VideoPlayerController.network(hlsUrl)
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController!.play();
      });
  }

  void initializeSocket() {
    _socket = IO.io('http://172.20.10.10:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.connect();
  }

  void startStreaming() {
    if (_cameraController?.value.isInitialized ?? false) {
      _cameraController!.startImageStream((CameraImage image) {
        if (!isProcessingImage) {
          setState(() => isProcessingImage = true);
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
      _socket!.emit('stream_image', base64Encode(Uint8List.fromList(jpg)));
    }
    setState(() => isProcessingImage = false);
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

          // Clipping RGB values to be within the 0-255 range
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          img.data[index] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }
      return img;
    } catch (e) {
      print("Error converting YUV420 to image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Broadcasting'),
        actions: [
          IconButton(icon: Icon(Icons.videocam), onPressed: startStreaming),
          IconButton(icon: Icon(Icons.switch_camera), onPressed: toggleCamera),
        ],
      ),
      body: Center(
        child: _videoPlayerController != null && _videoPlayerController!.value.isInitialized
          ? AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            )
          : (_cameraController != null && _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : CircularProgressIndicator()),
      ),
    );
  }

  void toggleStreaming() {
    if (isProcessingImage) {
      _cameraController?.stopImageStream();
      setState(() => isProcessingImage = false);
    } else {
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
    if (isProcessingImage) startStreaming();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    _socket?.disconnect();
    super.dispose();
  }
}
