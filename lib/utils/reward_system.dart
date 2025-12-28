// lib/utils/reward_system.dart

enum BetaLevel { bronze, silver, gold, platinum }

class BetaTesterStats {
  final String userId;
  BetaLevel level;
  int points;
  final int reviewCount;
  final int feedbackCount;
  final int usefulFeedbackCount;
  final double avgTrustLevel;
  List<String> badges;
  final String joinedAt;

  BetaTesterStats({
    required this.userId,
    this.level = BetaLevel.bronze,
    this.points = 0,
    required this.reviewCount,
    required this.feedbackCount,
    required this.usefulFeedbackCount,
    required this.avgTrustLevel,
    required this.badges,
    required this.joinedAt,
  });
}

// 레벨 계산 로직
BetaLevel calculateBetaLevel(int points) {
  if (points >= 1000) return BetaLevel.platinum;
  if (points >= 500) return BetaLevel.gold;
  if (points >= 200) return BetaLevel.silver;
  return BetaLevel.bronze;
}

// 포인트 계산
int calculatePoints({
  required int reviewCount,
  required int feedbackCount,
  required int usefulFeedbackCount,
  required double avgTrustLevel,
}) {
  int points = 0;
  
  // 리뷰 작성: 신뢰도 기반 차등 지급 (신뢰도 10당 1점 * 리뷰수?) 
  // 원본: reviewCount * Math.ceil(stats.avgTrustLevel / 10);
  points += reviewCount * (avgTrustLevel / 10).ceil();
  
  // 피드백 작성: 10P
  points += feedbackCount * 10;
  
  // 유용한 피드백: 50P
  points += usefulFeedbackCount * 50;
  
  return points;
}

// 뱃지 획득 조건
List<String> calculateBadges(BetaTesterStats stats) {
  final badges = <String>[];
  
  if (stats.reviewCount >= 1) badges.add('🎉 첫 리뷰 작성');
  if (stats.reviewCount >= 10) badges.add('✍️ 리뷰 마스터');
  if (stats.reviewCount >= 50) badges.add('👑 리뷰 왕');
  
  if (stats.feedbackCount >= 5) badges.add('💬 피드백 초보');
  if (stats.feedbackCount >= 20) badges.add('🔥 피드백 마스터');
  
  if (stats.avgTrustLevel >= 80) badges.add('⭐ 신뢰도 왕');
  if (stats.avgTrustLevel >= 90) badges.add('💎 완벽주의자');
  
  if (stats.usefulFeedbackCount >= 5) badges.add('🎯 핵심 피드백');
  
  return badges;
}

// 정식 출시 시 혜택
List<String> getRewards(BetaLevel level) {
  switch (level) {
    case BetaLevel.bronze:
      return [
        '🎁 정식 출시 기념 1,000원 할인 쿠폰',
        '📱 앱 광고 제거 1개월'
      ];
    case BetaLevel.silver:
      return [
        '🎁 정식 출시 기념 3,000원 할인 쿠폰',
        '📱 앱 광고 제거 3개월',
        '🏅 실버 뱃지 영구 지급'
      ];
    case BetaLevel.gold:
      return [
        '🎁 정식 출시 기념 5,000원 할인 쿠폰',
        '📱 앱 광고 영구 제거',
        '🏅 골드 뱃지 영구 지급',
        '🎤 베타 테스터 인터뷰 참여 기회'
      ];
    case BetaLevel.platinum:
      return [
        '🎁 정식 출시 기념 10,000원 할인 쿠폰',
        '📱 앱 프리미엄 평생 무료',
        '🏅 플래티넘 뱃지 + 특별 칭호',
        '🎤 베타 테스터 홀 오브 페임 등재',
        '💼 니즈파인 앰배서더 우선 선발'
      ];
  }
}

// 레벨별 설정 (색상, 이름 등)
Map<String, dynamic> getLevelConfig(BetaLevel level) {
  switch (level) {
    case BetaLevel.bronze:
      return {'color': 0xFFCD7F32, 'emoji': '🥉', 'name': '브론즈'};
    case BetaLevel.silver:
      return {'color': 0xFFC0C0C0, 'emoji': '🥈', 'name': '실버'};
    case BetaLevel.gold:
      return {'color': 0xFFFFD700, 'emoji': '🥇', 'name': '골드'};
    case BetaLevel.platinum:
      return {'color': 0xFFE5E4E2, 'emoji': '💎', 'name': '플래티넘'};
  }
}
