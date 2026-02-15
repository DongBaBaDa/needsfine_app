/* eslint-disable no-useless-escape */

/**
 * NeedsFine v17.3.0
 * - POLICY A (forced):
 *   userRating >= 4.0 => final score cannot go below 3.0 (unconditional).
 *
 * - POLICY B (long mixed):
 *   If long review AND has both pos & neg evidence (and not strongNeg),
 *   baseline = userRating - 1.2
 *   candidate = baseline + (positive-only gain * multiplier)
 *   finalRawScore = max(regularScore, candidate)
 *
 * - TRUST caps:
 *   trust <= 99
 *   if hasPhoto === false => trust <= 92
 */

export const NEEDSFINE_VERSION = "17.3.0";

export type AspectKey =
    | "taste"
    | "service"
    | "value"
    | "revisit"
    | "hygiene"
    | "ambience"
    | "wait"
    | "portion"
    | "overall";

export type Polarity = "POS" | "NEG" | "MIXED" | "NEUTRAL";

export interface ReviewInput {
    text: string;
    userRating?: number; // 1.0 ~ 5.0
    hasPhoto?: boolean; // default false
}

export interface EvidenceHit {
    aspect: AspectKey;
    polarity: "POS" | "NEG";
    weight: number;
    cue: string;
    snippet: string;
    ruleId: string;
    start: number;
    end: number;
}

export interface TagResult {
    aspect: AspectKey;
    label: string;
    mentioned: boolean;
    polarity: Polarity;
    strength: number;
}

export interface StrongNegativeInfo {
    flag: boolean;
    type:
    | "HYGIENE_CRITICAL"
    | "FRAUD_PRICE"
    | "NEVER_AGAIN"
    | "SERVICE_EXTREME"
    | "GENERIC_EXTREME"
    | "NONE";
    ceiling: number;
    matched: string[];
}

export interface NeedsFineAnalysis {
    needsFineScore: number; // 1.0~5.0
    trust: number; // 0~99
    label: string;
    tags: TagResult[];
    evidence: {
        positive: EvidenceHit[];
        negative: EvidenceHit[];
        strongNegative: StrongNegativeInfo;
    };
    debug?: {
        normalized: string;
        masked: string;
        appliedCaps: string[];
        baseScore: number;
        scoreMode: "REGULAR" | "LONG_MIXED_POS_ONLY";
        rawScore: number;
        detailBonus: number;
        synergyBonus: number;
        caveatAttenuated: boolean;
        userRating?: number;
        userRatingCapApplied?: number;
        trustCaps: string[];
        posAxes: AspectKey[];
        negAxes: AspectKey[];
        feature: Record<string, unknown>;
    };
}

export interface AnalyzeOptions {
    debug?: boolean;
}

export interface EngineConfig {
    baseScore: number;
    roundingStep: number;
    snippetRadius: number;

    posCoef: Record<AspectKey, number>;
    negCoef: Record<AspectKey, number>;
    posScale: Record<AspectKey, number>;
    negScale: Record<AspectKey, number>;

    aspectPosThreshold: number;
    aspectNegThreshold: number;

    // gates
    minPosAxesFor4: number;
    minPosEvidenceFor4: number;
    requireCoreAxisFor4: boolean;
    coreAxes: AspectKey[];
    capIfGateFail4: number;

    minPosAxesFor45: number;
    capIfGateFail45: number;
    maxScore: number;
    minLenFor45: number;

    // intensity/contrast
    recencyBoost: number;
    contrastPostBoost: number;
    contrastPrePenalty: number;
    intensityBoost: number;
    hedgePenalty: number;
    exclamBoost: number;
    maxWeightMultiplier: number;

    // detail bonus
    maxDetailBonus: number;

    // minor caveat attenuation (regular mode)
    caveatAspects: AspectKey[];
    caveatNegAttenuation: number;
    caveatApplyTastePosMin: number;
    caveatApplyNegNonCaveatMax: number;

    // TRUST caps
    trustMax: number; // 99
    trustMaxNoPhoto: number; // 92

    // SCORE caps by user rating (max caps)
    scoreCapUserRatingLt2: number; // 2.2
    scoreCapUserRatingLt3: number; // 3.6

    // Optional lift
    enableUserRatingLift: boolean;
    ratingLiftPerStar: number;
    ratingLiftMax: number;
    ratingLiftMinLen: number;
    ratingLiftMinPosEvidence: number;

    // POLICY A: forced floor for high-rating
    enableHighRatingFloor: boolean;
    highRatingFloorMinUserRating: number; // 4.0
    highRatingFloorMinScore: number; // 3.0

    // POLICY B: long mixed
    enableLongMixedMode: boolean;
    longMixedMinLenNoSpace: number; // 장문 기준
    longMixedRatingDelta: number; // 1.2
    longMixedPosGainMultiplier: number; // 0.55~0.70 권장
    longMixedMinPosEvidence: number;
    longMixedMinNegEvidence: number;
}

