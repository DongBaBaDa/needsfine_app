import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/signup/user_join_screen.dart';
import 'package:needsfine_app/screens/splash_screen.dart';
import 'package:needsfine_app/screens/initial_screen.dart';
import 'package:needsfine_app/screens/email_pw_find_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/config/supabase_config.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ 저장 기능

// ✅ 다국어 자동 생성 패키지
import 'package:needsfine_app/l10n/app_localizations.dart';

// ✅ 화면 import
import 'package:needsfine_app/screens/notification_screen.dart';
import 'package:needsfine_app/screens/notice_detail_screen.dart';
import 'package:needsfine_app/screens/inquiry_detail_screen.dart';

// ✅ 앱 전체 언어 상태를 관리하는 전역 변수
final ValueNotifier<Locale?> appLocaleNotifier = ValueNotifier(null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 저장된 언어 불러오기 (SharedPreferences)
  try {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      appLocaleNotifier.value = Locale(languageCode);
    }
  } catch (e) {
    print("언어 설정 로드 실패: $e");
  }

  // 2. Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.anonKey,
  );

  // 3. 네이버 지도 SDK 초기화
  await FlutterNaverMap().init(
    clientId: 'xqcofdggzk',
    onAuthFailed: (ex) {
      print("********* 네이버 지도 인증 실패 *********\n$ex");
      switch (ex) {
        case NQuotaExceededException(:final message):
          print("사용량 초과 (message: $message)");
          break;
        case NUnauthorizedClientException() ||
        NClientUnspecifiedException() ||
        NAnotherAuthFailedException():
          print("인증 실패 상세: $ex");
          break;
      }
    },
  );

  // 4. 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: 'dda52349c32ed7bea5d08d184fe8a953');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ValueListenableBuilder로 감싸서 언어 변경 시 앱 전체 리빌드
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'NeedsFine',
          theme: needsFineTheme,
          debugShowCheckedModeBanner: false,

          // ✅ 다국어 설정 (AppLocalizations 사용)
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          // ✅ 전역 변수에 저장된 언어 적용 (null이면 기기 언어 따름)
          locale: locale,

          home: const SplashScreen(),

          routes: {
            '/initial': (context) => const InitialScreen(),
            '/home': (context) => const MainShell(),
            '/join': (context) => const UserJoinScreen(),
            '/find': (context) => const EmailPWFindScreen(),

            // ✅ NotificationScreen 연결
            '/notifications': (context) => const NotificationScreen(),

            // 상세 페이지 경로
            '/notice_detail': (context) => const NoticeDetailScreen(),
            '/inquiry_detail': (context) => const InquiryDetailScreen(),
          },
        );
      },
    );
  }
}