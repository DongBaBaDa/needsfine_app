// 파일명: logic.ts ver 15.7 (Tracer + Dual Scope Fix)

/**
 * [NeedsFine Logic v15.7 - Tracer Edition]
 * - Debugging: 점수 계산 경로(Trace)와 기존 Tag를 동시에 기록.
 * - Logic Enforcement: 장문/단골이 점수 캡에 걸리는 현상 원천 봉쇄.
 * - Scope Fix: isFlavorless 등 핵심 변수 상위 스코프 선언 보장.
 */

// ==============================================================================
// 1. [Constants] 패턴 정의 (유지)
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

const INCENTIVE_PATTERNS = [
    /(리뷰|영수증)\s*(이벤트|참여|작성|약속)/,
    /(서비스|음료수|볶음밥|사리)[^]{0,10}(받았|주셨|주신|먹었)/,
    /(이벤트)[^]{0,10}(서비스|공짜|무료)/
];

const MALICIOUS_PATTERNS = [
    /(씨발|시발|개새끼|지랄|병신|망해|꺼져|퉤|니네|너네)/,
    /(미친|돌았)(?=\s*(놈|새끼|년|짓))/
];

const SERVICE_FAIL_PATTERNS = [
    /(불친절|싸가지|화내|화냄|짜증|무시|반말|던지|표정|교육|최악)[^]{0,10}(직원|사장|알바|서빙|응대)/,
    /(기분)[^]{0,10}(나빠|나쁨|잡침|상해|상함|더러)/
];

const GRATITUDE_PATTERNS = [
    /(잘|맛있게|배부르게)[^]{0,5}(먹었|먹고|갑니다|갔어요)/,
    /(감사|고마워|친절|최고|짱|굿|good|대박|빠름|빨라|신속)/
];

const POSITIVE_SLANG_PATTERNS = [
    /(맛|양|가격|가성비|비주얼|웨이팅|퀄리티|사장님|기름칠|분위기)[이가은는을를도\s]*(미쳤|돌았|개쩔|깡패|끝장|지리|오지)/,
    /(미친|돌았|개)[^]{0,5}(맛|존맛|꿀맛|대박|혜자)/,
    /(사장님)[^]{0,10}(미쳤)/
];

const QUALITY_FAIL_ABSOLUTE = [
    /(기름 둥둥|기름 범벅|쉰내|썩은|벌레|이물질|머리카락|재탕)/
];
const QUALITY_FAIL_CONDITIONAL = [
    '상한', '비린', '비릿', '잡내', '누린', '물컹', '안익', '식어', '딱딱', '말라', '오버쿡', '질겨', '질긴', '돼지 냄새', '느끼', '기름진', '짜서', '너무 짜', '간이 쎄'
];

const CRITICAL_HYGIENE_PATTERNS = [
    /(쓰레기|걸레|행주|음쓰)[^]{0,15}(손|만지|서빙|담아|그릇|위생)/,
    /(손|반찬|그릇)[^]{0,10}(안 씻|재사용|더러|지저분)/,
    /(위생)[^]{0,10}(개판|최악|별로|안좋|문제)/
];

export const KEYWORDS_PREFERENCE_MISMATCH = [
    /(밍밍|맹물|무슨 맛|니맛|내맛|싱거|심심|건강한 맛|우린 물|걸레 빤|화장품|비누|퐁퐁|세제|암모니아|겨드랑이|꼬린내)/,
    /(내 스타일|나랑|나에겐|저한테는|개인적|취향|호불호|이해|왜|모르겠|글쎄)/
];

const PERSONAL_REGRET_PATTERNS = [
    /(몸이|컨디션|배불러|배가 불러|시간이|멀어서|일정)[^]{0,15}(아쉽|못 먹|남겨|힘들)/,
    /(차|운전)[^]{0,15}(때문에|가져|라서)[^]{0,15}(아쉽|못 먹|참았)/
];