export const DEFAULT_CONFIG: EngineConfig = {
    baseScore: 2.78,
    roundingStep: 0.1,
    snippetRadius: 14,

    // 가점 작게, 감점 크게(비대칭)
    posCoef: {
        taste: 0.74,
        service: 0.42,
        value: 0.32,
        revisit: 0.28,
        hygiene: 0.22,
        ambience: 0.32,
        wait: 0.14,
        portion: 0.24,
        overall: 0.28,
    },
    negCoef: {
        taste: 0.95,
        service: 0.68,
        value: 0.50,
        revisit: 0.80,
        hygiene: 0.95,
        ambience: 0.38,
        wait: 0.40,
        portion: 0.28,
        overall: 0.40,
    },

    posScale: {
        taste: 1.05,
        service: 0.95,
        value: 0.95,
        revisit: 0.88,
        hygiene: 0.85,
        ambience: 0.95,
        wait: 0.95,
        portion: 0.95,
        overall: 1.0,
    },
    negScale: {
        taste: 1.25,
        service: 1.05,
        value: 1.10,
        revisit: 1.05,
        hygiene: 0.95,
        ambience: 1.05,
        wait: 1.0,
        portion: 1.0,
        overall: 1.10,
    },

    aspectPosThreshold: 0.45,
    aspectNegThreshold: 0.45,

    minPosAxesFor4: 2,
    minPosEvidenceFor4: 2,
    requireCoreAxisFor4: true,
    coreAxes: ["taste", "service", "value", "hygiene"],
    capIfGateFail4: 3.9,

    minPosAxesFor45: 3,
    capIfGateFail45: 4.4,
    maxScore: 4.65,
    minLenFor45: 120,

    recencyBoost: 0.05,
    contrastPostBoost: 0.12,
    contrastPrePenalty: 0.12,
    intensityBoost: 1.22,
    hedgePenalty: 0.86,
    exclamBoost: 1.08,
    maxWeightMultiplier: 1.45,

    maxDetailBonus: 0.28,

    caveatAspects: ["wait", "ambience"],
    caveatNegAttenuation: 0.62,
    caveatApplyTastePosMin: 0.90,
    caveatApplyNegNonCaveatMax: 0.35,

    trustMax: 99,
    trustMaxNoPhoto: 92,

    scoreCapUserRatingLt2: 2.2,
    scoreCapUserRatingLt3: 3.6,

    enableUserRatingLift: true,
    ratingLiftPerStar: 0.18,
    ratingLiftMax: 0.38,
    ratingLiftMinLen: 24,
    ratingLiftMinPosEvidence: 2,

    // ✅ POLICY A (forced)
    enableHighRatingFloor: true,
    highRatingFloorMinUserRating: 4.0,
    highRatingFloorMinScore: 3.0,

    // ✅ POLICY B
    enableLongMixedMode: true,
    longMixedMinLenNoSpace: 120,
    longMixedRatingDelta: 1.2,
    longMixedPosGainMultiplier: 0.65,
    longMixedMinPosEvidence: 1,
    longMixedMinNegEvidence: 1,
};

// -------------------------
// Helpers
// -------------------------
function clamp(min: number, max: number, v: number): number {
    return Math.max(min, Math.min(max, v));
}

function roundToStep(v: number, step: number): number {
    const inv = 1 / step;
    return Math.round(v * inv) / inv;
}

function satTanh(x: number): number {
    return Math.tanh(x);
}

function normalizeText(input: string): string {
    const t0 = String(input ?? "");
    return t0
        .replace(/\u200b/g, " ")
        .toLowerCase()
        .replace(/(ㅋ){3,}/g, "ㅋㅋ")
        .replace(/(ㅎ){3,}/g, "ㅎㅎ")
        .replace(/(ㅠ|ㅜ){2,}/g, "ㅠㅠ")
        .replace(/\s+/g, " ")
        .trim();
}

function hangulRatio(text: string): number {
    if (!text) return 0;
    const h = (text.match(/[가-힣]/g) || []).length;
    return h / Math.max(1, text.length);
}

function makeSnippet(text: string, start: number, end: number, radius: number): string {
    const s = Math.max(0, start - radius);
    const e = Math.min(text.length, end + radius);
    return text.slice(s, e).trim();
}

function overlaps(a: { start: number; end: number }, b: { start: number; end: number }): boolean {
    return a.start < b.end && b.start < a.end;
}

function parseUserRating(v: unknown): number | undefined {
    if (typeof v === "number" && Number.isFinite(v)) return clamp(0, 5, v);
    const s = String(v ?? "").trim();
    if (!s) return undefined;
    const m = s.match(/(\d+(?:\.\d+)?)/);
    if (!m) return undefined;
    const n = Number(m[1]);
    if (!Number.isFinite(n)) return undefined;
    return clamp(0, 5, n);
}

// -------------------------
// Sentence + contrast
// -------------------------
const CONTRAST_WORDS: RegExp[] = [/하지만/g, /그런데/g, /다만/g, /근데/g, /반면/g, /대신/g, /그래도/g];

function buildSentenceInfo(text: string) {
    const starts: number[] = [0];
    const boundaries = /[.!?]|[\n\r]+/g;
    let m: RegExpExecArray | null;
    while ((m = boundaries.exec(text)) !== null) {
        const idx = m.index + m[0].length;
        let j = idx;
        while (j < text.length && text[j] === " ") j++;
        if (j < text.length) starts.push(j);
    }
    const uniq = Array.from(new Set(starts)).sort((a, b) => a - b);

    const sentences = uniq.map((s, i) => {
        const e = i + 1 < uniq.length ? uniq[i + 1] : text.length;
        const seg = text.slice(s, e);
        let contrastAbs: number | null = null;
        for (const rx of CONTRAST_WORDS) {
            rx.lastIndex = 0;
            const mm = rx.exec(seg);
            if (mm) {
                const abs = s + mm.index;
                if (contrastAbs === null || abs < contrastAbs) contrastAbs = abs;
            }
        }
        return { start: s, end: e, contrastAbs };
    });

    return { sentences };
}

function findSentenceIndex(sentences: { start: number; end: number }[], pos: number): number {
    let lo = 0;
    let hi = sentences.length - 1;
    while (lo <= hi) {
        const mid = (lo + hi) >> 1;
        const s = sentences[mid];
        if (pos < s.start) hi = mid - 1;
        else if (pos >= s.end) lo = mid + 1;
        else return mid;
    }
    return Math.max(0, Math.min(sentences.length - 1, lo));
}

// -------------------------
// Neutralizers (meta negation masking)
// -------------------------
const NEUTRALIZERS: { key: string; rx: RegExp }[] = [
    {
        key: "meta_negated_taste_neg",
        rx: /(맛없|노맛|비추|최악)\s*(?:다는|단)?\s*(?:얘기|말|소문|리뷰|후기|평)(?:가|는|도|은|이)?\s*(?:없|없었|없더|없는데|없다)/giu,
    },
    {
        key: "meta_negated_service_neg",
        rx: /(불\s*친절|불친절|서비스\s*최악)\s*(?:하다는|하단)?\s*(?:얘기|말|소문|리뷰|후기|평)(?:가|는|도|은|이)?\s*(?:없|없었|없더|없는데|없다)/giu,
    },
    {
        key: "meta_negated_hygiene_neg",
        rx: /(위생|더럽|벌레|이물질|오염|악취)\s*(?:관련|문제)?\s*(?:얘기|말|소문|리뷰|후기|평)(?:가|는|도|은|이)?\s*(?:없|없었|없더|없는데|없다)/giu,
    },
];

