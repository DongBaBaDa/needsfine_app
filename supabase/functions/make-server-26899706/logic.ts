/**
 * NeedsFine Hybrid (Supabase Edge Function)
 * Core: v17.4.0_PATCH_NEG_FIRST_WAITPOS_TASTEEXT  +  Hybrid Lexicon + Term Mining
 *
 * ✅ Core requirements
 * 1) Score ceilings by user rating
 *    - userRating < 2.0 => score ≤ 2.2
 *    - userRating < 3.0 => score ≤ 2.9
 *    - userRating < 4.0 => score ≤ 4.2
 *    - NeedsFine max score: 4.9 (no 5.0)
 * 2) Simple reviews
 *    - "맛있어요"류 => score 3.2, trust 50
 *    - "맛없어요"류 => score 2.7, trust 50
 *    - no text => score 3.0, trust 30
 * 3) Trust caps
 *    - text only: ≤ 92%
 *    - with photo: ≤ 99%
 *
 * ✅ Hybrid (요구사항 7)
 * - Dynamic cues (사용자들이 쌓일수록 확장) from Supabase table: needsfine_lexicon
 * - New term mining → needsfine_candidate_terms에 누적
 * - (옵션) 충분히 높은 신뢰/빈도면 자동으로 needsfine_lexicon에 승격 (auto-promote)
 *
 * ✅ v17.5 patch summary
 * - POLICY A high-rating floor: 3.5 기반 + userRating에 따라 3.5~3.7 동적 (4.0★=3.5, 5.0★=3.7)
 * - strongNegative 플래그가 있으면 POLICY A floor 적용 금지 (ceiling 보호)
 * - (요구사항 5) 부정리뷰(userRating<3) & trust 높음(>=80) => userRating cap을 -0.4 추가 적용
 * - (요구사항 2) Evidence 오탐 일부 보강:
 *   - "친절함이 없고" / "친절도는 최하급" 등 서비스 부정 선점
 *   - "여기보다 맛있는 집 많음" 비교구문을 taste NEG로 선점
 *
 * Deploy
 * - Save as: supabase/functions/needsfine-hybrid/index.ts
 * - Create tables (SQL snippets below in comments)
 * - Set secrets:
 *   - SUPABASE_URL, SUPABASE_ANON_KEY (required)
 *   - SUPABASE_SERVICE_ROLE_KEY (optional but recommended for term mining / auto-promote)
 *   - NEEDSFINE_AUTO_PROMOTE=1 (optional, default 0)
 *   - NEEDSFINE_PROMOTE_MIN_COUNT=10 (optional)
 *   - NEEDSFINE_PROMOTE_MIN_CONF=0.88 (optional)
 */

/* -------------------------
   SQL (예시)
----------------------------

-- 1) Dynamic lexicon (scoring에 즉시 반영되는 사전)
create table if not exists public.needsfine_lexicon (
  term text primary key,
  aspect text not null check (aspect in ('taste','service','value','revisit','hygiene','ambience','wait','portion','overall')),
  polarity text not null check (polarity in ('POS','NEG')),
  weight double precision not null default 0.35,
  priority int not null default 35,
  enabled boolean not null default true,
  source text not null default 'manual', -- manual | auto
  confidence double precision default 0.5,
  occurrences int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2) Candidate terms (새 단어 자동 분류/누적)
create table if not exists public.needsfine_candidate_terms (
  term text primary key,
  stats jsonb not null default '{}'::jsonb, -- key: "aspect|POLARITY" -> count
  total_count int not null default 0,
  best_aspect text,
  best_polarity text,
  best_count int default 0,
  confidence double precision default 0,
  promoted boolean not null default false,
  last_seen timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 권장: Edge function이 SERVICE_ROLE로 쓰기하므로 RLS off or 정책 설정
-- alter table public.needsfine_lexicon enable row level security;
-- alter table public.needsfine_candidate_terms enable row level security;
*/

/* -------------------------------------------------------
   NeedsFine Core Engine (v17.4.0 patched) + Hybrid hooks
-------------------------------------------------------- */

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

export const NEEDSFINE_VERSION = "17.5.0_HYBRID_SUPABASE_v2";

export type Aspect =
  | "taste"
  | "service"
  | "value"
  | "revisit"
  | "hygiene"
  | "ambience"
  | "wait"
  | "portion"
  | "overall";

export type Polarity = "POS" | "NEG";

export interface NeedsFineConfig {
  baseScore: number;
  roundingStep: number;
  snippetRadius: number;

  posCoef: Record<Aspect, number>;
  negCoef: Record<Aspect, number>;

  posScale: Record<Aspect, number>;
  negScale: Record<Aspect, number>;

  aspectPosThreshold: number;
  aspectNegThreshold: number;

  minPosAxesFor4: number;
  minPosEvidenceFor4: number;
  requireCoreAxisFor4: boolean;
  coreAxes: Aspect[];
  capIfGateFail4: number;

  minPosAxesFor45: number;
  capIfGateFail45: number;
  maxScore: number;
  minLenFor45: number;

  recencyBoost: number;
  contrastPostBoost: number;
  contrastPrePenalty: number;
  intensityBoost: number;
  hedgePenalty: number;
  exclamBoost: number;
  maxWeightMultiplier: number;

  maxDetailBonus: number;

  caveatAspects: Aspect[];
  caveatNegAttenuation: number;
  caveatApplyTastePosMin: number;
  caveatApplyNegNonCaveatMax: number;

  trustMax: number;
  trustMaxNoPhoto: number;

  scoreCapUserRatingLt2: number;
  scoreCapUserRatingLt3: number;
  scoreCapUserRatingLt4: number;

  enableUserRatingLift: boolean;
  ratingLiftPerStar: number;
  ratingLiftMax: number;
  ratingLiftMinLen: number;
  ratingLiftMinPosEvidence: number;

  enableHighRatingFloor: boolean;
  highRatingFloorMinUserRating: number;
  highRatingFloorMinScore: number;

  enableLongMixedMode: boolean;
  longMixedMinLenNoSpace: number;
  longMixedRatingDelta: number;
  longMixedPosGainMultiplier: number;
  longMixedMinPosEvidence: number;
  longMixedMinNegEvidence: number;

  enableLongPositiveFloor: boolean;
  longPositiveMinLenNoSpace: number;
  longPositiveRatingMin: number;
  longPositiveRatingDelta: number;
  longPositivePosGainMultiplier: number;
  longPositiveMaxNegNonCaveatSum: number;
  longPositiveMinPosEvidence: number;
  longPositiveMinCorePos: boolean;
}

export const DEFAULT_CONFIG: NeedsFineConfig = {
  baseScore: 2.78,
  roundingStep: 0.1,
  snippetRadius: 14,

  // priority intent: hygiene > taste > service > ambience/environment
  // 가점 작게, 감점 크게(비대칭) + ambience/wait는 더 가볍게
  posCoef: {
    taste: 0.74,
    service: 0.44,
    value: 0.32,
    revisit: 0.28,
    hygiene: 0.28,
    ambience: 0.30,
    wait: 0.12,
    portion: 0.22,
    overall: 0.28,
  },
  negCoef: {
    taste: 0.95,
    service: 0.68,
    value: 0.50,
    revisit: 0.80,
    hygiene: 0.98,
    ambience: 0.30,
    wait: 0.24,
    portion: 0.26,
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
  coreAxes: ["hygiene", "taste", "service", "value"],
  capIfGateFail4: 3.9,

  minPosAxesFor45: 3,
  capIfGateFail45: 4.4,
  maxScore: 4.9,
  minLenFor45: 140,

  recencyBoost: 0.05,
  contrastPostBoost: 0.12,
  contrastPrePenalty: 0.12,
  intensityBoost: 1.22,
  hedgePenalty: 0.86,
  exclamBoost: 1.08,
  maxWeightMultiplier: 1.45,

  maxDetailBonus: 0.28,

  // 웨이팅/분위기/좁음 등은 (맛이 매우 좋고 비핵심 부정이 작으면) 크게 감쇠
  caveatAspects: ["wait", "ambience"],
  caveatNegAttenuation: 0.45,
  caveatApplyTastePosMin: 0.65,
  caveatApplyNegNonCaveatMax: 0.55,

  trustMax: 99,
  trustMaxNoPhoto: 92,

  scoreCapUserRatingLt2: 2.2,
  scoreCapUserRatingLt3: 2.9,
  scoreCapUserRatingLt4: 4.2,

  enableUserRatingLift: true,
  ratingLiftPerStar: 0.22,
  ratingLiftMax: 0.52,
  ratingLiftMinLen: 40,
  ratingLiftMinPosEvidence: 2,

  // v17.5: High-rating floor를 3.5 기반으로 상향 + (함수에서) userRating에 따라 3.5~3.7로 동적
  enableHighRatingFloor: true,
  highRatingFloorMinUserRating: 4.0,
  highRatingFloorMinScore: 3.0,

  enableLongMixedMode: true,
  longMixedMinLenNoSpace: 120,
  longMixedRatingDelta: 1.2,
  longMixedPosGainMultiplier: 0.70,
  longMixedMinPosEvidence: 1,
  longMixedMinNegEvidence: 1,

  // POLICY C: long positive floor (>=200자, 별점>=4.0)
  enableLongPositiveFloor: true,
  longPositiveMinLenNoSpace: 200,
  longPositiveRatingMin: 4.0,
  longPositiveRatingDelta: 1.2,
  longPositivePosGainMultiplier: 0.95,
  longPositiveMaxNegNonCaveatSum: 0.70,
  longPositiveMinPosEvidence: 2,
  longPositiveMinCorePos: true,
};

export interface ReviewInput {
  text: string;
  userRating?: number | string;
  hasPhoto?: boolean;
}

export interface AnalyzeOptions {
  debug?: boolean;
  /** internal use: return all evidence hits (for term mining / advanced UI) */
  returnAllEvidence?: boolean;
}

export interface EvidenceHit {
  aspect: Aspect;
  polarity: Polarity;
  weight: number;
  cue: string;
  snippet: string;
  ruleId: string;
  start: number;
  end: number;
  priority?: number;
  absWeight?: number;
}

export interface StrongNegative {
  flag: boolean;
  type: string;
  ceiling: number;
  matched: string[];
}

export interface TagResult {
  aspect: Aspect;
  label: string;
  mentioned: boolean;
  polarity: "POS" | "NEG" | "MIXED" | "NEUTRAL";
  strength: number;
}

export interface DebugInfo {
  normalized: string;
  masked: string;
  appliedCaps: string[];
  baseScore: number;
  scoreMode: string;
  rawScore: number;
  detailBonus: number;
  synergyBonus: number;
  caveatAttenuated: boolean;
  userRating?: number;
  userRatingCapApplied?: number;
  trustCaps: string[];
  posAxes: Aspect[];
  negAxes: Aspect[];
  feature: Record<string, unknown>;
}

export interface AnalyzeResult {
  needsFineScore: number;
  trust: number;
  label: string;
  tags: TagResult[];
  evidence: {
    positive: EvidenceHit[];
    negative: EvidenceHit[];
    strongNegative: StrongNegative;
  };
  debug?: DebugInfo;
}

/* -------------------------
   Hybrid lexicon types
------------------------- */
export interface DynamicCue {
  term: string; // normalized, lowercased
  aspect: Aspect;
  polarity: Polarity;
  baseWeight: number;
  priority: number; // 낮을수록 core보다 뒤에 선택됨
  source?: "manual" | "auto";
  confidence?: number;
}

function isAspect(x: unknown): x is Aspect {
  return (
    x === "taste" ||
    x === "service" ||
    x === "value" ||
    x === "revisit" ||
    x === "hygiene" ||
    x === "ambience" ||
    x === "wait" ||
    x === "portion" ||
    x === "overall"
  );
}
function isPolarity(x: unknown): x is Polarity {
  return x === "POS" || x === "NEG";
}

/* -------------------------
   Helpers
------------------------- */
function clamp(min: number, max: number, v: number) {
  return Math.max(min, Math.min(max, v));
}
function roundToStep(v: number, step: number) {
  const inv = 1 / step;
  return Math.round(v * inv) / inv;
}
function satTanh(x: number) {
  return Math.tanh(x);
}

export function normalizeText(input: unknown) {
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

function hangulRatio(text: string) {
  if (!text) return 0;
  const h = (text.match(/[가-힣]/g) || []).length;
  return h / Math.max(1, text.length);
}

function makeSnippet(text: string, start: number, end: number, radius: number) {
  const s = Math.max(0, start - radius);
  const e = Math.min(text.length, end + radius);
  return text.slice(s, e).trim();
}

function overlaps(a: { start: number; end: number }, b: { start: number; end: number }) {
  return a.start < b.end && b.start < a.end;
}

/**
 * ✅ RegExp safety: clone regex on every exec to avoid lastIndex state bugs.
 * When using /g flag, the RegExp object maintains lastIndex state between calls.
 * In Edge Function environments (persistent module scope), this can cause
 * rules to randomly miss matches across different requests.
 */
function safeExecAll(raw: string, rx: RegExp): Array<{ index: number; text: string }> {
  const flags = rx.flags.includes("g") ? rx.flags : rx.flags + "g";
  const re = new RegExp(rx.source, flags);
  re.lastIndex = 0;
  const out: Array<{ index: number; text: string }> = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(raw)) !== null) {
    out.push({ index: m.index, text: m[0] });
    if (m[0].length === 0) re.lastIndex++; // prevent infinite loop
  }
  return out;
}

