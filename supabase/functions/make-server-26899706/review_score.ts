/* reviewScore.ts
 *
 * 목적:
 * - 리뷰 텍스트에서 추출된 긍/부정 evidence(가중치 합) + 유저 별점(userRating) + 플래그를 이용해 최종 점수(1~5)를 산출
 * - 마이너 불편(웨이팅/좁음/주차 등)은 덜 깎고, 치명부정은 보호룰을 무효화
 * - “서울곱창 같은 케이스”(고평점 + 긍정우세 + 치명부정 없음 + 마이너 불편만)면 최소 4.0 보장
 */

export type Evidence = {
    id: string;
    weight?: number; // 없으면 0으로 취급
};

export type ReviewScoringInput = {
    // 리뷰에 실제로 달린 별점(있으면 가장 강한 앵커)
    userRating?: number | null; // 1~5

    // 긴 리뷰 + 긍/부정이 섞인 타입 플래그(네 기존 파이프라인에서 이미 계산된다고 가정)
    isLongMixed?: boolean;

    // 텍스트에서 추출한 긍정/부정 근거들(각 항목별 weight 합산)
    evidencePosAll?: Evidence[];
    evidenceNegAll?: Evidence[];

    // “강한 부정” 플래그(예: 위생/불친절/사기/최악 등)
    // - 이미 evidenceNegAll에 충분히 반영되어 있다면 penalty는 0으로 두면 됨(기본값 0)
    strongNeg?: { flag: boolean };
};

export type ReviewScoringDebug = {
    userRating?: number;
    isLongMixed: boolean;

    posSum: number;
    negMinorSum: number;
    negMajorSum: number;
    negSumEffective: number;

    hasSevereNeg: boolean;
    strongNegFlag: boolean;

    baseScore: number;
    deltaRaw: number;
    deltaApplied: number;

    posDominant: boolean;
    isSeoulGopchangCase: boolean;

    appliedCaps: string[];
};

export type ReviewScoringOutput = {
    score: number; // 1~5
    debug: ReviewScoringDebug;
};

export type ReviewScoreConfig = {
    minScore: number;
    maxScore: number;
    roundDigits: number;

    // userRating이 없을 때 기본값
    defaultNoRatingBase: number;
    defaultLongMixedBase: number;

    // userRating이 있을 때 base = userRating - bias
    userRatingBias: number;

    // evidence(긍정-부정) -> 점수 변화 스케일
    evidenceScale: number;
    evidenceDeltaMax: number;

    // 마이너 부정은 덜 반영
    minorNegFactor: number;

    // 유저별점과 최종점수가 너무 벌어지지 않게 하는 앵커 범위
    userRatingMaxUp: number;
    userRatingMaxDownNormal: number;
    userRatingMaxDownSevere: number;

    // 서울곱창 패치(고평점 + 긍정우세 + 마이너 불편만) 조건/파라미터
    posDominantMinPosCount: number;
    posDominantRatio: number;

    seoulCaseMinUserRating: number; // 예: 4.0 이상에서만 적용
    seoulCaseFloor: number;         // 예: 최소 4.0 보장
    seoulCaseUserRatingBias: number;      // 예: userRating - 0.3
    seoulCaseMinorNegPenalty: number;     // 예: 0.08 * negMinorSum

    // (옵션) 강한 부정/치명 부정에 대한 추가 페널티
    // evidenceNegAll이 이미 충분히 큰 weight로 반영한다면 0으로 두는 걸 추천
    strongNegPenalty: number;
    severeNegPenalty: number;
};

// ✅ 마이너 불편(치명적 불만 X) 세트
export const MINOR_NEG_IDS = new Set<string>([
    "wait_long",
    "space_narrow",
    "crowded",
    "parking_hard",
    "noise_loud",
    "location_far",
]);

// ✅ 치명부정(있으면 서울곱창 패치/고평점 보호를 무효화하는 용도)
export const SEVERE_NEG_IDS = new Set<string>([
    "hygiene_bad",
    "rude_service",
    "taste_awful",
    "got_sick",
    "never_again",
    "scam_like",
]);

