import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; 
import 'package:needsfine_app/core/needsfine_theme.dart';

import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/new_search_screen.dart'; // 새로운 검색 화면 import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NaverMapSdk.instance.initialize(
    clientId: '1rst5nv703', 
    onAuthFailed: (ex) => print("********* 네이버 지도 인증 실패 *********\n$ex"),
  );

  runApp(const MyApp(initialRoute: '/home'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeedsFine',
      theme: needsFineTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/home': (context) => const MainShell(),
        // [수정] /search 경로에 새로운 검색 화면 연결
        '/search': (context) => const NewSearchScreen(), 
      },
    );
  }
}
