// lib/core/profanity_filter.dart

class ProfanityFilter {
  // 🚨 여기에 필터링할 단어들을 추가하세요.
  // 심사를 위해서는 주요 욕설, 비하 발언 등을 포함해야 합니다.
  static final List<String> _badWords = [
    '시발', '씨발', '개새끼', '병신', '지랄', '좇', '좆',
    '섹스', 'sex', 'fuck', 'shit', 'bitch',
    '미친', '새끼', '놈', '년',
    '살인', '자살',
    // ... 필요한 만큼 추가하세요
  ];

  /// 비속어가 포함되어 있는지 확인하는 함수
  /// true를 반환하면 비속어가 포함된 것임
  static bool hasProfanity(String text) {
    if (text.isEmpty) return false;

    // 1. 공백과 특수문자를 제거하여 '시 발', '시.발' 같은 우회 시도 차단
    String normalizedText = text.replaceAll(RegExp(r'\s+'), '') // 공백 제거
        .replaceAll(RegExp(r'[!@#$%^&*(),.?":{}|<>]'), ''); // 특수문자 제거

    for (var word in _badWords) {
      // 2. 원래 텍스트에 포함되어 있거나
      if (text.contains(word)) return true;
      // 3. 공백/특수문자 제거된 버전에 포함되어 있는지 확인
      if (normalizedText.contains(word)) return true;
    }

    return false;
  }

  /// 비속어를 마스킹(*표시) 처리하는 함수 (필요시 사용)
  static String maskProfanity(String text) {
    String cleanText = text;
    for (var word in _badWords) {
      if (cleanText.contains(word)) {
        cleanText = cleanText.replaceAll(word, '*' * word.length);
      }
    }
    return cleanText;
  }
}