const ALCOHOL_CRAVING_PATTERNS = [
    /(차|운전|몸|약|건강)[^]{0,20}(때문에|이라)[^]{0,20}(술|소주|맥주|한잔)[^]{0,10}(못|참|아쉽|땡)/,
    /(술|소주|맥주|안주)[^]{0,10}(각|도둑|부르|땡|생각)/
];

const LOYALTY_PATTERNS = {
    ACTUAL: /(여기만|맨날|단골|n번째|또|매번|원픽|최애|항상|주기적|갈때마다|재방문입니다|[두세네오육칠팔구십]번째 방문)/,
    PROMISED: /(재방문|다시|또|오고|가고)[^]{0,10}(의사|싶|할|예정|각)/
};

const MEANINGFUL_SHORT_PATTERNS = [
    /(데이트|회식|모임|부모님|혼밥|안주|해장|소개팅|상견례)/,
    /(추천|강추|맛집|짱|굿|최고)/
];

const SPAM_PATTERNS = [
    /(매수|매도|양봉|음봉|손절|익절|차트|떡상|떡락|코인|비트|주식|투자|출장|조건만남|카톡ID|텔레그램|단톡방)/,
    /(하모닉|엘리어트|파동|반등|지지선|저항선|나스닥|코스피|리딩방)/,
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
    NEGATIVE: /(아쉽|별로|나쁘|사악|평범|쏘쏘|그닥|아니|창렬|없음|실패|후회|비싸|적다|작다|불친절|느리|최악|밍밍|비어|기대.*이하|느끼|기름진|기름기)/,
    PRICE_COMPLAINT: /(비싸|사악|창렬|가성비)/
};

