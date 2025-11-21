// lib/models/user_profile.dart
import 'package:flutter/material.dart';

class UserProfile {
  String? imagePath;      // 갤러리/카메라에서 받은 로컬 파일 경로
  String nickname;
  String? gender;         // "남" / "여" / null
  String? name;
  String? phone;
  String? phoneVerifiedCode;
  String? email;
  String? bio;            // 자기소개 (최대 50자)

  UserProfile({
    this.imagePath,
    this.nickname = "닉네임 미설정",
    this.gender,
    this.name,
    this.phone,
    this.phoneVerifiedCode,
    this.email,
    this.bio,
  });

  UserProfile copyWith({
  String? imagePath,
  String? nickname,
  String? gender,
  String? name,
  String?