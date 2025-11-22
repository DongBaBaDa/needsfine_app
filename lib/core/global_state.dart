import 'package:flutter/material.dart';

/// 순환 참조를 방지하기 위해 앱의 전역 상태 변수를 분리합니다.
final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
final ValueNotifier<int> notificationCount = ValueNotifier(3);
