import 'dart:math';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

List<String> extractReviewTags(String text) {
  final normalizedText = unorm.nfc(text);
  final tags = <Map<String, Object>>[];

  // 패턴 정의 (TS 코드 기반)
  const fatalPatterns = [
    {'word': '위생 상태 최악', 'pattern': r'(바퀴|벌레|파리|모기|머리카락|이물질|털)[\s\S]{0,50}(나왔|있|보였|다녀)'},
    {'word': '서비스 최악', 'pattern': r'(잡아|치워|그냥)[\s\S]{0,50}(달래|래|라니|라고|무시)'},
    // ... more patterns
  ];
  const infoPatterns = [
    {'word': '양이 적음', 'pattern': r'(양)[\s\S]{0,30}(적|작|창렬|부족)'},
    // ... more patterns
  ];
  // ... (featurePatterns, basicPatterns)

  fatalPatterns.forEach((p) {
    if (RegExp(p['pattern'] as String).hasMatch(normalizedText)) {
      tags.add({'word': p['word'] as String, 'priority': 0});
    }
  });
  infoPatterns.forEach((p) {
    if (RegExp(p['pattern'] as String).hasMatch(normalizedText)) {
      tags.add({'word': p['word'] as String, 'priority': 1});
    }
  });
  // ... (forEach for other patterns)
  
  final seen = <String>{};
  final uniqueTags = tags.where((item) => seen.add(item['word'] as String)).toList();
  uniqueTags.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

  return uniqueTags.take(3).map((t) => t['word'] as String).toList();
}

Map<String, dynamic> calculateNeedsFineScore(String reviewText, double userRating) {
  final normalizedText = unorm.nfc(reviewText).replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '').trim();
  final textLen = normalizedText.length;
  final safeRating = userRating;
  
  double qrScore = 0;
  final tags = extractReviewTags(normalizedText);
  final sincerityCount = RegExp(r'(n번째|재방문|또|단골|인생|최애|자주|맛있|최고|굿)').allMatches(normalizedText).length;
  final maliciousCount = RegExp(r'(쓰레기|개판|망해|최악|극혐|노맛)').allMatches(normalizedText).length;
  final fatalCount = RegExp(r'(바퀴|벌레|머리카락|상한|쉰|썩은)').allMatches(normalizedText).length;

  // 점수 계산 로직 (TS -> Dart 포팅)
  if (textLen < 15 && (safeRating <= 1.5 || safeRating >= 4.5)) {
    qrScore -= 2.0; // 의심스러운 짧은 리뷰
  } else if (textLen < 80) {
    qrScore += 2.0;
  } else {
    qrScore += 3.5;
  }
  qrScore += sincerityCount * 1.2;
  if (tags.isNotEmpty) qrScore += 1.5;
  if (fatalCount > 0) qrScore += 3.0;
  if (maliciousCount > 0 && fatalCount == 0) qrScore -= 2.0;

  final sigmoid = (double x) => 1 / (1 + exp(-0.6 * (x - 3.5)));
  double trustScore = sigmoid(qrScore);
  if (textLen < 10) trustScore = min(0.4, trustScore);
  trustScore = max(0.1, min(0.95, trustScore));
  final trustLevel = (trustScore * 100).round();

  double finalScore = safeRating;
  if (trustLevel < 50) {
    final anchor = safeRating < 3.0 ? 2.5 : 3.5;
    finalScore = (safeRating * trustScore) + (anchor * (1 - trustScore));
  }

  finalScore = max(1.0, min(5.0, finalScore));

  return {
    'needsfine_score': double.parse(finalScore.toStringAsFixed(1)),
    'trust_level': trustLevel,
    'tags': tags,
    'is_critical': (finalScore < 3.5 || fatalCount > 0) && trustLevel >= 50,
    'is_hidden': trustLevel < 25 || (maliciousCount > 0 && textLen < 20),
  };
}