const ANALYSIS_PATTERNS = {
    SENSORY: [
        /(쫄깃|바삭|물컹|딱딱|싱거|짜|매워|육즙|부드|고소|담백|비린|잡내|아삭|탱글|꾸덕|촉촉|질기|퍽퍽|시원|얼큰|불맛|불향|식감)/,
        /(두툼|마블링|기름진|느끼|야들|꼬들|쫀득|사르르|녹아|질겅|푸석|찰진)/,
        /(깊은|신선|풍미|감칠맛|간이|양념|소스|국물|육수|재료|토핑|퀄리티|조절|구수|진한|깔끔)/,
        /(존맛|꿀맛|맛있|맛나|미쳤|미친|도랏|개쩔|환상|예술|끝내|죽여|일품)/
    ],
    NARRATIVE: [
        /(친구|엄마|남편|가족|부모님|아이|애들|회식|모임|지인|동료|비가|늦게|실수로|우연히|지나가다|옆테이블|직원분이|솔직히|개인적으로|의외로|오랜만)/,
        /(n번째|재방문|또|단골|원픽|자주|인생|최애|벌써|매번|항상|예전|옛날|상륙|유명|본점)/
    ],
    ATMOSPHERE: [
        /(분위기|인테리어|조명|음악|뷰|경치|감성|깔끔|깨끗|넓|쾌적|시끄|조용|데이트|소개팅|위생|청결|매장|홀|룸|방|화장실|주차|완비|제격|안성맞춤)/
    ],
    SERVICE: [
        /(친절|응대|서비스|사장|직원|설명|구워|리필|인사|셀프바|반찬|제공|챙겨|주신|무한)/
    ],
    COMPARATIVE: [
        /(신라면|불닭|엽떡|마라탕|진라면|교촌|BBQ|BHC)/,
        /(보다|만큼|정도)[^]{0,10}(매워|맵|짜|달|맛있|괜찮|다르|않은)/
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

function isNegatedContext(text: string, keyword: string): boolean {
    const index = text.indexOf(keyword);
    if (index === -1) return false;
    const start = Math.max(0, index - 5);
    const end = Math.min(text.length, index + keyword.length + 15);
    const substring = text.substring(start, end);
    return /(안|않|없|못|잡았|잡혔|1도|일도|전혀|아니)/.test(substring);
}

export function extractReviewTags(text: string, isDeliveryFromApp: boolean): {
    tags: string[],
    isMalicious: boolean,
    isQualityFail: boolean,
    isServiceFail: boolean,
    isPreferenceMismatch: boolean,
    isPositiveSlang: boolean,
    isIncentive: boolean,
    isCriticalHygiene: boolean,
    isAiSuspect: boolean,
    isNegationPraise: boolean,
    isAlcoholCraving: boolean,
    isPersonalRegret: boolean
} {
    const normalizedText = (text || "").normalize("NFC");
    const extractedTags: { word: string; priority: number }[] = [];

    let isMalicious = false;
    let isQualityFail = false;
    let isServiceFail = false;
    let isPreferenceMismatch = false;
    let isPositiveSlang = false;
    let isIncentive = false;
    let isCriticalHygiene = false;
    let isAiSuspect = false;
    let isNegationPraise = false;
    let isAlcoholCraving = false;
    let isPersonalRegret = false;

    // Delivery: Only from App
    if (isDeliveryFromApp) {
        extractedTags.push({ word: '배달/포장', priority: 2 });
    }

    if (INCENTIVE_PATTERNS.some(p => p.test(normalizedText))) {
        isIncentive = true;
        extractedTags.push({ word: '리뷰이벤트', priority: 1 });
    }
    if (AI_PATTERNS.some(p => p.test(normalizedText))) {
        isAiSuspect = true;
    }
    if (POSITIVE_SLANG_PATTERNS.some(p => p.test(normalizedText))) {
        isPositiveSlang = true;
        extractedTags.push({ word: '극찬(Slang)', priority: 3 });
    }
    if (ALCOHOL_CRAVING_PATTERNS.some(p => p.test(normalizedText))) {
        isAlcoholCraving = true;
        extractedTags.push({ word: '술도둑', priority: 3 });
    }
    else if (PERSONAL_REGRET_PATTERNS.some(p => p.test(normalizedText))) {
        isPersonalRegret = true;
    }

    if (CRITICAL_HYGIENE_PATTERNS.some(p => p.test(normalizedText))) {
        isCriticalHygiene = true;
        extractedTags.push({ word: '위생 고발', priority: 0 });
    }

    if (SERVICE_FAIL_PATTERNS.some(p => p.test(normalizedText))) {
        isServiceFail = true;
        extractedTags.push({ word: '불친절/응대 불량', priority: 0 });
    }

    // Malicious
    if (!isPositiveSlang && !isCriticalHygiene && !isServiceFail) {
        if (MALICIOUS_PATTERNS.some(p => p.test(normalizedText))) {
            isMalicious = true;
            extractedTags.push({ word: '욕설/비방', priority: 0 });
        }
    }

    // Quality Fail
    QUALITY_FAIL_ABSOLUTE.forEach(p => {
        if (p.test(normalizedText)) {
            isQualityFail = true;
            extractedTags.push({ word: '위생/품질 불량', priority: 0 });
        }
    });
    QUALITY_FAIL_CONDITIONAL.forEach(keyword => {
        if (normalizedText.includes(keyword)) {
            if (isNegatedContext(normalizedText, keyword)) {
                isNegationPraise = true; // "잡내 없고" -> Negation Praise
            } else {
                isQualityFail = true;
                extractedTags.push({ word: '위생/품질 불량', priority: 0 });
            }
        }
    });

    // Preference Mismatch
    KEYWORDS_PREFERENCE_MISMATCH.forEach(p => {
        if (p.test(normalizedText)) {
            isPreferenceMismatch = true;
            extractedTags.push({ word: '취향 차이', priority: 1 });
        }
    });

    const basicPatterns = [
        { word: '웨이팅 있음', pattern: /(웨이팅|대기|줄)/ },
        { word: '가성비 아쉽', pattern: /(비싸|창렬|사악)/ },
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

    return {
        tags: uniqueTags, isMalicious, isQualityFail, isServiceFail, isPreferenceMismatch,
        isPositiveSlang, isIncentive, isCriticalHygiene, isAiSuspect,
        isNegationPraise, isAlcoholCraving, isPersonalRegret
    };
}

// ==============================================================================
// 3. 메인 로직
// ==============================================================================

export function calculateNeedsFineScore(reviewText: string, userRating: number, hasPhoto: boolean = false, isDelivery: boolean = false): NeedsFineResult {
    const safeText = reviewText || "";
    const safeRating = (typeof userRating === 'number' && !isNaN(userRating)) ? userRating : 3.0;

    let cleanText = safeText.normalize("NFC").replace(GIBBERISH_PATTERN, "").trim();
    const textLen = cleanText.length;

    // Debug Trace String
    let trace = "";

    // 1. Spam Filter (Strict)
    if (SPAM_PATTERNS.some(p => p.test(cleanText))) {
        return {
            needsfine_score: 1.0, trust_level: 0, authenticity: false, advertising_words: true, tags: ['내용부적합'],
            is_critical: false, is_hidden: true, is_malicious: false, debug_reason: "SPAM_DETECTED",
            logic_version: "v15.7_TRACE", entropy_score: 0
        };
    }

    if (!hasPhoto && textLen < 3) {
        return {
            needsfine_score: 1.0, trust_level: 0, authenticity: false, advertising_words: false, tags: ['내용부적합'],
            is_critical: false, is_hidden: true, is_malicious: false, debug_reason: "GRICE_QUANTITY_FAIL",
            logic_version: "v15.7_TRACE", entropy_score: 0
        };
    }

    // Keyword Counts
    let mainCount = 0, subCount = 0;
    KEYWORDS_MAIN.forEach(p => { if (p.test(cleanText)) mainCount++; });
    KEYWORDS_SUB.forEach(p => { if (p.test(cleanText)) subCount++; });
    const totalKeywords = mainCount + subCount;

    if (!hasPhoto && textLen >= 30 && totalKeywords === 0) {
        return {
            needsfine_score: 3.0, trust_level: 10, authenticity: false, advertising_words: false, tags: [],
            is_critical: false, is_hidden: true, is_malicious: false, debug_reason: "NO_CONTEXT",
            logic_version: "v15.7_TRACE", entropy_score: 0
        };
    }

    const isMeaningfulShort = MEANINGFUL_SHORT_PATTERNS.some(p => p.test(cleanText));

    // Short Text Anchor
    if (!hasPhoto && textLen < 10 && !isMeaningfulShort) {
        return {
            needsfine_score: 3.0, trust_level: 20, authenticity: false, advertising_words: false, tags: ['단답형'],
            is_critical: false, is_hidden: true, is_malicious: false, debug_reason: "SHORT_TEXT_ANCHOR",
            logic_version: "v15.7_TRACE", entropy_score: 0
        };
    }

    // Deep Analysis
    let sensoryCount = 0, narrativeCount = 0, comparativeCount = 0, clicheCount = 0;
    let atmosphereCount = 0, serviceCount = 0;

    ANALYSIS_PATTERNS.SENSORY.forEach(p => { if (p.test(cleanText)) sensoryCount++; });
    ANALYSIS_PATTERNS.NARRATIVE.forEach(p => { if (p.test(cleanText)) narrativeCount++; });
    ANALYSIS_PATTERNS.ATMOSPHERE.forEach(p => { if (p.test(cleanText)) atmosphereCount++; });
    ANALYSIS_PATTERNS.SERVICE.forEach(p => { if (p.test(cleanText)) serviceCount++; });
    ANALYSIS_PATTERNS.COMPARATIVE.forEach(p => { if (p.test(cleanText)) comparativeCount++; });
    ANALYSIS_PATTERNS.CLICHE.forEach(p => { if (p.test(cleanText)) clicheCount++; });

    const {
        tags, isMalicious, isQualityFail, isServiceFail, isPreferenceMismatch,
        isPositiveSlang, isIncentive, isCriticalHygiene, isAiSuspect,
        isNegationPraise, isAlcoholCraving, isPersonalRegret
    } = extractReviewTags(cleanText, isDelivery);

    let negativeWord = "";
    const hasNegative = SENTIMENT_PATTERNS.NEGATIVE.test(cleanText);
    if (hasNegative) {
        negativeWord = cleanText.match(SENTIMENT_PATTERNS.NEGATIVE)?.[0] || "Found";
    }

    const hasPositive = SENTIMENT_PATTERNS.POSITIVE.test(cleanText);
    const isActualLoyal = LOYALTY_PATTERNS.ACTUAL.test(cleanText);
    const isPromisedLoyal = LOYALTY_PATTERNS.PROMISED.test(cleanText);
    const hasContrast = LOGIC_PATTERNS.CONTRAST.test(cleanText);
    const hasWaiting = LOGIC_PATTERNS.WAITING.test(cleanText);

    // ----------------------------------------------------------------------------
    // 📡 Trust Calculation
    // ----------------------------------------------------------------------------
    const entropy = calculateInformationDensity(cleanText);

    let rawTrust = Math.log(textLen + 1) * 0.7;
    if (totalKeywords > 0) rawTrust += 0.8;
    if (sensoryCount > 0) rawTrust += 1.0;
    if (atmosphereCount > 0) rawTrust += 0.5;
    if (hasPhoto) rawTrust += 1.5;

    if (isActualLoyal) rawTrust += 1.5;
    if (isMeaningfulShort) rawTrust += 0.5;

    if (isCriticalHygiene || isServiceFail || isQualityFail) rawTrust += 5.0;
    if (isPreferenceMismatch) rawTrust += 1.0;
    if (isAlcoholCraving) rawTrust += 1.2;

    if (clicheCount >= 2 && sensoryCount === 0) rawTrust -= 1.5;
    if (entropy < 0.4) rawTrust -= 1.0;

    const sigmoid = (x: number) => 1 / (1 + Math.exp(-0.7 * (x - 3.5)));
    let trustScore = sigmoid(rawTrust);

    // [New] Slang Trust Boost (User Feedback: "Trust them more")
    if (isPositiveSlang) {
        trustScore = Math.max(trustScore, 0.5); // 신뢰도 최소 50% 보장
    }

    if (hasWaiting && sensoryCount === 0) trustScore = Math.min(trustScore, 0.6);
    if (textLen < 20 && !isMeaningfulShort) trustScore = Math.min(trustScore, 0.3);

    // AI Mercy
    if (isAiSuspect) {
        trustScore = Math.min(trustScore, 0.5);
    }
    // Incentive Penalty
    if (isIncentive) {
        trustScore = Math.min(trustScore, 0.5);
    }

    trustScore = Math.max(0.1, Math.min(0.99, trustScore));

    if (!hasPhoto) {
        trustScore = Math.min(trustScore, 0.9);
    }

    // ----------------------------------------------------------------------------
    // 💎 Score Calculation & Tracing
    // ----------------------------------------------------------------------------

    let predictedScore = 3.0;
    let scoreEvidenceWeight = trustScore;

    if (isMalicious || isCriticalHygiene || isQualityFail || isServiceFail) {
        predictedScore = 1.0;
        scoreEvidenceWeight = 0.95;
    }
    else if (isPositiveSlang || isAlcoholCraving) {
        predictedScore = 4.8;
    } else if (hasNegative) {
        const priceKeywords = SENTIMENT_PATTERNS.PRICE_COMPLAINT;
        const onlyPriceComplaint = priceKeywords.test(cleanText) && !/(맛없|별로|최악)/.test(cleanText);
        const isActuallyPraise = isNegationPraise && !/(맛없|별로|최악)/.test(cleanText);
        const isRegret = isPersonalRegret;

        if (isActuallyPraise || isAlcoholCraving) predictedScore = 4.5;
        else if (isRegret) predictedScore = 4.0;
        else if (onlyPriceComplaint && hasPositive) predictedScore = 4.0;
        else if (tags.includes('가성비 아쉽') && hasPositive) predictedScore = 3.8;
        else if (isActualLoyal && hasContrast) predictedScore = 3.5;
        else predictedScore = 2.0;
    } else if (hasPositive) {
        if (isActualLoyal) predictedScore = 4.9;
        else if (isPromisedLoyal) predictedScore = 4.2;
        else {
            const basePositive = (trustScore >= 0.7 || hasPhoto) ? 4.2 : 3.5;
            predictedScore = (atmosphereCount > 0 && sensoryCount === 0) ? 4.0 : basePositive;
        }
    }

    trace += `Pred[${predictedScore}]`;

    // 🌟 [Safety Net] 장문(70자 이상)이면 기본 점수 4.0 보장 (황금코다리 구제)
    // [Modified] 단골(ActualLoyal)이거나, 부정어가 있어도 장문이면 4.0 보장 (단, 품질 불량 제외)
    const isLongReview = textLen >= 70;
    if (isLongReview && (!hasNegative || isActualLoyal) && !isQualityFail && predictedScore < 4.0) {
        predictedScore = 4.0;
        trace += `->LongBoost[4.0]`;
    }

    // Bayesian Mixing
    let finalScore = 0;
    const isMismatch = Math.abs(safeRating - predictedScore) >= 1.5;

    // 1. Calculate weighted average first
    if (isMismatch && trustScore > 0.6) {
        finalScore = (safeRating * 0.2) + (predictedScore * 0.8);
    } else {
        finalScore = (safeRating * (1 - scoreEvidenceWeight)) + (predictedScore * scoreEvidenceWeight);
    }

    // 2. Apply Overrides/Floors
    if (isPreferenceMismatch && !isActualLoyal) {
        finalScore = 3.2;
    }
    else if (isActualLoyal && finalScore < 3.2 && predictedScore > 2.5) {
        finalScore = 3.2; // Floor for loyal
    }

    trace += `->Mix[${finalScore.toFixed(2)}]`;

    // ----------------------------------------------------------------------------
    // 🚧 [Cap Logic]
    // ----------------------------------------------------------------------------

    // 🚨 [Correct Scope Fix] 이 변수들을 외부 스코프로 빼야 ReferenceError가 발생하지 않습니다.
    const isFlavorless = sensoryCount === 0 && atmosphereCount === 0 && serviceCount === 0 && !isPositiveSlang;
    const isGratitudeOnly = GRATITUDE_PATTERNS.some(p => p.test(cleanText)) && sensoryCount === 0;

    // 1. Zero Tolerance
    if (isQualityFail || isCriticalHygiene || isServiceFail) {
        finalScore = Math.min(finalScore, 2.5);
        trace += `->ZeroTol[2.5]`;
    }
    else {
        // 2. FLAVORLESS DEFENSE + GRATITUDE CHECK + LENGTH SAFETY
        if ((isFlavorless || isGratitudeOnly) && !isActualLoyal && !isAlcoholCraving && !isLongReview) {
            finalScore = hasPhoto ? 3.2 : 3.0;
            trace += `->FlavorCap[${finalScore}]`;
        }
        else {
            // [Modified] Mixed Feeling Cap: 부정어 섞인 긍정 리뷰는 3.5점 제한 (User: "Mid-3s")
            if (hasNegative && hasPositive && finalScore > 3.5 && !isActualLoyal) {
                finalScore = 3.5;
                trace += `->MixedCap[3.5]`;
            }
            // Slang Cap: 신뢰도 낮은 슬랭은 3.8점 제한 (신뢰도 자체는 위에서 0.5로 상향됨)
            else if (isPositiveSlang && textLen < 50 && finalScore > 3.8) {
                finalScore = 3.8;
                trace += `->SlangCap[3.8]`;
            }
            // Incentive Cap
            else if (isIncentive && !isActualLoyal) {
                if (finalScore > 3.9) finalScore = 3.9;
                trace += `->IncentiveCap[3.9]`;
            }
            // Delivery Cap
            else if (isDelivery && sensoryCount === 0 && !isActualLoyal) {
                if (finalScore > 4.0) finalScore = 4.0;
                trace += `->DeliCap[4.0]`;
            }
            // Generic Cap (단문 긍정)
            else if (!isPositiveSlang && !isAlcoholCraving && !isNegationPraise && sensoryCount === 0 && atmosphereCount === 0 && !isActualLoyal && !isLongReview) {
                if (finalScore > 3.8) finalScore = 3.8;
                trace += `->GenericCap[3.8]`;
            }
            // Normal Positive Cap
            else if (!isPositiveSlang && !isAlcoholCraving && !isNegationPraise && !isActualLoyal) {
                if (finalScore > 4.6) finalScore = 4.6;
                trace += `->NormalCap[4.6]`;
            }
        }
    }

    if (isMalicious) {
        finalScore = 1.0;
        trustScore = 0.05;
        trace += `->Malicious[1.0]`;
    }

    finalScore = parseFloat(Math.max(1.0, Math.min(5.0, finalScore)).toFixed(1));
    const trustLevel = Math.round(trustScore * 100);
    const isHidden = trustLevel < 30;

    // [Restored Debug Classification Logic]
    let debugTag = "NORMAL";
    const lenTag = `(Len: ${textLen})`;
    const negTag = negativeWord ? `[Neg:${negativeWord}] ` : "";

    if (isMalicious) debugTag = `MALICIOUS`;
    else if (isCriticalHygiene) debugTag = `CRITICAL_HYGIENE`;
    else if (isServiceFail) debugTag = `SERVICE_FAIL`;
    else if (isQualityFail) debugTag = `QUALITY_FAIL`;
    else if (isFlavorless && !isLongReview) debugTag = `FLAVORLESS_CAP`;
    else if (isGratitudeOnly && !isLongReview) debugTag = `GRATITUDE_CAP`;
    else if (isAiSuspect) debugTag = `TURING_SUSPECT`;
    else if (isIncentive) debugTag = `INCENTIVE_CAP`;
    else if (isAlcoholCraving) debugTag = `ALCOHOL_CRAVING`;
    else if (isNegationPraise) debugTag = `NEGATION_PRAISE`;
    else if (isPositiveSlang && textLen < 50) debugTag = `SHORT_SLANG_CAP`;
    else if (isPositiveSlang) debugTag = `POSITIVE_SLANG`;
    else if (isPreferenceMismatch) debugTag = `PREFERENCE_RESPECT`;
    else if (isActualLoyal) debugTag = `ACTUAL_LOYALTY`;
    else if (isDelivery && sensoryCount === 0) debugTag = `DELIVERY_CAP`;
    else if (hasNegative && hasPositive && finalScore === 3.5) debugTag = `MIXED_CAP`;
    else if (!hasPhoto && trustLevel === 90) debugTag = `PHOTO_CONSTRAINT_CAP`;
    else if (isHidden) debugTag = `LOW_TRUST`;

    const debugReason = `TRACE: ${trace} | TAG: ${debugTag} ${negTag}${lenTag}`;

    return {
        needsfine_score: finalScore,
        trust_level: trustLevel,
        authenticity: trustLevel >= 75,
        advertising_words: false,
        tags: tags,
        is_critical: (finalScore <= 3.0 || isQualityFail || isCriticalHygiene || isServiceFail) && trustLevel >= 40,
        is_hidden: isHidden,
        is_malicious: isMalicious,
        debug_reason: debugReason,
        logic_version: "v15.7_TRACE",
        entropy_score: parseFloat(entropy.toFixed(2))
    };
}