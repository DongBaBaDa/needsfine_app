import 'dart:async';
import 'package:flutter/material.dart';

// 화면들 임포트
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
import 'package:needsfine_app/screens/sanctuary_screen.dart'; // 성지
import 'package:needsfine_app/screens/menu_screen.dart';      // 메뉴
import 'package:needsfine_app/screens/store_detail_screen.dart'; // [NEW] 가게 상세
import 'package:needsfine_app/screens/write_review_screen.dart'; // [NEW] 리뷰 작성
import 'package:needsfine_app/screens/nearby_screen.dart';     // 내 주변
import 'package:needsfine_app/screens/my_taste_screen.dart';   // 나의 입맛

final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
final ValueNotifier<int> notificationCount = ValueNotifier(3);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String initialRoute = '/splash'; // 개발용 시작 화면
  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeedsFine',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'NotoSansKR',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 1,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
        '/login': (context) => const LoginScreen(),
        '/find-account': (context) => const IDPWFindScreen(),
        '/join-select': (context) => const JoinSelectScreen(),
        '/join-store': (context) => const StoreJoinScreen(),
        '/join-user': (context) => const UserJoinScreen(),
        '/user-mypage': (context) => const UserMyPageScreen(),
        '/store-mypage': (context) => const StoreMyPageScreen(),
        '/sanctuary': (context) => const SanctuaryScreen(),
        '/menu': (context) => const MenuScreen(),
        '/store-detail': (context) => const StoreDetailScreen(),
        '/write-review': (context) => const WriteReviewScreen(),
        '/nearby': (context) => const NearbyScreen(),
        '/mytaste': (context) => const MyTasteScreen(),
      },
    );
  }
}