
import { Hono } from "npm:hono";
import { cors } from "npm:hono/cors";
import { logger } from "npm:hono/logger";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { analyzeReview, NEEDSFINE_VERSION, normalizeText, DEFAULT_CONFIG, loadDynamicCues, mineTermEvents, upsertCandidateTerms } from "./logic.ts";
import { getMyReferralCode, applyReferralCode } from "./referral.ts";

const app = new Hono();

// [1] 로그 및 미들웨어 설정
app.use("*", logger(console.log));

// [2] CORS 설정 (사용자님 원본 설정 유지)
app.use(
  "/*",
  cors({
    origin: "*",
    allowHeaders: ["Content-Type", "Authorization", "X-Admin-Password", "apikey", "X-Client-Info", "x-client-info"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    exposeHeaders: ["Content-Length", "Content-Type"],
    maxAge: 86400,
    credentials: true,
  }),
);

// [3] Supabase Client
const supabase = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "");

// [3-1] Storage 초기화
async function initializeStorage() {
  try {
    const bucketName = "make-26899706-review-photos";
    const { data: buckets } = await supabase.storage.listBuckets();
    const bucketExists = buckets?.some((bucket) => bucket.name === bucketName);

    if (!bucketExists) {
      const { error } = await supabase.storage.createBucket(bucketName, {
        public: false,
        fileSizeLimit: 5242880,
        allowedMimeTypes: ["image/png", "image/jpeg", "image/jpg", "image/webp"],
      });
      if (error) console.error("❌ Storage bucket creation error:", error);
      else console.log("✅ Storage bucket created:", bucketName);
    }
  } catch (error) {
    console.error("❌ Storage initialization error:", error);
  }
}
initializeStorage();

// [4] 관리자 확인
const verifyAdmin = (c: any): boolean => {
  const adminPasswordHeader = c.req.header("X-Admin-Password");
  const adminPassword = Deno.env.get("ADMIN_PASSWORD") || "needsfine2953";
  return adminPasswordHeader === adminPassword;
};

// [5] 유저 관리
async function getOrCreateUser(authId: string | null, email: string | null, ipAddress: string) {
  if (authId) {
    const { data: profile } = await supabase.from("profiles").select("*").eq("id", authId).maybeSingle();
    if (profile) return profile;
    const { data: newProfile, error } = await supabase
      .from("profiles")
      .upsert(
        {
          id: authId,
          email,
          ip_address: ipAddress,
          nickname: `유저_${authId.substring(0, 5)}_${Math.floor(Math.random() * 1000)}`,
        },
        { onConflict: "id" },
      )
      .select()
      .single();
    if (error) throw error;
    return newProfile;
  }
  const guestId = crypto.randomUUID();
  const { data: guestProfile, error: guestError } = await supabase
    .from("profiles")
    .insert({
      id: guestId,
      ip_address: ipAddress,
      nickname: `익명_${guestId.substring(0, 4)}_${ipAddress.split(".").pop() || "Guest"}`,
      introduction: "웹 테스트용 익명 유저입니다.",
    })
    .select()
    .single();
  if (guestError) throw guestError;
  return guestProfile;
}

// ==========================================
// API 엔드포인트
// ==========================================

// ✅ (패치 반영 확인용) health에 logic version 포함
app.get("/make-server-26899706/health", (c) => c.json({ status: "ok", needsfine_version: NEEDSFINE_VERSION }));

