// lib/services/score_calculator.dart
import 'dart:math';

class ScoreCalculator {
  
  // 🏷️ 태그 추출 (logic.ts의 extractReviewTags 이식)
  static List<String> extractReviewTags(String text) {
    final normalizedText = text.trim();
    final List<({String word, int priority})> tags = [];

    // Fatal Patterns (치명적 문제)
    final fatalPatterns = {
      '위생 상태 최악': RegExp(r'(바퀴|벌레|파리|모기|머리카락|이물질|털).*(나왔|있|보였|다녀)'),
      '서비스 최악': RegExp(r'(잡아|치워|그냥).*(달래|래|라니|라고|무시)'),
      '응대 불량': RegExp(r'(욕|반말|싸우|시비|소리).*(하|했|듣|지르)'),
      '식중독 주의': RegExp(r'(상한|쉰|썩은|비린|비릿).*(맛|냄새)'),
    };

    // Info Patterns (정보성 태그)
    final infoPatterns = {
      '공기밥 적음': RegExp(r'(공기밥|밥|양).*(적|작|모자|부족|아쉽)'),
      '양이 적음': RegExp(r'(양).*(적|작|창렬|부족)'),
      '웨이팅 주의': RegExp(r'(웨이팅|대기|줄).*(길|많|심해|헬|필수)'),
      '가성비 아쉽': RegExp(r'(가격|비싸|가성비).*(별로|나쁘|안좋|사악)'),
      '직원 응대 아쉽': RegExp(r'(직원|알바|서빙|이모|아줌마|종업원).*(불친절|느리|실수|반말|무시|치우|뺏)'),
      '주차 불편': RegExp(r'(주차|차).*(힘들|없|불편|헬)'),
      '화장실 불편': RegExp(r'(화장실).*(더럽|좁|멀|별로)'),
      '시끄러움': RegExp(r'(시끄|소란|정신없|시장통)'),
      '재방문 의사 없음': RegExp(r'(재방문|다시|또|굳이).*(안|못|없|않|모르)'),
      '메뉴 아쉬움': RegExp(r'(메뉴|선택|시키|주문).*(실패|잘못|아쉽|후회|미스)'),
    };

    // Feature Patterns (특징 태그)
    final featurePatterns = {
      '뷰 좋음': RegExp(r'(뷰|전망|경치)\s*(가|이|는|도)?\s*(좋|예쁘|끝내|최고|맛집)'),
      '혼밥 가능': RegExp(r'(혼밥|혼자).*(가능|좋|편해)'),
      '양이 많음': RegExp(r'(양).*(많|푸짐|넉넉|배터)'),
      '가성비 좋음': RegExp(r'(가성비|가격).*(좋|착해|저렴|합리)'),
      '친절함': RegExp(r'(친절|상냥|매너|서비스)'),
      '재료 신선': RegExp(r'(신선|재료|채소|해산물).*(좋|싱싱)'),
      '국물 진국': RegExp(r'(국물|육수).*(진국|깊|진하|끝내)'),
      '데이트 추천': RegExp(r'(데이트|소개팅|분위기|기념일|커플)'),
      '고기 맛집': RegExp(r'(고기|갈비|삼겹|육즙).*(좋|맛있|부드|살살)'),
      '키오스크 없음': RegExp(r'(키오스크|주문).*(없|안|직원)'),
    };

    // Basic Patterns (기본 태그)
    final basicPatterns = {
      '맛있음': RegExp(r'(맛있|존맛|꿀맛|별미|굿)'),
      '분위기 좋음': RegExp(r'(분위기).*(좋|깡패|예쁘|감성|레트로)'),
      '깨끗함': RegExp(r'(깨끗|청결|깔끔)'),
      '맛 평범/쏘쏘': RegExp(r'(맛|음식|간|반응).*(평범|쏘쏘|무난|그저|보통|애매|특별함.*없)'),
    };

    // 패턴 매칭
    fatalPatterns.forEach((word, pattern) {
      if (pattern.hasMatch(normalizedText)) {
        tags.add((word: word, priority: 0));
      }
    });

    infoPatterns.forEach((word, pattern) {
      if (pattern.hasMatch(normalizedText)) {
        tags.add((word: word, priority: 1));
      }
    });

    featurePatterns.forEach((word, pattern) {
      if (pattern.hasMatch(normalizedText)) {
        tags.add((word: word, priority: 2));
      }
    });

    basicPatterns.forEach((word, pattern) {
      if (pattern.hasMatch(normalizedText)) {
        tags.add((word: word, priority: 3));
      }
    });

    // 중복 제거 및 우선순위 정렬
    // Set을 사용하여 중복 제거 (word 기준)
    final uniqueWords = <String>{};
    final uniqueTags = <({String word, int priority})>[];
    
    for (var tag in tags) {
      if (uniqueWords.add(tag.word)) {
        uniqueTags.add(tag);
      }
    }

    uniqueTags.sort((a, b) => a.priority.compareTo(b.priority));

    // 상위 3개만 반환
    return uniqueTags.take(3).map((t) => t.word).toList();
  }

