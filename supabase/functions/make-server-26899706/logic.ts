// 파일명: logic.ts ver 14.3

/**
 * [NeedsFine Logic v14.3]
 * - Regional Gem Standard: 4.0점 이상은 맛/분위기/정보의 삼박자가 맞아야 함.
 * - Delivery Exception: 배달은 분위기 제외, 맛 묘사 필수.
 * - Loyalty Override: 찐단골은 취향 불일치 패널티 면제.
 * - Cap Logic: 묘사가 부족한 단순 긍정은 4.2점 초과 금지.
 */

// ==============================================================================
// 1. [Constants] 패턴 정의
// ==============================================================================

export const KEYWORDS_MAIN = [
    /(맛|국물|소스|고기|면|밥|양념|간|향|식감|메뉴|반찬|재료|신선|비린|짜|달|매워|뜨거|차가|회|스시|초밥|매운탕|질겨|질긴|부드러|바삭|눅눅)/,
    /(존맛|노맛|꿀맛|먹|마시|시키|주문|요리|음식|그릇|접시|포장|배달|양|토핑|씹|뜯|넘김|입맛)/,
];

export const KEYWORDS_SUB = [
    /(친절|서비스|사장|직원|알바|응대|인사|웨이팅|대기|예약|자리|테이블|룸|화장실|주차|매장|가게|식당|집|곳|위생|청결|더러|깨끗)/,
    /(가격|가성비|비싸|저렴|계산|결제|영수증|돈|원|인분)/,
    /(분위기|인테리어|점심|저녁|아침|식사|친구|가족|연인|데이트|회식|혼밥|방문|갔|와|오|가시|추천|비추|재방문)/
];

// [Delivery] 배달/포장 감지
const DELIVERY_PATTERNS = [
    /(배달|포장|요기요|쿠팡|배민|리뷰이벤트|서비스|집에서|시켜|주문)/
];

// 🚨 [Slang Filter]
const MALICIOUS_PATTERNS = [
    /(씨발|시발|개새끼|지랄|병신|쓰레기|망해|꺼져|퉤|니네|너네)/,
    /(미친|돌았)(?=\s*(놈|새끼|년|짓))/
];

const POSITIVE_SLANG_PATTERNS = [
    /(맛|양|가격|가성비|비주얼|웨이팅|퀄리티|사장님)[이가은는을를도\s]*(미쳤|돌았|개쩔|깡패|끝장|지리|오지)/,
    /(미친|돌았|개)[^]{0,5}(맛|존맛|꿀맛|대박|혜자)/,
    /(사장님)[^]{0,10}(미쳤)/
];

// [Quality Fail]
export const KEYWORDS_QUALITY_FAIL = [
    /(상한|쉰|썩은|비린|비릿|잡내|누린|물컹|안익|차가|식어|딱딱|말라|비계만|오버쿡|탄|탔|이물질|털|벌레)/,
    /(너무 짜|소금|짜서|간이 쎄|설탕|달아|물려|느끼|기름)/
];

// [Preference Mismatch]
export const KEYWORDS_PREFERENCE_MISMATCH = [
    /(밍밍|맹물|무슨 맛|니맛|내맛|싱거|심심|건강한 맛|우린 물|걸레|화장품|비누|퐁퐁|세제|암모니아|겨드랑이|꼬린내)/,
    /(내 스타일|나랑|나에겐|저한테는|개인적|취향|호불호|이해|왜|모르겠|글쎄)/
];

// [Loyalty]
const LOYALTY_PATTERNS = {
    ACTUAL: /(여기만|맨날|단골|n번째|또|매번|원픽|최애|항상|주기적|갈때마다)/, // 찐단골 (행동)
    PROMISED: /(재방문|다시|또|오고|가고)[^]{0,10}(의사|싶|할|예정|각)/ // 약속 (의사)
};

const MEANINGFUL_SHORT_PATTERNS = [
    /(데이트|회식|모임|부모님|혼밥|안주|해장|소개팅|상견례)/,
    /(추천|강추|맛집|짱|굿|최고)/
];

const SPAM_PATTERNS = [
    /(매수|매도|양봉|음봉|손절|익절|차트|떡상|떡락|코인|비트|주식|투자|출장|조건만남|카톡ID|텔레)/,
    /(하모닉|엘리어트|파동|패턴|반등|조정|지지선|저항선|나스닥|코스피)/,
    /(협찬|제공받아|체험단|원고료|소정의|서포터즈|광고)/
];

