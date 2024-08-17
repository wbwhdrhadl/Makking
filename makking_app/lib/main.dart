import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'screens/home_screen.dart';
import 'package:path_provider/path_provider.dart'; // For getTemporaryDirectory
import 'screens/login.dart'; // LoginScreen 임포트
import 'screens/broadcast_list_screen.dart';
import 'screens/register_screen.dart'; // LoginScreen 임포트
import 'screens/broadcast_start_screen.dart'; // LoginScreen 임포트
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv 패키지 임포트
import 'package:path_provider/path_provider.dart'; // For getTemporaryDirectory

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(
      nativeAppKey: '06227f68ca3165e60c6c3f8941c6885f'); // 여기에 카카오 앱 키를 입력하세요

  const serverIp = '172.30.1.44'; // 여기에서 직접 서버 IP 설정
  // KakaoSdk.origin 값을 비동기적으로 가져와서 출력
  String kakaoOrigin = await KakaoSdk.origin;
  print(kakaoOrigin);

  runApp(MyApp(serverIp: serverIp));
}

class MyApp extends StatelessWidget {
  final String serverIp;
  MyApp({required this.serverIp});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Broadcast App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(serverIp: serverIp),
    );
  }
}
