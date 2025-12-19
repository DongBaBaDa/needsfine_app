import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart'; // 네이버 지도 SDK import
import 'package:needsfine_app/core/needsfine_theme.dart';

import 'package:needsfine_app/screens/address_search_screen.dart';
import 'package:needsfine_app/screens/splash_screen.dart';
import 'package:needsfine_app/screens/initial_screen.dart';
import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/screens/location_screen.dart';
import 'package:needsfine_app/screens/notification_screen.dart';
import 'package:needsfine_app/screens/search_screen.dart';
import 'package:needsfine_app/screens/login_screen.dart';
import 'package:needsfine_app/screens/id_pw_find_screen.dart';
import 'package:needsfine_app/screens/join_select_screen.dart';
import 'package:needsfine_app/screens/store_join_screen.dart';
import 'package:needsfine_app/screens/user_join_screen.dart';
import 'package:needsfine_app/screens/user_mypage_screen.dart';
import 'package:needsfine_app/screens/store_mypage_screen.dart';
import 'package:needsfine_app/screens/sanctuary_screen.dart';
import 'package:needsfine_app/screens/ranking_screen.dart';
import 'package:needsfine_app/screens/store_detail_screen.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';
import 'package:needsfine_app/screens/nearby_screen.dart';
import 'package:needsfine_app/screens/my_taste_screen.dart';
import 'package:needsfine_app/screens/public_profile_screen.dart';

final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
final ValueNotifier<int> notificationCount = ValueNotifier(3);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 네이버 지도 SDK 초기화
  await NaverMapSdk.instance.initialize(
    clientId: 'peiu5pezpj', 
    onAuthFailed: (ex) {
      print("********* 네이버 지도 인증 실패 *********");
      print(ex);
    },
  );

  runApp(const MyApp(initialRoute: '/splash'));
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
        '/splash': (context) => const SplashScreen(),
        '/initial': (context) => const InitialScreen(),
        '/home': (context) => const MainShell(),
        '/location': (context) => const LocationScreen(),
        '/notification': (context) => const NotificationScreen(),
        '/notification-detail': (context) =>
            const NotificationDetailScreen(message: "알림 상세 내용"),
        '/search': (context) => const SearchScreen(),
        '/address-search': (context) => const AddressSearchScreen(),
        '/login': (context) => const LoginScreen(),
        '/find-account': (context) => const IDPWFindScreen(),
        '/join-select': (context) => const JoinSelectScreen(),
        '/join-store': (context) => const StoreJoinScreen(),
        '/join-user': (context) => const UserJoinScreen(),
        '/user-mypage': (context) => const UserMyPageScreen(),
        '/store-mypage': (context) => const StoreMyPageScreen(),
        '/sanctuary': (context) => const SanctuaryScreen(),
        '/menu': (context) => const RankingScreen(),
        '/store-detail': (context) => const StoreDetailScreen(),
        '/write-review': (context) => const WriteReviewScreen(),
        '/nearby': (context) => const NearbyScreen(),
        '/mytaste': (context) => const MyTasteScreen(),
        '/public-profile': (context) => PublicProfileScreen(),
      },
    );
  }
}

class NotificationDetailScreen extends StatelessWidget {
  final String message;
  const NotificationDetailScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("알림 상세")),
      body: Center(child: Text(message)),
    );
  }
}