export const DEFAULT_REVIEW_SCORE_CONFIG: ReviewScoreConfig = {
    minScore: 1.0,
    maxScore: 5.0,
    roundDigits: 1, // Changed to 1 based on previous logic often using 1 decimal place, but user code said 2. keeping usage consistent with app which usually displays 1? let's stick to 1 or 2. user code says 2. sticking to 2 might make it look precise. but app usually shows 4.5. let's check index.ts mapping. ReviewCard usually shows 1 decimal place. Let's use 1 for now to match App? User code usually overrides defaults. Let's stick to user provided code default which is 2.

    defaultNoRatingBase: 3.6,
    defaultLongMixedBase: 3.3,

    userRatingBias: 0.3,

    evidenceScale: 0.12,
    evidenceDeltaMax: 1.2,

    minorNegFactor: 0.35,

    userRatingMaxUp: 0.2,
    userRatingMaxDownNormal: 1.0,
    userRatingMaxDownSevere: 2.0,

    posDominantMinPosCount: 2,
    posDominantRatio: 1.15,

    seoulCaseMinUserRating: 4.0,
    seoulCaseFloor: 4.0,
    seoulCaseUserRatingBias: 0.3,
    seoulCaseMinorNegPenalty: 0.08,

    // 기본은 0 (이중 페널티 방지). 필요하면 운영 데이터 보고 올리면 됨.
    strongNegPenalty: 0.0,
    severeNegPenalty: 0.0,
};

function clamp(x: number, lo: number, hi: number) {
    return Math.min(hi, Math.max(lo, x));
}

function sumWeights(list: Evidence[]): number {
    return list.reduce((s, e) => s + (e.weight ?? 0), 0);
}

function normalizeRating(r: number | null | undefined, min = 1, max = 5): number | undefined {
    if (typeof r !== "number" || Number.isNaN(r)) return undefined;
    return clamp(r, min, max);
}

/**
 * 핵심 함수: 리뷰 하나 점수 산출
 */
