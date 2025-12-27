// lib/core/needsfine_theme.dart
import 'package:flutter/material.dart';

/// 니즈파인 대표 색 – 따뜻한 보라 + 포인트 보라
const Color kNeedsFinePurple = Color(0xFFC87CFF);      // 포인트 (더 따뜻한 톤으로 변경)
const Color kNeedsFinePurpleLight = Color(0xFFF6E4FF); // 배경용 (따뜻한 연보라)

ThemeData needsFineTheme = ThemeData(
  scaffoldBackgroundColor: const Color(0xFFFFFDF9), // 따뜻한 미색 배경
  fontFamily: 'NotoSansKR',
  colorScheme: ColorScheme.fromSeed(
    seedColor: kNeedsFinePurple,
    primary: kNeedsFinePurple,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFFFDF9),
    elevation: 0.5,
    iconTheme: IconThemeData(color: Colors.black87),
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kNeedsFinePurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStatePropertyAll(kNeedsFinePurple),
  ),
);
