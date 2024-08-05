import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'screens/home_screen.dart';
import 'package:path_provider/path_provider.dart'; // For getTemporaryDirectory

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화를 보장
  KakaoSdk.init(
      nativeAppKey: '06227f68ca3165e60c6c3f8941c6885f'); // 여기에 카카오 앱 키를 입력하세요

  // KakaoSdk.origin 값을 비동기적으로 가져와서 출력
  String kakaoOrigin = await KakaoSdk.origin;
  print(kakaoOrigin);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broadcast App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}