function collectNeutralizedSpans(text: string) {
    const spans: { start: number; end: number; key: string; txt: string }[] = [];
    for (const n of NEUTRALIZERS) {
        n.rx.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = n.rx.exec(text)) !== null) {
            spans.push({ start: m.index, end: m.index + m[0].length, key: n.key, txt: m[0] });
        }
    }
    return spans.sort((a, b) => a.start - b.start);
}

function maskSpans(text: string, spans: { start: number; end: number }[]): string {
    if (spans.length === 0) return text;
    const arr = text.split("");
    for (const sp of spans) {
        for (let i = sp.start; i < sp.end && i < arr.length; i++) arr[i] = " ";
    }
    return arr.join("");
}

// -------------------------
// Aspect mention detection (tag detection only)
// -------------------------
const ASPECT_LABEL: Record<AspectKey, string> = {
    taste: "맛",
    service: "서비스",
    value: "가격/가성비",
    revisit: "재방문",
    hygiene: "위생",
    ambience: "분위기",
    wait: "대기",
    portion: "양",
    overall: "전반",
};

const ASPECT_MENTIONS: { aspect: AspectKey; rx: RegExp }[] = [
    { aspect: "taste", rx: /(맛|음식|메뉴|식사|요리)/giu },
    { aspect: "service", rx: /(서비스|응대|직원|사장|서빙|태도)/giu },
    { aspect: "value", rx: /(가격|가성비|비싸|저렴|돈|원|만원|값어치)/giu },
    { aspect: "revisit", rx: /(재방문|또\s*갈|다시\s*갈|다음에도|자주\s*오|종종\s*오|매번\s*오|단골|정착|다신\s*안|절대\s*안)/giu },
    { aspect: "hygiene", rx: /(위생|청결|깨끗|깔끔|더럽|이물질|벌레|오염|악취)/giu },
    { aspect: "ambience", rx: /(분위기|인테리어|매장|공간|좌석|테이블|감성|뷰|조명|소음|연기)/giu },
    { aspect: "wait", rx: /(웨이팅|대기|줄|기다리|늦게\s*나오|오래\s*걸리)/giu },
    { aspect: "portion", rx: /(양|푸짐|넉넉|배부르|리필|무한)/giu },
    { aspect: "overall", rx: /(만족|좋았|괜찮|별로|실망|후회|추천)/giu },
];

function detectAspectMentions(text: string): Set<AspectKey> {
    const s = new Set<AspectKey>();
    for (const m of ASPECT_MENTIONS) {
        m.rx.lastIndex = 0;
        if (m.rx.test(text)) s.add(m.aspect);
    }
    return s;
}

// -------------------------
// Evidence rules
// -------------------------
const INTENSIFIERS = ["진짜", "너무", "완전", "엄청", "겁나", "개", "존", "찐", "레알", "대박", "최고", "미친", "핵"];
const HEDGES = ["좀", "약간", "그냥", "무난", "나름", "뭐", "그럭저럭", "평범"];

// ⚠️ .test() 상태성 버그 방지: g 제거
const PREFERENCE_CONTEXT = /(취향|호불호|개인차|사람마다|개인적|주관)/iu;
const ADJUSTABLE_CONTEXT = /(조절|요청|가능|말하(?:면|니)|덜\s*(맵|짜|달)게|간\s*조절)/iu;

interface CueRule {
    id: string;
    aspect: AspectKey;
    polarity: "POS" | "NEG";
    baseWeight: number;
    priority: number;
    rx: RegExp;
    preCheck?: (raw: string, start: number, matchText: string) => boolean;
    skipIf?: (raw: string, start: number, end: number, matchText: string) => boolean;
}