// 1. 리뷰 생성
app.post("/make-server-26899706/reviews", async (c) => {
  try {
    const authHeader = c.req.header("Authorization");
    let authenticatedUser = null;
    if (authHeader && authHeader.startsWith("Bearer ")) {
      const {
        data: { user },
      } = await supabase.auth.getUser(authHeader.replace("Bearer ", ""));
      authenticatedUser = user;
    }
    const body = await c.req.json();
    const { store_name, store_address, review_text, user_rating, photo_urls, store_lat, store_lng } = body;

    if (!store_name || !review_text) return c.json({ error: "식당명과 리뷰 내용은 필수입니다." }, 400);

    const clientIp = c.req.header("x-forwarded-for")?.split(",")[0].trim() || "unknown";
    const profile = await getOrCreateUser(authenticatedUser?.id || null, authenticatedUser?.email || null, clientIp);

    const hasPhoto = photo_urls && Array.isArray(photo_urls) && photo_urls.length > 0;

    // logic.ts 호출 (동적 사전 포함)
    const dynamicCues = await loadDynamicCues(supabase);
    const analysis = analyzeReview({ text: review_text, userRating: Number(user_rating), hasPhoto: hasPhoto }, {}, DEFAULT_CONFIG, dynamicCues);

    // Adapter: Map analysis to DB schema

    const calculated = {
      needsfine_score: analysis.needsFineScore,
      trust_level: analysis.trust,
      authenticity: analysis.trust >= 70,
      advertising_words: false,
      tags: analysis.tags.map((t) => t.label),
      is_critical: analysis.needsFineScore <= 2.0 || (analysis.evidence.strongNegative?.flag ?? false),
      is_hidden: analysis.trust <= 2,
      logic_version: NEEDSFINE_VERSION,
    };

    const { count, error: countErr } = await supabase
      .from("reviews")
      .select("*", { count: "exact", head: true })
      .eq("user_id", profile.id)
      .eq("store_name", store_name);

    const visit_count = (count || 0) + 1;

    const { data: review, error } = await supabase
      .from("reviews")
      .insert({
        store_name,
        store_address: store_address || null,
        review_text,
        user_rating,
        user_id: profile.id,
        photo_urls: photo_urls || [],
        store_lat: store_lat ?? null,
        store_lng: store_lng ?? null,
        needsfine_score: calculated.needsfine_score,
        trust_level: calculated.trust_level,
        authenticity: calculated.authenticity,
        advertising_words: calculated.advertising_words,
        tags: calculated.tags,
        is_critical: calculated.is_critical,
        is_hidden: calculated.is_hidden,
        logic_version: calculated.logic_version,
        visit_count: visit_count,
      })
      .select(`*, profiles:user_id (user_number, email, nickname, is_admin, reliability)`)
      .single();

    if (error) throw error;

    // 단어 자동 마이닝 (비동기로 백그라운드 수행해도 되지만, 일단 완료 대기)
    try {
      const normalized = normalizeText(review_text || "");
      const evidenceAll = [...analysis.evidence.positive, ...analysis.evidence.negative];
      const events = mineTermEvents({
        normalized,
        evidenceAll,
        dynamicCues,
      });
      if (events.length > 0) {
        await upsertCandidateTerms(supabase, events);
      }
    } catch (mineErr) {
      console.error("Term mining error:", mineErr);
    }

    return c.json(review, 201);
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

// 2. 리뷰 목록 조회
app.get("/make-server-26899706/reviews", async (c) => {
  try {
    const limit = parseInt(c.req.query("limit") || "20");
    const store_name = c.req.query("store_name");
    let query = supabase
      .from("reviews")
      .select(`*, profiles:user_id (*)`)
      .eq("is_hidden", false)
      .order("created_at", { ascending: false })
      .limit(limit);
    if (store_name) query = query.eq("store_name", store_name);
    const { data: reviews, error } = await query;
    if (error) throw error;
    return c.json(reviews);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

// 3. 리뷰 상세
app.get("/make-server-26899706/reviews/:id", async (c) => {
  try {
    const { data: review, error } = await supabase
      .from("reviews")
      .select(`*, profiles:user_id (*)`)
      .eq("id", c.req.param("id"))
      .single();
    if (error) throw error;
    return c.json(review);
  } catch (_error: any) {
    return c.json({ error: "리뷰 로드 실패" }, 500);
  }
});

// 4. 통계
app.get("/make-server-26899706/stats", async (c) => {
  try {
    const { count: totalReviews } = await supabase.from("reviews").select("*", { count: "exact", head: true }).eq("is_hidden", false);
    const { data: avgData } = await supabase.from("reviews").select("needsfine_score, trust_level").eq("is_hidden", false);
    const avgScore = avgData && avgData.length > 0 ? avgData.reduce((sum, r) => sum + r.needsfine_score, 0) / avgData.length : 0;

    const { data: topStoresData } = await supabase.from("reviews").select("store_name, needsfine_score").eq("is_hidden", false);
    const storeStats: { [key: string]: { count: number; total: number } } = {};
    topStoresData?.forEach((r: any) => {
      if (!storeStats[r.store_name]) storeStats[r.store_name] = { count: 0, total: 0 };
      storeStats[r.store_name].count++;
      storeStats[r.store_name].total += r.needsfine_score;
    });
    const topStores = Object.entries(storeStats)
      .map(([name, s]) => ({ store_name: name, review_count: s.count, avg_score: s.total / s.count }))
      .sort((a, b) => b.review_count - a.review_count)
      .slice(0, 10);

    return c.json({ total_reviews: totalReviews, average_score: avgScore, top_stores: topStores });
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

// 5. 피드백 생성 (앱에서의 건의사항/문의 처리 포함 가능)
app.post("/make-server-26899706/feedback", async (c) => {
  try {
    const body = await c.req.json();
    const clientIp = c.req.header("x-forwarded-for")?.split(",")[0].trim() || "unknown";
    const profile = await getOrCreateUser(null, null, clientIp);
    const { data: feedback, error } = await supabase
      .from("feedback")
      .insert({ user_id: profile.id, email: body.email || null, message: body.message || body.content })
      .select(`*, profiles:user_id (*)`)
      .single();
    if (error) throw error;
    return c.json(feedback, 201);
  } catch (_error: any) {
    return c.json({ error: "피드백 저장 실패" }, 500);
  }
});

// 6. 재계산 (🚨 [Fixed] 타임아웃 방지 배치 처리 로직)
// ✅ 재계산만 “확실히 적용되게” 보강: upsert onConflict="id" (재계산 부분 안에서만 변경)
app.post("/make-server-26899706/recalculate-all", async (c) => {
  if (c.req.method === "OPTIONS") return c.newResponse(null, 204);
  if (!verifyAdmin(c)) return c.json({ error: "Unauthorized" }, 401);

  let lastError: any = null;

  try {
    // 1. Service Role Key 확인
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    console.log(`[Recalculate] Service Role Key exists: ${!!serviceRoleKey}`);

    // 2. 리뷰 데이터 조회
    const { data: reviews, error: fetchError } = await supabase.from("reviews").select("*");

    if (fetchError) {
      console.error(`[Recalculate] Fetch Error:`, fetchError);
      throw fetchError;
    }

    console.log(`[Recalculate] Reviews found: ${reviews?.length ?? 0}`);

    let successCount = 0;
    let lastLogicVersion = "unknown";
    const total = reviews?.length || 0;

    // 0. Dynamic Cues Load (Cached)
    // 0. Dynamic Cues Load (Removed)

    // 성능 최적화: 50개씩 묶어서 UPSERT 처리
    const batchSize = 50;
    for (let i = 0; i < total; i += batchSize) {
      const chunk = reviews!.slice(i, i + batchSize);
      const updates = chunk.map((r: any) => {
        const hasPhoto = r.photo_urls && Array.isArray(r.photo_urls) && r.photo_urls.length > 0;

        // ✅ Hybrid Logic 적용 (v17.4.0)
        const analysis = analyzeReview(
          { text: r.review_text, userRating: Number(r.user_rating), hasPhoto: hasPhoto },
          {},
          DEFAULT_CONFIG
        );

        lastLogicVersion = NEEDSFINE_VERSION;

        return {
          id: r.id,
          store_name: r.store_name,
          store_address: r.store_address,
          user_id: r.user_id,
          review_text: r.review_text,
          user_rating: r.user_rating,
          photo_urls: r.photo_urls,
          created_at: r.created_at,
          needsfine_score: analysis.needsFineScore,
          trust_level: analysis.trust,
          authenticity: analysis.trust >= 70,
          advertising_words: false,
          tags: analysis.tags.map((t: any) => t.label),
          is_critical: analysis.needsFineScore <= 2.0 || (analysis.evidence.strongNegative?.flag ?? false),
          is_hidden: analysis.trust <= 2,
          logic_version: NEEDSFINE_VERSION,
        };
      });

      // ✅ 핵심: onConflict="id"를 명시해야 “업데이트”가 확실히 됨 (재계산 적용 안됨 원인 1순위)
      const { error: updateError } = await supabase.from("reviews").upsert(updates, { onConflict: "id" });

      if (updateError) {
        console.error(`Batch ${i} update error:`, updateError);
        lastError = updateError;
      } else successCount += chunk.length;
    }

    if (successCount === 0 && total > 0) {
      return c.json(
        {
          success: false,
          count: 0,
          total: total,
          logic_version: lastLogicVersion,
          error: `Recalculation failed. Last error: ${JSON.stringify(lastError)}`,
        },
        400,
      );
    }

    return c.json({
      success: true,
      count: successCount,
      total: total,
      logic_version: lastLogicVersion,
    });
  } catch (e: any) {
    return c.json({ error: e.message, last_error: lastError }, 500);
  }
});

// 7. 건의사항 전송 (앱 전용 엔드포인트 호환성)
app.post("/make-server-26899706/send-suggestion", async (c) => {
  try {
    const body = await c.req.json();
    const { data, error } = await supabase.from("suggestions").insert({
      user_id: body.userId,
      email: body.email,
      content: body.content,
    });
    if (error) throw error;

    await sendAdminPush("새로운 건의사항", body.content, body.userId);
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

// 8. 1:1 문의 전송 (앱 전용 엔드포인트 호환성)
app.post("/make-server-26899706/send-inquiry", async (c) => {
  try {
    const body = await c.req.json();
    const { data, error } = await supabase.from("feedback").insert({
      user_id: body.userId,
      email: body.email,
      content: body.content,
      message: body.content, // 기존 호환성 유지
    });
    if (error) throw error;

    await sendAdminPush("새로운 1:1 문의", body.content, body.userId);
    return c.json({ success: true });
  } catch (e: any) {
    return c.json({ error: e.message }, 500);
  }
});

// ✅ 실시간 피드백 우선순위: 맛 > 위생 > 서비스 > 분위기 > 환경(주차 등)
const ASPECT_PRIORITY: Record<string, number> = {
  taste: 1, hygiene: 2, service: 3, ambience: 4, wait: 5, portion: 6, value: 7, revisit: 8, overall: 9,
};

function generateFeedbackMessage(tags: any[], reviewText: string, userTags?: string[]): { message: string; is_warning: boolean } {
  const isDelivery = (userTags ?? []).some((t: string) => /배달|포장|delivery|takeout/i.test(t));

  // 한글 키워드 기반 간단 체크
  const hasTaste = /(맛|음식|메뉴|식감|소스|면|국물|고소|담백|바삭|풍미|감칠맛|재료)/iu.test(reviewText);
  const hasHygiene = /(위생|청결|깨끗|깔끔|이물질|벌레)/iu.test(reviewText);
  const hasService = /(서비스|직원|사장|친절|불친절|응대|태도)/iu.test(reviewText);
  const hasAmbience = /(분위기|인테리어|매장|공간|좌석|조명|소음|뷰)/iu.test(reviewText);
  const hasEnvironment = /(주차|환기|연기|냄새|좁|넓|불편|화장실)/iu.test(reviewText);

  if (isDelivery) {
    // 배달/포장: 맛만 체크
    if (!hasTaste) return { message: "어떤 맛이었나요? 맛에 대한 구체적인 표현을 추가해보세요!", is_warning: false };
    return { message: "", is_warning: false };
  }

  // 우선순위: 맛 > 위생 > 서비스 > 분위기 > 환경
  if (!hasTaste) return { message: "어떤 맛이었나요? 맛에 대한 구체적인 표현을 추가해보세요!", is_warning: false };
  if (!hasHygiene) return { message: "매장 위생/청결 상태는 어땠나요?", is_warning: false };
  if (!hasService) return { message: "직원 서비스나 응대는 어떠셨나요?", is_warning: false };
  if (!hasAmbience) return { message: "매장 분위기는 어땠나요?", is_warning: false };
  if (!hasEnvironment) return { message: "주차, 환기 등 매장 환경은 어땠나요?", is_warning: false };

  return { message: "", is_warning: false };
}

// 9. 분석 (실시간 미리보기용)
app.post("/make-server-26899706/analyze", async (c) => {
  if (c.req.method === "OPTIONS") return c.newResponse(null, 204);
  try {
    const body = await c.req.json();
    const reviewText = body.review_text || body.reviewText || "";
    const userRating = body.user_rating || body.userRating;
    const hasPhoto = body.has_photo || body.hasPhoto || false;
    const userTags: string[] = body.tags || [];

    // Options
    const debug = Boolean(body.debug);
    const learn = body.learn !== false; // default true
    const evidenceMode = body.evidenceMode === "all" ? "all" : "top";

    // Dynamic Cues Removed

    // 내부 학습/채굴용으로는 all evidence가 필요할 수 있음
    const needAllEvidence = learn || evidenceMode === "all";

    const analysis = analyzeReview(
      { text: reviewText, userRating: Number(userRating), hasPhoto: Boolean(hasPhoto) },
      { debug: debug, returnAllEvidence: needAllEvidence },
      DEFAULT_CONFIG
    );

    // ---- term mining (optional)
    // Term mining removed
    let learning: { mined: number; candidateUpdated: number; promoted: number } | undefined = undefined;

    // 우선순위에 따라 태그 정렬
    const sortedTags = [...analysis.tags].sort((a, b) => {
      const pa = ASPECT_PRIORITY[(a as any).aspect] ?? 99;
      const pb = ASPECT_PRIORITY[(b as any).aspect] ?? 99;
      return pa - pb;
    });

    // 실시간 피드백 메시지
    const feedback = generateFeedbackMessage(sortedTags, reviewText || "", userTags);

    // Map for App compatibility (review_service.dart expects snake_case)
    const result = {
      needsfine_score: analysis.needsFineScore,
      trust_level: analysis.trust,
      tags: sortedTags.map((t) => (t as any).label),
      message: feedback.message,
      is_warning: analysis.needsFineScore <= 2.0 || (analysis.evidence.strongNegative?.flag ?? false) || feedback.is_warning,
      logic_version: NEEDSFINE_VERSION,
      evidence: evidenceMode === "all" ? analysis.evidence : {
        positive: (analysis.evidence.positive ?? []).slice(0, 2),
        negative: (analysis.evidence.negative ?? []).slice(0, 2),
        strongNegative: analysis.evidence.strongNegative,
      },
      learning,
      debug: debug ? analysis.debug : undefined,
    };
    return c.json(result);
  } catch (_error: any) {
    return c.json({ error: "분석 실패", details: _error.message }, 500);
  }
});



// [추가] FCM 푸시 발송 유틸
async function sendAdminPush(title: string, body: string, referenceId: string | null) {
  try {
    const adminEmail = "ineedsfine@gmail.com";

    // 1. 관리자 ID 조회
    const { data: adminProfile } = await supabase.from("profiles").select("id").eq("email", adminEmail).single();
    if (!adminProfile) {
      console.log("Admin profile not found");
      return;
    }

    // 2. 알림 DB 저장
    await supabase.from("notifications").insert({
      receiver_id: adminProfile.id,
      type: "admin_alert",
      title,
      content: body,
      reference_id: referenceId,
      is_read: false,
    });

    // 3. FCM 토큰 조회
    const { data: tokens } = await supabase.from("fcm_tokens").select("token").eq("user_id", adminProfile.id);
    if (!tokens || tokens.length === 0) {
      console.log("No FCM tokens for admin");
      return;
    }

    const fcmServerKey = Deno.env.get("FCM_SERVER_KEY");
    if (!fcmServerKey) {
      console.log("FCM_SERVER_KEY not set env");
      return;
    }

    // 4. FCM 발송 (Legacy API)
    const pushPromises = tokens.map((t: any) =>
      fetch("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `key=${fcmServerKey}`,
        },
        body: JSON.stringify({
          to: t.token,
          notification: {
            title,
            body,
            sound: "default",
            badge: 1,
          },
          data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            type: "admin_alert",
            reference_id: referenceId,
          },
        }),
      })
    );

    await Promise.all(pushPromises);
    console.log(`Sent push to ${tokens.length} devices`);
  } catch (e) {
    console.error("Push send failed:", e);
  }
}

// [Additional Endpoint] Batch Image Fetching
app.post("/make-server-26899706/fetch-store-images", async (c: any) => {
  try {
    const body = await c.req.json();
    const store_names: any[] = body.store_names;

    if (!store_names || !Array.isArray(store_names) || store_names.length === 0) {
      return c.json({ data: [] });
    }

    // 1. 요청된 상점 이름 목록 (중복 제거)
    const targets: string[] = [...new Set(store_names.map((n: any) => n.toString().trim()))];
    const results: { store_name: string; photo_url: string }[] = [];

    // 2. DB 조회
    const { data: exactMatches, error: exactError } = await supabase
      .from("reviews")
      .select("store_name, photo_urls")
      .in("store_name", targets)
      .not("photo_urls", "is", null)
      .order("created_at", { ascending: false });

    if (exactError) throw exactError;

    // 3. 매칭된 데이터 처리
    const foundMap = new Map<string, string>();

    if (exactMatches) {
      for (const row of exactMatches as any[]) {
        const name = row.store_name;
        if (!foundMap.has(name)) {
          const photos = row.photo_urls as any[];
          if (photos && photos.length > 0 && photos[0]) {
            foundMap.set(name, photos[0]);
            results.push({ store_name: name, photo_url: photos[0] });
          }
        }
      }
    }

    // 4. (Optional) 미발견 상점에 대해 공백 제거 매칭
    const missing = targets.filter((t) => !foundMap.has(t));
    if (missing.length > 0) {
      const cleanToOriginal = new Map<string, string>();
      const cleanTargets: string[] = [];

      for (const m of missing) {
        const clean = m.replace(/\s+/g, "");
        if (clean !== m) {
          cleanToOriginal.set(clean, m);
          cleanTargets.push(clean);
        }
      }

      if (cleanTargets.length > 0) {
        const { data: fuzzyMatches } = await supabase
          .from("reviews")
          .select("store_name, photo_urls")
          .in("store_name", cleanTargets)
          .not("photo_urls", "is", null)
          .order("created_at", { ascending: false });

        if (fuzzyMatches) {
          for (const row of fuzzyMatches as any[]) {
            const cleanName = row.store_name;
            const originalName = cleanToOriginal.get(cleanName);
            if (originalName && !foundMap.has(originalName)) {
              const photos = row.photo_urls as any[];
              if (photos && photos.length > 0 && photos[0]) {
                foundMap.set(originalName, photos[0]);
                results.push({ store_name: originalName, photo_url: photos[0] });
              }
            }
          }
        }
      }
    }

    return c.json({ data: results });
  } catch (e: any) {
    console.error("fetch-store-images error:", e);
    return c.json({ error: e.message }, 500);
  }
});

// [Referral Endpoint] Get or Generate Referral Code
app.post("/make-server-26899706/get-my-referral-code", async (c: any) => {
  return await getMyReferralCode(c, supabase);
});

// [Referral Endpoint] Apply Referral Code
app.post("/make-server-26899706/apply-referral-code", async (c: any) => {
  // IMPORTANT: We need Service Role Key to update Referrer's profile securely.
  const adminSupabase = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "");
  return await applyReferralCode(c, adminSupabase);
});

// ==========================================
// Admin Term Management Endpoints
// ==========================================

// 후보 목록 조회
app.get("/make-server-26899706/term-candidates", async (c) => {
  try {
    if (!verifyAdmin(c)) return c.json({ error: "Unauthorized" }, 401);

    // min_confidence, min_count 등을 파라미터로 받게 할 수도 있음
    const { data, error } = await supabase
      .from("needsfine_candidate_terms")
      .select("*")
      .eq("promoted", false)
      .order("total_count", { ascending: false })
      .limit(100);

    if (error) throw error;
    return c.json(data);
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

// 후보 단어 액션 (승인/거절)
app.post("/make-server-26899706/term-candidates/action", async (c) => {
  try {
    if (!verifyAdmin(c)) return c.json({ error: "Unauthorized" }, 401);

    const { term, action, overrideAspect, overridePolarity } = await c.req.json();
    if (!term || !action) return c.json({ error: "Missing required fields" }, 400);

    const nowIso = new Date().toISOString();

    if (action === "approve") {
      // 1. 후보 데이터 가져오기
      const { data: cand, error: fetchErr } = await supabase
        .from("needsfine_candidate_terms")
        .select("*")
        .eq("term", term)
        .single();

      if (fetchErr) throw fetchErr;
      if (!cand) return c.json({ error: "Candidate not found" }, 404);

      // 2. 관리자가 aspect/polarity 수정 가능하게 지원
      const aspect = overrideAspect || cand.best_aspect;
      const polarity = overridePolarity || cand.best_polarity;

      if (!aspect || !polarity) return c.json({ error: "Missing aspect or polarity" }, 400);

      // 3. needsfine_lexicon에 넣기
      const weight = Math.max(0.2, Math.min(0.65, 0.2 + (cand.confidence || 0.5) * 0.3));

      const lexPayload = {
        term: term,
        aspect: aspect,
        polarity: polarity,
        weight: weight,
        priority: 40, // 적절한 중간 우선순위 (코어보단 낮게)
        enabled: true,
        source: "admin_approved",
        confidence: cand.confidence || 1.0,
        occurrences: cand.total_count || 0,
        updated_at: nowIso,
      };

      const { error: lexErr } = await supabase
        .from("needsfine_lexicon")
        .upsert(lexPayload, { onConflict: "term" });

      if (lexErr) throw lexErr;

      // 4. 후보 목록에서 삭제 (또는 promoted=true 변경)
      await supabase.from("needsfine_candidate_terms").delete().eq("term", term);

      return c.json({ success: true, message: `Term '${term}' approved.` });

    } else if (action === "reject") {
      // 거절 시 삭제 (이후 다시 쌓일 수 있지만, 블랙리스트를 별도로 둘 수도 있음)
      const { error: delErr } = await supabase.from("needsfine_candidate_terms").delete().eq("term", term);
      if (delErr) throw delErr;

      return c.json({ success: true, message: `Term '${term}' rejected.` });
    } else {
      return c.json({ error: "Invalid action" }, 400);
    }
  } catch (error: any) {
    return c.json({ error: error.message }, 500);
  }
});

// ==========================================
// Web View for Shared Lists
// ==========================================
app.get("/make-server-26899706/list/:id", async (c) => {
  try {
    const listId = c.req.param("id");

    // Fetch list info
    const { data: listData, error: listError } = await supabase
      .from("user_lists")
      .select("id, name, is_public, profiles:user_id(nickname)")
      .eq("id", listId)
      .single();

    if (listError || !listData) {
      return c.html(`<html><head><meta charset="utf-8"></head><body style="padding: 20px; font-family: sans-serif;"><h2>리스트를 찾을 수 없습니다.</h2></body></html>`, 404);
    }

    // Checking if public
    if (!listData.is_public) {
      return c.html(`<html><head><meta charset="utf-8"></head><body style="padding: 20px; font-family: sans-serif;"><h2>비공개된 리스트입니다.</h2><p>리스트 작성자가 공개로 전환해야 볼 수 있습니다.</p></body></html>`, 403);
    }

    // Fetch items
    const { data: listItems } = await supabase
      .from("user_list_items")
      .select("review_id")
      .eq("list_id", listId);

    let reviews: any[] = [];
    if (listItems && listItems.length > 0) {
      const reviewIds = listItems.map(item => item.review_id);
      const { data: reviewsData } = await supabase
        .from("reviews")
        .select("id, store_name, store_address, needsfine_score, trust_level")
        .in("id", reviewIds);

      if (reviewsData) {
        reviews = reviewsData;
      }
    }

    const listName = listData.name;
    const authorArray = listData.profiles as any; // Handle array vs object of Supabase join
    const authorName = Array.isArray(authorArray) ? authorArray[0]?.nickname : (authorArray?.nickname || "익명");

    const html = `
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${listName} - 니즈파인</title>
  <meta property="og:title" content="${listName} | 니즈파인 추천 리스트">
  <meta property="og:description" content="${authorName}님이 공유한 진짜 맛집 리스트를 확인해보세요!">
  
  <!-- 피그마/앱 디자인을 반영한 깔끔한 UI -->
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #F2F2F7; margin: 0; padding: 0; padding-bottom: 90px; }
    .header { background-color: #ffffff; padding: 18px 20px; text-align: center; border-bottom: 1px solid #E5E5EA; position: sticky; top: 0; z-index: 10; }
    .logo { color: #8A2BE2; font-weight: 900; font-size: 20px; margin: 0; display: inline-flex; align-items: center; gap: 6px; }
    .list-title { text-align: center; margin: 32px 20px 24px; }
    .list-title h1 { font-size: 24px; font-weight: 800; color: #1C1C1E; margin: 0 0 8px; line-height: 1.3; }
    .list-title p { font-size: 15px; color: #8E8E93; margin: 0; font-weight: 500; }
    .container { max-width: 600px; margin: 0 auto; padding: 0 16px; }
    .card { background-color: #ffffff; border-radius: 16px; padding: 20px; margin-bottom: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.03); display: flex; flex-direction: column;}
    .store-name { font-size: 18px; font-weight: 800; color: #1C1C1E; margin: 0 0 6px; }
    .store-address { font-size: 13px; color: #8E8E93; margin: 0 0 16px; line-height: 1.4; }
    .stats { display: flex; gap: 8px; }
    .stat-badge { background-color: #F2F2F7; padding: 6px 10px; border-radius: 8px; font-size: 13px; font-weight: 700; color: #3A3A3C; display: flex; align-items: center; gap: 4px; }
    .stat-badge span { color: #8A2BE2; }
    .cta-banner { position: fixed; bottom: 0; left: 0; width: 100%; background-color: #ffffff; padding: 16px 20px; padding-bottom: calc(16px + env(safe-area-inset-bottom)); box-shadow: 0 -4px 16px rgba(0,0,0,0.06); display: flex; justify-content: space-between; align-items: center; box-sizing: border-box; z-index: 20; }
    .cta-text p { margin: 0 0 2px 0; font-size: 14px; font-weight: 700; color: #1C1C1E; }
    .cta-text span { font-size: 12px; color: #8E8E93; font-weight: 500; }
    .btn-download { background-color: #8A2BE2; color: #ffffff; text-decoration: none; padding: 10px 20px; border-radius: 20px; font-size: 14px; font-weight: 700; transition: background-color 0.2s; }
    .btn-download:active { background-color: #6C1EAC; }
    .empty { text-align: center; color: #8E8E93; padding: 60px 0; font-size: 15px; }
  </style>
</head>
<body>
  <div class="header">
    <h1 class="logo">NeedsFine</h1>
  </div>
  
  <div class="list-title">
    <h1>${listName}</h1>
    <p>by ${authorName}</p>
  </div>

  <div class="container">
    ${reviews.length === 0 ? '<div class="empty">리스트에 담긴 맛집이 없습니다.</div>' : ''}
    ${reviews.map(r => `
      <div class="card">
        <h2 class="store-name">${r.store_name}</h2>
        <p class="store-address">${r.store_address || '주소 정보 없음'}</p>
        <div class="stats">
          <div class="stat-badge">니즈파인 <span>${(typeof r.needsfine_score === 'number' ? r.needsfine_score.toFixed(1) : parseFloat(r.needsfine_score || 0).toFixed(1))}</span></div>
          <div class="stat-badge">신뢰도 <span>${r.trust_level || 0}%</span></div>
        </div>
      </div>
    `).join('')}
  </div>

  <div class="cta-banner">
    <div class="cta-text">
      <p>진짜 맛집 리뷰가 궁금하다면?</p>
      <span>광고 없는 진짜 리뷰 앱, 니즈파인</span>
    </div>
    <a href="needsfine://list/${listId}" onclick="setTimeout(function(){ window.location.href='https://needsfine.com'; }, 1500);" class="btn-download">앱 열기</a>
  </div>
</body>
</html>
    `;
    // Return HTML with Content-Type explicitly
    return c.html(html);
  } catch (e: any) {
    console.error("Shared list error:", e);
    return c.html(`<html><head><meta charset="utf-8"></head><body style="padding: 20px; font-family: sans-serif;"><h2>서버 오류가 발생했습니다.</h2></body></html>`, 500);
  }
});

Deno.serve(app.fetch);
