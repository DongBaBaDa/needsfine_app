import 'dart:async';
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
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase
import 'package:needsfine_app/services/notification_service.dart'; // ✅ 푸시 알림
import 'package:app_links/app_links.dart'; // ✅ App Links (딥링크 처리)

// ✅ 다국어 자동 생성 패키지
import 'package:needsfine_app/l10n/app_localizations.dart';

// ✅ 화면 import
import 'package:needsfine_app/screens/notification_screen.dart';
import 'package:needsfine_app/screens/notice_detail_screen.dart';
import 'package:needsfine_app/screens/inquiry_detail_screen.dart';
import 'package:needsfine_app/screens/shared_list_screen.dart'; // ✅ 공유 리스트 읽기 전용 화면

// ✅ 앱 전체 언어 상태를 관리하는 전역 변수
final ValueNotifier<Locale?> appLocaleNotifier = ValueNotifier(null);

// ✅ 딥링크 처리를 위한 글로벌 네비게이터 키
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Firebase 초기화
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase 초기화 실패: $e");
  }

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

  // 2-1. 푸시 알림 서비스 초기화 (Supabase 초기화 후)
  try {
    NotificationService().initialize();
  } catch (e) {
    print("NotificationService 초기화 실패: $e");
  }

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // ✅ 앱이 꺼진 상태에서 링크로 열렸을 때 (초기 딥링크)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial uri: $e");
    }

    // ✅ 앱이 실행 중이거나 백그라운드에 있을 때 링크 클릭 방지
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("Deep link stream error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("🔗 딥링크 감지: $uri");
    String? listId;

    // 1. 커스텀 스킴: needsfine://list/리스트ID
    if (uri.scheme == 'needsfine' && uri.host == 'list') {
      listId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }
    // 2. 유니버셜/앱 링크: https://needsfine.com/list?id=리스트ID
    else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.contains('needsfine.com') &&
        uri.path == '/list') {
      listId = uri.queryParameters['id'];
    }

    if (listId != null && listId.isNotEmpty && navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => SharedListScreen(listId: listId!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ValueListenableBuilder로 감싸서 언어 변경 시 앱 전체 리빌드
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // ✅ 전역 네비게이터 키 설정
          title: 'NeedsFine',
          theme: needsFineTheme,
          debugShowCheckedModeBanner: false,

          // ✅ 다국어 설정 (AppLocalizations 사용)
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,

          // ✅ 전역 변수에 저장된 언어 적용 (null이면 기기 언어 따름)
          locale: locale,
          
          // ✅ 아랍어 등 RTL 언어에서도 UI 반전 방지 (강제 LTR)
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: child!,
            );
          },

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