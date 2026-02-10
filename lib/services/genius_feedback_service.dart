
import 'package:needsfine_app/models/ranking_models.dart';

class GeniusFeedback {
  final String message;

  GeniusFeedback({
    required this.message,
  });
}

class GeniusFeedbackService {
  // ------------------------------------------------------------------------
  // 1. Regex Patterns (분석 로직)
  // ------------------------------------------------------------------------

  // [Gauss] 논리, 가성비, 가격, 양
  static final _pricePatterns = RegExp(r'(가격|가성비|비싸|저렴|계산|결제|영수증|돈|원|인분|양|푸짐|넉넉|배터|창렬|혜자)');
  
  // [Shakespeare] 감성, 맛 묘사, 식감
  static final _sensoryPatterns = RegExp(r'(맛있|존맛|꿀맛|별미|굿|진국|깊|진하|끝내|신선|재료|채소|해산물|싱싱|고기|육즙|부드|살살|쫄깃|바삭|아삭|탱글|꾸덕|촉촉|질기|퍽퍽|시원|얼큰|불맛|감칠맛|달달|매콤|칼칼|개운|냄새|향)');
  
  // [Sherlock] 관찰, 서비스, 편의시설, 분위기
  static final _infoPatterns = RegExp(r'(친절|서비스|사장|직원|알바|응대|웨이팅|대기|예약|자리|테이블|룸|화장실|주차|발렛|키오스크|태블릿|아기의자|매장|가게|식당|분위기|인테리어|조명|음악|뷰|전망|혼밥|데이트|모임|회식)');

  // ------------------------------------------------------------------------
  // 2. Feedback Generation (Professional Tone)
  // ------------------------------------------------------------------------

  static GeniusFeedback generateFeedback(String text, double rating, List<String> tags) {
    if (text.length < 10) {
      return GeniusFeedback(
        message: "최소 10자 이상 작성해주세요.",
      );
    }

    // 1. 분석 실행
    bool hasPrice = _pricePatterns.hasMatch(text);
    bool hasSensory = _sensoryPatterns.hasMatch(text);
    bool hasInfo = _infoPatterns.hasMatch(text);

    // [Logic Check] 배달/포장은 매장 분위기(Info) 체크 생략
    bool isDeliveryOrTakeout = tags.any((t) => t.contains('배달') || t.contains('포장'));

    // 2. 우선순위 결정 (가장 부족한 부분 지적)
    // 순서: 맛(기본) -> 정보(디테일) -> 가격(논리)
    
    // [Case 1] 맛 표현이 부족할 때
    if (!hasSensory) {
      return GeniusFeedback(
        message: "어떤 맛이었나요? 식감이나 향도 궁금해요.", // 정중한 말투
      );
    }

    // [Case 2] 정보/분위기가 부족할 때
    // 배달/포장이 아닐 때만 체크
    if (!hasInfo && !isDeliveryOrTakeout) {
      return GeniusFeedback(
        message: "매장 분위기나 서비스는 어땠나요?", // 정중한 말투
      );
    }

    // [Case 3] 가격/가성비가 부족할 때
    if (!hasPrice) {
      return GeniusFeedback(
        message: "가격 대비 만족도는 어떠셨나요?", // 정중한 말투
      );
    }

    // [Case 4] 모두 충족했을 때 (칭찬)
    if (text.length < 50) {
      return GeniusFeedback(
        message: "조금 더 길게 써주시면 신뢰도가 올라갑니다.", // 에디터 톤
      );
    }

    return GeniusFeedback(
      message: "완벽해요! 아주 훌륭한 리뷰입니다. ✨",
    );
  }
}
