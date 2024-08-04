import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class BroadcastScreen extends StatefulWidget {
  final Uint8List? imageBytes;

  BroadcastScreen({this.imageBytes});

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
  Image? processedImage; // 서버로부터 받은 이미지를 저장할 변수

  @override
  void initState() {
    super.initState();
    initializeCamera();
    initializeSocket();
  }

  void initializeSocket() {
    _socket = IO.io('http://localhost:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket!.connect();

    _socket!.on('connect', (_) {
      print('Connected');
    });

    _socket!.on('receive_message', (data) {
      setState(() {
        serverMessage = data;
        processedImage =
            Image.memory(base64Decode(data)); // 서버로부터 받은 이미지를 디코드하여 저장
      });
    });

    _socket!.on('disconnect', (_) => print('Disconnected'));
    _socket!.on('fromServer', (_) => print(_));
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _cameraController =
          CameraController(_cameras.first, ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {});
    } else {
      print("No cameras available");
    }
  }

  void startStreaming() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print("Camera is not initialized.");
      return;
    }
    _cameraController!.startImageStream((CameraImage image) {
      if (!isStreaming) {
        isStreaming = true;
        processImage(image);
      }
    });
  }

  Future<void> processImage(CameraImage image) async {
    var img = await compute(convertYUV420toImage, image);
    if (img != null) {
      List<int> png = imglib.encodePng(img);
      Uint8List data = Uint8List.fromList(png);
      _socket!.emit('stream_image', base64Encode(data));
    }
    await Future.delayed(Duration(milliseconds: 500)); // Adjust the frame rate
    isStreaming = false;
  }

  static imglib.Image? convertYUV420toImage(CameraImage image) {
    try {
      final img = imglib.Image(image.width, image.height);
      for (int i = 0; i < image.width * image.height; i++) {
        img.data[i] = 0xFF000000 |
            (image.planes[0].bytes[i] << 16) |
            (image.planes[0].bytes[i] << 8) |
            image.planes[0].bytes[i];
      }
      return img;
    } catch (e) {
      print("Error converting YUV420 to image: $e");
      return null;
    }
  }

  void stopStreaming() {
    _cameraController?.stopImageStream();
    setState(() {
      isStreaming = false;
    });
  }

  void toggleStreaming() {
    if (isStreaming) {
      stopStreaming();
    } else {
      startStreaming();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: toggleStreaming,
          child: Text(isStreaming ? 'Stop Broadcasting' : 'Start Broadcasting'),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: toggleCamera,
          ),
        ],
      ),
      body: processedImage != null
          ? processedImage!
          : widget.imageBytes != null
              ? Image.memory(widget.imageBytes!)
              : _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : Center(
                      child: Text('Initializing camera...'),
                    ), // 처리된 이미지 또는 카메라 미리보기를 표시
    );
  }

  void toggleCamera() async {
    if (_cameras.isEmpty) {
      print("No cameras available");
      return;
    }

    CameraLensDirection currentDirection =
        _cameraController?.description.lensDirection ??
            CameraLensDirection.front;
    CameraDescription newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != currentDirection,
      orElse: () => _cameras.first,
    );

    await _cameraController?.dispose();
    _cameraController = CameraController(newCamera, ResolutionPreset.high);
    await _cameraController!.initialize();
    if (isStreaming) {
      startStreaming();
    }
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
