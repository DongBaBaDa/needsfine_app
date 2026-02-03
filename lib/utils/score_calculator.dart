import 'dart:math';

class ScoreCalculator {
  // ✅ 태그 추출 로직
  static List<String> extractReviewTags(String text) {
    final normalizedText = text.trim();
    List<Map<String, dynamic>> tags = [];

    void addTagIfMatch(String word, String patternStr, int priority) {
      final pattern = RegExp(patternStr, caseSensitive: false, dotAll: true);
      if (pattern.hasMatch(normalizedText)) {
        tags.add({'word': word, 'priority': priority});
      }
    }

    // [패턴 정의]
    addTagIfMatch('위생 상태 최악', r'(바퀴|벌레|파리|모기|머리카락|이물질|털)[\s\S]{0,50}(나왔|있|보였|다녀)', 0);
    addTagIfMatch('서비스 최악', r'(잡아|치워|그냥|내돈)[\s\S]{0,50}(달래|래|라니|라고|무시|아깝)', 0);
    addTagIfMatch('응대 불량', r'(욕|반말|싸우|시비|소리|기분)[\s\S]{0,50}(하|했|듣|지르|나쁘|잡쳐)', 0);
    addTagIfMatch('식중독/상태 불량', r'(상한|쉰|썩은|비린|비릿|잡내|누린|물컹|딱딱|안익|차가)[\s\S]{0,50}(맛|냄새|식감|상태)', 0);
    addTagIfMatch('가성비 아쉽', r'(가격|비싸|가성비)[\s\S]{0,30}(별로|나쁘|안좋|사악|창렬)', 1);
    addTagIfMatch('맛이 평범함', r'(찾아갈.*아니|그닥|그저|무난|쏘쏘|평범|특별함.*없|기대.*이하)', 1);
    addTagIfMatch('양이 적음', r'(양)[\s\S]{0,30}(적|작|창렬|부족)', 1);
    addTagIfMatch('재방문 의사 없음', r'(재방문|다시|또|굳이)[\s\S]{0,30}(안|못|없|않|모르)', 1);
    addTagIfMatch('메뉴 아쉬움', r'(메뉴|선택|시키|주문)[\s\S]{0,30}(실패|잘못|아쉽|후회|미스)', 1);
    addTagIfMatch('공기밥 적음', r'(공기밥|밥|양)[\s\S]{0,30}(적|작|모자|부족|아쉽)', 1);
    addTagIfMatch('웨이팅 있음', r'(웨이팅|대기|줄)[\s\S]{0,50}(길|많|심해|헬|필수)', 1);
    addTagIfMatch('직원 응대 아쉽', r'(직원|알바|서빙|이모|아줌마|종업원)[\s\S]{0,50}(불친절|느리|실수|반말|무시|치우|뺏)', 1);
    addTagIfMatch('주차 불편', r'(주차|차)[\s\S]{0,30}(힘들|없|불편|헬)', 1);
    addTagIfMatch('화장실 불편', r'(화장실)[\s\S]{0,30}(더럽|좁|멀|별로)', 1);
    addTagIfMatch('시끄러움', r'(시끄|소란|정신없|시장통)', 1);
    addTagIfMatch('매장 환경', r'(좁다|좁은|넓다|넓은|쾌적|답답|시원|덥다|더워|추워|춥다|환기|연기|냄새|에어컨|히터)', 1);
    addTagIfMatch('분위기/소음', r'(조용|분위기|음악|노래|BGM|인테리어|조명|힙한|노포)', 1);
    addTagIfMatch('편의시설', r'(남녀공용|테이블간격|의자|바닥|미끄|기름기|끈적|태블릿|키오스크|아기의자)', 1);
    addTagIfMatch('서비스 디테일', r'(구워|잘라|리필|벨|호출|가져다|셀프|무한)', 1);
    addTagIfMatch('뷰 좋음', r'(뷰|전망|경치)\s*(가|이|는|도)?\s*(좋|예쁘|끝내|최고|맛집)', 2);
    addTagIfMatch('혼밥 가능', r'(혼밥|혼자)[\s\S]{0,30}(가능|좋|편해)', 2);
    addTagIfMatch('양이 많음', r'(양)[\s\S]{0,30}(많|푸짐|넉넉|배터)', 2);
    addTagIfMatch('가성비 좋음', r'(가성비|가격)[\s\S]{0,30}(좋|착해|저렴|합리)', 2);
    addTagIfMatch('친절함', r'(친절|상냥|매너|서비스)', 2);
    addTagIfMatch('재료 신선', r'(신선|재료|채소|해산물)[\s\S]{0,30}(좋|싱싱)', 2);
    addTagIfMatch('국물 진국', r'(국물|육수)[\s\S]{0,30}(진국|깊|진하|끝내)', 2);
    addTagIfMatch('데이트 추천', r'(데이트|소개팅|분위기|기념일|커플)', 2);
    addTagIfMatch('고기 맛집', r'(고기|갈비|삼겹|육즙)[\s\S]{0,30}(좋|맛있|부드|살살)', 2);
    addTagIfMatch('키오스크 없음', r'(키오스크|주문)[\s\S]{0,30}(없|안|직원)', 2);
    addTagIfMatch('고기 퀄리티', r'(두툼|두껍|얇은|대패|마블링|비계|껍질|육즙)', 2);
    addTagIfMatch('식감 좋음', r'(부들|야들|꼬들|쫀득|탱탱|아삭|사르르|녹아|숙성|활어|찰진|꾸덕|크리미|알덴테)', 2);
    addTagIfMatch('맛 디테일', r'(불맛|불향|숯불향|훈연|감칠맛|간이|슴슴|짭짤|달달|매콤|얼큰|칼칼|시원|개운|웍질)', 2);
    addTagIfMatch('맛 비교', r'(신라면|불닭|엽떡|마라탕|진라면|열라면|~보다|~만큼|~정도)', 2);
    addTagIfMatch('맛있음', r'(맛있|존맛|꿀맛|별미|굿)', 3);
    addTagIfMatch('분위기 좋음', r'(분위기)[\s\S]{0,30}(좋|깡패|예쁘|감성|레트로)', 3);
    addTagIfMatch('깨끗함', r'(깨끗|청결|깔끔)', 3);
    addTagIfMatch('맛 준수함', r'(맛|음식|간|반응)[\s\S]{0,30}(준수|나쁘지|괜찮)', 3);

    final uniqueTags = <String>{};
    final sortedTags = <String>[];
    tags.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

    for (var t in tags) {
      if (uniqueTags.add(t['word'])) {
        sortedTags.add(t['word']);
      }
    }
    return sortedTags.take(3).toList();
  }

