import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/main_shell.dart';
// ▼▼▼ 경로 수정됨 (screens/signup/user_join_screen.dart) ▼▼▼
import 'package:needsfine_app/screens/signup/user_join_screen.dart';
import 'package:needsfine_app/screens/splash_screen.dart';
import 'package:needsfine_app/screens/initial_screen.dart';
import 'package:needsfine_app/screens/email_pw_find_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/config/supabase_config.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // ✅ 카카오 SDK 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.anonKey,
  );

  // 2. 네이버 지도 SDK 초기화
  await NaverMapSdk.instance.initialize(
    clientId: '1rst5nv703',
    onAuthFailed: (ex) {
      print("********* 네이버 지도 인증 실패 *********\n$ex");
    },
  );

  // ✅ 3. 카카오 SDK 초기화 (네이티브 앱 키 적용)
  KakaoSdk.init(nativeAppKey: 'dda52349c32ed7bea5d08d184fe8a953');

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

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
      ],
      locale: const Locale('ko', 'KR'),

      home: const SplashScreen(),

      routes: {
        '/initial': (context) => const InitialScreen(),
        '/home': (context) => const MainShell(),
        '/join': (context) => const UserJoinScreen(),
        '/find': (context) => const EmailPWFindScreen(),
      },
    );
  }
}