function safeTest(raw: string, rx: RegExp): boolean {
  const flags = rx.flags.replace(/g/g, "").replace(/y/g, "");
  return new RegExp(rx.source, flags).test(raw);
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

/* -------------------------
   Simple review detection
------------------------- */
function detectSimpleReview(normalized: string) {
  const compact = normalized.replace(/\s+/g, "");
  const len = compact.length;
  if (len < 2 || len > 18) return "NONE";

  // 접속/대조/조건 등, 또는 음식 특징이나 양적 설명이 있으면 단순리뷰 아님
  if (/(하지만|그런데|다만|근데|반면|대신|그래도|가격|서비스|위생|분위기|웨이팅|대기|줄|토핑|추가|치즈|도우|소스|양념|듬뿍|많이|조금)/iu.test(normalized))
    return "NONE";

  const pos = /(맛있(?:어|었)?요|맛있습니다|맛있음|맛나요|존맛|jmt|꿀맛|개맛있|존맛탱)/iu.test(normalized);
  const neg = /(맛없(?:어|었)?요|맛없습니다|맛없음|노맛)/iu.test(normalized);

  if (pos && !neg) return "SIMPLE_POS";
  if (neg && !pos) return "SIMPLE_NEG";
  return "NONE";
}

/* -------------------------
   Sentence + contrast
------------------------- */
const CONTRAST_WORDS: RegExp[] = [/하지만/g, /그런데/g, /다만/g, /근데/g, /반면/g, /대신/g, /그래도/g];

function buildSentenceInfo(text: string) {
  const starts = [0];
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

function findSentenceIndex(sentences: Array<{ start: number; end: number; contrastAbs: number | null }>, pos: number) {
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

/* -------------------------
   Neutralizers (meta negation masking)
------------------------- */
const NEUTRALIZERS: Array<{ key: string; rx: RegExp }> = [
  {
    key: "meta_negated_taste_neg",
    rx: /(맛없|노맛|비추|최악)\s*(?:다는|단)?\s*(?:얘기|말|소문|리뷰|후기|평)(?:가|는|도|은|이)?\s*(?:없|없었|없더|없는데|없다)/gi,
  },
  {
    key: "meta_negated_service_neg",
    rx: /(불\s*친절|불친절|서비스\s*최악)\s*(?:하다는|하단)?\s*(?:얘기|말|소문|리뷰|후기|평)(?:가|는|도|은|이)?\s*(?:없|없었|없더|없는데|없다)/gi,
  },
  {
    key: "meta_negated_hygiene_neg",
    rx: /(위생|더럽|벌레|이물질|오염|악취)\s*(?:관련|문제)?\s*(?:얘기|말|소문|리뷰|후기|평)(?:가|는|도|은|이)?\s*(?:없|없었|없더|없는데|없다)/gi,
  },
];

function collectNeutralizedSpans(text: string) {
  const spans: Array<{ start: number; end: number; key: string; txt: string }> = [];
  for (const n of NEUTRALIZERS) {
    const matches = safeExecAll(text, n.rx);
    for (const m of matches) {
      spans.push({ start: m.index, end: m.index + m.text.length, key: n.key, txt: m.text });
    }
  }
  return spans.sort((a, b) => a.start - b.start);
}

function maskSpans(text: string, spans: Array<{ start: number; end: number }>) {
  if (spans.length === 0) return text;
  const arr = text.split("");
  for (const sp of spans) {
    for (let i = sp.start; i < sp.end && i < arr.length; i++) arr[i] = " ";
  }
  return arr.join("");
}

/* -------------------------
   Aspect mention detection (tag detection only)
------------------------- */
const ASPECT_LABEL: Record<Aspect, string> = {
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

const ASPECT_MENTIONS: Array<{ aspect: Aspect; rx: RegExp }> = [
  { aspect: "taste", rx: /(맛|음식|메뉴|식사|요리|먹었|먹어|먹기|재료|퀄리티|풍미|감칠맛|소스|면)/gi },
  { aspect: "service", rx: /(서비스|응대|직원|사장|서빙|태도|친절|불친절)/gi },
  { aspect: "value", rx: /(가격|가성비|비싸|저렴|돈|원|만원|값어치|돈값)/gi },
  { aspect: "revisit", rx: /(재방문|또\s*갈|다시\s*갈|다음에도|자주\s*오|종종\s*오|매번\s*오|단골|정착|다신\s*안|절대\s*안)/gi },
  { aspect: "hygiene", rx: /(위생|청결|깨끗|깔끔|더럽|이물질|벌레|오염|악취)/gi },
  { aspect: "ambience", rx: /(분위기|인테리어|매장|공간|좌석|테이블|감성|뷰|조명|소음|연기|환기|좁|불편|주차)/gi },
  { aspect: "wait", rx: /(웨이팅|대기|대기\s*줄|웨이팅\s*줄|기다리|늦게\s*나오|오래\s*걸리|조리\s*시간)/gi },
  { aspect: "portion", rx: /(양|푸짐|넉넉|배부르|리필|무한)/gi },
  { aspect: "overall", rx: /(만족|좋았|괜찮|별로|실망|후회|추천|비추|맛집)/gi },
];

function detectAspectMentions(text: string) {
  const s = new Set<Aspect>();
  for (const m of ASPECT_MENTIONS) {
    if (safeTest(text, m.rx)) s.add(m.aspect);
  }
  return s;
}

/* -------------------------
   Evidence rules (CORE)
------------------------- */
const INTENSIFIERS = ["진짜", "너무", "완전", "엄청", "겁나", "개", "존", "찐", "레알", "대박", "최고", "미친", "핵"];
const HEDGES = ["좀", "약간", "그냥", "무난", "나름", "뭐", "그럭저럭", "평범"];

// ⚠️ .test() 상태성 버그 방지: g 제거
const PREFERENCE_CONTEXT = /(취향|호불호|개인차|사람마다|개인적|주관)/iu;
const ADJUSTABLE_CONTEXT = /(조절|요청|가능|말하(?:면|니)|덜\s*(맵|짜|달)게|간\s*조절)/iu;

interface CueRule {
  id: string;
  aspect: Aspect;
  polarity: Polarity;
  baseWeight: number;
  priority: number;
  rx: RegExp;
  preCheck?: (raw: string, start: number, cue: string) => boolean;
  skipIf?: (raw: string, start: number, end: number, cue: string) => boolean;
}

/**
 * ✅ NEGATION-FIRST:
 *   - "돈 아깝지 않" => POS(가치/가성비 긍정)로 먼저 잡고, "돈 아깝" NEG를 덮어씀
 *   - "비린내 전혀 없" => POS(맛)로 먼저 잡음
 * ✅ WAIT:
 *   - "웨이팅" 자체는 NEG 금지. (정보/시그널) => POS(light)
 *   - "기다릴 가치/줄서서 먹을만" => 강한 POS(전체/대기)
 *   - "웨이팅 너무 길/지옥/짜증" 처럼 명시적 불만만 NEG
 * ✅ SERVICE_EXTREME:
 *   - "하던지" 오탐 방지: 던지 뒤에 (다/더/고/며/듯/길/면/지/네/네요/...) 있을 때만 매치
 */
const CORE_CUE_RULES: CueRule[] = [
  // -------------------------
  // NEGATION-FIRST overrides (TOP PRIORITY)
  // -------------------------
  {
    id: "taste_no_fishy_smell",
    aspect: "taste",
    polarity: "POS",
    baseWeight: 1.05,
    priority: 160,
    rx: /(?:비린\s*내|비린내|잡\s*내|잡내|누린\s*내|누린내)\s*(?:가|이|는|도)?\s*(?:전혀|하나도|1도)?\s*(?:없(?:었|더라|네요|었어요|어요|음|습니다)?|나지\s*않|나진\s*않|안\s*나|안\s*나고|안\s*나서)/gi,
  },
  {
    id: "taste_not_fishy",
    aspect: "taste",
    polarity: "POS",
    baseWeight: 0.90,
    priority: 158,
    rx: /비리(?:지(?:는|도)?)?\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?)/gi,
  },
  {
    id: "taste_negated_texture_saltiness",
    aspect: "taste",
    polarity: "POS",
    baseWeight: 0.85,
    priority: 156,
    rx: /(느끼(?:하)?지\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?)|느끼함\s*(?:없(?:었|더라|네요|었어요|어요|음|습니다)?))|(안\s*느끼)|(짜(?:지)?\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?))|(안\s*짜)|(싱겁(?:지)?\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?))|(안\s*싱거)|(밍밍(?:하)?지\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?))|(안\s*밍밍)|(텁텁(?:하)?지\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?))|(안\s*텁텁)|(질기(?:지)?\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?))|(안\s*질겨)|(퍽퍽(?:하)?지\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?))|(안\s*퍽퍽)|(눅눅(?:하)?지\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?))|(안\s*눅눅)/gi,
  },
  {
    id: "value_not_waste_money",
    aspect: "value",
    polarity: "POS",
    baseWeight: 0.95,
    priority: 160,
    rx: /(?:돈|가격|값|비용|금액)\s*(?:이|도|은|는|을|가)?\s*(?:전혀|하나도|1도)?\s*(?:안\s*아깝(?:다|요|네|네요|더라|더라고|었|았|음|습니다)?|아깝\s*(?:지|진|지는|지\s*는)?\s*(?:않(?:았|아|더라|네요|었어요|아요|음|습니다)?))/gi,
  },

  // WAIT strong positive (worth it) -> also signals overall is strong positive
  {
    id: "wait_worth_it_overall",
    aspect: "overall",
    polarity: "POS",
    baseWeight: 1.05,
    priority: 150,
    rx: /(기다릴\s*(?:가치|만|만큼)(?:가|는|도|만)?\s*(?:있|충분|쌉|넘)|기다릴\s*만한\s*가치(?:가|는|도|만)?\s*(?:있|충분|쌉|넘)|줄\s*서서\s*(?:먹을\s*)?(?:만|만한|가치|보람)(?:은|도)?|웨이팅\s*(?:있어도|해도)[\s\S]{0,12}(?:기다릴|가치|보람|만))/gi,
  },
  {
    id: "wait_worth_it_wait",
    aspect: "wait",
    polarity: "POS",
    baseWeight: 0.70,
    priority: 148,
    rx: /(기다릴\s*(?:가치|만|만큼)(?:가|는|도|만)?\s*(?:있|충분|쌉|넘)|기다릴\s*만한\s*가치(?:가|는|도|만)?\s*(?:있|충분|쌉|넘)|줄\s*서서\s*(?:먹을\s*)?(?:만|만한|가치|보람)(?:은|도)?|웨이팅\s*(?:있어도|해도)[\s\S]{0,12}(?:기다릴|가치|보람|만))/gi,
  },

  // -------------------------
  // negated positives (still high)
  // -------------------------
  {
    id: "taste_negated_positive",
    aspect: "taste",
    polarity: "NEG",
    baseWeight: 1.10,
    priority: 130,
    rx: /맛있(?:지(?:는|도|만|라도)?)?\s*않|맛있는\s*건\s*아니|맛이\s*별로/gi,
  },
  {
    // v17.5: "친절함이 없고", "친절도는 최하급" 등 커버 보강
    id: "service_negated_positive",
    aspect: "service",
    polarity: "NEG",
    baseWeight: 1.05,
    priority: 130,
    rx: /친절(?:하)?(?:지(?:는|도|만|라도)?)?\s*않|친절함(?:이|은|는|도)?\s*없|친절(?:도)?(?:이|은|는|도)?\s*(?:없|최하급|최악)|서비스\s*(?:좋|괜찮)[\s\S]{0,3}않/gi,
  },

  // double negatives => mild POS
  {
    id: "taste_double_negative",
    aspect: "taste",
    polarity: "POS",
    baseWeight: 0.35,
    priority: 120,
    rx: /(맛없|노맛)[\s\S]{0,5}않/gi,
  },
  {
    id: "service_double_negative",
    aspect: "service",
    polarity: "POS",
    baseWeight: 0.30,
    priority: 120,
    rx: /(불\s*친절|불친절)[\s\S]{0,6}않/gi,
  },
  {
    id: "overall_not_bad",
    aspect: "overall",
    polarity: "POS",
    baseWeight: 0.30,
    priority: 118,
    rx: /나쁘지\s*않/gi,
  },

  // -------------------------
  // strong negatives
  // -------------------------
  {
    id: "hygiene_critical",
    aspect: "hygiene",
    polarity: "NEG",
    baseWeight: 1.60,
    priority: 115,
    rx: /(벌레|이물질|곰팡|오염|악취|식중독|철수세미|재활용)/gi,
  },
  {
    id: "fraud_price",
    aspect: "value",
    polarity: "NEG",
    baseWeight: 1.40,
    priority: 115,
    rx: /(사기|바가지|가격\s*다르게|강요|강매|계산\s*실수|결제\s*실수|바꿔치기)/gi,
  },
  {
    id: "never_again",
    aspect: "revisit",
    polarity: "NEG",
    baseWeight: 1.35,
    priority: 115,
    rx: /(다신\s*안|다시는\s*안|두\s*번\s*다시\s*안|절대\s*안|강력\s*비추|먹지\s*마(?!시고)|가지\s*마(?!시고)|오지\s*마(?!시고))/gi,
    skipIf: (raw, start, end) => {
      // 1. Suffix check: "시고" (recommendation connective)
      const wE = Math.min(raw.length, end + 2);
      const after = raw.slice(end, wE);
      if (after === "시고") return true;

      // 2. Prefix check: context modifiers
      const wS = Math.max(0, start - 6);
      const before = raw.slice(wS, start);
      // "멀리", "굳이", "딴데", "까지" (location particle indicating distance/comparison)
      if (/(멀리|굳이|딴데|다른데|까지)\s*$/.test(before)) return true;

      return false;
    },
  },

  // ✅ SERVICE_EXTREME: "던지" 오탐 방지(하던지 X)
  {
    id: "service_extreme",
    aspect: "service",
    polarity: "NEG",
    baseWeight: 1.30,
    priority: 115,
    rx: /(막말|하대|서비스\s*최악|불친절\s*최악|무시당|무시하|반말|던져|던지(?=다|더|고|며|듯|길|면|지|네|네요|더라|더라고|더군|었|았)|툭툭|째려|도끼눈)/gi,
  },

  {
    id: "taste_strong_negative",
    aspect: "taste",
    polarity: "NEG",
    baseWeight: 1.20,
    priority: 110,
    rx: /(맛없|노맛|최악|쓰레기|실망|후회|비추|별\s*한\s*개도\s*아까)/gi,
  },

  // v17.5: 비교구문 NEG 선점 ("여기보다 맛있는 집 많음" 등)
  {
    id: "taste_comparison_others_better",
    aspect: "taste",
    polarity: "NEG",
    baseWeight: 0.95,
    priority: 105, // taste_positive(70)보다 높게
    rx: /(여기|이집|이곳|여긴|여기가)\s*(?:보다|보단)[\s\S]{0,10}(?:더\s*)?맛있(?:는|은)?[\s\S]{0,12}(?:집|곳|가게)(?:이|가|은|는|도)?\s*(?:더\s*)?(?:많|많음|많다|많아요|많더라)/gi,
  },

  // -------------------------
  // negatives (mild~moderate)
  // -------------------------
  {
    id: "value_negative",
    aspect: "value",
    polarity: "NEG",
    baseWeight: 0.90,
    priority: 95,
    rx: /(비싸|돈\s*아깝|가격대비\s*별로|창렬|가성비\s*(?:별로|최악)|값어치\s*의문)/gi,
    skipIf: (raw: string, start: number, end: number) => {
      // "돈 아깝지 않" / "비싸지만 돈값" 등 이미 POS로 잡힌 문맥이면 skip
      const wS = Math.max(0, start - 12);
      const wE = Math.min(raw.length, end + 12);
      const win = raw.slice(wS, wE);
      return /돈\s*(?:전혀|하나도)?\s*아깝지\s*않|돈\s*안\s*아깝|아깝지\s*않았|값어치\s*(?:있|충분)|돈값\s*(?:하|함)|가격\s*(?:이|도)\s*납득|비싼데도\s*(?:만족|괜찮)/iu.test(win);
    },
  },
  {
    id: "service_negative",
    aspect: "service",
    polarity: "NEG",
    baseWeight: 0.85,
    priority: 90,
    rx: /(불\s*친절|불친절|무례|퉁명|불쾌|성의\s*없|태도\s*별로|응대\s*별로|엉망|개판|한숨|인상\s*쓰)/gi,
  },

  // ambience: "좁음"은 아주 작은 감점
  {
    id: "ambience_space_minor",
    aspect: "ambience",
    polarity: "NEG",
    baseWeight: 0.22,
    priority: 86,
    rx: /(매장\s*좁|좁은\s*편|비좁|자리\s*좁|테이블\s*간격\s*좁)/gi,
  },
  {
    id: "ambience_negative",
    aspect: "ambience",
    polarity: "NEG",
    baseWeight: 0.48,
    priority: 88,
    rx: /(시끄럽|소음|불편|어수선|답답|연기|환기|냄새\s*배|덥|추웠)/gi,
  },

  // ✅ WAIT: 명시적 불만만 NEG (웨이팅 단독은 NEG 금지)
  {
    id: "wait_negative_explicit",
    aspect: "wait",
    polarity: "NEG",
    baseWeight: 0.55,
    priority: 92,
    rx: /(웨이팅|대기|줄)\s*(?:시간)?\s*(?:너무|진짜|엄청|겁나|개)\s*(?:길|김|오래)|대기\s*시간\s*(?:길|김|오래)|웨이팅\s*(?:지옥|헬|극악)|기다리다\s*(?:지침|지쳤|빡침|힘들|짜증)|(?:늦게\s*나오|오래\s*걸리)[\s\S]{0,10}(?:짜증|빡|불만|별로|실망)|(?:웨이팅|대기|줄)[\s\S]{0,12}\b[3-9]\d\s*분\b|(?:웨이팅|대기|줄)[\s\S]{0,12}한\s*시간/gi,
  },

  // ✅ WAIT: 시그널(정보) => POS(light), 단 불만 문맥이면 skip
  {
    id: "wait_positive_signal",
    aspect: "wait",
    polarity: "POS",
    baseWeight: 0.28,
    priority: 64,
    rx: /(웨이팅|대기|줄\s*서)/gi,
    skipIf: (raw, start, end) => {
      const wS = Math.max(0, start - 14);
      const wE = Math.min(raw.length, end + 14);
      const win = raw.slice(wS, wE);
      return /(너무|진짜|엄청|겁나|길|김|지옥|헬|극악|짜증|빡|힘들|지침|별로|실망)/iu.test(win);
    },
  },

  // (옵션) 웨이팅 없다 => 편의 POS
  {
    id: "wait_no_wait_positive",
    aspect: "wait",
    polarity: "POS",
    baseWeight: 0.32,
    priority: 66,
    rx: /(웨이팅|대기|줄)\s*(?:이|가)?\s*(?:전혀|거의)?\s*(?:없(?:었|더라|네요|었어요|어요|음|습니다)?|없다)/gi,
  },

  // taste texture negative (주의: “비린내 없다”는 위 POS가 선점)
  {
    id: "taste_texture_negative",
    aspect: "taste",
    polarity: "NEG",
    baseWeight: 0.78,
    priority: 85,
    rx: /(질기|퍽퍽|눅눅|비리|누린내|잡내|밍밍|싱겁|짜다|짜요|짜네)/gi,
    skipIf: (raw, start, end) => {
      const wS = Math.max(0, start - 18);
      const wE = Math.min(raw.length, end + 18);
      const win = raw.slice(wS, wE);
      if (/(맵|짜|달)/.test(win) && ADJUSTABLE_CONTEXT.test(win)) return true;
      return false;
    },
  },

  // -------------------------
  // POS (TASTE expanded massively)
  // -------------------------
  {
    id: "taste_positive_core_expanded",
    aspect: "taste",
    polarity: "POS",
    baseWeight: 1.00,
    priority: 70,
    rx: /(맛있|맛나|꿀맛|풍미|감칠맛|고소|담백|깔끔|진한\s*맛|깊은\s*맛|조화|밸런스|육즙|불향|숯향|바삭|바삭바삭|쫄깃|쫀득|탱글|탱탱|부드럽|촉촉|신선|향\s*좋|향이\s*좋|알덴테|면\s*삶|면발|소스\s*맛|소스가\s*(?:좋|미쳤|최고)|재료\s*퀄리티|퀄리티\s*(?:좋|확실)|재료가\s*(?:좋|다르)|토핑\s*(?:가득|많|추가|듬뿍)|치즈\s*(?:가득|많|추가|듬뿍))/gi,
  },
  {
    id: "taste_positive_texture_soft",
    aspect: "taste",
    polarity: "POS",
    baseWeight: 0.92,
    priority: 69,
    rx: /(포곤포곤|포슬포슬|폭신폭신|퐁신퐁신|폭닥|보들보들|쫀쫀|쫀득쫀득|탱글탱글|바삭바삭|꾸덕|꾸덕꾸덕|크리미|사르르|입에서\s*녹|식감\s*좋|식감이\s*좋)/gi,
  },
  {
    id: "taste_positive_deep",
    aspect: "taste",
    polarity: "POS",
    baseWeight: 0.95,
    priority: 68,
    rx: /(구수|진한\s*국물|깊은\s*국물|국물\s*맛|깊은\s*맛|깔끔한\s*맛|근본|전통\s*맛|정성\s*가득|재료가\s*신선)/gi,
  },
  {
    id: "taste_strong_praise_phrase",
    aspect: "taste",
    polarity: "POS",
    baseWeight: 1.22,
    priority: 66,
    rx: /(존맛(탱|탱구리)?|개맛있|개존맛|핵맛|jmt|미친\s*맛|맛\s*미쳤|레전드|역대급|원탑|탑티어|인생\s*(?:맛집|메뉴|파스타|브런치|디저트)|최애|찐맛집|검증된\s*맛집|끝내주|환상|황홀|미쳤다|미친듯이\s*맛)/gi,
  },

  // service positives
  {
    id: "service_positive",
    aspect: "service",
    polarity: "POS",
    baseWeight: 0.75,
    priority: 70,
    rx: /(친절|응대\s*좋|서비스\s*(?:좋|최고)|배려|잘해주|유쾌|감사|고맙)/gi,
    preCheck: (raw, start) => {
      const prev = start > 0 ? raw[start - 1] : "";
      if (prev === "불" || prev === "안") return false;
      return true;
    },
  },

  // hospitality positives (대접받는 느낌 / 정성)
  {
    id: "hospitality_positive",
    aspect: "overall",
    polarity: "POS",
    baseWeight: 0.95,
    priority: 68,
    rx: /(대접받|정성|흡족|기분\s*좋|즐거운\s*시간|돈\s*아깝지\s*않|기대\s*이상)/gi,
  },

  // overall / award signals
  {
    id: "overall_award_signal",
    aspect: "overall",
    polarity: "POS",
    baseWeight: 0.90,
    priority: 67,
    rx: /(블루\s*리본|블루리본|미슐랭|미쉐린|michelin)/gi,
  },
  {
    id: "overall_expectation_exceeded",
    aspect: "overall",
    polarity: "POS",
    baseWeight: 0.85,
    priority: 67,
    rx: /(기대\s*이상|상상\s*이상|예상\s*이상|생각\s*이상)/gi,
  },

  // value positives
  {
    id: "value_positive",
    aspect: "value",
    polarity: "POS",
    baseWeight: 0.70,
    priority: 68,
    rx: /(가성비\s*(?:좋|최고)|혜자|저렴|싸(?:다|요)|가격\s*(?:착|괜찮)|돈값|값어치\s*(?:있|충분)|가격값|무한리필)/gi,
  },

  // revisit positives
  {
    id: "revisit_positive",
    aspect: "revisit",
    polarity: "POS",
    baseWeight: 0.70,
    priority: 68,
    rx: /(재방문|또\s*갈|또\s*갈꺼|또\s*갈게|다시\s*갈|다음에도|또\s*오|자주\s*오|종종\s*오|매번\s*오|단골|정착)/gi,
  },

  // hygiene positives
  {
    id: "hygiene_positive",
    aspect: "hygiene",
    polarity: "POS",
    baseWeight: 0.60,
    priority: 65,
    rx: /(깨끗|청결|위생\s*좋|깔끔)/gi,
  },

  // ambience positives
  {
    id: "ambience_positive",
    aspect: "ambience",
    polarity: "POS",
    baseWeight: 0.65,
    priority: 65,
    rx: /(분위기\s*좋|인테리어\s*(?:예쁘|멋지)|쾌적|아늑|뷰\s*좋|조용|넓|개인룸)/gi,
  },

  // portion positives
  {
    id: "portion_positive",
    aspect: "portion",
    polarity: "POS",
    baseWeight: 0.60,
    priority: 62,
    rx: /(양\s*많|푸짐|넉넉|배부르|리필\s*가능|무한리필)/gi,
  },

  // overall positives / negatives
  {
    id: "overall_positive",
    aspect: "overall",
    polarity: "POS",
    baseWeight: 0.70,
    priority: 55,
    rx: /(만족|좋았|좋아요|추천|강추|최고|대박|훌륭|맛집)/gi,
    skipIf: (raw, start, end) => {
      const wS = Math.max(0, start - 12);
      const wE = Math.min(raw.length, end + 18);
      const win = raw.slice(wS, wE);
      return /(만족하실\s*수\s*있도록|만족할\s*수\s*있도록|만족하길|만족되면)/iu.test(win);
    },
  },
  {
    id: "overall_negative",
    aspect: "overall",
    polarity: "NEG",
    baseWeight: 0.70,
    priority: 55,
    rx: /(실망|후회|추천\s*안|안\s*추천)/gi,
  },
];