const CUE_RULES: CueRule[] = [
    // negated positives
    {
        id: "taste_negated_positive",
        aspect: "taste",
        polarity: "NEG",
        baseWeight: 1.10,
        priority: 130,
        rx: /맛있(?:지(?:는|도|만|라도)?)?\s*않|맛있는\s*건\s*아니|맛이\s*별로/giu,
    },
    {
        id: "service_negated_positive",
        aspect: "service",
        polarity: "NEG",
        baseWeight: 1.05,
        priority: 130,
        rx: /친절(?:하)?(?:지(?:는|도|만|라도)?)?\s*않|친절함\s*없|서비스\s*(?:좋|괜찮)[\s\S]{0,3}않/giu,
    },

    // double negatives => mild POS
    {
        id: "taste_double_negative",
        aspect: "taste",
        polarity: "POS",
        baseWeight: 0.35,
        priority: 120,
        rx: /(맛없|노맛)[\s\S]{0,3}않/giu,
    },
    {
        id: "service_double_negative",
        aspect: "service",
        polarity: "POS",
        baseWeight: 0.30,
        priority: 120,
        rx: /(불\s*친절|불친절)[\s\S]{0,3}않/giu,
    },
    {
        id: "overall_not_bad",
        aspect: "overall",
        polarity: "POS",
        baseWeight: 0.30,
        priority: 118,
        rx: /나쁘지\s*않/giu,
    },

    // strong negatives
    {
        id: "hygiene_critical",
        aspect: "hygiene",
        polarity: "NEG",
        baseWeight: 1.60,
        priority: 115,
        rx: /(벌레|이물질|곰팡|오염|악취|식중독|철수세미)/giu,
    },
    {
        id: "fraud_price",
        aspect: "value",
        polarity: "NEG",
        baseWeight: 1.40,
        priority: 115,
        rx: /(사기|바가지|가격\s*다르게|강요|강매|계산\s*실수|결제\s*실수)/giu,
    },
    {
        id: "never_again",
        aspect: "revisit",
        polarity: "NEG",
        baseWeight: 1.35,
        priority: 115,
        rx: /(다신\s*안|다시는\s*안|두\s*번\s*다시\s*안|절대\s*안|강력\s*비추|먹지\s*마|가지\s*마|오지\s*마)/giu,
    },
    {
        id: "service_extreme",
        aspect: "service",
        polarity: "NEG",
        baseWeight: 1.30,
        priority: 115,
        rx: /(막말|하대|서비스\s*최악|불친절\s*최악|무시당|무시하|반말|던지|툭툭|째려|도끼눈)/giu,
    },
    {
        id: "taste_strong_negative",
        aspect: "taste",
        polarity: "NEG",
        baseWeight: 1.20,
        priority: 110,
        rx: /(맛없|노맛|최악|쓰레기|실망|후회|비추|별\s*한\s*개도\s*아까)/giu,
    },

    // negatives (mild~moderate)
    {
        id: "value_negative",
        aspect: "value",
        polarity: "NEG",
        baseWeight: 0.90,
        priority: 95,
        rx: /(비싸|돈\s*아깝|가격대비\s*별로|창렬|가성비\s*(?:별로|최악)|값어치\s*의문)/giu,
    },
    {
        id: "service_negative",
        aspect: "service",
        polarity: "NEG",
        baseWeight: 0.85,
        priority: 90,
        rx: /(불\s*친절|불친절|무례|퉁명|불쾌|성의\s*없|태도\s*별로|응대\s*별로|엉망|개판|한숨|인상\s*쓰)/giu,
    },
    {
        id: "ambience_negative",
        aspect: "ambience",
        polarity: "NEG",
        baseWeight: 0.70,
        priority: 88,
        rx: /(시끄럽|소음|좁|불편|어수선|답답|연기|환기|냄새\s*배)/giu,
    },
    {
        id: "wait_negative",
        aspect: "wait",
        polarity: "NEG",
        baseWeight: 0.75,
        priority: 88,
        rx: /(웨이팅|대기|줄\s*길|기다리|늦게\s*나오|오래\s*걸리|한\s*시간|\b[3-9]\d\s*분\b)/giu,
    },
    {
        id: "taste_texture_negative",
        aspect: "taste",
        polarity: "NEG",
        baseWeight: 0.78,
        priority: 85,
        rx: /(질기|퍽퍽|눅눅|비리|누린내|잡내|밍밍|싱겁|짜다)/giu,
        skipIf: (raw, start, end) => {
            const wS = Math.max(0, start - 18);
            const wE = Math.min(raw.length, end + 18);
            const win = raw.slice(wS, wE);
            if (/(맵|짜|달)/.test(win) && ADJUSTABLE_CONTEXT.test(win)) return true;
            return false;
        },
    },

    // positives (expanded)
    {
        id: "taste_positive_core",
        aspect: "taste",
        polarity: "POS",
        baseWeight: 1.00,
        priority: 70,
        rx: /(맛있|존맛|jmt|꿀맛|풍미|육즙|고소|바삭|쫄깃|부드럽|신선)/giu,
    },
    {
        id: "taste_positive_deep",
        aspect: "taste",
        polarity: "POS",
        baseWeight: 0.95,
        priority: 68,
        rx: /(구수|진한\s*맛|깊은\s*맛|감칠맛|깔끔한\s*맛|근본|전통\s*맛)/giu,
    },
    {
        id: "taste_strong_praise_phrase",
        aspect: "taste",
        polarity: "POS",
        baseWeight: 1.10,
        priority: 66,
        rx: /(맛으로는\s*깔\s*수\s*없|배신하지\s*않아|찐맛집|검증된\s*맛집|레전드|끝내주|미친맛)/giu,
    },
    {
        id: "service_positive",
        aspect: "service",
        polarity: "POS",
        baseWeight: 0.75,
        priority: 70,
        rx: /(친절|응대\s*좋|서비스\s*(?:좋|최고)|배려|잘해주|유쾌|감사|고맙)/giu,
        preCheck: (raw, start) => {
            const prev = start > 0 ? raw[start - 1] : "";
            if (prev === "불" || prev === "안") return false;
            return true;
        },
    },
    {
        id: "hospitality_positive",
        aspect: "overall",
        polarity: "POS",
        baseWeight: 0.95,
        priority: 68,
        rx: /(대접받|정성|흡족|기분\s*좋|즐거운\s*시간)/giu,
    },
    {
        id: "value_positive",
        aspect: "value",
        polarity: "POS",
        baseWeight: 0.70,
        priority: 68,
        rx: /(가성비\s*(?:좋|최고)|혜자|저렴|싸(?:다|요)|가격\s*(?:착|괜찮)|돈값|무한리필)/giu,
    },
    {
        id: "revisit_positive",
        aspect: "revisit",
        polarity: "POS",
        baseWeight: 0.70,
        priority: 68,
        rx: /(재방문|또\s*갈|다시\s*갈|다음에도|또\s*오|자주\s*오|종종\s*오|매번\s*오|단골|정착)/giu,
    },
    {
        id: "hygiene_positive",
        aspect: "hygiene",
        polarity: "POS",
        baseWeight: 0.60,
        priority: 65,
        rx: /(깨끗|청결|위생\s*좋|깔끔)/giu,
    },
    {
        id: "ambience_positive",
        aspect: "ambience",
        polarity: "POS",
        baseWeight: 0.65,
        priority: 65,
        rx: /(분위기\s*좋|인테리어\s*(?:예쁘|멋지)|쾌적|아늑|뷰\s*좋|조용|넓|개인룸)/giu,
    },
    {
        id: "portion_positive",
        aspect: "portion",
        polarity: "POS",
        baseWeight: 0.60,
        priority: 62,
        rx: /(양\s*많|푸짐|넉넉|배부르|리필\s*가능|무한리필)/giu,
    },
    {
        id: "overall_positive",
        aspect: "overall",
        polarity: "POS",
        baseWeight: 0.70,
        priority: 55,
        rx: /(만족|좋았|좋아요|추천|강추|최고|대박|훌륭)/giu,
        skipIf: (raw, start, end) => {
            const wS = Math.max(0, start - 12);
            const wE = Math.min(raw.length, end + 18);
            const win = raw.slice(wS, wE);
            // ⚠️ g 제거
            return /(만족하실\s*수\s*있도록|만족할\s*수\s*있도록|만족하길|만족되면)/iu.test(win);
        },
    },
    {
        id: "overall_negative",
        aspect: "overall",
        polarity: "NEG",
        baseWeight: 0.70,
        priority: 55,
        rx: /(실망|후회|추천\s*안|안\s*추천)/giu,
    },
];

