import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/new_search_screen.dart';
import 'package:needsfine_app/screens/splash_screen.dart'; // 스플래시 스크린 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NaverMapSdk.instance.initialize(
    clientId: '1rst5nv703',
    onAuthFailed: (ex) => print("********* 네이버 지도 인증 실패 *********\n$ex"),
  );

  runApp(const MyApp()); // MyApp 직접 실행
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeedsFine',
      theme: needsFineTheme,
      debugShowCheckedModeBanner: false,
      // [수정] home 속성을 사용하여 SplashScreen을 첫 화면으로 지정
      home: const SplashScreen(), 
      routes: {
        // routes에 있던 initialRoute 관련 로직 제거
        '/home': (context) => const MainShell(),
        '/search': (context) => const NewSearchScreen(),
      },
    );
  }
}
