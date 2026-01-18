import 'dart:math';

class ScoreCalculator {
  // ---------------------------------------------------------------------------
  // 1. 태그 추출 로직 (v11.1)
  // ---------------------------------------------------------------------------
  static List<String> extractReviewTags(String text) {
    if (text.isEmpty) return [];

    // Dart에서는 normalize가 기본적으로 처리되거나 문자열 조작 시 자동 처리됨
    final normalizedText = text;
    final List<Map<String, dynamic>> tags = [];

    // 정규식 패턴 정의 (Dart raw string r'...' 사용)
    final fatalPatterns = [
      {'word': '위생 상태 최악', 'pattern': RegExp(r'(바퀴|벌레|파리|모기|머리카락|이물질|털)[^]{0,50}(나왔|있|보였|다녀)')},
      {'word': '서비스 최악', 'pattern': RegExp(r'(잡아|치워|그냥|내돈)[^]{0,50}(달래|래|라니|라고|무시|아깝)')},
      {'word': '응대 불량', 'pattern': RegExp(r'(욕|반말|싸우|시비|소리|기분)[^]{0,50}(하|했|듣|지르|나쁘|잡쳐)')},
      {'word': '식중독/상태 불량', 'pattern': RegExp(r'(상한|쉰|썩은|비린|비릿|잡내|누린|물컹|딱딱|안익|차가)[^]{0,50}(맛|냄새|식감|상태)')},
    ];

    final negativePatterns = [
      {'word': '가성비 아쉽', 'pattern': RegExp(r'(가격|비싸|가성비)[^]{0,30}(별로|나쁘|안좋|사악|창렬)')},
      {'word': '맛이 평범함', 'pattern': RegExp(r'(찾아갈.*아니|그닥|그저|무난|쏘쏘|평범|특별함.*없|기대.*이하)')},
      {'word': '양이 적음', 'pattern': RegExp(r'(양)[^]{0,30}(적|작|창렬|부족)')},
      {'word': '재방문 의사 없음', 'pattern': RegExp(r'(재방문|다시|또|굳이)[^]{0,30}(안|못|없|않|모르)')},
      {'word': '메뉴 아쉬움', 'pattern': RegExp(r'(메뉴|선택|시키|주문)[^]{0,30}(실패|잘못|아쉽|후회|미스)')},
    ];

    final infoPatterns = [
      {'word': '공기밥 적음', 'pattern': RegExp(r'(공기밥|밥|양)[^]{0,30}(적|작|모자|부족|아쉽)')},
      {'word': '웨이팅 있음', 'pattern': RegExp(r'(웨이팅|대기|줄)[^]{0,50}(길|많|심해|헬|필수)')},
      {'word': '직원 응대 아쉽', 'pattern': RegExp(r'(직원|알바|서빙|이모|아줌마|종업원)[^]{0,50}(불친절|느리|실수|반말|무시|치우|뺏)')},
      {'word': '주차 불편', 'pattern': RegExp(r'(주차|차)[^]{0,30}(힘들|없|불편|헬)')},
      {'word': '화장실 불편', 'pattern': RegExp(r'(화장실)[^]{0,30}(더럽|좁|멀|별로)')},
      {'word': '시끄러움', 'pattern': RegExp(r'(시끄|소란|정신없|시장통)')},
      {'word': '매장 환경', 'pattern': RegExp(r'(좁다|좁은|넓다|넓은|쾌적|답답|시원|덥다|더워|추워|춥다|환기|연기|냄새|에어컨|히터)')},
      {'word': '분위기/소음', 'pattern': RegExp(r'(조용|분위기|음악|노래|BGM|인테리어|조명|힙한|노포)')},
      {'word': '편의시설', 'pattern': RegExp(r'(남녀공용|테이블간격|의자|바닥|미끄|기름기|끈적|태블릿|키오스크|아기의자)')},
      {'word': '서비스 디테일', 'pattern': RegExp(r'(구워|잘라|리필|벨|호출|가져다|셀프|무한)')},
    ];

    final featurePatterns = [
      {'word': '뷰 좋음', 'pattern': RegExp(r'(뷰|전망|경치)\s*(가|이|는|도)?\s*(좋|예쁘|끝내|최고|맛집)')},
      {'word': '혼밥 가능', 'pattern': RegExp(r'(혼밥|혼자)[^]{0,30}(가능|좋|편해)')},
      {'word': '양이 많음', 'pattern': RegExp(r'(양)[^]{0,30}(많|푸짐|넉넉|배터)')},
      {'word': '가성비 좋음', 'pattern': RegExp(r'(가성비|가격)[^]{0,30}(좋|착해|저렴|합리)')},
      {'word': '친절함', 'pattern': RegExp(r'(친절|상냥|매너|서비스)')},
      {'word': '재료 신선', 'pattern': RegExp(r'(신선|재료|채소|해산물)[^]{0,30}(좋|싱싱)')},
      {'word': '국물 진국', 'pattern': RegExp(r'(국물|육수)[^]{0,30}(진국|깊|진하|끝내)')},
      {'word': '데이트 추천', 'pattern': RegExp(r'(데이트|소개팅|분위기|기념일|커플)')},
      {'word': '고기 맛집', 'pattern': RegExp(r'(고기|갈비|삼겹|육즙)[^]{0,30}(좋|맛있|부드|살살)')},
      {'word': '키오스크 없음', 'pattern': RegExp(r'(키오스크|주문)[^]{0,30}(없|안|직원)')},
      {'word': '고기 퀄리티', 'pattern': RegExp(r'(두툼|두껍|얇은|대패|마블링|비계|껍질|육즙)')},
      {'word': '식감 좋음', 'pattern': RegExp(r'(부들|야들|꼬들|쫀득|탱탱|아삭|사르르|녹아|숙성|활어|찰진|꾸덕|크리미|알덴테)')},
      {'word': '맛 디테일', 'pattern': RegExp(r'(불맛|불향|숯불향|훈연|감칠맛|간이|슴슴|짭짤|달달|매콤|얼큰|칼칼|시원|개운|웍질)')},
      {'word': '맛 비교', 'pattern': RegExp(r'(신라면|불닭|엽떡|마라탕|진라면|열라면|~보다|~만큼|~정도)')},
    ];

    final basicPatterns = [
      {'word': '맛있음', 'pattern': RegExp(r'(맛있|존맛|꿀맛|별미|굿)')},
      {'word': '분위기 좋음', 'pattern': RegExp(r'(분위기)[^]{0,30}(좋|깡패|예쁘|감성|레트로)')},
      {'word': '깨끗함', 'pattern': RegExp(r'(깨끗|청결|깔끔)')},
      {'word': '맛 준수함', 'pattern': RegExp(r'(맛|음식|간|반응)[^]{0,30}(준수|나쁘지|괜찮)')},
    ];

    // 태그 수집
    void addTags(List<Map<String, dynamic>> patterns, int priority) {
      for (var p in patterns) {
        if ((p['pattern'] as RegExp).hasMatch(normalizedText)) {
          tags.add({'word': p['word'], 'priority': priority});
        }
      }
    }

    addTags(fatalPatterns, 0);
    addTags(negativePatterns, 1);
    addTags(infoPatterns, 1);
    addTags(featurePatterns, 2);
    addTags(basicPatterns, 3);

    // 중복 제거 및 우선순위 정렬
    final seen = <String>{};
    final uniqueTags = tags.where((item) => seen.add(item['word'] as String)).toList();
    uniqueTags.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));

    return uniqueTags.take(3).map((e) => e['word'] as String).toList();
  }

  // ---------------------------------------------------------------------------
  // 2. NeedsFine 점수 계산 로직 (v11.1 Score Diet)
  // ---------------------------------------------------------------------------
  static Map<String, dynamic> calculateNeedsFineScore(
      String reviewText,
      double userRating,
      bool hasPhoto,
      ) {
    final safeText = reviewText.trim();
    // 텍스트 정제 (보이지 않는 문자 제거 등)
    final normalizedText = safeText.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), "").trim();
    final int textLen = normalizedText.length;

    // 1. 변수 추출
    final tags = extractReviewTags(normalizedText);
    final hasNegativeNuance = tags.any((t) => RegExp(r'(아쉽|별로|나쁘|사악|평범|쏘쏘|그닥|아니|창렬|없음|실패|후회)').hasMatch(t));
    final hasFact = RegExp(r'([0-9]+(분|시간|시|명|개|원|만원|천원)|한시간|두시간|반시간|오십분)').hasMatch(normalizedText);
    final hasContrast = RegExp(r'(하지만|그래도|불구하고|반면|~데|~지만|~한데|~나|~으나)').hasMatch(normalizedText);

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
    final comparativePatterns = [
      r'(신라면|불닭|엽떡|마라탕|진라면|열라면)',
      r'(~보다|~만큼|~정도)[^]{0,10}(매워|맵|짜|달|맛있|괜찮)'
    ];
    for (var p in comparativePatterns) { if (RegExp(p).hasMatch(normalizedText)) comparativeCount++; }

    // Cliché Count
    int clicheCount = 0;
    final clichePatterns = [
      r'(겉바속촉|입에서 녹아|육즙이? (팡팡|가득)|잡내(가)? (1도|전혀|하나도) (없|안)|사장님(이)? (왕)?친절|재방문 (의사|각|100)|강추|존맛탱|비주얼 (대박|굿|미쳤))'
    ];
    for (var p in clichePatterns) { if (RegExp(p).hasMatch(normalizedText)) clicheCount++; }

    // Narrative Count
    int narrativeCount = 0;
    final narrativePatterns = [
      r'(친구(랑|들이랑)|엄마(랑|가)|남편(이랑|이)|비가|늦게|실수로|우연히|지나가다|옆테이블|직원분이|~해서 좋았|~는 좀|다만|솔직히|개인적으로|의외로|운좋게)',
      r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러|벌써|매번)'
    ];
    for (var p in narrativePatterns) { if (RegExp(p).hasMatch(normalizedText)) narrativeCount++; }

    // Mitigated Count
    int mitigatedCount = 0;
    final mitigatedPatterns = [
      r'(걱정|고민|망설|의심|비싸|멀|힘들)[^]{0,20}(하지만|그런데|반전|오히려|불구하고|싹|해소|용서|이해|만족)'
    ];
    for (var p in mitigatedPatterns) { if (RegExp(p).hasMatch(normalizedText)) mitigatedCount++; }

    // Fatal / Malicious / Praise / Sensory / Sincerity counts
    int fatalCount = 0;
    final fatalP = [r'(바퀴|벌레|파리|모기|머리카락|이물질|털)[^]{0,50}(나왔|있|보였|다녀)', r'(잡아|치워|내돈)[^]{0,30}(달래|래|라니|라고|무시|아깝)', r'(욕|반말|싸우|시비)[^]{0,30}(하|했|듣)', r'(상한|쉰|썩은|비린|비릿|잡내|누린|물컹|딱딱|안익)[^]{0,30}(맛|냄새|식감|상태)'];
    for (var p in fatalP) { if (RegExp(p).hasMatch(normalizedText)) fatalCount++; }

    int maliciousCount = 0;
    final maliciousP = [r'(쓰레기|개판|망해|최악|극혐|폐업|기분.*잡쳐|더러워|미친)', r'(노맛|존노|퉤)', r'(니|너|새끼)[^]{0,20}(들|가)'];
    for (var p in maliciousP) { if (RegExp(p).hasMatch(normalizedText)) maliciousCount++; }

    int praiseCount = 0;
    final praiseP = [r'(맛있|최고|굿|짱|존맛|좋았|강추|대박|예술|환상)'];
    for (var p in praiseP) { if (RegExp(p).hasMatch(normalizedText)) praiseCount++; }

    int sensoryCount = 0;
    final sensoryP = [
      r'(쫄깃|바삭|물컹|딱딱|싱거|짜|매워|육즙|부드|고소|담백|비린|잡내|아삭|탱글|꾸덕|촉촉|질기|퍽퍽|시원|얼큰)',
      r'(두툼|두껍|얇은|대패|마블링|비계|껍질|기름진|느끼|부들|야들|꼬들|쫀득|사르르|녹아|질겅|푸석|흐물|눅눅)',
      r'(불맛|불향|숯불향|훈연|감칠맛|간이|슴슴|짭짤|달달|달짝|매콤|칼칼|개운|숙성|활어|찰진|진한|깊은|크리미|알덴테|퍼진|익힘|굽기|웍질|걸쭉|청량|목넘김|술도둑)'
    ];
    for (var p in sensoryP) { if (RegExp(p).hasMatch(normalizedText)) sensoryCount++; }

    int sincerityCount = 0;
    final sincerityP = [r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러)', r'(일주|한달|매주)[^]{0,20}(번|회)', r'(처음|첫)[^]{0,20}(방문|와보|먹어)', r'(메뉴|음식|반찬|국물|식감|튀김|상태|비주얼|양념|소스|간이|육즙)[^]{0,50}(설명|나오|구워|주시)'];
    for (var p in sincerityP) { if (RegExp(p).hasMatch(normalizedText)) sincerityCount++; }

    // 2. 품질 점수 (q_r_score) 계산
    double lengthFactor = textLen < 40 ? 0.6 : 0.8;
    double qrScore = log(textLen + 1) * lengthFactor;

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
    if (mitigatedCount > 0) qrScore -= 1.5;
    if (maliciousCount > 0) qrScore -= 3.0;
    if (fatalCount > 0) {
      double evidenceStrength = (textLen - 40) / 10;
      qrScore += max(-1.0, min(2.0, evidenceStrength));
    }

    // 사진 가산점 (UI상에서 사진이 있으면 +)
    if (hasPhoto) qrScore += 2.0;

    // 3. 신뢰도(Trust Level) 계산
    // sigmoid = 1 / (1 + exp(-0.4 * (x - 3.5)))
    double trustScore = 1 / (1 + exp(-0.4 * (qrScore - 3.5)));

    // 재방문 면제권
    final bool isRevisit = RegExp(r'(n번째|재방문|또|단골|원픽|자주|인생|최애|킬러|벌써|매번)').hasMatch(normalizedText);

    if (textLen < 40 && !isRevisit) {
      if (infoCount == 0 && comparativeCount == 0) {
        trustScore *= 0.7;
      }
    }

    // 너무 완벽한 리뷰 견제
    if (textLen >= 100 && userRating == 5.0 && !hasNegativeNuance && fatalCount == 0 && infoCount == 0 && clicheCount >= 2) {
      trustScore = min(trustScore, 0.8);
    }

    // 재방문 시 신뢰도 보정
    if (isRevisit) {
      trustScore = max(trustScore, 0.7);
    }

    trustScore = 0.1 + (trustScore * 0.88);

    // 4. 최종 점수 (Anchor Gravity)
    double baseAnchor = 2.5;

    if (fatalCount > 0) {
      baseAnchor = 1.0;
    } else if (maliciousCount > 0) {
      baseAnchor = 2.0;
    } else if (hasNegativeNuance && userRating >= 3.0) {
      baseAnchor = 2.5;
    } else {
      if (userRating >= 4.0) {
        bool isProven = (trustScore > 0.7 && textLen >= 50) || isRevisit;
        baseAnchor = isProven ? 3.5 : 2.5;
      } else if (userRating <= 2.0) {
        baseAnchor = 1.5;
      } else {
        baseAnchor = 2.5;
      }
    }

    double finalScore = (userRating * trustScore) + (baseAnchor * (1 - trustScore));

    // Platinum Cap
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
      'tags': tags,
      // UI 표시용 추가 정보
      'is_revisit': isRevisit,
      'info_count': infoCount,
      'narrative_count': narrativeCount,
    };
  }
}