function intensityMultiplier(raw: string, start: number, end: number, cfg: EngineConfig): number {
    const wS = Math.max(0, start - 10);
    const wE = Math.min(raw.length, end + 10);
    const win = raw.slice(wS, wE);

    let mult = 1.0;
    if (INTENSIFIERS.some((t) => win.includes(t))) mult *= cfg.intensityBoost;
    if (HEDGES.some((t) => win.includes(t))) mult *= cfg.hedgePenalty;
    if (win.includes("!")) mult *= cfg.exclamBoost;
    return clamp(0.6, cfg.maxWeightMultiplier, mult);
}

function preferenceMultiplier(raw: string, start: number, end: number): number {
    const wS = Math.max(0, start - 18);
    const wE = Math.min(raw.length, end + 18);
    const win = raw.slice(wS, wE);
    if (PREFERENCE_CONTEXT.test(win)) return 0.88;
    return 1.0;
}

function extractEvidence(rawNormalized: string, cfg: EngineConfig) {
    const spans = collectNeutralizedSpans(rawNormalized);
    const masked = maskSpans(rawNormalized, spans);

    const { sentences } = buildSentenceInfo(rawNormalized);
    const nSent = Math.max(1, sentences.length);

    type Candidate = EvidenceHit & { priority: number; absWeight: number };
    const candidates: Candidate[] = [];

    for (const rule of CUE_RULES) {
        rule.rx.lastIndex = 0;
        let m: RegExpExecArray | null;
        while ((m = rule.rx.exec(masked)) !== null) {
            const start = m.index;
            const cue = m[0];
            const end = start + cue.length;

            if (rule.preCheck && !rule.preCheck(rawNormalized, start, cue)) continue;
            if (rule.skipIf && rule.skipIf(rawNormalized, start, end, cue)) continue;

            const sIdx = findSentenceIndex(sentences, start);
            const recency = nSent <= 1 ? 1.0 : 1.0 + cfg.recencyBoost * (sIdx / (nSent - 1));

            const sentence = sentences[sIdx];
            let contrast = 1.0;
            if (sentence.contrastAbs !== null) {
                if (start >= sentence.contrastAbs) contrast *= 1.0 + cfg.contrastPostBoost;
                else contrast *= 1.0 - cfg.contrastPrePenalty;
            }

            const intense = intensityMultiplier(rawNormalized, start, end, cfg);
            const pref = preferenceMultiplier(rawNormalized, start, end);

            const weight = rule.baseWeight * recency * contrast * intense * pref;

            candidates.push({
                aspect: rule.aspect,
                polarity: rule.polarity,
                weight,
                cue,
                snippet: makeSnippet(rawNormalized, start, end, cfg.snippetRadius),
                ruleId: rule.id,
                start,
                end,
                priority: rule.priority,
                absWeight: Math.abs(weight),
            });
        }
    }

    candidates.sort((a, b) => {
        if (b.priority !== a.priority) return b.priority - a.priority;
        return b.absWeight - a.absWeight;
    });

    const selected: Candidate[] = [];
    for (const c of candidates) {
        if (selected.some((s) => overlaps({ start: c.start, end: c.end }, { start: s.start, end: s.end }))) continue;
        selected.push(c);
    }

    return { masked, selected };
}

// -------------------------
// Strong negative ceiling
// -------------------------
function detectStrongNegative(textMasked: string): StrongNegativeInfo {
    const matched: string[] = [];

    const hygiene = /(벌레|이물질|곰팡|오염|악취|식중독|철수세미)/giu;
    const fraud = /(사기|바가지|가격\s*다르게|강요|강매|계산\s*실수|결제\s*실수)/giu;
    const neverAgain = /(다신\s*안|다시는\s*안|두\s*번\s*다시\s*안|절대\s*안|강력\s*비추|먹지\s*마|가지\s*마|오지\s*마)/giu;
    const serviceExtreme = /(막말|하대|서비스\s*최악|불친절\s*최악|무시당|무시하|반말|던지|툭툭|도끼눈|째려)/giu;
    const genericExtreme = /(최악|쓰레기|별\s*한\s*개도\s*아까|없어져도\s*되|절대\s*비추|안\s*추천|추천\s*안|후회합니다|후회됨)/giu;

    const hit = (rx: RegExp) => {
        rx.lastIndex = 0;
        let m: RegExpExecArray | null;
        let any = false;
        while ((m = rx.exec(textMasked)) !== null) {
            any = true;
            matched.push(m[0]);
        }
        return any;
    };

    if (hit(hygiene)) return { flag: true, type: "HYGIENE_CRITICAL", ceiling: 1.8, matched };
    if (hit(fraud)) return { flag: true, type: "FRAUD_PRICE", ceiling: 2.5, matched };
    if (hit(neverAgain)) return { flag: true, type: "NEVER_AGAIN", ceiling: 2.9, matched };
    if (hit(serviceExtreme)) return { flag: true, type: "SERVICE_EXTREME", ceiling: 2.8, matched };
    if (hit(genericExtreme)) return { flag: true, type: "GENERIC_EXTREME", ceiling: 2.9, matched };

    return { flag: false, type: "NONE", ceiling: 5.0, matched: [] };
}

