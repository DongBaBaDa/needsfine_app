import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/user_join_screen.dart';
import 'package:needsfine_app/screens/splash_screen.dart';
import 'package:needsfine_app/screens/initial_screen.dart';
import 'package:needsfine_app/screens/email_pw_find_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/config/supabase_config.dart';

// [요청 반영] 지도 초기화
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.anonKey,
  );

  // 2. 네이버 지도 SDK 초기화 (Client ID 적용, 버전 가이드 반영)
  await NaverMapSdk.instance.initialize(
    clientId: '1rst5nv703',
    onAuthFailed: (ex) {
      print("********* 네이버 지도 인증 실패 *********\n$ex");
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 서울시청 좌표 (37.5666, 126.979)
    const seoulCityHall = NLatLng(37.5666, 126.979);
    final safeAreaPadding = MediaQuery.paddingOf(context);

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

      // [요청 반영] 네이버 지도 예제 (서울시청 마커 표시)
      home: Scaffold(
        body: NaverMap(
          options: NaverMapViewOptions(
            contentPadding: safeAreaPadding, // SafeArea 고려
            initialCameraPosition: const NCameraPosition(target: seoulCityHall, zoom: 14),
          ),
          onMapReady: (controller) {
            final marker = NMarker(
              id: "city_hall", // Required
              position: seoulCityHall, // Required
              caption: const NOverlayCaption(text: "서울시청"), // Optional
            );
            controller.addOverlay(marker); // 지도에 마커를 추가
            print("naver map is ready!");
          },
        ),
      ),
      
      routes: {
        '/initial': (context) => const InitialScreen(),
        '/home': (context) => const MainShell(),
        '/join': (context) => const UserJoinScreen(),
        '/find': (context) => const EmailPWFindScreen(),
      },
    );
  }
}