const AI_PATTERNS = [
    /(결론적으로|종합해보면|전반적으로|살펴보자면|요약하자면)/,
    /(매우 만족스러운 경험이었습니다|훌륭한 선택이 될 것입니다|방문해보시길 권장합니다)/,
    /(영업시간은.*주차는)/
];

const LOGIC_PATTERNS = {
    CONTRAST: /(는데|지만|불구하고|반면|그래도)/,
    WAITING: /(웨이팅|대기|줄|입장|캐치테이블|테이블링)/
};

const SENTIMENT_PATTERNS = {
    POSITIVE: /(맛있|존맛|꿀맛|최고|굿|좋았|강추|대박|예술|환상|친절|신선|부드러|잘|깔끔|만족|근본|엄청)/,
    NEGATIVE: /(아쉽|별로|나쁘|사악|평범|쏘쏘|그닥|아니|창렬|없음|실패|후회|비싸|적다|작다|불친절|느리|최악|밍밍|비어|기대.*이하)/
};

const ANALYSIS_PATTERNS = {
    SENSORY: [
        /(쫄깃|바삭|물컹|딱딱|싱거|짜|매워|육즙|부드|고소|담백|비린|잡내|아삭|탱글|꾸덕|촉촉|질기|퍽퍽|시원|얼큰)/,
        /(두툼|마블링|기름진|느끼|야들|꼬들|쫀득|사르르|녹아|질겅|푸석|불맛|불향|감칠맛|슴슴|칼칼|개운|숙성|활어|찰진)/
    ],
    NARRATIVE: [
        /(친구(랑|들이랑)|엄마(랑|가)|남편(이랑|이)|비가|늦게|실수로|우연히|지나가다|옆테이블|직원분이|솔직히|개인적으로|의외로)/,
        /(n번째|재방문|또|단골|원픽|자주|인생|최애|벌써|매번)/
    ],
    // [New] Atmosphere & Service (4.0점 자격 심사용)
    ATMOSPHERE: [
        /(분위기|인테리어|조명|음악|뷰|경치|감성|깔끔|깨끗|넓|쾌적|시끄|조용)/
    ],
    SERVICE: [
        /(친절|응대|서비스|사장|직원|설명|구워|리필|인사)/
    ],
    COMPARATIVE: [
        /(신라면|불닭|엽떡|마라탕|진라면|교촌|BBQ|BHC)/,
        /(보다|만큼|정도)[^]{0,10}(매워|맵|짜|달|맛있|괜찮)/
    ],
    CLICHE: [
        /(겉바속촉|입에서 녹아|육즙이? (팡팡|가득)|잡내(가)? (1도|전혀|하나도) (없|안)|사장님(이)? (왕)?친절|재방문 (의사|각|100)|강추|존맛탱|비주얼 (대박|굿|미쳤))/
    ]
};

const GIBBERISH_PATTERN = /([ㄱ-ㅎㅏ-ㅣ가-힣a-zA-Z])\1{2,}/g;

export interface NeedsFineResult {
    needsfine_score: number;
    trust_level: number;
    authenticity: boolean;
    advertising_words: boolean;
    tags: string[];
    is_critical: boolean;
    is_hidden: boolean;
    is_malicious: boolean;
    debug_reason: string;
    logic_version: string;
    entropy_score?: number;
}

// ==============================================================================
// 2. 헬퍼 함수
// ==============================================================================

function calculateInformationDensity(text: string): number {
    if (!text) return 0;
    const words = text.split(/\s+/).filter(w => w.length > 1);
    const totalWords = words.length;
    if (totalWords < 3) return 0.5;
    const uniqueWords = new Set(words).size;
    let density = uniqueWords / totalWords;
    return Math.min(1.0, density);
}