  // ✅ NeedsFine 점수 계산 로직
  static Map<String, dynamic> calculateNeedsFineScore(String reviewText, double userRating, bool hasImages) {
    final safeText = reviewText.trim();
    final safeRating = (userRating.isNaN) ? 3.0 : userRating;
    final textLen = safeText.length;

    final tags = extractReviewTags(safeText);
    final hasNegativeNuance = tags.any((t) => RegExp(r'(아쉽|별로|나쁘|사악|평범|쏘쏘|그닥|아니|창렬|없음|실패|후회)').hasMatch(t));
    final hasFact = RegExp(r'([0-9]+(분|시간|시|명|개|원|만원|천원)|한시간|두시간|반시간|오십분)').hasMatch(safeText);
    final hasContrast = RegExp(r'(하지만|그래도|불구하고|반면|~데|~지만|~한데|~나|~으나)').hasMatch(safeText);

    int contextCount = 0;
    final contextPatterns = [
      r'(모임|회식|단체|연말|송년|신년|기념일|가족|상견례|뒤풀이)',
      r'(예약|캐치테이블|테이블링|웨이팅|대기|줄|입장)',
      r'(룸|방|칸막이|분할|프라이빗|조용|시끌|벅적|주차|화장실|창가|뷰|테라스)',
      r'(혼자|혼밥|커플|데이트|친구|부모님|아이|애기|유모차)',
      r'(짜장|짬뽕|탕수육|볶음밥|군만두|양장피|유산슬|깐풍기|마라|멘보샤|코스|요리|파스타|피자|리조또|스테이크|샐러드|버거|샌드위치|김치|반찬)',
      r'(된장|찌개|김치|국밥|냉면|계란찜|공기밥|볶음밥|누룽지|쌈|상추|깻잎|파절이|명이나물|숯불|그릴|불판)',
      r'(멜젓|갈치속젓|와사비|소금|쌈장|기름장|콩가루|쯔란|마늘|고추)',
      r'(초밥|스시|사시미|회|라멘|우동|소바|돈까스|카츠|덮밥|텐동|락교|초생강|단무지|미소|장국)',
      r'(파스타|스파게티|리조또|필라프|스테이크|피자|버거|샐러드|식전빵|피클|할라피뇨|와인|에이드)',
      r'(짜장|짬뽕|탕수육|꿔바로우|마라탕|샹궈|군만두|딤섬|멘보샤|춘장|고량주)',
      r'(안주|탕|튀김|소주|맥주|생맥|하이볼|위스키|칵테일|사케|막걸리|기본안주|뻥튀기)'
    ];
    for (var p in contextPatterns) {
      if (RegExp(p).hasMatch(safeText)) contextCount++;
    }

    int infoCount = 0;
    final infoPatterns = [
      r'(좁다|좁은|넓다|넓은|쾌적|답답|시원|덥다|더워|추워|춥다|환기|연기|냄새|에어컨|히터)',
      r'(시끄|소란|정신없|시장통|조용|분위기|음악|노래|BGM|인테리어|조명)',
      r'(화장실|주차|발렛|키오스크|태블릿|아기의자|구워|잘라|리필|벨|호출)'
    ];
    for (var p in infoPatterns) {
      if (RegExp(p).hasMatch(safeText)) infoCount++;
    }

    int comparativeCount = 0;
    final compPatterns = [
      r'(신라면|불닭|엽떡|마라탕|진라면|열라면)',
      r'(~보다|~만큼|~정도)[\s\S]{0,10}(매워|맵|짜|달|맛있|괜찮)'
    ];
    for (var p in compPatterns) {
      if (RegExp(p).hasMatch(safeText)) comparativeCount++;
    }

    int clicheCount = 0;
    if (RegExp(r'(겉바속촉|입에서 녹아|육즙이? (팡팡|가득)|잡내(가)? (1도|전혀|하나도) (없|안)|사장님(이)? (왕)?친절|재방문 (의사|각|100)|강추|존맛탱|비주얼 (대박|굿|미쳤))').hasMatch(safeText)) {
      clicheCount++;
    }

    int narrativeCount = 0;
    final narrativePatterns = [
      r'(친구(랑|들이랑)|엄마(랑|가)|남편(이랑|이)|비가|늦게|실수로|우연히|지나가다|옆테이블|직원분이|~해서 좋았|~는 좀|다만|솔직히|개인적으로|의외로|운좋게)',
      r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러|벌써|매번)'
    ];
    for (var p in narrativePatterns) {
      if (RegExp(p).hasMatch(safeText)) narrativeCount++;
    }

