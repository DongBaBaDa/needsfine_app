import 'dart:math';

class ScoreCalculator {
  // ---------------------------------------------------------------------------
  // 1. 태그 추출 로직 (v11.4 PHOTO BONUS)
  // ---------------------------------------------------------------------------
  static List<String> extractReviewTags(String text) {
    if (text.isEmpty) return [];

    // Dart에서는 normalize가 기본적으로 처리되거나 문자열 조작 시 자동 처리됨
    // TS: const normalizedText = (text || "").normalize("NFC");
    final normalizedText = text.trim();
    final List<Map<String, dynamic>> tags = [];

    void addTagIfMatch(String word, String patternStr, int priority) {
      final pattern = RegExp(patternStr, caseSensitive: false, dotAll: true);
      if (pattern.hasMatch(normalizedText)) {
        tags.add({'word': word, 'priority': priority});
      }
    }

    // [Fatal Patterns]
    addTagIfMatch('위생 상태 최악', r'(바퀴|벌레|파리|모기|머리카락|이물질|털)[^]{0,50}(나왔|있|보였|다녀)', 0);
    addTagIfMatch('서비스 최악', r'(잡아|치워|그냥|내돈)[^]{0,50}(달래|래|라니|라고|무시|아깝)', 0);
    addTagIfMatch('응대 불량', r'(욕|반말|싸우|시비|소리|기분)[^]{0,50}(하|했|듣|지르|나쁘|잡쳐)', 0);
    addTagIfMatch('식중독/상태 불량', r'(상한|쉰|썩은|비린|비릿|잡내|누린|물컹|딱딱|안익|차가)[^]{0,50}(맛|냄새|식감|상태)', 0);

    // [Negative Patterns]
    addTagIfMatch('가성비 아쉽', r'(가격|비싸|가성비)[^]{0,30}(별로|나쁘|안좋|사악|창렬)', 1);
    addTagIfMatch('맛이 평범함', r'(찾아갈.*아니|그닥|그저|무난|쏘쏘|평범|특별함.*없|기대.*이하)', 1);
    addTagIfMatch('양이 적음', r'(양)[^]{0,30}(적|작|창렬|부족)', 1);
    addTagIfMatch('재방문 의사 없음', r'(재방문|다시|또|굳이)[^]{0,30}(안|못|없|않|모르)', 1);
    addTagIfMatch('메뉴 아쉬움', r'(메뉴|선택|시키|주문)[^]{0,30}(실패|잘못|아쉽|후회|미스)', 1);

    // [Info Patterns]
    addTagIfMatch('공기밥 적음', r'(공기밥|밥|양)[^]{0,30}(적|작|모자|부족|아쉽)', 1);
    addTagIfMatch('웨이팅 있음', r'(웨이팅|대기|줄)[^]{0,50}(길|많|심해|헬|필수)', 1);
    addTagIfMatch('직원 응대 아쉽', r'(직원|알바|서빙|이모|아줌마|종업원)[^]{0,50}(불친절|느리|실수|반말|무시|치우|뺏)', 1);
    addTagIfMatch('주차 불편', r'(주차|차)[^]{0,30}(힘들|없|불편|헬)', 1);
    addTagIfMatch('화장실 불편', r'(화장실)[^]{0,30}(더럽|좁|멀|별로)', 1);
    addTagIfMatch('시끄러움', r'(시끄|소란|정신없|시장통)', 1);
    // [v10.3 추가]
    addTagIfMatch('매장 환경', r'(좁다|좁은|넓다|넓은|쾌적|답답|시원|덥다|더워|추워|춥다|환기|연기|냄새|에어컨|히터)', 1);
    addTagIfMatch('분위기/소음', r'(조용|분위기|음악|노래|BGM|인테리어|조명|힙한|노포)', 1);
    addTagIfMatch('편의시설', r'(남녀공용|테이블간격|의자|바닥|미끄|기름기|끈적|태블릿|키오스크|아기의자)', 1);
    addTagIfMatch('서비스 디테일', r'(구워|잘라|리필|벨|호출|가져다|셀프|무한)', 1);

    // [Feature Patterns]
    addTagIfMatch('뷰 좋음', r'(뷰|전망|경치)\s*(가|이|는|도)?\s*(좋|예쁘|끝내|최고|맛집)', 2);
    addTagIfMatch('혼밥 가능', r'(혼밥|혼자)[^]{0,30}(가능|좋|편해)', 2);
    addTagIfMatch('양이 많음', r'(양)[^]{0,30}(많|푸짐|넉넉|배터)', 2);
    addTagIfMatch('가성비 좋음', r'(가성비|가격)[^]{0,30}(좋|착해|저렴|합리)', 2);
    addTagIfMatch('친절함', r'(친절|상냥|매너|서비스)', 2);
    addTagIfMatch('재료 신선', r'(신선|재료|채소|해산물)[^]{0,30}(좋|싱싱)', 2);
    addTagIfMatch('국물 진국', r'(국물|육수)[^]{0,30}(진국|깊|진하|끝내)', 2);
    addTagIfMatch('데이트 추천', r'(데이트|소개팅|분위기|기념일|커플)', 2);
    addTagIfMatch('고기 맛집', r'(고기|갈비|삼겹|육즙)[^]{0,30}(좋|맛있|부드|살살)', 2);
    addTagIfMatch('키오스크 없음', r'(키오스크|주문)[^]{0,30}(없|안|직원)', 2);
    // [v10.3 추가]
    addTagIfMatch('고기 퀄리티', r'(두툼|두껍|얇은|대패|마블링|비계|껍질|육즙)', 2);
    addTagIfMatch('식감 좋음', r'(부들|야들|꼬들|쫀득|탱탱|아삭|사르르|녹아|숙성|활어|찰진|꾸덕|크리미|알덴테)', 2);
    addTagIfMatch('맛 디테일', r'(불맛|불향|숯불향|훈연|감칠맛|간이|슴슴|짭짤|달달|매콤|얼큰|칼칼|시원|개운|웍질)', 2);
    addTagIfMatch('맛 비교', r'(신라면|불닭|엽떡|마라탕|진라면|열라면|~보다|~만큼|~정도)', 2);

    // [Basic Patterns]
    addTagIfMatch('맛있음', r'(맛있|존맛|꿀맛|별미|굿)', 3);
    addTagIfMatch('분위기 좋음', r'(분위기)[^]{0,30}(좋|깡패|예쁘|감성|레트로)', 3);
    addTagIfMatch('깨끗함', r'(깨끗|청결|깔끔)', 3);
    addTagIfMatch('맛 준수함', r'(맛|음식|간|반응)[^]{0,30}(준수|나쁘지|괜찮)', 3);

    // 중복 제거 및 우선순위 정렬
    final seen = <String>{};
    final uniqueTags = tags.where((item) => seen.add(item['word'] as String)).toList();
    uniqueTags.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

    return uniqueTags.take(3).map((e) => e['word'] as String).toList();
  }

