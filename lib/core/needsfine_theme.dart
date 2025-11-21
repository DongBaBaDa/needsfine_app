// lib/core/needsfine_theme.dart
import 'package:flutter/material.dart';

/// 니즈파인 대표 색 – 연한 보라 + 포인트 보라
const Color kNeedsFinePurple = Color(0xFF9C7CFF);      // 포인트
const Color kNeedsFinePurpleLight = Color(0xFFF0E9FF); // 배경용

ThemeData needsFineTheme = ThemeData(
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'NotoSansKR',
  colorScheme: ColorScheme.fromSeed(
    seedColor: kNeedsFinePurple,
    primary: kNeedsFinePurple,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
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