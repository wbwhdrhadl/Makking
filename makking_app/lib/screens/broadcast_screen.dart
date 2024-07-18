import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'dart:ui' as ui;

class BroadcastScreen extends StatefulWidget {
  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  IO.Socket? _socket;
  bool isStreaming = false;
  Timer? _timer;
  String serverMessage = '';
  Image? processedImage;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    initializeSocket();
  }

  void initializeSocket() {
    _socket = IO.io('http://172.30.1.13:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.connect();
    _socket!.on('connect', (_) => print('Connected'));
    _socket!.on('receive_message', _handleImageData);
    _socket!.on('disconnect', (_) => print('Disconnected'));
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.medium, // Changed resolution to medium to potentially increase frame rate
        enableAudio: false
      );
      await _cameraController!.initialize();
      setState(() {});
    } else {
      print("No cameras available");
    }
  }

  void startStreaming() {
    if (_cameraController?.value.isInitialized ?? false) {
      _cameraController!.startImageStream((CameraImage image) => processImage(image)).catchError((error) {
        print("Error starting image stream: $error");
      });
      setState(() => isStreaming = true);
    } else {
      print("Camera is not initialized.");
    }
  }

  Future<void> processImage(CameraImage image) async {
    var img = await compute(convertYUV420toImage, image);
    if (img != null) {
      final resizedImg = imglib.copyResize(img, width: 320, height: 240);
      List<int> jpg = imglib.encodeJpg(resizedImg, quality: 70);
      if (isStreaming) _socket!.emit('stream_image', base64Encode(Uint8List.fromList(jpg)));
    }
  }

  static imglib.Image? convertYUV420toImage(CameraImage image) {
    try {
      final img = imglib.Image(image.width, image.height);
      for (int i = 0; i < image.width * image.height; i++) {
        img.data[i] = 0xFF000000 | (image.planes[0].bytes[i] << 16) | (image.planes[0].bytes[i] << 8) | image.planes[0].bytes[i];
      }
      return img;
    } catch (e) {
      print("Error converting YUV420 to image: $e");
      return null;
    }
  }

  void _handleImageData(dynamic data) {
    Uint8List imageData = base64Decode(data);
    setState(() {
      serverMessage = data;
      processedImage = Image.memory(imageData);
    });
  }

  void stopStreaming() {
    if (isStreaming) {
      _cameraController?.stopImageStream();
      setState(() => isStreaming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Broadcasting'),
        actions: [
          IconButton(icon: Icon(isStreaming ? Icons.stop : Icons.videocam), onPressed: toggleStreaming),
          IconButton(icon: Icon(Icons.switch_camera), onPressed: toggleCamera),
        ],
      ),
      body: Center(child: processedImage ?? CameraPreview(_cameraController!)),
    );
  }

  void toggleStreaming() => isStreaming ? stopStreaming() : startStreaming();

  void toggleCamera() async {
    if (_cameras.isEmpty) {
      print("No cameras available");
      return;
    }

    CameraDescription newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != _cameraController?.description.lensDirection,
      orElse: () => _cameras.first,
    );

    await _cameraController?.dispose();
    _cameraController = CameraController(newCamera, ResolutionPreset.medium); // Adjusted here as well
    await _cameraController!.initialize();
    if (isStreaming) startStreaming();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _socket?.disconnect();
    _timer?.cancel();
    super.dispose();
  }
}