  // ---------------------------------------------------------------------------
  // 2. NeedsFine 점수 계산 로직 (v11.4 PHOTO BONUS)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> calculateNeedsFineScore(
      String reviewText,
      double userRating, [
        bool hasPhoto = false,
      ]) {

    final safeText = reviewText.trim(); // replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), "") 처리는 trim()으로 대체 가능하거나 필요시 추가
    final safeRating = (userRating.isNaN) ? 3.0 : userRating;
    final normalizedText = safeText.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), "").trim();
    final textLen = normalizedText.length;

    // 1. 변수 추출
    final tags = extractReviewTags(normalizedText);

    // [v11.3 수정] 본문 텍스트 기반 부정 뉘앙스 탐지
    final hasNegativeText = RegExp(r'(아쉽|별로|나쁘|사악|평범|쏘쏘|그닥|아니|창렬|없음|실패|후회|비싸|적다|작다|불친절|느리)').hasMatch(normalizedText);
    final hasNegativeNuance = tags.any((t) => RegExp(r'(아쉽|별로|나쁘|사악|평범|쏘쏘|그닥|아니|창렬|없음|실패|후회)').hasMatch(t)) || hasNegativeText;

    final hasFact = RegExp(r'([0-9]+(분|시간|시|명|개|원|만원|천원)|한시간|두시간|반시간|오십분)').hasMatch(normalizedText);
    final hasContrast = RegExp(r'(하지만|그래도|불구하고|반면|는데|은데|지만|으나|그런데|다만)').hasMatch(normalizedText);

    // Context Count
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
    for (var p in contextPatterns) { if (RegExp(p).hasMatch(normalizedText)) contextCount++; }

    // Info Count
    int infoCount = 0;
    final infoPatterns = [
      r'(좁다|좁은|넓다|넓은|쾌적|답답|시원|덥다|더워|추워|춥다|환기|연기|냄새|에어컨|히터)',
      r'(시끄|소란|정신없|시장통|조용|분위기|음악|노래|BGM|인테리어|조명)',
      r'(화장실|주차|발렛|키오스크|태블릿|아기의자|구워|잘라|리필|벨|호출)'
    ];
    for (var p in infoPatterns) { if (RegExp(p).hasMatch(normalizedText)) infoCount++; }

    // Comparative Count
    int comparativeCount = 0;
    final compPatterns = [
      r'(신라면|불닭|엽떡|마라탕|진라면|열라면)',
      r'(보다|만큼|정도)[^]{0,10}(매워|맵|짜|달|맛있|괜찮)'
    ];
    for (var p in compPatterns) { if (RegExp(p).hasMatch(normalizedText)) comparativeCount++; }

    // Cliché Count
    int clicheCount = 0;
    if (RegExp(r'(겉바속촉|입에서 녹아|육즙이? (팡팡|가득)|잡내(가)? (1도|전혀|하나도) (없|안)|사장님(이)? (왕)?친절|재방문 (의사|각|100)|강추|존맛탱|비주얼 (대박|굿|미쳤))').hasMatch(normalizedText)) {
      clicheCount++;
    }

    // Narrative Count
    int narrativeCount = 0;
    final narrativePatterns = [
      r'(친구(랑|들이랑)|엄마(랑|가)|남편(이랑|이)|비가|늦게|실수로|우연히|지나가다|옆테이블|직원분이|~해서 좋았|~는 좀|다만|솔직히|개인적으로|의외로|운좋게)',
      r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러|벌써|매번)'
    ];
    for (var p in narrativePatterns) { if (RegExp(p).hasMatch(normalizedText)) narrativeCount++; }

    // Mitigated Count
    int mitigatedCount = 0;
    if (RegExp(r'(걱정|고민|망설|의심|비싸|멀|힘들)[^]{0,20}(하지만|그런데|반전|오히려|불구하고|싹|해소|용서|이해|만족)').hasMatch(normalizedText)) {
      mitigatedCount++;
    }

    // Fatal / Malicious / Praise / Sensory / Sincerity counts
    int fatalCount = 0;
    final fatalP = [
      r'(바퀴|벌레|파리|모기|머리카락|이물질|털)[^]{0,50}(나왔|있|보였|다녀)',
      r'(잡아|치워|내돈)[^]{0,30}(달래|래|라니|라고|무시|아깝)',
      r'(욕|반말|싸우|시비)[^]{0,30}(하|했|듣)',
      r'(상한|쉰|썩은|비린|비릿|잡내|누린|물컹|딱딱|안익)[^]{0,30}(맛|냄새|식감|상태)'
    ];
    for (var p in fatalP) { if (RegExp(p).hasMatch(normalizedText)) fatalCount++; }

    int maliciousCount = 0;
    final maliciousP = [
      r'(쓰레기|개판|망해|최악|극혐|폐업|기분.*잡쳐|더러워|미친)',
      r'(노맛|존노|퉤)',
      r'(니네|너네|새끼)[^]{0,20}(들|가)'
    ];
    for (var p in maliciousP) { if (RegExp(p).hasMatch(normalizedText)) maliciousCount++; }

    int praiseCount = 0;
    if (RegExp(r'(맛있|최고|굿|짱|존맛|좋았|강추|대박|예술|환상)').hasMatch(normalizedText)) praiseCount++;

    int sensoryCount = 0;
    final sensoryP = [
      r'(쫄깃|바삭|물컹|딱딱|싱거|짜|매워|육즙|부드|고소|담백|비린|잡내|아삭|탱글|꾸덕|촉촉|질기|퍽퍽|시원|얼큰)',
      r'(두툼|두껍|얇은|대패|마블링|비계|껍질|기름진|느끼|부들|야들|꼬들|쫀득|사르르|녹아|질겅|푸석|흐물|눅눅)',
      r'(불맛|불향|숯불향|훈연|감칠맛|간이|슴슴|짭짤|달달|달짝|매콤|칼칼|개운|숙성|활어|찰진|진한|깊은|크리미|알덴테|퍼진|익힘|굽기|웍질|걸쭉|청량|목넘김|술도둑)'
    ];
    for (var p in sensoryP) { if (RegExp(p).hasMatch(normalizedText)) sensoryCount++; }

    int sincerityCount = 0;
    final sincerityP = [
      r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러)',
      r'(일주|한달|매주)[^]{0,20}(번|회)',
      r'(처음|첫)[^]{0,20}(방문|와보|먹어)',
      r'(메뉴|음식|반찬|국물|식감|튀김|상태|비주얼|양념|소스|간이|육즙)[^]{0,50}(설명|나오|구워|주시)'
    ];
    for (var p in sincerityP) { if (RegExp(p).hasMatch(normalizedText)) sincerityCount++; }


    // 2. 품질 점수 (q_r_score) 계산

    // [v10.1 튜닝] 글이 짧으면 기본 점수 대폭 하향
    double lengthFactor = textLen < 40 ? 0.6 : 0.8;
    double qrScore = log(textLen + 1) * lengthFactor;

    // 🔥 [v11.4] 사진 가산점 (강력한 증거)
    if (hasPhoto) {
      qrScore += 1.5;
    }

    qrScore += sqrt(contextCount) * 0.5;
    qrScore += (log(sincerityCount + 1) / ln2) * 1.8; // log2
    qrScore += min(5.0, sensoryCount * 1.5);

    if (comparativeCount > 0) qrScore += 2.0;
    if (narrativeCount > 0) qrScore += 1.5;
    qrScore += sqrt(infoCount) * 1.2;

    if (hasFact) qrScore += 1.5;
    if (hasContrast) qrScore += 1.2;
    if (hasNegativeNuance) qrScore += 1.0;

    // 감점 로직
    if (clicheCount >= 3 && !hasNegativeNuance && fatalCount == 0) {
      if (narrativeCount > 0) qrScore -= 1.0;
      else qrScore -= 2.0;
    }
    if (mitigatedCount > 0) {
      qrScore -= 1.5;
    }

    if (maliciousCount > 0) qrScore -= 3.0;

    if (fatalCount > 0) {
      double evidenceStrength = (textLen - 40) / 10;
      qrScore += max(-1.0, min(2.0, evidenceStrength));
    }

    // 3. 신뢰도(Trust Level) 계산
    // sigmoid = 1 / (1 + exp(-0.4 * (x - 3.5)))
    double trustScore = 1 / (1 + exp(-0.4 * (qrScore - 3.5)));

    bool isRevisit = RegExp(r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러|벌써|매번)').hasMatch(normalizedText);

    // 🔥 [v11.4] 사진이 있으면 짧은 글 페널티 면제
    if (textLen < 40 && !isRevisit && !hasPhoto) {
      if (infoCount == 0 && comparativeCount == 0) {
        trustScore *= 0.7;
      }
    }

    // 너무 완벽한 리뷰 견제
    if (textLen >= 100 && safeRating == 5.0 && !hasNegativeNuance && fatalCount == 0 && infoCount == 0 && clicheCount >= 2) {
      trustScore = min(trustScore, 0.8);
    }

    // 🔥 [v11.4] 사진/재방문 시 신뢰도 바닥값 보정
    if (hasPhoto) {
      trustScore = max(trustScore, 0.5); // 사진 있으면 최소 50%
    }
    if (isRevisit) {
      trustScore = max(trustScore, 0.7); // 재방문은 최소 70%
    }

    trustScore = 0.1 + (trustScore * 0.88);


    // 4. 최종 점수 (Anchor Gravity) (Score Diet: 2.5 Anchor)
    double baseAnchor = 2.5;

    if (fatalCount > 0) {
      baseAnchor = 1.0;
    } else if (maliciousCount > 0) {
      baseAnchor = 2.0;
    } else if (hasNegativeNuance && safeRating >= 3.0) {
      baseAnchor = 2.5;
    } else {
      if (safeRating >= 4.0) {
        // 🔥 [v11.4] 사진이 있으면 증명된 것으로 간주 (맛집 기준 Anchor)
        bool isProven = (trustScore > 0.7 && textLen >= 50) || isRevisit || hasPhoto;
        baseAnchor = isProven ? 3.5 : 2.5;
      } else if (safeRating <= 2.0) {
        baseAnchor = 1.5;
      } else {
        baseAnchor = 2.5;
      }
    }

    double finalScore = (safeRating * trustScore) + (baseAnchor * (1 - trustScore));

    // Platinum Cap (고득점 쿼터제)
    if (finalScore >= 4.5) {
      // 🔥 [v11.4] 사진도 Platinum 증거로 인정
      bool hasPlatinumEvidence = (narrativeCount > 0 || hasNegativeNuance || fatalCount > 0 || isRevisit || hasPhoto);
      if (!hasPlatinumEvidence) {
        finalScore = 4.4;
      }
    }

    finalScore = double.parse(max(1.0, min(5.0, finalScore)).toStringAsFixed(1));
    int trustLevel = (trustScore * 100).round();

    // 5. 메타데이터
    bool authenticity = trustLevel >= 70;
    bool advertisingWords = (sincerityCount == 0 && sensoryCount == 0 && praiseCount > 0 && RegExp(r'(최고|완전|대박|꼭|무조건|강추)').hasMatch(normalizedText) && safeRating >= 4.0);

    bool isCritical = (finalScore < 3.5 || fatalCount > 0) && trustLevel >= 50;
    bool isHidden = trustLevel < 25 || (maliciousCount > 0 && fatalCount == 0 && textLen < 20);

    return {
      'needsfine_score': finalScore,
      'trust_level': trustLevel,
      'authenticity': authenticity,
      'advertising_words': advertisingWords,
      'tags': tags,
      'is_critical': isCritical,
      'is_hidden': isHidden,
      'logic_version': "v11.4_PHOTO_BONUS",
      // UI 표시용 추가 정보
      'is_revisit': isRevisit,
      'info_count': infoCount,
      'narrative_count': narrativeCount,
      'cliche_count': clicheCount,
      'malicious_count': maliciousCount,
      'text_len': textLen,
      'has_images': hasPhoto,
    };
  }

  // ✅ 실시간 피드백 메시지 생성
  static Map<String, dynamic> getFeedbackMessage(Map<String, dynamic> analysis) {
    int trust = analysis['trust_level'] ?? 0;
    int textLen = analysis['text_len'] ?? 0;
    bool hasImages = analysis['has_images'] ?? false;
    int malicious = analysis['malicious_count'] ?? 0;
    int cliche = analysis['cliche_count'] ?? 0;
    int narrative = analysis['narrative_count'] ?? 0;
    int info = analysis['info_count'] ?? 0;

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