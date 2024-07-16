import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as imglib;
import 'dart:async';

class BroadcastScreen extends StatefulWidget {
  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://172.30.1.13:5002'),
  );
  int selectedCameraIndex = 0; // 선택된 카메라 인덱스 초기화
  bool isStreaming = false; // 스트리밍 상태
  Timer? _timer; // 타이머 객체
  String serverMessage = '';

  @override
  void initState() {
    super.initState();
    initializeCamera();
    _channel.stream.listen((message) {
      setState(() {
        serverMessage = message;
      });
    });
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    CameraDescription? frontCamera;
    for (var camera in _cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        frontCamera = camera;
        break;
      }
    }

    if (frontCamera != null) {
      _cameraController = CameraController(frontCamera, ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {});
    } else {
      print("전방 카메라를 찾을 수 없습니다.");
    }
  }

  void toggleCamera() async {
    if (_cameras.isEmpty) {
      print("카메라를 찾을 수 없습니다.");
      return;
    }

    // 현재 카메라의 방향을 기반으로 새 카메라 결정
    CameraLensDirection currentDirection = _cameraController?.description.lensDirection ?? CameraLensDirection.front;
    CameraDescription newCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection != currentDirection,
      orElse: () => _cameras.first // 적절한 카메라를 찾지 못하면 첫 번째 카메라를 선택
    );

    if (newCamera == null) {
      print("적합한 카메라를 찾을 수 없습니다.");
      return;
    }

    // 이전 컨트롤러를 해제하고 새 컨트롤러로 업데이트
    await _cameraController?.dispose();

    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false // 오디오는 비활성화
    );

    try {
      await _cameraController!.initialize();
    } catch (e) {
      print("카메라 초기화 실패: $e");
      return;
    }

    // 상태 업데이트 및 스트리밍 재시작
    if (mounted) {
      setState(() {});
      if (isStreaming) {
        startStreaming();
      }
    }
  }

  void startStreaming() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) async {
      if (!_cameraController!.value.isStreamingImages) {
        await _cameraController!.startImageStream((CameraImage image) async {
          final width = image.planes[0].width ?? 0;
          final height = image.planes[0].height ?? 0;

          if (width == 0 || height == 0) return;

          final img = imglib.Image.fromBytes(
            width,
            height,
            image.planes[0].bytes,
            format: imglib.Format.bgra,
          );

          List<int> png = imglib.encodePng(img);
          Uint8List data = Uint8List.fromList(png);

          _channel.sink.add(base64Encode(data));
        });
      }
    });
  }

  void stopStreaming() {
    _timer?.cancel();
    _timer = null;
    _cameraController?.stopImageStream();
    isStreaming = false;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => BroadcastListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            if (isStreaming) {
              stopStreaming();
            } else {
              startStreaming();
            }
            setState(() {
              isStreaming = !isStreaming;
            });
          },
          child: Text(isStreaming ? '방송 종료' : '방송 시작'),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.switch_camera),
            onPressed: toggleCamera, // 카메라 전환 버튼
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 300, // 채팅 창의 높이 조정
              color: Colors.black54,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      '방송 규칙: 채팅 여러번 치기 금지, 다들 좋은 방방 관람 하세요 ~',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ChatMessage(message: '안녕하세요'),
                        ChatMessage(message: '좋아요!'),
                        ChatMessage(message: '방송 재밌네요!'),
                        ChatMessage(message: '다음 방송 언제인가요?'),
                        ChatMessage(message: '이 채팅 좋네요!'),
                      ],
                    ),
                  ),
                  Text(
                    '서버 메시지: $serverMessage',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilterButton(label: '필터 적용', imagePath: 'assets/img3.jpeg'),
                FilterButton(label: '필터 적용', imagePath: 'assets/img4.jpeg'),
                FilterButton(label: '필터 적용', imagePath: 'assets/img3.jpeg'),
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
    _channel.sink.close();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String message;

  ChatMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  final String label;
  final String imagePath;

  FilterButton({required this.label, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundImage: AssetImage(imagePath),
          radius: 20,
        ),
        SizedBox(height: 5),
        ElevatedButton(
          onPressed: () {
            // 필터 적용 로직 추가
          },
          child: Text(label),
        ),
      ],
    );
  }
}

class BroadcastListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Broadcast List'),
      ),
      body: Center(
        child: Text('Broadcast List Screen'),
      ),
    );
  }
}