/* -------------------------
   HYBRID_PATCH: Scoring anchoring system
   Ported from test_bench.html v17.5.0
   - Long mixed anchor: clamps score near userRating
   - Seoul case floor: for pos-dominant minor-neg-only reviews
   - 4.5 gate enforcement after hybrid adjustments
------------------------- */
const HYBRID_PATCH = {
  enable: true,
  minorNegFactor: 0.35,
  posDominantMinPosCount: 2,
  posDominantRatio: 1.15,

  enableLongMixedAnchor: true,
  userRatingMaxUp: 0.20,
  userRatingMaxDownNormal: 1.0,
  userRatingMaxDownSevere: 2.0,

  enableSeoulCaseFloor: true,
  seoulCaseMinUserRating: 4.0,
  seoulCaseFloor: 4.0,
  seoulCaseUserRatingBias: 0.30,
  seoulCaseMinorNegPenalty: 0.08,

  enforce45GateAfterHybrid: true,
};

const HYBRID_SEVERE_NEG_RULE_IDS = new Set([
  "hygiene_critical", "fraud_price", "never_again", "service_extreme", "taste_strong_negative",
]);

function intensityMultiplier(raw: string, start: number, end: number, cfg: NeedsFineConfig) {
  const wS = Math.max(0, start - 10);
  const wE = Math.min(raw.length, end + 10);
  const win = raw.slice(wS, wE);

  let mult = 1.0;
  if (INTENSIFIERS.some((t) => win.includes(t))) mult *= cfg.intensityBoost;
  if (HEDGES.some((t) => win.includes(t))) mult *= cfg.hedgePenalty;
  if (win.includes("!")) mult *= cfg.exclamBoost;
  return clamp(0.6, cfg.maxWeightMultiplier, mult);
}

