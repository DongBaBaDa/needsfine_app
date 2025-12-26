import 'dart:io';

class UserProfile {
  String nickname;
  String introduction;
  String activityZone;
  String profileImageUrl; // 서버에 저장된 URL
  File? imageFile;       // 로컬에서 선택한 파일
  int reliability;
  int followerCount;
  int followingCount;
  List<String> snsLinks;
  List<String> tastes;
  DateTime? birthDate;

  UserProfile({
    required this.nickname,
    this.introduction = '',
    this.activityZone = '',
    this.profileImageUrl = '',
    this.imageFile,
    required this.reliability,
    required this.followerCount,
    required this.followingCount,
    this.snsLinks = const [],
    this.tastes = const [],
    this.birthDate,
  });
}