// -------------------------
// Score label mapping
// -------------------------
export function scoreToLabel(score: number): string {
    if (score < 2.0) return "많이 노력해야하는 집";
    if (score < 3.0) return "노력해야하는 집";
    if (score < 3.4) return "먹을만한 집 / 호불호 갈리는 집";
    if (score < 3.8) return "괜찮은 집";
    if (score < 4.1) return "맛있는 집";
    if (score < 4.5) return "로컬맛집";
    return "웨이팅 찐맛집";
}

// -------------------------
// Trust scoring (with caps)
// -------------------------
function computeTrustBase(params: {
    normalized: string;
    lenNoSpace: number;
    sentenceCount: number;
    hangulRatio: number;
    mentionCount: number;
    hasNumbers: boolean;
    hasPrice: boolean;
    hasTime: boolean;
    evidenceCount: number;
    strongNeg: StrongNegativeInfo;
    userRating?: number;
    posEvidenceCount: number;
    negEvidenceCount: number;
}): number {
    const {
        normalized,
        lenNoSpace,
        sentenceCount,
        hangulRatio: hr,
        mentionCount,
        hasNumbers,
        hasPrice,
        hasTime,
        evidenceCount,
        strongNeg,
        userRating,
        posEvidenceCount,
        negEvidenceCount,
    } = params;

    if (!normalized) return 0;
    const onlyNoise = /^[ㅋㅎㅠㅜ!?.,\s]+$/.test(normalized) && lenNoSpace <= 6;
    if (onlyNoise) return 0;

    let trust = 0;
    if (lenNoSpace <= 10) trust = 25;
    else if (lenNoSpace <= 30) trust = 40;
    else if (lenNoSpace <= 70) trust = 55;
    else if (lenNoSpace <= 120) trust = 68;
    else if (lenNoSpace <= 220) trust = 78;
    else trust = 86;

    trust += Math.min(15, mentionCount * 3);
    if (sentenceCount >= 2) trust += 4;
    if (hasNumbers) trust += 5;
    if (hasPrice) trust += 5;
    if (hasTime) trust += 4;

    trust += Math.min(8, evidenceCount * 2);

    if (hr < 0.25) trust -= 15;

    const laugh = (normalized.match(/[ㅋㅎ]/g) || []).length;
    if (laugh >= 10) trust -= 8;

    const excl = (normalized.match(/!/g) || []).length;
    if (excl >= 4) trust -= 5;

    if (lenNoSpace < 25 && evidenceCount <= 1) {
        if (strongNeg.flag && strongNeg.type === "HYGIENE_CRITICAL") trust = Math.min(trust, 65);
        else trust = Math.min(trust, 50);
    }

    if (typeof userRating === "number" && Number.isFinite(userRating)) {
        if (userRating >= 4.5 && negEvidenceCount >= 2 && posEvidenceCount === 0) trust -= 10;
        if (userRating <= 2.0 && posEvidenceCount >= 2 && negEvidenceCount === 0) trust -= 8;
    }

    return clamp(0, 100, Math.round(trust));
}

function applyTrustCaps(trust: number, hasPhoto: boolean, cfg: EngineConfig) {
    const caps: string[] = [];
    let t = trust;
    if (t > cfg.trustMax) {
        t = cfg.trustMax;
        caps.push(`TRUST_CAP_GLOBAL(${cfg.trustMax})`);
    }
    if (!hasPhoto && t > cfg.trustMaxNoPhoto) {
        t = cfg.trustMaxNoPhoto;
        caps.push(`TRUST_CAP_NO_PHOTO(${cfg.trustMaxNoPhoto})`);
    }
    return { trust: t, trustCaps: caps };
}

// -------------------------
// Score caps by user rating (policy max caps)
// -------------------------
function applyUserRatingScoreCaps(rawScore: number, userRating: number | undefined, cfg: EngineConfig) {
    if (typeof userRating !== "number" || !Number.isFinite(userRating)) {
        return { score: rawScore, capApplied: undefined as number | undefined };
    }

    let cap: number | undefined;
    if (userRating < 2.0) cap = cfg.scoreCapUserRatingLt2;
    else if (userRating < 3.0) cap = cfg.scoreCapUserRatingLt3;

    if (cap === undefined) return { score: rawScore, capApplied: undefined };

    return { score: Math.min(rawScore, cap), capApplied: cap };
}

// -------------------------
// POLICY A: High-rating forced floor
// -------------------------
function applyHighRatingFloorForced(score: number, userRating: number | undefined, cfg: EngineConfig) {
    if (!cfg.enableHighRatingFloor) return score;
    if (typeof userRating !== "number" || !Number.isFinite(userRating)) return score;
    if (userRating < cfg.highRatingFloorMinUserRating) return score;
    return Math.max(score, cfg.highRatingFloorMinScore);
}

