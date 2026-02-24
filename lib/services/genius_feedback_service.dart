
import 'package:needsfine_app/models/ranking_models.dart';

class GeniusFeedback {
  final String message;

  GeniusFeedback({
    required this.message,
  });
}

class GeniusFeedbackService {
  // ------------------------------------------------------------------------
  // 1. Regex Patterns (우선순위: 맛 > 위생 > 서비스 > 분위기 > 환경)
  // ------------------------------------------------------------------------

  // [1순위] 맛 - 맛 묘사, 식감, 향
  static final _tastePatterns = RegExp(r'(맛있|맛없|존맛|꿀맛|별미|굿|진국|깊|진하|끝내|신선|재료|채소|해산물|싱싱|고기|육즙|부드|살살|쫄깃|바삭|아삭|탱글|꾸덕|촉촉|질기|퍽퍽|시원|얼큰|불맛|감칠맛|달달|매콤|칼칼|개운|향|풍미|담백|고소|소스|면|국물|음식|메뉴|식감)');

  // [2순위] 위생 - 청결, 위생 상태
  static final _hygienePatterns = RegExp(r'(위생|청결|깨끗|깔끔|더럽|이물질|벌레|곰팡|오염|악취|식중독)');

  // [3순위] 서비스 - 직원 응대, 태도
  static final _servicePatterns = RegExp(r'(친절|불친절|서비스|사장|직원|알바|응대|태도|무례|퉁명|불쾌|성의|배려)');

  // [4순위] 분위기 - 인테리어, 공간감
  static final _ambiencePatterns = RegExp(r'(분위기|인테리어|매장|공간|좌석|테이블|조명|음악|뷰|전망|감성|아늑|쾌적|소음|조용)');

  // [5순위] 환경 - 주차, 환기, 편의시설
  static final _environmentPatterns = RegExp(r'(주차|발렛|환기|연기|냄새\s*배|좁|넓|불편|화장실|키오스크|태블릿|아기의자|룸|웨이팅|대기)');

  // ------------------------------------------------------------------------
  // 2. Feedback Generation (우선순위: 맛 > 위생 > 서비스 > 분위기 > 환경)
  // ------------------------------------------------------------------------

  static GeniusFeedback generateFeedback(String text, double rating, List<String> tags) {
    if (text.length < 10) {
      return GeniusFeedback(
        message: "최소 10자 이상 작성해주세요.",
      );
    }

    // 배달/포장 여부 체크
    bool isDeliveryOrTakeout = tags.any((t) =>
        t.contains('배달') || t.contains('포장') ||
        t.toLowerCase().contains('delivery') || t.toLowerCase().contains('takeout'));

    // 각 카테고리 분석
    bool hasTaste = _tastePatterns.hasMatch(text);
    bool hasHygiene = _hygienePatterns.hasMatch(text);
    bool hasService = _servicePatterns.hasMatch(text);
    bool hasAmbience = _ambiencePatterns.hasMatch(text);
    bool hasEnvironment = _environmentPatterns.hasMatch(text);

    // 배달/포장: 맛만 체크
    if (isDeliveryOrTakeout) {
      if (!hasTaste) {
        return GeniusFeedback(
          message: "어떤 맛이었나요? 맛에 대한 구체적인 표현을 추가해보세요!",
        );
      }
      if (text.length < 50) {
        return GeniusFeedback(
          message: "조금 더 길게 써주시면 신뢰도가 올라갑니다.",
        );
      }
      return GeniusFeedback(
        message: "완벽해요! 아주 훌륭한 리뷰입니다. ✨",
      );
    }

    // 우선순위: 맛 > 위생 > 서비스 > 분위기 > 환경
    if (!hasTaste) {
      return GeniusFeedback(
        message: "어떤 맛이었나요? 식감이나 향도 궁금해요.",
      );
    }
    if (!hasHygiene) {
      return GeniusFeedback(
        message: "매장 위생/청결 상태는 어땠나요?",
      );
    }
    if (!hasService) {
      return GeniusFeedback(
        message: "직원 서비스나 응대는 어떠셨나요?",
      );
    }
    if (!hasAmbience) {
      return GeniusFeedback(
        message: "매장 분위기는 어땠나요?",
      );
    }
    if (!hasEnvironment) {
      return GeniusFeedback(
        message: "주차, 환기 등 매장 환경은 어땠나요?",
      );
    }

    // 모두 충족
    if (text.length < 50) {
      return GeniusFeedback(
        message: "조금 더 길게 써주시면 신뢰도가 올라갑니다.",
      );
    }

    return GeniusFeedback(
      message: "완벽해요! 아주 훌륭한 리뷰입니다. ✨",
    );
  }
}
