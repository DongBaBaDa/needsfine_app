import 'dart:math';

// 서버의 analyzeContextualSentiment 로직을 Dart로 변환
int analyzeContextualSentiment(String text) {
  int score = 0;
  final sentences = text.split(RegExp(r'[.|!|?|\n]'));

  for (var sentence in sentences) {
    final cleanSentence = sentence.trim();
    if (cleanSentence.isEmpty) continue;

    const positiveRoots = [
      '맛있', '좋', '굳', '굿', '최고', '친절', '추천', '신선', '깔끔', '예쁘', '이쁘', '빠르', '넉넉', '푸짐'
    ];
    const negativeRoots = [
      '별로', '나쁘', '최악', '실망', '아쉽', '질기', '비리', '짜', '불친절', '더럽', '오래', '느리'
    ];
    final negatorPattern = RegExp(r'(안|못|않|없|아니)');

    int sentenceScore = 0;

    for (var root in positiveRoots) {
      if (cleanSentence.contains(root)) {
        final index = cleanSentence.indexOf(root);
        final prefix = cleanSentence.substring(max(0, index - 10), index);

        if (negatorPattern.hasMatch(prefix)) {
          sentenceScore -= 1;
        } else {
          sentenceScore += 1;
        }
      }
    }

    for (var root in negativeRoots) {
      if (cleanSentence.contains(root)) {
        sentenceScore -= 1;
      }
    }

    score += sentenceScore;
  }

  return score;
}

// 서버의 calculateNeedsFineScore 로직을 Dart로 변환
Map<String, dynamic> calculateNeedsFineScore(String reviewText, double userRating) {
  double qrScore = 0;
  final textLen = reviewText.trim().length;

  if (textLen < 20) {
    qrScore += 0.1;
  } else if (textLen < 50) {
    qrScore += 0.5;
  } else if (textLen <= 150) {
    qrScore += 1.5;
  } else {
    qrScore += 1.2;
  }

  const basicWords = ['맛있', '좋았', '추천', '만족', '괜찮', '훌륭', '최고'];
  const sensoryWords = [
    '쫄깃', '칼칼', '간이', '짭짤', '싱겁', '육즙', '바삭', '촉촉', '부드러', '질기',
    '비린', '잡내', '향', '식감', '냄새', '양념', '소스', '국물', '푸짐', '신선'
  ];
  const infoWords = ['예약', '웨이팅', '대기', '주차', '발렛', '포장', '화장실', '위치', '꿀팁', '방문'];

  final mentionedBasic = basicWords.where((word) => reviewText.contains(word)).length;
  final mentionedSensory = sensoryWords.where((word) => reviewText.contains(word)).length;
  final mentionedInfo = infoWords.where((word) => reviewText.contains(word)).length;

  qrScore += (0.2 * min(mentionedBasic, 3));
  qrScore += (0.5 * mentionedSensory);
  qrScore += (0.8 * min(mentionedInfo, 2));

  final sentimentScore = analyzeContextualSentiment(reviewText);
  if (sentimentScore > 2) {
    qrScore += 0.5;
  }
  if (sentimentScore < -1) {
    qrScore -= 0.5;
  }

  if (RegExp(r'(.)\1{3,}').hasMatch(reviewText) || RegExp(r'([!?.])\1{3,}').hasMatch(reviewText)) {
    qrScore *= 0.5;
  }

  final fReviewQuality = log(1 + qrScore);
  final fReviewQualityNorm = min(1, fReviewQuality / 3.0);

  const baseTrust = 0.6;
  const qualityWeight = 0.4;
  final trustScore = baseTrust + (fReviewQualityNorm * qualityWeight);
  final trustLevel = (trustScore * 100).round();

  final finalScore = double.parse((userRating * trustScore).toStringAsFixed(1));

  final authenticity = textLen >= 40 && (mentionedSensory > 0 || mentionedInfo > 0);
  const advertisingPattern = '(최고|완전|대박|꼭|무조건|강추)';
  const neutralWords = ['조금', '살짝', '편이', '아쉬', '비싸', '대신'];
  final hasNeutral = neutralWords.any((word) => reviewText.contains(word));
  final advertisingWords = !hasNeutral && RegExp(advertisingPattern).hasMatch(reviewText) && mentionedSensory == 0;
  final emotionalBalance = mentionedSensory > 0;

  return {
    'needsfine_score': finalScore,
    'trust_level': trustLevel,
    'authenticity': authenticity,
    'advertising_words': advertisingWords,
    'emotional_balance': emotionalBalance
  };
}