function preferenceMultiplier(raw: string, start: number, end: number) {
  const wS = Math.max(0, start - 18);
  const wE = Math.min(raw.length, end + 18);
  const win = raw.slice(wS, wE);
  if (PREFERENCE_CONTEXT.test(win)) return 0.88;
  return 1.0;
}

/* -------------------------
   Hybrid evidence extraction
------------------------- */
function extractEvidenceHybrid(rawNormalized: string, cfg: NeedsFineConfig, dynamicCues: DynamicCue[]) {
  const spans = collectNeutralizedSpans(rawNormalized);
  const masked = maskSpans(rawNormalized, spans);

  const { sentences } = buildSentenceInfo(rawNormalized);
  const nSent = Math.max(1, sentences.length);

  const candidates: EvidenceHit[] = [];

  // 1) Core rules — ✅ safeExecAll: clone RegExp to avoid lastIndex state bugs
  for (const rule of CORE_CUE_RULES) {
    const matches = safeExecAll(masked, rule.rx);
    for (const m of matches) {
      const start = m.index;
      const cue = m.text;
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

  // 2) Dynamic cues (Supabase lexicon)
  // - core 안전장치 우선: priority 기본 35 (core는 55~160)
  // - term은 plain match (indexOf)로 빠르게 처리
  if (dynamicCues && dynamicCues.length > 0) {
    for (const dc of dynamicCues) {
      const term = dc.term;
      if (!term || term.length < 2) continue;

      let from = 0;
      while (true) {
        const idx = masked.indexOf(term, from);
        if (idx < 0) break;

        const start = idx;
        const end = idx + term.length;

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

        const weight = dc.baseWeight * recency * contrast * intense * pref;

        candidates.push({
          aspect: dc.aspect,
          polarity: dc.polarity,
          weight,
          cue: term,
          snippet: makeSnippet(rawNormalized, start, end, cfg.snippetRadius),
          ruleId: "DYN:" + term,
          start,
          end,
          priority: dc.priority,
          absWeight: Math.abs(weight),
        });

        from = end; // prevent infinite loop on empty matches
      }
    }
  }

  candidates.sort((a, b) => {
    const pa = a.priority ?? 0;
    const pb = b.priority ?? 0;
    if (pb !== pa) return pb - pa;
    return (b.absWeight ?? 0) - (a.absWeight ?? 0);
  });

  const selected: EvidenceHit[] = [];
  for (const c of candidates) {
    if (selected.some((s) => overlaps({ start: c.start, end: c.end }, { start: s.start, end: s.end }))) continue;
    selected.push(c);
  }

  return { masked, selected };
}

/* -------------------------
   Strong negative ceiling
------------------------- */
function detectStrongNegative(textMasked: string): StrongNegative {
  const matched: string[] = [];

  const hygiene = /(벌레|이물질|곰팡|오염|악취|식중독|철수세미|재활용)/gi;
  const fraud = /(사기|바가지|가격\s*다르게|강요|강매|계산\s*실수|결제\s*실수|바꿔치기)/gi;
  const neverAgain = /(다신\s*안|다시는\s*안|두\s*번\s*다시\s*안|절대\s*안|강력\s*비추|먹지\s*마(?!시고)|가지\s*마(?!시고)|오지\s*마(?!시고))/gi;

  // ✅ "던지" 오탐 방지 동일 적용
  const serviceExtreme =
    /(막말|하대|서비스\s*최악|불친절\s*최악|무시당|무시하|반말|던져|던지(?=다|더|고|며|듯|길|면|지|네|네요|더라|더라고|더군|었|았)|툭툭|도끼눈|째려)/gi;

  const genericExtreme = /(최악|쓰레기|별\s*한\s*개도\s*아까|없어져도\s*되|절대\s*비추|안\s*추천|추천\s*안|후회합니다|후회됨)/gi;

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

  return { flag: false, type: "NONE", ceiling: 4.9, matched: [] };
}

/* -------------------------
   Score label mapping
------------------------- */
function scoreToLabel(score: number) {
  if (score <= 0.01) return "무의미/무관 리뷰";
  if (score < 2.0) return "많이 노력해야하는 집";
  if (score < 3.0) return "노력해야하는 집";
  if (score < 3.5) return "호불호 갈리는 집";
  if (score < 3.9) return "괜찮은 집";
  if (score < 4.4) return "지역맛집";
  return "웨이팅 맛집";
}

/* -------------------------
   Trust scoring (with caps)
------------------------- */
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
  strongNeg: StrongNegative;
  userRating?: number;
  posEvidenceCount: number;
  negEvidenceCount: number;
}) {
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

  const onlyNoise = /^[ㅋㅎㅠㅜ!?.,\s]+$/.test(normalized) && lenNoSpace <= 10;
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

  // [수정] 감탄사 과다 및 구체적 정보 부족 페널티 강화
  const excl = (normalized.match(/!/g) || []).length;
  if (excl >= 3) {
    // 3개 이상부터 1개당 3점씩 차감 (최대 20점 차감)
    trust -= Math.min(20, (excl - 2) * 3);
  }

  const hasConcreteDetails = hasNumbers || hasPrice || hasTime;
  if (!hasConcreteDetails && lenNoSpace >= 20) {
    trust -= 10; // 구체적 정보(숫자, 가격, 시간)가 없으면 신뢰도 대폭 차감
  }

  if (lenNoSpace < 25 && evidenceCount <= 1) {
    if (strongNeg.flag && strongNeg.type === "HYGIENE_CRITICAL") trust = Math.min(trust, 65);
    else trust = Math.min(trust, 50);
  }

  if (typeof userRating === "number" && Number.isFinite(userRating)) {
    if (userRating >= 4.5 && negEvidenceCount >= 2 && posEvidenceCount === 0) trust -= 10;

    // Sarcasm Penalty (반어법 / 별점-텍스트 강한 모순)
    if (userRating <= 2.5 && posEvidenceCount > 0 && negEvidenceCount === 0) {
      if (posEvidenceCount >= 2) trust -= 40; // 강력한 페널티
      else trust -= 20;
    }
  }

  return clamp(0, 100, Math.round(trust));
}