  // 📊 니즈파인 점수 계산 (logic.ts의 calculateNeedsFineScore 이식)
  static Map<String, dynamic> calculateNeedsFineScore(
    String reviewText,
    double userRating,
    bool hasPhoto,
  ) {
    final safeText = reviewText.trim();
    final safeRating = userRating.clamp(0.5, 5.0);
    final textLen = safeText.length;

    double qrScore = 0;

    // 태그 추출
    final tags = extractReviewTags(safeText);
    final hasInfoTag = tags.any((t) => 
      RegExp(r'(적음|아쉽|불편|주의|치우|시끄|없음|평범|쏘쏘)').hasMatch(t)
    );

    // Fatal 패턴 카운트
    final fatalPatterns = [
      RegExp(r'(바퀴|벌레|파리|모기|머리카락|이물질|털).{0,50}(나왔|있|보였|다녀)'),
      RegExp(r'(잡아|치워).{0,30}(달래|래|라니|라고)'),
      RegExp(r'(욕|반말|싸우|시비).{0,30}(하|했|듣)'),
      RegExp(r'(상한|쉰|썩은|비린|비릿).{0,30}(맛|냄새)'),
    ];
    int fatalCount = fatalPatterns.where((p) => p.hasMatch(safeText)).length;

    // Malicious 패턴 카운트
    final maliciousPatterns = [
      RegExp(r'(쓰레기|개판|망해|최악|극혐|폐업|기분.*잡쳐|더러워|미친)'),
      RegExp(r'(노맛|존노|퉤)'),
      RegExp(r'(니|너|새끼).{0,20}(들|가)'),
    ];
    int maliciousCount = maliciousPatterns.where((p) => p.hasMatch(safeText)).length;

    // Sincerity 패턴 카운트
    final sincerityPatterns = [
      RegExp(r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러)'),
      RegExp(r'(일주|한달|매주).{0,20}(번|회)'),
      RegExp(r'(처음|첫).{0,20}(방문|와보|먹어)'),
      RegExp(r'(메뉴|음식|반찬|국물).{0,50}(설명|나오|구워|주시|쫄깃)'),
      RegExp(r'(맛있|최고|굿|짱|존맛|좋았)'),
      RegExp(r'(물컹|비린|딱딱|질긴|불은|불어|차가운|식은).{0,30}(식감|느낌|상태|면|튀김)'),
    ];
    int sincerityCount = sincerityPatterns.where((p) => p.hasMatch(safeText)).length;

    // 신뢰도 기초 점수 계산
    final isShortAndHigh = textLen < 20 && safeRating >= 4.0;

    if (textLen < 30) {
      qrScore += isShortAndHigh ? -1.5 : (sincerityCount > 0 ? 1.0 : 0.5);
    } else if (textLen < 80) {
      qrScore += 2.0;
    } else {
      qrScore += 3.5;
    }

    qrScore += sincerityCount * 1.2;
    if (hasInfoTag) qrScore += 1.5;

    // 치명적 이슈 가중치
    if (fatalCount > 0) qrScore += 3.0 + (sincerityCount * 0.5);
    if (maliciousCount > 0 && fatalCount == 0 && textLen < 150) {
      qrScore -= 2.0;
    }

    // 신뢰도 계산 (Sigmoid)
    double sigmoid(double x) => 1 / (1 + exp(-0.6 * (x - 3.5)));
    double trustScore = sigmoid(qrScore);

    // 📸 사진 유무에 따른 신뢰도 보정
    if (hasPhoto) {
      trustScore = (trustScore + 0.15).clamp(0.0, 0.99);
    } else {
      trustScore = trustScore.clamp(0.0, 0.85);
    }

    // 짧은 글 락
    if (textLen < 20 && !hasPhoto) {
      trustScore = trustScore.clamp(0.0, 0.35);
    }

    trustScore = trustScore.clamp(0.1, 1.0);
    final trustLevel = (trustScore * 100).round();

    // 최종 점수 계산
    double finalScore = safeRating;
    final isLazyReview = textLen < 20 && sincerityCount == 0 && !hasPhoto;

    if (trustLevel >= 60) {
      if (fatalCount > 0) {
        finalScore = (safeRating * 0.6) + (1.0 * 0.4);
      } else {
        finalScore = safeRating;
      }
    } else {
      if (maliciousCount > 0) {
        finalScore = (safeRating * 0.5) + (1.5 * 0.5);
      } else {
        double anchor = isLazyReview ? 3.0 : (safeRating >= 3.0 ? 3.5 : 2.5);
        finalScore = (safeRating * trustScore) + (anchor * (1 - trustScore));
      }
    }

    // 내용 기반 차감
    if (hasInfoTag && finalScore >= 4.0) {
      finalScore -= 0.3;
    }

    // 감정-별점 불일치 보정
    if (fatalCount > 0 && finalScore >= 3.0) {
      finalScore = (finalScore * 0.5).clamp(0.0, 1.5);
    }

    final hasNegativeContent = hasInfoTag || 
                               maliciousCount > 0 || 
                               RegExp(r'(별로|실망|그닥|아쉽|최악)').hasMatch(safeText);
    if (hasNegativeContent && finalScore >= 3.5) {
      finalScore -= 0.5;
    }

    // 범위 보정
    finalScore = finalScore.clamp(1.0, 5.0);

    // 메타데이터
    final authenticity = trustLevel >= 70;
    final advertisingPattern = RegExp(r'(최고|완전|대박|꼭|무조건|강추)');
    final advertisingWords = sincerityCount == 0 && advertisingPattern.hasMatch(safeText);

    return {
      'needsfine_score': double.parse(finalScore.toStringAsFixed(1)),
      'trust_level': trustLevel,
      'authenticity': authenticity,
      'advertising_words': !advertisingWords, // 반전 (자연스러움)
      'emotional_balance': !hasNegativeContent, // 감정 균형
      'tags': tags,
    };
  }
}