// -------------------------
// Main
// -------------------------
export function analyzeReview(
    input: ReviewInput,
    options: AnalyzeOptions = {},
    cfg: EngineConfig = DEFAULT_CONFIG,
): NeedsFineAnalysis {
    const normalized = normalizeText(input.text || "");
    const hasPhoto = Boolean(input.hasPhoto);
    const userRating = parseUserRating(input.userRating);

    const compact = normalized.replace(/\s+/g, "");
    const lenNoSpace = compact.length;

    // empty/noise
    if (!normalized || lenNoSpace <= 1) {
        const baseTrust = 0;
        const { trust, trustCaps } = applyTrustCaps(baseTrust, hasPhoto, cfg);

        const score0 = 1.0;
        return {
            needsFineScore: score0,
            trust,
            label: scoreToLabel(score0),
            tags: [],
            evidence: {
                positive: [],
                negative: [],
                strongNegative: { flag: false, type: "NONE", ceiling: 5.0, matched: [] },
            },
            debug: options.debug
                ? {
                    normalized,
                    masked: normalized,
                    appliedCaps: ["EMPTY_OR_TOO_SHORT"],
                    baseScore: cfg.baseScore,
                    scoreMode: "REGULAR",
                    rawScore: score0,
                    detailBonus: 0,
                    synergyBonus: 0,
                    caveatAttenuated: false,
                    userRating,
                    userRatingCapApplied: undefined,
                    trustCaps,
                    posAxes: [],
                    negAxes: [],
                    feature: { lenNoSpace },
                }
                : undefined,
        };
    }

    const mentionSet = detectAspectMentions(normalized);
    const { masked, selected } = extractEvidence(normalized, cfg);
    const strongNeg = detectStrongNegative(masked);

    const allAspects: AspectKey[] = [
        "taste",
        "service",
        "value",
        "revisit",
        "hygiene",
        "ambience",
        "wait",
        "portion",
        "overall",
    ];

    const aspects: Record<
        AspectKey,
        { pos: number; neg: number; posHits: EvidenceHit[]; negHits: EvidenceHit[] }
    > = Object.create(null);

    for (const a of allAspects) aspects[a] = { pos: 0, neg: 0, posHits: [], negHits: [] };

    for (const hit of selected) {
        if (hit.polarity === "POS") {
            aspects[hit.aspect].pos += hit.weight;
            aspects[hit.aspect].posHits.push(hit);
        } else {
            aspects[hit.aspect].neg += hit.weight;
            aspects[hit.aspect].negHits.push(hit);
        }
    }

    // per-aspect polarity -> tags
    const tagsAll: TagResult[] = [];
    const posAxes: AspectKey[] = [];
    const negAxes: AspectKey[] = [];

    for (const a of allAspects) {
        const mentioned = mentionSet.has(a) || aspects[a].posHits.length > 0 || aspects[a].negHits.length > 0;
        const pos = aspects[a].pos;
        const neg = aspects[a].neg;
        const net = pos - neg;

        let polarity: Polarity = "NEUTRAL";
        if (pos > 0.2 || neg > 0.2) {
            if (net >= cfg.aspectPosThreshold) polarity = "POS";
            else if (net <= -cfg.aspectNegThreshold) polarity = "NEG";
            else polarity = "MIXED";
        }

        const strength = clamp(0, 1, Math.abs(net) / 2.0);

        tagsAll.push({ aspect: a, label: ASPECT_LABEL[a], mentioned, polarity, strength });

        if (mentioned && polarity === "POS") posAxes.push(a);
        if (mentioned && polarity === "NEG") negAxes.push(a);
    }

    const evidencePosAll = selected.filter((h) => h.polarity === "POS");
    const evidenceNegAll = selected.filter((h) => h.polarity === "NEG");

    // -------------------------
    // SCORE computation
    // -------------------------
    // regular mode
    let scoreRegular = cfg.baseScore;
    let posContrib = 0; // sum of positive parts (coef*tanh)
    let negContrib = 0;

    const negNonCaveatSum = allAspects
        .filter((a) => !cfg.caveatAspects.includes(a))
        .reduce((acc, a) => acc + aspects[a].neg, 0);

    const tastePos = aspects.taste.pos;
    const caveatAttenuated =
        tastePos >= cfg.caveatApplyTastePosMin && negNonCaveatSum <= cfg.caveatApplyNegNonCaveatMax;

    for (const a of allAspects) {
        const pos = aspects[a].pos;
        let neg = aspects[a].neg;

        if (caveatAttenuated && cfg.caveatAspects.includes(a)) {
            neg = neg * cfg.caveatNegAttenuation;
        }

        const posPart = cfg.posCoef[a] * satTanh(pos / cfg.posScale[a]);
        const negPart = cfg.negCoef[a] * satTanh(neg / cfg.negScale[a]);

        scoreRegular += posPart;
        scoreRegular -= negPart;

        posContrib += posPart;
        negContrib += negPart;
    }

    // synergy bonus
    const distinctPosAxesCount = new Set(posAxes.filter((a) => a !== "overall")).size;
    let synergyBonus = 0;
    if (distinctPosAxesCount >= 2) synergyBonus += 0.12;
    if (distinctPosAxesCount >= 3) synergyBonus += 0.08;
    scoreRegular += synergyBonus;

    // detail bonus (only if there is positive evidence)
    const hasNumbers = /\d/.test(normalized);
    const hasPrice = /(\d+\s*원|만원)/iu.test(normalized); // g 제거
    const hasTime = /(\b\d+\s*(분|시간)\b|한\s*시간)/iu.test(normalized); // g 제거
    const sentenceCount = buildSentenceInfo(normalized).sentences.length;

    const detailSignals =
        (sentenceCount >= 2 ? 1 : 0) +
        (hasNumbers ? 1 : 0) +
        (hasPrice ? 1 : 0) +
        (hasTime ? 1 : 0) +
        (/(주차|예약|포장|배달|매장|좌석|룸|웨이팅|대기|리필|무한리필)/iu.test(normalized) ? 1 : 0);

    let detailBonus = 0;
    if (evidencePosAll.length >= 1) {
        if (lenNoSpace >= 80) detailBonus += 0.12;
        if (lenNoSpace >= 140) detailBonus += 0.07;
        detailBonus += Math.min(0.07, detailSignals * 0.016);
        detailBonus = Math.min(cfg.maxDetailBonus, detailBonus);
        scoreRegular += detailBonus;
    }

    const appliedCaps: string[] = [];
    let scoreMode: "REGULAR" | "LONG_MIXED_POS_ONLY" = "REGULAR";

    // brevity caps
    if (lenNoSpace <= 6) {
        scoreRegular = Math.min(scoreRegular, 3.1);
        appliedCaps.push("BREVITY_CAP_LEN<=6 => 3.1");
    } else if (lenNoSpace <= 12) {
        scoreRegular = Math.min(scoreRegular, 3.4);
        appliedCaps.push("BREVITY_CAP_LEN<=12 => 3.4");
    }

    // optional lift (regular mode only)
    let ratingLift = 0;
    if (cfg.enableUserRatingLift && typeof userRating === "number" && userRating >= 3.0) {
        if (!strongNeg.flag && lenNoSpace >= cfg.ratingLiftMinLen && evidencePosAll.length >= cfg.ratingLiftMinPosEvidence) {
            const quality = clamp(0, 1, evidencePosAll.length / 4 + distinctPosAxesCount / 4);
            ratingLift = Math.min(cfg.ratingLiftMax, (userRating - 3.0) * cfg.ratingLiftPerStar * quality);
            scoreRegular += ratingLift;
            appliedCaps.push(`USER_RATING_LIFT(+${ratingLift.toFixed(2)})`);
        }
    }

    // ✅ POLICY B: long mixed candidate
    let scoreLongMixed: number | undefined = undefined;
    const isLongMixed =
        cfg.enableLongMixedMode &&
        typeof userRating === "number" &&
        !strongNeg.flag &&
        lenNoSpace >= cfg.longMixedMinLenNoSpace &&
        evidencePosAll.length >= cfg.longMixedMinPosEvidence &&
        evidenceNegAll.length >= cfg.longMixedMinNegEvidence;

    if (isLongMixed) {
        const baseline = userRating - cfg.longMixedRatingDelta;
        const posGainBase = posContrib + synergyBonus + detailBonus;
        const posGain = cfg.longMixedPosGainMultiplier * posGainBase;

        scoreLongMixed = baseline + posGain;

        appliedCaps.push(
            `POLICY_B_LONG_MIXED: baseline(userRating-${cfg.longMixedRatingDelta})=${baseline.toFixed(
                2,
            )}, +posOnly*${cfg.longMixedPosGainMultiplier}(${posGainBase.toFixed(2)})`,
        );
    }

    // choose max (prevents “mixed long collapse” while never lowering good cases)
    let score = scoreRegular;
    if (scoreLongMixed !== undefined) {
        if (scoreLongMixed > scoreRegular) {
            score = scoreLongMixed;
            scoreMode = "LONG_MIXED_POS_ONLY";
        }
    }

    // strong negative ceiling (still applied here)
    if (strongNeg.flag) {
        score = Math.min(score, strongNeg.ceiling);
        appliedCaps.push(`STRONG_NEG_CEILING(${strongNeg.type}) => ${strongNeg.ceiling}`);
    }

    // 4.0 / 4.5 gates
    const distinctPosEvidence = new Set(evidencePosAll.map((e) => `${e.aspect}:${e.ruleId}`)).size;
    const hasCorePos = posAxes.some((a) => cfg.coreAxes.includes(a));

    if (score >= 4.0) {
        const gateFail =
            distinctPosAxesCount < cfg.minPosAxesFor4 ||
            distinctPosEvidence < cfg.minPosEvidenceFor4 ||
            (cfg.requireCoreAxisFor4 && !hasCorePos);

        if (gateFail) {
            score = Math.min(score, cfg.capIfGateFail4);
            appliedCaps.push("GATE_4.0_FAIL => cap 3.9");
        }
    }

    if (score >= 4.5) {
        const gateFail45 = distinctPosAxesCount < cfg.minPosAxesFor45 || lenNoSpace < cfg.minLenFor45;
        if (gateFail45) {
            score = Math.min(score, cfg.capIfGateFail45);
            appliedCaps.push("GATE_4.5_FAIL => cap 4.4");
        }
    }

    // global max cap
    score = Math.min(score, cfg.maxScore);

    // clamp
    let rawScore = clamp(1.0, 5.0, score);

    // userRating max caps (<2, <3)
    const { score: cappedByUserRating, capApplied } = applyUserRatingScoreCaps(rawScore, userRating, cfg);
    rawScore = cappedByUserRating;
    if (capApplied !== undefined) appliedCaps.push(`USER_RATING_CAP => ${capApplied}`);

    // ✅ POLICY A: forced 4~5 rating floor (UNCONDITIONAL)
    const beforeFloor = rawScore;
    rawScore = applyHighRatingFloorForced(rawScore, userRating, cfg);
    if (rawScore !== beforeFloor && typeof userRating === "number" && userRating >= cfg.highRatingFloorMinUserRating) {
        appliedCaps.push(`POLICY_A_HIGH_RATING_FLOOR => ${cfg.highRatingFloorMinScore}`);
    }

    // round
    let finalScore = roundToStep(rawScore, cfg.roundingStep);
    if (capApplied !== undefined) finalScore = Math.min(finalScore, capApplied);

    // evidence minimal output
    const topPos = [...evidencePosAll].sort((a, b) => b.weight - a.weight).slice(0, 2);
    const topNeg = [...evidenceNegAll].sort((a, b) => b.weight - a.weight).slice(0, 2);

    // trust
    const baseTrust = computeTrustBase({
        normalized,
        lenNoSpace,
        sentenceCount,
        hangulRatio: hangulRatio(normalized),
        mentionCount: mentionSet.size,
        hasNumbers,
        hasPrice,
        hasTime,
        evidenceCount: selected.length,
        strongNeg,
        userRating,
        posEvidenceCount: evidencePosAll.length,
        negEvidenceCount: evidenceNegAll.length,
    });

    const { trust, trustCaps } = applyTrustCaps(baseTrust, hasPhoto, cfg);

    const uiTags = tagsAll.filter((t) => t.mentioned);

    return {
        needsFineScore: finalScore,
        trust,
        label: scoreToLabel(finalScore),
        tags: uiTags,
        evidence: {
            positive: topPos,
            negative: topNeg,
            strongNegative: strongNeg,
        },
        debug: options.debug
            ? {
                normalized,
                masked,
                appliedCaps,
                baseScore: cfg.baseScore,
                scoreMode,
                rawScore,
                detailBonus,
                synergyBonus,
                caveatAttenuated,
                userRating,
                userRatingCapApplied: capApplied,
                trustCaps,
                posAxes,
                negAxes,
                feature: {
                    lenNoSpace,
                    sentenceCount,
                    hasNumbers,
                    hasPrice,
                    hasTime,
                    detailSignals,
                    distinctPosAxesCount,
                    distinctPosEvidence,
                    tastePos,
                    negNonCaveatSum,
                    hasPhoto,
                    posContrib,
                    negContrib,
                    ratingLift,
                    scoreRegular,
                    scoreLongMixed,
                },
            }
            : undefined,
    };
}