function applyTrustCaps(trust: number, hasPhoto: boolean, cfg: NeedsFineConfig) {
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

/* -------------------------
   Score caps by user rating (policy max caps)
------------------------- */
function applyUserRatingScoreCaps(score: number, userRating: number | string | undefined, cfg: NeedsFineConfig): { score: number, capApplied?: number } {
  if (typeof userRating !== "number") return { score, capApplied: undefined };
  let cap = cfg.maxScore;
  if (userRating < 2.0) cap = cfg.scoreCapUserRatingLt2;
  else if (userRating < 3.0) cap = cfg.scoreCapUserRatingLt3;
  else if (userRating < 4.0) cap = cfg.scoreCapUserRatingLt4;

  if (score > cap) return { score: cap, capApplied: cap };
  return { score, capApplied: undefined };
}
/* -------------------------
   POLICY A: High-rating forced floor (v17.5)
------------------------- */
function computeHighRatingFloor(userRating: number, cfg: NeedsFineConfig) {
  // 4.0★ => 3.5
  // 5.0★ => 3.7
  const perStar = 0.2;
  const floor = cfg.highRatingFloorMinScore + perStar * (userRating - cfg.highRatingFloorMinUserRating);
  // 최대 +0.6까지만 허용(안전장치)
  return clamp(cfg.highRatingFloorMinScore, cfg.highRatingFloorMinScore + 0.6, floor);
}

function applyHighRatingFloorForced(score: number, userRating: number | undefined, cfg: NeedsFineConfig) {
  if (!cfg.enableHighRatingFloor) return score;
  if (typeof userRating !== "number" || !Number.isFinite(userRating)) return score;
  if (userRating < cfg.highRatingFloorMinUserRating) return score;
  return Math.max(score, computeHighRatingFloor(userRating, cfg));
}

/* -------------------------
   Irrelevant / noise-only detection
------------------------- */
function isHardNoiseOrTest(normalized: string, lenNoSpace: number) {
  const s = normalized.trim();
  if (!s) return false;

  if (/^[ㅋㅎㅠㅜ!?.,\s]+$/.test(s)) return true;

  if (
    lenNoSpace <= 24 &&
    /^(test|tset|asdf|qwer|zxcv|ghj|gf|qqq|www|eee|rrr|ttt|yyy|uuu|iii|ooo|ppp)$/iu.test(s.replace(/\s+/g, ""))
  )
    return true;

  if (lenNoSpace <= 30 && /^[a-z0-9\s]+$/iu.test(s) && /(test|dummy|sample)/iu.test(s)) return true;

  if (/^[ㄱ-ㅎㅏ-ㅣ]+$/.test(s) && lenNoSpace <= 20) return true;

  return false;
}

function hasRestaurantContext(normalized: string) {
  return /(맛|먹|음식|메뉴|식당|가게|맛집|주문|방문|서비스|가격|가성비|위생|청결|깨끗|깔끔|분위기|매장|좌석|테이블|웨이팅|대기|줄|양|리필|추천|비추|실망|후회|친절|불친절)/iu.test(
    normalized,
  );
}

function isIrrelevantReview(params: { normalized: string; lenNoSpace: number; hangulRatio: number; mentionCount: number; evidenceCount: number }) {
  const { normalized, lenNoSpace, hangulRatio: hr, mentionCount, evidenceCount } = params;

  if (isHardNoiseOrTest(normalized, lenNoSpace)) return true;

  if (mentionCount === 0 && evidenceCount === 0) {
    const hasCtx = hasRestaurantContext(normalized);

    // Short-but-meaningful opinion words that often appear without domain keywords.
    const shortButMeaningful =
      /(보통|무난|쏘쏘|평범|그냥|그저|나쁘지|괜찮|별로|굿|짱|강추|아쉽|애매|좋(아요|음)?|최고|최악|만족|불만|추천|비추|실망|후회|다신|재방문|또\s*갈|또\s*오)/u.test(normalized);

    // If there's enough natural language signal (even without explicit restaurant keywords),
    // don't force IRRELEVANT_CONTEXTLESS.
    const looksLikeNaturalText = lenNoSpace >= 4 && hr >= 0.35;

    if (!hasCtx && !shortButMeaningful && !looksLikeNaturalText) return true;

    // Also guard very low Hangul ratio + no obvious domain words (mostly symbols/latin)
    if (
      hr < 0.18 &&
      !shortButMeaningful &&
      !/(맛|food|meal|restaurant|place|서비스|service|price|가격|menu|메뉴|portion|양|staff|직원|owner|사장|clean|hygiene|recommend)/iu.test(
        normalized,
      )
    ) {
      return true;
    }
  }

  return false;
}

/* -------------------------
   Main analyzeReview (Hybrid)
------------------------- */
export function analyzeReview(
  input: ReviewInput,
  options: AnalyzeOptions = {},
  cfg: NeedsFineConfig = DEFAULT_CONFIG,
  dynamicCues: DynamicCue[] = [],
): AnalyzeResult {
  const debugOn = options.debug !== false;

  const normalized = normalizeText(input.text || "");
  const hasPhoto = Boolean(input.hasPhoto);
  const userRating = parseUserRating(input.userRating);

  const compact = normalized.replace(/\s+/g, "");
  const lenNoSpace = compact.length;

  // No text => score 3.0, trust 30
  if (!normalized || lenNoSpace <= 0) {
    const baseScoreNoText = 3.0;
    const { score: capped, capApplied } = applyUserRatingScoreCaps(baseScoreNoText, userRating, cfg);

    const baseTrustNoText = 30;
    const { trust, trustCaps } = applyTrustCaps(baseTrustNoText, hasPhoto, cfg);

    const finalScore = roundToStep(clamp(0, cfg.maxScore, capped), cfg.roundingStep);

    return {
      needsFineScore: finalScore,
      trust,
      label: scoreToLabel(finalScore),
      tags: [],
      evidence: {
        positive: [],
        negative: [],
        strongNegative: { flag: false, type: "NONE", ceiling: cfg.maxScore, matched: [] },
      },
      debug: debugOn
        ? {
          normalized,
          masked: normalized,
          appliedCaps: ["NO_TEXT_SCORE_3.0_TRUST_30", ...(capApplied ? [`USER_RATING_CAP => ${capApplied}`] : [])],
          baseScore: cfg.baseScore,
          scoreMode: "NO_TEXT",
          rawScore: finalScore,
          detailBonus: 0,
          synergyBonus: 0,
          caveatAttenuated: false,
          userRating,
          userRatingCapApplied: capApplied,
          trustCaps,
          posAxes: [],
          negAxes: [],
          feature: { lenNoSpace },
        }
        : undefined,
    };
  }

  // Hard noise/test early exit
  if (isHardNoiseOrTest(normalized, lenNoSpace)) {
    const baseTrust = 0;
    const { trust, trustCaps } = applyTrustCaps(baseTrust, hasPhoto, cfg);
    const score0 = 0.0;
    return {
      needsFineScore: score0,
      trust,
      label: scoreToLabel(score0),
      tags: [],
      evidence: {
        positive: [],
        negative: [],
        strongNegative: { flag: false, type: "NONE", ceiling: cfg.maxScore, matched: [] },
      },
      debug: debugOn
        ? {
          normalized,
          masked: normalized,
          appliedCaps: ["IRRELEVANT_NOISE_OR_TEST => SCORE_0_TRUST_0"],
          baseScore: cfg.baseScore,
          scoreMode: "IRRELEVANT",
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

  // Simple review shortcut (요구사항 1: 유지)
  const simpleKind = detectSimpleReview(normalized);
  if (simpleKind !== "NONE") {
    const base = simpleKind === "SIMPLE_POS" ? 3.2 : 2.7;
    const { score: capped, capApplied } = applyUserRatingScoreCaps(base, userRating, cfg);
    const score = roundToStep(clamp(0, cfg.maxScore, capped), cfg.roundingStep);

    const baseTrust = 50;
    const { trust, trustCaps } = applyTrustCaps(baseTrust, hasPhoto, cfg);

    const tag: TagResult = {
      aspect: "taste",
      label: ASPECT_LABEL.taste,
      mentioned: true,
      polarity: simpleKind === "SIMPLE_POS" ? "POS" : "NEG",
      strength: 0.55,
    };

    const fakeHit: EvidenceHit = {
      aspect: "taste",
      polarity: simpleKind === "SIMPLE_POS" ? "POS" : "NEG",
      weight: 1.0,
      cue: simpleKind === "SIMPLE_POS" ? "맛있" : "맛없",
      snippet: normalized.slice(0, Math.min(40, normalized.length)),
      ruleId: "SIMPLE_REVIEW",
      start: 0,
      end: Math.min(normalized.length, 10),
    };

    return {
      needsFineScore: score,
      trust,
      label: scoreToLabel(score),
      tags: [tag],
      evidence: {
        positive: simpleKind === "SIMPLE_POS" ? [fakeHit] : [],
        negative: simpleKind === "SIMPLE_NEG" ? [fakeHit] : [],
        strongNegative: { flag: false, type: "NONE", ceiling: cfg.maxScore, matched: [] },
      },
      debug: debugOn
        ? {
          normalized,
          masked: normalized,
          appliedCaps: ["SIMPLE_REVIEW_SCORE_TRUST", ...(capApplied ? [`USER_RATING_CAP => ${capApplied}`] : [])],
          baseScore: cfg.baseScore,
          scoreMode: "SIMPLE",
          rawScore: score,
          detailBonus: 0,
          synergyBonus: 0,
          caveatAttenuated: false,
          userRating,
          userRatingCapApplied: capApplied,
          trustCaps,
          posAxes: simpleKind === "SIMPLE_POS" ? ["taste"] : [],
          negAxes: simpleKind === "SIMPLE_NEG" ? ["taste"] : [],
          feature: { lenNoSpace, simpleKind },
        }
        : undefined,
    };
  }

  // Full analysis
  const mentionSet = detectAspectMentions(normalized);
  const { masked, selected } = extractEvidenceHybrid(normalized, cfg, dynamicCues);

  // Irrelevant detection
  if (
    isIrrelevantReview({
      normalized,
      lenNoSpace,
      hangulRatio: hangulRatio(normalized),
      mentionCount: mentionSet.size,
      evidenceCount: selected.length,
    })
  ) {
    const baseTrust = 0;
    const { trust, trustCaps } = applyTrustCaps(baseTrust, hasPhoto, cfg);
    const score0 = 0.0;

    return {
      needsFineScore: score0,
      trust,
      label: scoreToLabel(score0),
      tags: [],
      evidence: {
        positive: [],
        negative: [],
        strongNegative: { flag: false, type: "NONE", ceiling: cfg.maxScore, matched: [] },
      },
      debug: debugOn
        ? {
          normalized,
          masked,
          appliedCaps: ["IRRELEVANT_CONTEXTLESS => SCORE_0_TRUST_0"],
          baseScore: cfg.baseScore,
          scoreMode: "IRRELEVANT",
          rawScore: score0,
          detailBonus: 0,
          synergyBonus: 0,
          caveatAttenuated: false,
          userRating,
          userRatingCapApplied: undefined,
          trustCaps,
          posAxes: [],
          negAxes: [],
          feature: { lenNoSpace, mentionCount: mentionSet.size, evidenceCount: selected.length },
        }
        : undefined,
    };
  }

  const strongNeg = detectStrongNegative(masked);

  const allAspects: Aspect[] = ["taste", "service", "value", "revisit", "hygiene", "ambience", "wait", "portion", "overall"];

  const aspects: Record<Aspect, { pos: number; neg: number; posHits: EvidenceHit[]; negHits: EvidenceHit[] }> = Object.create(null);
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
  const posAxes: Aspect[] = [];
  const negAxes: Aspect[] = [];

  for (const a of allAspects) {
    const mentioned = mentionSet.has(a) || aspects[a].posHits.length > 0 || aspects[a].negHits.length > 0;
    const pos = aspects[a].pos;
    const neg = aspects[a].neg;
    const net = pos - neg;

    let polarity: TagResult["polarity"] = "NEUTRAL";
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

  // SCORE computation (REGULAR)
  let scoreRegular = cfg.baseScore;
  let posContrib = 0;
  let negContrib = 0;

  const negNonCaveatSum = allAspects
    .filter((a) => !cfg.caveatAspects.includes(a))
    .reduce((acc, a) => acc + aspects[a].neg, 0);

  const tastePos = aspects.taste.pos;
  const caveatAttenuated = tastePos >= cfg.caveatApplyTastePosMin && negNonCaveatSum <= cfg.caveatApplyNegNonCaveatMax;

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

  // detail bonus
  const hasNumbers = /\d/.test(normalized);
  const hasPrice = /(\d+\s*원|만원)/iu.test(normalized);
  const hasTime = /(\b\d+\s*(분|시간)\b|한\s*시간)/iu.test(normalized);
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
  let scoreMode = "REGULAR";

  // brevity caps
  if (lenNoSpace <= 6) {
    scoreRegular = Math.min(scoreRegular, 3.1);
    appliedCaps.push("BREVITY_CAP_LEN<=6 => 3.1");
  } else if (lenNoSpace <= 12) {
    scoreRegular = Math.min(scoreRegular, 3.4);
    appliedCaps.push("BREVITY_CAP_LEN<=12 => 3.4");
  }

  // optional lift
  let ratingLift = 0;
  if (cfg.enableUserRatingLift && typeof userRating === "number" && userRating >= 3.0) {
    const quality = clamp(0, 1, evidencePosAll.length / 4 + distinctPosAxesCount / 4);
    if (!strongNeg.flag && lenNoSpace >= cfg.ratingLiftMinLen && evidencePosAll.length >= cfg.ratingLiftMinPosEvidence) {
      ratingLift = Math.min(cfg.ratingLiftMax, (userRating - 3.0) * cfg.ratingLiftPerStar * quality);
      scoreRegular += ratingLift;
      appliedCaps.push(`USER_RATING_LIFT(+${ratingLift.toFixed(2)})`);
    }
  }

  // POLICY B: long mixed
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
      `POLICY_B_LONG_MIXED: baseline(userRating-${cfg.longMixedRatingDelta})=${baseline.toFixed(2)}, +posOnly*${cfg.longMixedPosGainMultiplier}(${posGainBase.toFixed(
        2,
      )})`,
    );
  }

  // POLICY C: long positive floor
  let scoreLongPositive: number | undefined = undefined;
  const hasCorePos = posAxes.some((a) => cfg.coreAxes.includes(a));
  const isLongPositiveCandidate =
    cfg.enableLongPositiveFloor &&
    typeof userRating === "number" &&
    userRating >= cfg.longPositiveRatingMin &&
    !strongNeg.flag &&
    lenNoSpace >= cfg.longPositiveMinLenNoSpace &&
    evidencePosAll.length >= cfg.longPositiveMinPosEvidence &&
    (cfg.longPositiveMinCorePos ? hasCorePos : true) &&
    negNonCaveatSum <= cfg.longPositiveMaxNegNonCaveatSum;

  if (isLongPositiveCandidate) {
    const baseline = userRating - cfg.longPositiveRatingDelta;
    const positiveGainBase = posContrib + synergyBonus + detailBonus;
    scoreLongPositive = baseline + cfg.longPositivePosGainMultiplier * positiveGainBase;

    appliedCaps.push(
      `POLICY_C_LONG_POSITIVE_FLOOR: baseline(userRating-${cfg.longPositiveRatingDelta})=${baseline.toFixed(2)}, +pos*${cfg.longPositivePosGainMultiplier}(${positiveGainBase.toFixed(
        2,
      )})`,
    );
  }

  // choose best
  let score = scoreRegular;

  if (scoreLongMixed !== undefined && scoreLongMixed > score) {
    score = scoreLongMixed;
    scoreMode = "LONG_MIXED_POS_ONLY";
  }

  if (scoreLongPositive !== undefined) {
    if (score < scoreLongPositive) {
      score = scoreLongPositive;
      scoreMode = "LONG_POSITIVE_FLOOR";
    }
  }

  // strong negative ceiling
  if (strongNeg.flag) {
    score = Math.min(score, strongNeg.ceiling);
    appliedCaps.push(`STRONG_NEG_CEILING(${strongNeg.type}) => ${strongNeg.ceiling}`);
  }

  // --- HYBRID Adjustments (ported from test_bench.html) ---
  const hybridMinorAspects = new Set(cfg.caveatAspects);
  const hybridPosSum = evidencePosAll.reduce((s, h) => s + (h.weight ?? 0), 0);
  const hybridNegMinorSum = evidenceNegAll.filter((h) => hybridMinorAspects.has(h.aspect as Aspect)).reduce((s, h) => s + Math.abs(h.weight ?? 0), 0);
  const hybridNegMajorSum = evidenceNegAll.filter((h) => !hybridMinorAspects.has(h.aspect as Aspect)).reduce((s, h) => s + Math.abs(h.weight ?? 0), 0);
  const hybridNegEffective = hybridNegMajorSum + HYBRID_PATCH.minorNegFactor * hybridNegMinorSum;
  const hybridHasSevereNeg = strongNeg.flag || evidenceNegAll.some((h) => HYBRID_SEVERE_NEG_RULE_IDS.has(h.ruleId));
  const hybridPosDominant = evidencePosAll.length >= HYBRID_PATCH.posDominantMinPosCount && (hybridNegEffective <= 0.00001 ? hybridPosSum >= 0.8 : hybridPosSum >= HYBRID_PATCH.posDominantRatio * hybridNegEffective);

  let hybridAnchorApplied = false;
  let hybridSeoulApplied = false;
  let hybridSeoulCandidate: number | null = null;

  if (HYBRID_PATCH.enable && typeof userRating === "number" && !strongNeg.flag) {
    // Long Mixed Anchor: clamp score near userRating
    if (HYBRID_PATCH.enableLongMixedAnchor && isLongMixed && hybridPosDominant) {
      const maxDown = hybridHasSevereNeg ? HYBRID_PATCH.userRatingMaxDownSevere : HYBRID_PATCH.userRatingMaxDownNormal;
      const floor = userRating - maxDown;
      const cap = userRating + HYBRID_PATCH.userRatingMaxUp;
      const before = score;
      const anchored = clamp(floor, cap, score);
      if (anchored !== before) {
        score = anchored;
        appliedCaps.push(`HYBRID_ANCHOR range=[${(userRating - maxDown).toFixed(2)},${(userRating + HYBRID_PATCH.userRatingMaxUp).toFixed(2)}] ${before.toFixed(2)}→${score.toFixed(2)}`);
        hybridAnchorApplied = true;
      }
    }

    // Seoul Case Floor: pos-dominant with only minor negatives
    const isSeoulGopchangCase = HYBRID_PATCH.enableSeoulCaseFloor && isLongMixed && userRating >= HYBRID_PATCH.seoulCaseMinUserRating && hybridPosDominant && hybridNegMajorSum <= 0.00001 && !hybridHasSevereNeg;
    if (isSeoulGopchangCase) {
      const floor = HYBRID_PATCH.seoulCaseFloor;
      const cap = Math.max(floor, userRating - HYBRID_PATCH.seoulCaseUserRatingBias);
      const candidate = clamp(floor, cap, (userRating - HYBRID_PATCH.seoulCaseUserRatingBias) - HYBRID_PATCH.seoulCaseMinorNegPenalty * hybridNegMinorSum);
      hybridSeoulCandidate = candidate;
      if (score < candidate) {
        const before = score;
        score = candidate;
        scoreMode = "HYBRID_SEOUL_ANCHOR";
        appliedCaps.push(`HYBRID_SEOUL_CASE floor=${floor.toFixed(2)} cap=${cap.toFixed(2)} negMinor=${hybridNegMinorSum.toFixed(2)} => ${before.toFixed(2)}→${score.toFixed(2)}`);
        hybridSeoulApplied = true;
      }
    }
  }

  // 4.0 / 4.5 gates
  const distinctPosEvidence = new Set(evidencePosAll.map((e) => `${e.aspect}:${e.ruleId}`)).size;
  const bypassGate4 = (scoreMode === "LONG_POSITIVE_FLOOR" && isLongPositiveCandidate) || (scoreMode === "HYBRID_SEOUL_ANCHOR");

  if (score >= 4.0 && !bypassGate4) {
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

  // Calculate Trust *early* so we can cap the score for low-trust spammy reviews
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

  // TRUST-BASED SCORE CEILING
  // 신뢰도가 60 미만인 광고성/가짜 의심 리뷰는 점수를 3점대 중반(3.6)으로 강제 제한
  if (trust < 60) {
    const capFake = 3.6;
    if (score > capFake) {
      score = capFake;
      appliedCaps.push(`TRUST_SCALING_CAP(trust<60) => ${capFake}`);
    }
  }

  // global max cap (4.9)
  score = Math.min(score, cfg.maxScore);

  // clamp
  let rawScore = clamp(0.0, cfg.maxScore, score);

  // userRating max caps
  const { score: cappedByUserRating, capApplied } = applyUserRatingScoreCaps(rawScore, userRating, cfg);
  rawScore = cappedByUserRating;
  if (capApplied !== undefined) appliedCaps.push(`USER_RATING_CAP => ${capApplied}`);

  // POLICY A forced floor (v17.5: dynamic). strong negative면 floor 적용 금지(ceiling 보호)
  if (!strongNeg.flag) {
    const beforeFloor = rawScore;
    rawScore = applyHighRatingFloorForced(rawScore, userRating, cfg);
    if (rawScore !== beforeFloor && typeof userRating === "number" && userRating >= cfg.highRatingFloorMinUserRating) {
      appliedCaps.push(`POLICY_A_HIGH_RATING_FLOOR => ${computeHighRatingFloor(userRating, cfg).toFixed(1)}`);
    }
  }

  // round (일단 1차 산출)
  let finalScore = roundToStep(clamp(0.0, cfg.maxScore, rawScore), cfg.roundingStep);
  if (capApplied !== undefined) finalScore = Math.min(finalScore, capApplied);

  // evidence output
  const posOut =
    options.returnAllEvidence === true ? [...evidencePosAll] : [...evidencePosAll].sort((a, b) => b.weight - a.weight).slice(0, 2);
  const negOut =
    options.returnAllEvidence === true ? [...evidenceNegAll] : [...evidenceNegAll].sort((a, b) => b.weight - a.weight).slice(0, 2);

  // (추가 안전) cap 이후 최종 라운딩 재보정 (cap 값이 0.1 step이므로 안정적)
  finalScore = roundToStep(clamp(0.0, cfg.maxScore, finalScore), cfg.roundingStep);
  if (capApplied !== undefined) finalScore = Math.min(finalScore, capApplied);

  let uiTags = tagsAll.filter((t) => t.mentioned);

  // [추가] 모순 태그 방지 (Contradictory Tag Prevention)
  // 평점이 2.0 이하이거나 치명적인 부정(strongNeg)이 있는 경우 긍정(POS) 태그 표출 완전 차단
  if ((typeof userRating === "number" && userRating <= 2.0) || strongNeg.flag) {
    uiTags = uiTags.filter((t) => t.polarity !== "POS");
  }

  return {
    needsFineScore: finalScore,
    trust,
    label: scoreToLabel(finalScore),
    tags: uiTags,
    evidence: {
      positive: posOut,
      negative: negOut,
      strongNegative: strongNeg,
    },
    debug: debugOn
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
          scoreLongPositive,
          isLongPositiveCandidate,
          dynamicCueCount: dynamicCues?.length ?? 0,
          evidenceAllCount: selected.length,
        },
      }
      : undefined,
  };
}

/* -------------------------------------------------------
   Hybrid self-learning: term mining + optional auto-promote
-------------------------------------------------------- */

const STOPWORDS = new Set<string>([
  "그리고",
  "그래서",
  "하지만",
  "그런데",
  "다만",
  "근데",
  "반면",
  "대신",
  "그래도",
  "진짜",
  "너무",
  "완전",
  "엄청",
  "개",
  "존",
  "핵",
  "미친",
  "최고",
  "대박",
  "약간",
  "그냥",
  "무난",
  "나름",
  "뭐",
  "그럭저럭",
  "평범",
  "여기",
  "거기",
  "저기",
  "오늘",
  "어제",
  "내일",
  "이번",
  "저번",
  "다음",
  "사람",
  "분들",
  "사장님",
  "직원",
  "가게",
  "식당",
  "매장",
  "음식",
  "메뉴",
  "맛",
  "서비스",
  "가격",
  "가성비",
  "위생",
  "청결",
  "분위기",
  "웨이팅",
  "대기",
  "추천",
  "비추",
  "최악",
  "실망",
  "후회",
  "좋아요",
  "좋았",
  "괜찮",
  "맛있",
  "맛없",
  "친절",
  "불친절",
]);

type TermEvent = {
  term: string;
  aspect: Aspect;
  polarity: Polarity;
  confidence: number; // 0~1
};

function extractHangulTokens(normalized: string) {
  const tokens = normalized.match(/[가-힣]{2,}/g) ?? [];
  const uniq = Array.from(new Set(tokens));
  return uniq;
}

export function mineTermEvents(params: { normalized: string; evidenceAll: EvidenceHit[]; dynamicCues: DynamicCue[]; maxTerms?: number }): TermEvent[] {
  const { normalized, evidenceAll, dynamicCues } = params;
  const maxTerms = params.maxTerms ?? 24;

  // known dynamic single-word terms (avoid re-mining)
  const known = new Set<string>();
  for (const dc of dynamicCues ?? []) {
    if (!dc.term) continue;
    const t = dc.term.trim();
    if (t.length >= 2 && t.length <= 12 && !t.includes(" ")) known.add(t);
  }

  const tokens = extractHangulTokens(normalized)
    .map((t) => t.trim())
    .filter((t) => t.length >= 2 && t.length <= 10)
    .filter((t) => !STOPWORDS.has(t))
    .filter((t) => !known.has(t));

  if (tokens.length === 0) return [];

  // sentence signals
  const { sentences } = buildSentenceInfo(normalized);
  const perSentNet: Array<Record<Aspect, number>> = sentences.map(() => {
    const obj: Record<Aspect, number> = {
      taste: 0,
      service: 0,
      value: 0,
      revisit: 0,
      hygiene: 0,
      ambience: 0,
      wait: 0,
      portion: 0,
      overall: 0,
    };
    return obj;
  });

  for (const hit of evidenceAll) {
    const sIdx = findSentenceIndex(sentences, hit.start);
    const sign = hit.polarity === "POS" ? 1 : -1;
    perSentNet[sIdx][hit.aspect] += sign * Math.abs(hit.weight);
  }

  const events: TermEvent[] = [];

  for (const term of tokens) {
    // find first occurrence only (reduce noisy counts)
    const idx = normalized.indexOf(term);
    if (idx < 0) continue;
    const sIdx = findSentenceIndex(sentences, idx);

    const net = perSentNet[sIdx];
    // choose best aspect by |net|
    let bestAspect: Aspect | null = null;
    let bestAbs = 0;
    let bestNet = 0;
    let secondAbs = 0;

    (Object.keys(net) as Aspect[]).forEach((a) => {
      const v = net[a];
      const av = Math.abs(v);
      if (av > bestAbs) {
        secondAbs = bestAbs;
        bestAbs = av;
        bestNet = v;
        bestAspect = a;
      } else if (av > secondAbs) {
        secondAbs = av;
      }
    });

    // not enough signal in that sentence
    if (!bestAspect || bestAbs < 0.55) continue;

    const polarity: Polarity = bestNet >= 0 ? "POS" : "NEG";
    const conf = clamp(0, 1, bestAbs / (bestAbs + secondAbs + 0.15));
    if (conf < 0.58) continue;

    events.push({ term, aspect: bestAspect, polarity, confidence: conf });
  }

  // sort by confidence and trim
  events.sort((a, b) => b.confidence - a.confidence);
  return events.slice(0, maxTerms);
}

type CandidateRow = {
  term: string;
  stats: Record<string, number>;
  total_count: number;
  best_aspect: Aspect | null;
  best_polarity: Polarity | null;
  best_count: number;
  confidence: number;
  promoted: boolean;
};

function pickBest(stats: Record<string, number>) {
  const entries = Object.entries(stats).sort((a, b) => b[1] - a[1]);
  const [bestKey, bestCount] = entries[0] ?? ["", 0];
  const secondCount = entries[1]?.[1] ?? 0;
  return { bestKey, bestCount, secondCount };
}

function parseKey(key: string): { aspect: Aspect | null; polarity: Polarity | null } {
  const [a, p] = key.split("|");
  const aspect = isAspect(a) ? a : null;
  const polarity = isPolarity(p) ? p : null;
  return { aspect, polarity };
}

export async function upsertCandidateTerms(supabase: SupabaseClient, events: TermEvent[]): Promise<{ updated: number; promoted: number }> {
  if (!events || events.length === 0) return { updated: 0, promoted: 0 };

  const nowIso = new Date().toISOString();
  const terms = Array.from(new Set(events.map((e) => e.term)));

  // fetch existing rows (batch)
  const { data: existing, error: selErr } = await supabase
    .from("needsfine_candidate_terms")
    .select("term,stats,total_count,best_aspect,best_polarity,best_count,confidence,promoted")
    .in("term", terms);

  if (selErr) {
    console.error("[candidate_terms] select error:", selErr);
    // still try naive upsert (overwrite only)
  }

  const map = new Map<string, any>();
  for (const r of existing ?? []) map.set(String((r as any).term), r);

  const payload: any[] = [];

  // update stats
  for (const ev of events) {
    const cur = map.get(ev.term);
    const stats: Record<string, number> = (cur?.stats as any) && typeof cur.stats === "object" ? { ...(cur.stats as any) } : {};
    const key = `${ev.aspect}|${ev.polarity}`;
    stats[key] = (stats[key] ?? 0) + 1;

    const total = Number(cur?.total_count ?? 0) + 1;

    const { bestKey, bestCount } = pickBest(stats);
    const { aspect: bestAspect, polarity: bestPol } = parseKey(bestKey);
    const conf = total > 0 ? bestCount / total : 0;

    payload.push({
      term: ev.term,
      stats,
      total_count: total,
      best_aspect: bestAspect,
      best_polarity: bestPol,
      best_count: bestCount,
      confidence: conf,
      promoted: Boolean(cur?.promoted ?? false),
      last_seen: nowIso,
      updated_at: nowIso,
    });
  }

  const { error: upErr } = await supabase.from("needsfine_candidate_terms").upsert(payload, { onConflict: "term" });
  if (upErr) console.error("[candidate_terms] upsert error:", upErr);

  // optional auto-promote
  const autoPromote = Deno.env.get("NEEDSFINE_AUTO_PROMOTE") === "1";
  const minCount = Number(Deno.env.get("NEEDSFINE_PROMOTE_MIN_COUNT") ?? "10");
  const minConf = Number(Deno.env.get("NEEDSFINE_PROMOTE_MIN_CONF") ?? "0.88");

  let promoted = 0;

  if (autoPromote) {
    // re-read to ensure latest (batch)
    const { data: rows, error: readErr } = await supabase
      .from("needsfine_candidate_terms")
      .select("term,total_count,best_aspect,best_polarity,confidence,promoted")
      .in("term", terms);

    if (readErr) {
      console.error("[candidate_terms] reread error:", readErr);
      return { updated: terms.length, promoted: 0 };
    }

    const toPromote = (rows ?? []).filter((r: any) => {
      const total = Number(r.total_count ?? 0);
      const conf = Number(r.confidence ?? 0);
      const already = Boolean(r.promoted ?? false);
      const a = r.best_aspect;
      const p = r.best_polarity;
      return !already && total >= minCount && conf >= minConf && isAspect(a) && isPolarity(p);
    });

    if (toPromote.length > 0) {
      // insert lexicon (ignore duplicates so manual lexicon stays)
      const lexPayload = toPromote.map((r: any) => {
        const total = Number(r.total_count ?? 0);
        const conf = Number(r.confidence ?? 0);

        // weight: confidence/빈도 기반으로 아주 보수적으로
        const weight = clamp(0.15, 0.65, 0.18 + Math.log10(1 + total) * 0.1 + conf * 0.22);

        return {
          term: normalizeText(r.term),
          aspect: r.best_aspect,
          polarity: r.best_polarity,
          weight,
          priority: 33, // core보다 낮게
          enabled: true,
          source: "auto",
          confidence: conf,
          occurrences: total,
          updated_at: nowIso,
        };
      });

      const { error: lexErr } = await supabase
        .from("needsfine_lexicon")
        .upsert(lexPayload, { onConflict: "term", ignoreDuplicates: true });
      if (lexErr) {
        console.error("[lexicon] auto-promote upsert error:", lexErr);
      } else {
        promoted = lexPayload.length;

        // mark promoted=true
        const promTerms = lexPayload.map((x: any) => x.term);
        const { error: markErr } = await supabase.from("needsfine_candidate_terms").update({ promoted: true, updated_at: nowIso }).in("term", promTerms);

        if (markErr) console.error("[candidate_terms] mark promoted error:", markErr);

        // invalidate cache (so newly promoted terms affect scoring quickly)
        invalidateLexiconCache();
      }
    }
  }

  return { updated: terms.length, promoted };
}

/* -------------------------------------------------------
   Supabase dynamic lexicon loader (cached)
-------------------------------------------------------- */
let _lexCache: { at: number; cues: DynamicCue[] } | null = null;
const LEX_TTL_MS = 1000 * 60 * 5;

function invalidateLexiconCache() {
  _lexCache = null;
}

export async function loadDynamicCues(supabase: SupabaseClient): Promise<DynamicCue[]> {
  if (_lexCache && Date.now() - _lexCache.at < LEX_TTL_MS) return _lexCache.cues;

  const { data, error } = await supabase
    .from("needsfine_lexicon")
    .select("term,aspect,polarity,weight,priority,enabled,source,confidence,occurrences")
    .eq("enabled", true)
    .order("confidence", { ascending: false })
    .order("occurrences", { ascending: false })
    .limit(600);

  if (error) {
    console.error("[lexicon] load error:", error);
    _lexCache = { at: Date.now(), cues: [] };
    return [];
  }

  const cues: DynamicCue[] = [];
  for (const row of data ?? []) {
    const term = normalizeText((row as any).term);
    if (!term || term.length < 2 || term.length > 24) continue;

    const aspectRaw = (row as any).aspect;
    const polRaw = (row as any).polarity;

    if (!isAspect(aspectRaw) || !isPolarity(polRaw)) continue;

    const w = Number((row as any).weight);
    const baseWeight = Number.isFinite(w) ? clamp(0.05, 2.0, w) : 0.35;

    const pr = Number((row as any).priority);
    const priority = Number.isFinite(pr) ? clamp(1, 200, pr) : 35;

    cues.push({
      term,
      aspect: aspectRaw,
      polarity: polRaw,
      baseWeight,
      priority,
      source: ((row as any).source as any) ?? "manual",
      confidence: Number((row as any).confidence ?? 0.5),
    });
  }

  _lexCache = { at: Date.now(), cues };
  return cues;
}