export function extractReviewTags(text: string): { tags: string[], isMalicious: boolean, isQualityFail: boolean, isPreferenceMismatch: boolean, isPositiveSlang: boolean, isDelivery: boolean } {
    const normalizedText = (text || "").normalize("NFC");
    const extractedTags: { word: string; priority: number }[] = [];
    let isMalicious = false;
    let isQualityFail = false;
    let isPreferenceMismatch = false;
    let isPositiveSlang = false;
    let isDelivery = false;

    // Delivery Check
    if (DELIVERY_PATTERNS.some(p => p.test(normalizedText))) {
        isDelivery = true;
        extractedTags.push({ word: '배달/포장', priority: 2 });
    }

    // Positive Slang
    if (POSITIVE_SLANG_PATTERNS.some(p => p.test(normalizedText))) {
        isPositiveSlang = true;
        extractedTags.push({ word: '극찬(Slang)', priority: 3 });
    }

    // Malicious
    if (!isPositiveSlang) {
        if (MALICIOUS_PATTERNS.some(p => p.test(normalizedText))) {
            isMalicious = true;
            extractedTags.push({ word: '욕설/비방', priority: 0 });
        }
    }

    // Quality Fail
    KEYWORDS_QUALITY_FAIL.forEach(p => {
        if (p.test(normalizedText)) {
            isQualityFail = true;
            extractedTags.push({ word: '위생/품질 불량', priority: 0 });
        }
    });

    // Preference Mismatch
    KEYWORDS_PREFERENCE_MISMATCH.forEach(p => {
        if (p.test(normalizedText)) {
            isPreferenceMismatch = true;
            extractedTags.push({ word: '취향 차이', priority: 1 });
        }
    });

    // Basic Tags
    const basicPatterns = [
        { word: '웨이팅 있음', pattern: /(웨이팅|대기|줄)/ },
        { word: '가성비 아쉽', pattern: /(비싸|창렬)/ },
        { word: '맛있음', pattern: /(맛있|존맛|최고)/ }
    ];
    basicPatterns.forEach(p => {
        if (p.pattern.test(normalizedText)) extractedTags.push({ word: p.word, priority: 2 });
    });

    const seen = new Set<string>();
    const uniqueTags = extractedTags
        .filter(item => !seen.has(item.word) && seen.add(item.word))
        .sort((a, b) => a.priority - b.priority)
        .map(t => t.word)
        .slice(0, 3);

    return { tags: uniqueTags, isMalicious, isQualityFail, isPreferenceMismatch, isPositiveSlang, isDelivery };
}

function createSpamResult(reason: string): NeedsFineResult {
    return {
        needsfine_score: 1.0,
        trust_level: 0,
        authenticity: false,
        advertising_words: true,
        tags: ['내용부적합'],
        is_critical: false,
        is_hidden: true,
        is_malicious: false,
        debug_reason: reason,
        logic_version: "v14.3_GEM"
    };
}

// ==============================================================================
// 3. 메인 로직: 니즈파인 점수 계산 (v14.3)
// ==============================================================================

