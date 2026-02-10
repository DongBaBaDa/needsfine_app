import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNoti = FlutterLocalNotificationsPlugin();
  // SupabaseClient는 initialize 시점에, 혹은 접근 시점에 가져옵니다.
  SupabaseClient get _supabase => Supabase.instance.client;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    // 0. 로그인 상태 변경 리스너 등록 (로그인 시 토큰 저장)
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null && data.event == AuthChangeEvent.signedIn) {
        _refreshAndSaveToken();
      }
    });

    // 1. 권한 요청
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('🔔 푸시 알림 권한 상태: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('🔔 푸시 알림 권한 승인됨');
    }

    // 2. 로컬 알림 초기화
    // ✅ 앱 아이콘으로 설정 (@mipmap/launcher_icon)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNoti.initialize(initSettings);

    // ✅ 안드로이드 알림 채널 생성 (Android 8.0+)
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNoti.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // name
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
        ),
      );
    }

    // 3. 포그라운드 메시지 핸들링
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('🔔 포그라운드 메시지 수신: ${message.notification?.title}');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNoti.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon', // ✅ 알림 아이콘 명시
            ),
          ),
        );
      }
    });

    // 4. 초기 토큰 저장 시도
    await _refreshAndSaveToken();

    // 5. 토큰 리프레시 리스너
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(newToken);
    });
  }

  Future<void> _refreshAndSaveToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      if (kDebugMode) print('❌ FCM 토큰 가져오기 실패: $e');
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    // 유저가 없으면 저장 불가 (나중에 로그인 시 저장됨)
    if (user == null) {
      if (kDebugMode) print('⚠️ 유저 로그아웃 상태라 토큰 저장 보류');
      return;
    }

    try {
      await _supabase.from('fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'device_type': Platform.isIOS ? 'ios' : 'android',
        'last_updated_at': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) print('🔔 FCM 토큰 저장 성공 (User: ${user.id})');
    } catch (e) {
      if (kDebugMode) print('❌ FCM 토큰 저장 실패: $e');
    }
  }
}