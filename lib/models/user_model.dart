class UserProfile {
  String nickname;
  String title;
  int level;
  double currentExp; // 현재 경험치 (예: 50)
  double maxExp;     // 다음 레벨까지 필요한 경험치 (예: 100)
  String introduction;
  int influence;
  int points;
  String? profileImagePath;

  UserProfile({
    required this.nickname,
    required this.title,
    required this.level,
    required this.currentExp,
    required this.maxExp,
    required this.introduction,
    required this.influence,
    required this.points,
    this.profileImagePath,
  });

  // 경험치 퍼센트 계산 (0.0 ~ 1.0)
  double get expPercent => (currentExp / maxExp).clamp(0.0, 1.0);

  // 레벨업 가능 여부 확인
  bool get canLevelUp => currentExp >= maxExp;
}