export function calculateNeedsFineScore(reviewText: string, userRating: number, hasPhoto: boolean = false): NeedsFineResult {
    const safeText = reviewText || "";
    const safeRating = (typeof userRating === 'number' && !isNaN(userRating)) ? userRating : 3.0;

    let cleanText = safeText.normalize("NFC").replace(GIBBERISH_PATTERN, "").trim();
    const textLen = cleanText.length;

    // 1. [Grice & Turing] 1차 필터링
    if (SPAM_PATTERNS.some(p => p.test(cleanText))) return createSpamResult("GRICE_RELATION_FAIL");
    if (AI_PATTERNS.some(p => p.test(cleanText))) return createSpamResult("TURING_AI_DETECTED");
    if (!hasPhoto && textLen < 3) return createSpamResult("GRICE_QUANTITY_FAIL");

    // 키워드 카운팅
    let mainCount = 0, subCount = 0;
    KEYWORDS_MAIN.forEach(p => { if (p.test(cleanText)) mainCount++; });
    KEYWORDS_SUB.forEach(p => { if (p.test(cleanText)) subCount++; });
    const totalKeywords = mainCount + subCount;

    if (!hasPhoto && textLen >= 30 && totalKeywords === 0) return createSpamResult("NO_CONTEXT");

    const isMeaningfulShort = MEANINGFUL_SHORT_PATTERNS.some(p => p.test(cleanText));

    // Case: 아주 짧은 텍스트 ("맛있어요")
    if (!hasPhoto && textLen < 10 && !isMeaningfulShort) {
        return {
            needsfine_score: 3.0,
            trust_level: 20,
            authenticity: false,
            advertising_words: false,
            tags: ['단답형'],
            is_critical: false,
            is_hidden: true,
            is_malicious: false,
            debug_reason: "SHORT_TEXT_ANCHOR",
            logic_version: "v14.3_GEM"
        };
    }

    // [Deep Analysis]
    let sensoryCount = 0, narrativeCount = 0, comparativeCount = 0, clicheCount = 0;
    let atmosphereCount = 0, serviceCount = 0; // New Counters

    ANALYSIS_PATTERNS.SENSORY.forEach(p => { if (p.test(cleanText)) sensoryCount++; });
    ANALYSIS_PATTERNS.NARRATIVE.forEach(p => { if (p.test(cleanText)) narrativeCount++; });
    ANALYSIS_PATTERNS.ATMOSPHERE.forEach(p => { if (p.test(cleanText)) atmosphereCount++; });
    ANALYSIS_PATTERNS.SERVICE.forEach(p => { if (p.test(cleanText)) serviceCount++; });
    ANALYSIS_PATTERNS.COMPARATIVE.forEach(p => { if (p.test(cleanText)) comparativeCount++; });
    ANALYSIS_PATTERNS.CLICHE.forEach(p => { if (p.test(cleanText)) clicheCount++; });

    const { tags, isMalicious, isQualityFail, isPreferenceMismatch, isPositiveSlang, isDelivery } = extractReviewTags(cleanText);
    const hasNegative = SENTIMENT_PATTERNS.NEGATIVE.test(cleanText);
    const hasPositive = SENTIMENT_PATTERNS.POSITIVE.test(cleanText);

    // Loyalty Logic
    const isActualLoyal = LOYALTY_PATTERNS.ACTUAL.test(cleanText);
    const isPromisedLoyal = LOYALTY_PATTERNS.PROMISED.test(cleanText);

    const hasContrast = LOGIC_PATTERNS.CONTRAST.test(cleanText);
    const hasWaiting = LOGIC_PATTERNS.WAITING.test(cleanText);

    // ----------------------------------------------------------------------------
    // 📡 신뢰도(Trust) 계산
    // ----------------------------------------------------------------------------
    const entropy = calculateInformationDensity(cleanText);

    let rawTrust = Math.log(textLen + 1) * 0.7;
    if (totalKeywords > 0) rawTrust += 0.8;
    if (sensoryCount > 0) rawTrust += 1.0;
    if (atmosphereCount > 0) rawTrust += 0.5; // 분위기 언급 시 신뢰도 상승
    if (hasPhoto) rawTrust += 1.5;

    if (isActualLoyal) rawTrust += 1.5; // 찐단골 보너스 강화
    if (isMeaningfulShort) rawTrust += 0.5;

    if (clicheCount >= 2 && sensoryCount === 0) rawTrust -= 1.5;
    if (entropy < 0.4) rawTrust -= 1.0;

    const sigmoid = (x: number) => 1 / (1 + Math.exp(-0.7 * (x - 3.5)));
    let trustScore = sigmoid(rawTrust);

    // [Trust Constraints]

    // 🚨 Logic Fix: 찐단골(Actual)이면 취향불일치(Preference) 무시 (단골의 면책권)
    const effectivePreferenceMismatch = isPreferenceMismatch && !isActualLoyal;

    if (effectivePreferenceMismatch) trustScore = 0.3;
    if (isQualityFail) trustScore = Math.max(trustScore, 0.85);

    if (hasWaiting && sensoryCount === 0) trustScore = Math.min(trustScore, 0.6);
    if (textLen < 20 && !isMeaningfulShort) trustScore = Math.min(trustScore, 0.3);

    trustScore = Math.max(0.1, Math.min(0.99, trustScore));

    // ----------------------------------------------------------------------------
    // 💎 점수 계산 & 4.0점 자격 심사 (Trifecta)
    // ----------------------------------------------------------------------------

    let predictedScore = 3.0;
    let scoreEvidenceWeight = trustScore;

    if (isMalicious) {
        predictedScore = 1.0;
    } else if (isQualityFail) {
        predictedScore = 1.0;
        scoreEvidenceWeight = 0.95;
    } else if (isPositiveSlang) {
        predictedScore = 4.8;
    } else if (hasNegative) {
        if (tags.includes('가성비 아쉽') && hasPositive) predictedScore = 3.8;
        else if (isActualLoyal && hasContrast) predictedScore = 3.2;
        else predictedScore = 2.0;
    } else if (hasPositive) {
        // [New Score Prediction]
        if (isActualLoyal) predictedScore = 4.9; // 찐단골
        else if (isPromisedLoyal) predictedScore = 4.2; // "또 올게요" -> 4.2로 하향 (거품 제거)
        else {
            // 일반 긍정 예측
            predictedScore = (trustScore >= 0.7 || hasPhoto) ? 4.2 : 3.5;
        }
    }

    // [Bayesian Mixing]
    let finalScore = 0;
    const isMismatch = Math.abs(safeRating - predictedScore) >= 1.5;

    if (effectivePreferenceMismatch) {
        finalScore = 3.0;
    } else if (isMismatch && trustScore > 0.6) {
        finalScore = (safeRating * 0.2) + (predictedScore * 0.8);
    } else {
        finalScore = (safeRating * (1 - scoreEvidenceWeight)) + (predictedScore * scoreEvidenceWeight);
    }

    // ----------------------------------------------------------------------------
    // 🚧 [Cap Logic: The Regional Gem Gatekeeper]
    // ----------------------------------------------------------------------------

    // Cap 1. 품질 불량은 회복 불가
    if (isQualityFail) finalScore = Math.min(finalScore, 2.0);

    // Cap 2. 찐단골이나 극찬이 아닌 경우의 상한선 심사
    if (!isActualLoyal && !isPositiveSlang) {

        let maxCap = 4.6; // 기본 상한선

        // [Delivery Mode]
        if (isDelivery) {
            // 배달은 '맛' 묘사가 생명. 없으면 4.0을 넘을 수 없음.
            if (sensoryCount === 0) maxCap = 4.0;
        }
        // [Dine-in Mode]
        else {
            // 지역 맛집(4.2 초과) 조건: 맛(Sensory) + (분위기 or 서비스) + 충분한 길이(정보)
            const hasAtmosphereOrService = atmosphereCount > 0 || serviceCount > 0;
            const hasDetail = sensoryCount > 0;
            const hasInfo = textLen >= 40 || isMeaningfulShort;

            // 하나라도 부족하면 4.2점에서 컷 (리뷰 13, 14번 방어)
            if (!hasDetail || !hasAtmosphereOrService || !hasInfo) {
                maxCap = 4.2;
            }
        }

        // 최종 점수가 상한선을 넘으면 깎음
        if (finalScore > maxCap) finalScore = maxCap;
    }

    // Malicious Handling
    if (isMalicious) {
        finalScore = 1.0;
        trustScore = 0.05;
    }

    // Final Output
    finalScore = parseFloat(Math.max(1.0, Math.min(5.0, finalScore)).toFixed(1));
    const trustLevel = Math.round(trustScore * 100);
    const isHidden = trustLevel < 30;

    // Debugging
    let debugReason = "NORMAL";
    if (isMalicious) debugReason = "MALICIOUS";
    else if (isPositiveSlang) debugReason = "POSITIVE_SLANG";
    else if (isQualityFail) debugReason = "QUALITY_FAIL";
    else if (effectivePreferenceMismatch) debugReason = "PREFERENCE_MISMATCH";
    else if (isActualLoyal) debugReason = "ACTUAL_LOYALTY";
    else if (isDelivery && sensoryCount === 0) debugReason = "DELIVERY_NO_DETAIL"; // 배달인데 묘사 없음
    else if (!isActualLoyal && finalScore >= 4.0 && sensoryCount === 0) debugReason = "LACK_OF_SENSORY_CAP"; // 4점대인데 묘사 부족
    else if (isHidden) debugReason = "LOW_TRUST";

    return {
        needsfine_score: finalScore,
        trust_level: trustLevel,
        authenticity: trustLevel >= 75,
        advertising_words: false,
        tags: tags,
        is_critical: (finalScore <= 3.0 || isQualityFail) && trustLevel >= 40,
        is_hidden: isHidden,
        is_malicious: isMalicious,
        debug_reason: debugReason,
        logic_version: "v14.3_GEM",
        entropy_score: parseFloat(entropy.toFixed(2))
    };
}