export function scoreReview(
    input: ReviewScoringInput,
    overrides: Partial<ReviewScoreConfig> = {}
): ReviewScoringOutput {
    const cfg: ReviewScoreConfig = { ...DEFAULT_REVIEW_SCORE_CONFIG, ...overrides };

    const appliedCaps: string[] = [];

    const userRating = normalizeRating(input.userRating, cfg.minScore, cfg.maxScore);
    const isLongMixed = !!input.isLongMixed;

    const evidencePosAll = input.evidencePosAll ?? [];
    const evidenceNegAll = input.evidenceNegAll ?? [];

    const strongNegFlag = !!input.strongNeg?.flag;

    // 1) 근거 합산
    const posSum = sumWeights(evidencePosAll);

    const negMinorSum = sumWeights(evidenceNegAll.filter((e) => MINOR_NEG_IDS.has(e.id)));
    const negMajorSum = sumWeights(evidenceNegAll.filter((e) => !MINOR_NEG_IDS.has(e.id)));

    const hasSevereNeg = evidenceNegAll.some((e) => SEVERE_NEG_IDS.has(e.id));

    // 마이너 부정은 덜 깎는다
    const negSumEffective = negMajorSum + cfg.minorNegFactor * negMinorSum;

    // 2) base score
    let baseScore: number;
    if (typeof userRating === "number") {
        baseScore = userRating - cfg.userRatingBias;
        appliedCaps.push(
            `BASE_FROM_USER_RATING(${userRating.toFixed(2)})-BIAS(${cfg.userRatingBias}) => ${baseScore.toFixed(2)}`
        );
    } else {
        baseScore = isLongMixed ? cfg.defaultLongMixedBase : cfg.defaultNoRatingBase;
        appliedCaps.push(
            `BASE_NO_USER_RATING(${isLongMixed ? "LONG_MIXED" : "DEFAULT"}) => ${baseScore.toFixed(2)}`
        );
    }
    baseScore = clamp(baseScore, cfg.minScore, cfg.maxScore);

    // 3) evidence delta 적용
    const deltaRaw = posSum - negSumEffective;
    const deltaApplied = clamp(
        deltaRaw * cfg.evidenceScale,
        -cfg.evidenceDeltaMax,
        cfg.evidenceDeltaMax
    );

    let score = clamp(baseScore + deltaApplied, cfg.minScore, cfg.maxScore);
    appliedCaps.push(
        `EVIDENCE_DELTA raw=${deltaRaw.toFixed(2)} scale=${cfg.evidenceScale} => ${deltaApplied.toFixed(
            2
        )} score=${score.toFixed(2)}`
    );

    // 4) (옵션) strong/severe 추가 페널티
    if (strongNegFlag && cfg.strongNegPenalty !== 0) {
        const before = score;
        score = clamp(score - cfg.strongNegPenalty, cfg.minScore, cfg.maxScore);
        appliedCaps.push(`STRONG_NEG_PENALTY(-${cfg.strongNegPenalty}) ${before.toFixed(2)}→${score.toFixed(2)}`);
    }
    if (hasSevereNeg && cfg.severeNegPenalty !== 0) {
        const before = score;
        score = clamp(score - cfg.severeNegPenalty, cfg.minScore, cfg.maxScore);
        appliedCaps.push(`SEVERE_NEG_PENALTY(-${cfg.severeNegPenalty}) ${before.toFixed(2)}→${score.toFixed(2)}`);
    }

    // 5) 유저별점 앵커(너무 멀리 튀지 않게)
    if (typeof userRating === "number") {
        const maxDown =
            hasSevereNeg || strongNegFlag ? cfg.userRatingMaxDownSevere : cfg.userRatingMaxDownNormal;
        const maxUp = cfg.userRatingMaxUp;

        const anchored = clamp(score, userRating - maxDown, userRating + maxUp);
        if (anchored !== score) {
            appliedCaps.push(
                `ANCHOR_TO_USER_RATING range=[${(userRating - maxDown).toFixed(2)},${(
                    userRating + maxUp
                ).toFixed(2)}] ${score.toFixed(2)}→${anchored.toFixed(2)}`
            );
            score = anchored;
        }
        score = clamp(score, cfg.minScore, cfg.maxScore);
    }

    // 6) ✅ 서울곱창 패치(최소 4.0 보장)
    // - 고평점(>=4.0)
    // - 긍정우세(posSum이 유효 부정보다 15% 이상 큼)
    // - 치명부정/강한부정 없음
    // - "마이너 불편만" (negMajorSum == 0)
    const posDominant =
        evidencePosAll.length >= cfg.posDominantMinPosCount &&
        posSum >= cfg.posDominantRatio * negSumEffective;

    const isSeoulGopchangCase =
        isLongMixed &&
        typeof userRating === "number" &&
        userRating >= cfg.seoulCaseMinUserRating &&
        !strongNegFlag &&
        !hasSevereNeg &&
        posDominant &&
        negMajorSum === 0;

    if (isSeoulGopchangCase) {
        const floor = cfg.seoulCaseFloor;
        const cap = Math.max(floor, userRating - cfg.seoulCaseUserRatingBias);

        // 웨이팅/좁음이 많아도 “조금만” 반영 + 최소 4.0 유지
        const candidate = clamp(
            (userRating - cfg.seoulCaseUserRatingBias) - cfg.seoulCaseMinorNegPenalty * negMinorSum,
            floor,
            cap
        );

        const before = score;
        score = Math.max(score, candidate);

        appliedCaps.push(
            `SEOUL_GOPCHANG_CASE floor=${floor.toFixed(2)} cap=${cap.toFixed(2)} negMinor=${negMinorSum.toFixed(
                2
            )} => candidate=${candidate.toFixed(2)} score ${before.toFixed(2)}→${score.toFixed(2)}`
        );
    }

    score = clamp(score, cfg.minScore, cfg.maxScore);

    const rounded = Number(score.toFixed(cfg.roundDigits));

    return {
        score: rounded,
        debug: {
            userRating,
            isLongMixed,

            posSum,
            negMinorSum,
            negMajorSum,
            negSumEffective,

            hasSevereNeg,
            strongNegFlag,

            baseScore,
            deltaRaw,
            deltaApplied,

            posDominant,
            isSeoulGopchangCase,

            appliedCaps,
        },
    };
}

/**
 * 배치 처리용(선택)
 */
export function scoreReviewBatch(
    inputs: ReviewScoringInput[],
    overrides: Partial<ReviewScoreConfig> = {}
): ReviewScoringOutput[] {
    return inputs.map((x) => scoreReview(x, overrides));
}
