import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/new_search_screen.dart';
import 'package:needsfine_app/screens/splash_screen.dart';
import 'package:needsfine_app/screens/initial_screen.dart'; // [추가]
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.anonKey,
  );

  await NaverMapSdk.instance.initialize(
    clientId: '1rst5nv703',
    onAuthFailed: (ex) => print("********* 네이버 지도 인증 실패 *********\n$ex"),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeedsFine',
      theme: needsFineTheme,
      debugShowCheckedModeBanner: false,
      // [수정] SplashScreen을 첫 화면으로 명시
      home: const SplashScreen(),
      routes: {
        // [수정] 라우팅 테이블에 initial_screen 추가
        '/initial': (context) => const InitialScreen(), 
        '/home': (context) => const MainShell(),
        '/search': (context) => const NewSearchScreen(),
      },
    );
  }
}