    int mitigatedCount = 0;
    if (RegExp(r'(걱정|고민|망설|의심|비싸|멀|힘들)[\s\S]{0,20}(하지만|그런데|반전|오히려|불구하고|싹|해소|용서|이해|만족)').hasMatch(safeText)) {
      mitigatedCount++;
    }

    int fatalCount = 0;
    final fatalPatterns = [
      r'(바퀴|벌레|파리|모기|머리카락|이물질|털)[\s\S]{0,50}(나왔|있|보였|다녀)',
      r'(잡아|치워|내돈)[\s\S]{0,30}(달래|래|라니|라고|무시|아깝)',
      r'(욕|반말|싸우|시비)[\s\S]{0,30}(하|했|듣)',
      r'(상한|쉰|썩은|비린|비릿|잡내|누린|물컹|딱딱|안익)[\s\S]{0,30}(맛|냄새|식감|상태)'
    ];
    for (var p in fatalPatterns) {
      if (RegExp(p).hasMatch(safeText)) fatalCount++;
    }

    int maliciousCount = 0;
    final maliciousPatterns = [
      r'(쓰레기|개판|망해|최악|극혐|폐업|기분.*잡쳐|더러워|미친)',
      r'(노맛|존노|퉤)',
      r'(니|너|새끼)[\s\S]{0,20}(들|가)'
    ];
    for (var p in maliciousPatterns) {
      if (RegExp(p).hasMatch(safeText)) maliciousCount++;
    }

    int sensoryCount = 0;
    final sensoryPatterns = [
      r'(쫄깃|바삭|물컹|딱딱|싱거|짜|매워|육즙|부드|고소|담백|비린|잡내|아삭|탱글|꾸덕|촉촉|질기|퍽퍽|시원|얼큰)',
      r'(두툼|두껍|얇은|대패|마블링|비계|껍질|기름진|느끼|부들|야들|꼬들|쫀득|사르르|녹아|질겅|푸석|흐물|눅눅)',
      r'(불맛|불향|숯불향|훈연|감칠맛|간이|슴슴|짭짤|달달|달짝|매콤|칼칼|개운|숙성|활어|찰진|진한|깊은|크리미|알덴테|퍼진|익힘|굽기|웍질|걸쭉|청량|목넘김|술도둑)'
    ];
    for (var p in sensoryPatterns) {
      if (RegExp(p).hasMatch(safeText)) sensoryCount++;
    }

    int sincerityCount = 0;
    final sincerityPatterns = [
      r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러)',
      r'(일주|한달|매주)[\s\S]{0,20}(번|회)',
      r'(처음|첫)[\s\S]{0,20}(방문|와보|먹어)',
      r'(메뉴|음식|반찬|국물|식감|튀김|상태|비주얼|양념|소스|간이|육즙)[\s\S]{0,50}(설명|나오|구워|주시)'
    ];
    for (var p in sincerityPatterns) {
      if (RegExp(p).hasMatch(safeText)) sincerityCount++;
    }

    double lengthFactor = textLen < 40 ? 0.6 : 0.8;
    double qrScore = log(textLen + 1) * lengthFactor;

    qrScore += sqrt(contextCount) * 0.5;
    qrScore += (log(sincerityCount + 1) / ln2) * 1.8;
    qrScore += min(5.0, sensoryCount * 1.5);

    if (comparativeCount > 0) qrScore += 2.0;
    if (narrativeCount > 0) qrScore += 1.5;
    qrScore += sqrt(infoCount) * 1.2;

    if (hasFact) qrScore += 1.5;
    if (hasContrast) qrScore += 1.2;
    if (hasNegativeNuance) qrScore += 1.0;

    if (clicheCount >= 3 && !hasNegativeNuance && fatalCount == 0) {
      if (narrativeCount > 0) {
        qrScore -= 1.0;
      } else {
        qrScore -= 2.0;
      }
    }
    if (mitigatedCount > 0) qrScore -= 1.5;
    if (maliciousCount > 0) qrScore -= 3.0;
    if (fatalCount > 0) {
      double evidenceStrength = (textLen - 40) / 10;
      qrScore += max(-1.0, min(2.0, evidenceStrength));
    }

    double sigmoid(double x) => 1 / (1 + exp(-0.4 * (x - 3.5)));
    double trustScore = sigmoid(qrScore);

    bool isRevisit = RegExp(r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러|벌써|매번)').hasMatch(safeText);

    if (textLen < 40 && !isRevisit) {
      if (infoCount == 0 && comparativeCount == 0) {
        trustScore *= 0.7;
      }
    }

    if (textLen >= 100 && safeRating == 5.0 && !hasNegativeNuance && fatalCount == 0 && infoCount == 0 && clicheCount >= 2) {
      trustScore = min(trustScore, 0.8);
    }

    if (isRevisit) {
      trustScore = max(trustScore, 0.7);
    }

    if (hasImages) {
      trustScore = min(1.0, trustScore * 1.1);
    } else {
      trustScore *= 0.9;
    }

    trustScore = 0.1 + (trustScore * 0.88);

    double baseAnchor = 2.5;
    if (fatalCount > 0) {
      baseAnchor = 1.0;
    } else if (maliciousCount > 0) {
      baseAnchor = 2.0;
    } else if (hasNegativeNuance && safeRating >= 3.0) {
      baseAnchor = 2.5;
    } else {
      if (safeRating >= 4.0) {
        bool isProven = (trustScore > 0.7 && textLen >= 50) || isRevisit;
        baseAnchor = isProven ? 3.5 : 2.5;
      } else if (safeRating <= 2.0) {
        baseAnchor = 1.5;
      } else {
        baseAnchor = 2.5;
      }
    }

    double finalScore = (safeRating * trustScore) + (baseAnchor * (1 - trustScore));

    if (finalScore >= 4.5) {
      bool hasPlatinumEvidence = (narrativeCount > 0 || hasNegativeNuance || fatalCount > 0 || isRevisit);
      if (!hasPlatinumEvidence) {
        finalScore = 4.4;
      }
    }

    finalScore = double.parse(max(1.0, min(5.0, finalScore)).toStringAsFixed(1));
    int trustLevel = (trustScore * 100).round();

    return {
      'needsfine_score': finalScore,
      'trust_level': trustLevel,
      'is_revisit': isRevisit,
      'malicious_count': maliciousCount,
      'cliche_count': clicheCount,
      'narrative_count': narrativeCount,
      'info_count': infoCount,
      'text_len': textLen,
      'has_images': hasImages,
    };
  }

  // ✅ [수정 완료] 누락되었던 메서드 추가됨
  static Map<String, dynamic> getFeedbackMessage(Map<String, dynamic> analysis) {
    int trust = analysis['trust_level'];
    int textLen = analysis['text_len'];
    bool hasImages = analysis['has_images'];
    int malicious = analysis['malicious_count'];
    int cliche = analysis['cliche_count'];
    int narrative = analysis['narrative_count'];
    int info = analysis['info_count'];

    String message = "";
    bool isWarning = false;

    if (malicious > 0) {
      message = "혹시 속상한 일이 있으셨나요? 과격한 표현은 다른 사용자에게 상처가 될 수 있어요. 😥";
      isWarning = true;
    } else if (textLen < 30) {
      message = "첫 문장이 가장 중요해요! 어떤 점이 기억에 남았나요? (맛, 분위기 등) 😊";
    } else if (!hasImages) {
      message = "사진이 있으면 신뢰도가 확 올라가요! 📸 맛있는 사진을 공유해주세요.";
    } else if (cliche >= 2 && narrative == 0) {
      message = "너무 좋은 말만 가득해요! 혹시 광고로 오해받지 않게 구체적인 경험을 더해주시겠어요? ✨";
      isWarning = true;
    } else if (trust < 50) {
      message = "조금 더 구체적으로 묘사해보는 건 어떨까요? 메뉴 이름이나 가격 정보도 좋아요! 📝";
    } else if (info == 0 && trust < 70) {
      message = "매장 분위기나 주차 정보 같은 꿀팁을 더하면 완벽할 것 같아요! 🚗";
    } else if (trust >= 80) {
      message = "완벽해요! 이 리뷰는 많은 분들에게 진짜 맛집을 찾는 지도가 될 거예요. 💖";
    } else {
      message = "좋아요! 솔직하고 도움이 되는 리뷰를 작성하고 계시네요. 👍";
    }

    return {
      'message': message,
      'is_warning': isWarning,
    };
  }
}