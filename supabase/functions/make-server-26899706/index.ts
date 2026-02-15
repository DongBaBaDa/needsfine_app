import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { Hono } from "npm:hono";
import { cors } from "npm:hono/cors";
import { logger } from "npm:hono/logger";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { analyzeReview, NEEDSFINE_VERSION } from "./logic.ts";
import { getMyReferralCode, applyReferralCode } from "./referral.ts";

const app = new Hono();

// [1] 로그 및 미들웨어 설정
app.use('*', logger(console.log));

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
const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
);

// [3-1] Storage 초기화
async function initializeStorage() {
    try {
        const bucketName = 'make-26899706-review-photos';
        const { data: buckets } = await supabase.storage.listBuckets();
        const bucketExists = buckets?.some(bucket => bucket.name === bucketName);

        if (!bucketExists) {
            const { error } = await supabase.storage.createBucket(bucketName, {
                public: false,
                fileSizeLimit: 5242880,
                allowedMimeTypes: ['image/png', 'image/jpeg', 'image/jpg', 'image/webp']
            });
            if (error) console.error('❌ Storage bucket creation error:', error);
            else console.log('✅ Storage bucket created:', bucketName);
        }
    } catch (error) {
        console.error('❌ Storage initialization error:', error);
    }
}
initializeStorage();

// [4] 관리자 확인
const verifyAdmin = (c: any): boolean => {
    const adminPasswordHeader = c.req.header('X-Admin-Password');
    const adminPassword = Deno.env.get('ADMIN_PASSWORD') || 'needsfine2953';
    return adminPasswordHeader === adminPassword;
};

// [5] 유저 관리
async function getOrCreateUser(authId: string | null, email: string | null, ipAddress: string) {
    if (authId) {
        const { data: profile } = await supabase.from('profiles').select('*').eq('id', authId).maybeSingle();
        if (profile) return profile;
        const { data: newProfile, error } = await supabase.from('profiles').upsert({
            id: authId, email, ip_address: ipAddress, nickname: `유저_${authId.substring(0, 5)}_${Math.floor(Math.random() * 1000)}`
        }, { onConflict: 'id' }).select().single();
        if (error) throw error;
        return newProfile;
    }
    const guestId = crypto.randomUUID();
    const { data: guestProfile, error: guestError } = await supabase.from('profiles').insert({
        id: guestId, ip_address: ipAddress, nickname: `익명_${guestId.substring(0, 4)}_${ipAddress.split('.').pop() || 'Guest'}`, introduction: '웹 테스트용 익명 유저입니다.'
    }).select().single();
    if (guestError) throw guestError;
    return guestProfile;
}

// ==========================================
// API 엔드포인트
// ==========================================

app.get("/make-server-26899706/health", (c) => c.json({ status: "ok" }));

// 1. 리뷰 생성
app.post("/make-server-26899706/reviews", async (c) => {
    try {
        const authHeader = c.req.header('Authorization');
        let authenticatedUser = null;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const { data: { user } } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
            authenticatedUser = user;
        }
        const body = await c.req.json();
        const { store_name, store_address, review_text, user_rating, photo_urls } = body;

        if (!store_name || !review_text) return c.json({ error: "식당명과 리뷰 내용은 필수입니다." }, 400);

        const clientIp = c.req.header('x-forwarded-for')?.split(',')[0].trim() || 'unknown';
        const profile = await getOrCreateUser(authenticatedUser?.id || null, authenticatedUser?.email || null, clientIp);

        const hasPhoto = photo_urls && Array.isArray(photo_urls) && photo_urls.length > 0;

        // logic.ts 호출 (v17.2.0)
        const analysis = analyzeReview({ text: review_text, userRating: Number(user_rating), hasPhoto: hasPhoto });

        // Adapter: Map Policy v1 analysis to DB schema
        const calculated = {
            needsfine_score: analysis.needsFineScore,
            trust_level: analysis.trust,
            // Authenticity: high trust
            authenticity: analysis.trust >= 70,
            // Advertising: removed to default false
            advertising_words: false,
            // tags: analysis.tags (TagResult[]) -> string[] for DB/App compatibility
            tags: analysis.tags.map(t => t.label),
            // Critical: Low score or specific debug reasons (Updated for v17.2.0)
            is_critical: analysis.needsFineScore <= 2.0 || (analysis.evidence.strongNegative?.flag ?? false),
            // Hidden: Only hide if trust is extremely low (<= 2%)
            // Simple Logic v1.0 gives 3% for spam/low-info, but 2~5% for very short reviews.
            // To be safe and show everything for now, we set threshold to 2.
            is_hidden: analysis.trust <= 2,
            logic_version: NEEDSFINE_VERSION
        };

        const { data: review, error } = await supabase.from('reviews').insert({
            store_name, store_address: store_address || null, review_text, user_rating, user_id: profile.id, photo_urls: photo_urls || [],
            needsfine_score: calculated.needsfine_score, trust_level: calculated.trust_level,
            authenticity: calculated.authenticity, advertising_words: calculated.advertising_words,
            tags: calculated.tags, is_critical: calculated.is_critical, is_hidden: calculated.is_hidden, logic_version: calculated.logic_version
        }).select(`*, profiles:user_id (user_number, email, nickname, is_admin, reliability)`).single();

        if (error) throw error;
        return c.json(review, 201);
    } catch (e) { return c.json({ error: e.message }, 500); }
});

// 2. 리뷰 목록 조회
app.get("/make-server-26899706/reviews", async (c) => {
    try {
        const limit = parseInt(c.req.query("limit") || "20");
        const store_name = c.req.query("store_name");
        let query = supabase.from('reviews').select(`*, profiles:user_id (*)`).eq('is_hidden', false).order('created_at', { ascending: false }).limit(limit);
        if (store_name) query = query.eq('store_name', store_name);
        const { data: reviews, error } = await query;
        if (error) throw error;
        return c.json(reviews);
    } catch (error) { return c.json({ error: error.message }, 500); }
});

// 3. 리뷰 상세
app.get("/make-server-26899706/reviews/:id", async (c) => {
    try {
        const { data: review, error } = await supabase.from('reviews').select(`*, profiles:user_id (*)`).eq('id', c.req.param("id")).single();
        if (error) throw error;
        return c.json(review);
    } catch (error) { return c.json({ error: "리뷰 로드 실패" }, 500); }
});

// 4. 통계
app.get("/make-server-26899706/stats", async (c) => {
    try {
        const { count: totalReviews } = await supabase.from('reviews').select('*', { count: 'exact', head: true }).eq('is_hidden', false);
        const { data: avgData } = await supabase.from('reviews').select('needsfine_score, trust_level').eq('is_hidden', false);
        const avgScore = avgData && avgData.length > 0 ? avgData.reduce((sum, r) => sum + r.needsfine_score, 0) / avgData.length : 0;

        const { data: topStoresData } = await supabase.from('reviews').select('store_name, needsfine_score').eq('is_hidden', false);
        const storeStats: { [key: string]: { count: number; total: number } } = {};
        topStoresData?.forEach(r => {
            if (!storeStats[r.store_name]) storeStats[r.store_name] = { count: 0, total: 0 };
            storeStats[r.store_name].count++;
            storeStats[r.store_name].total += r.needsfine_score;
        });
        const topStores = Object.entries(storeStats).map(([name, s]) => ({ store_name: name, review_count: s.count, avg_score: s.total / s.count })).sort((a, b) => b.review_count - a.review_count).slice(0, 10);
        return c.json({ total_reviews: totalReviews, average_score: avgScore, top_stores: topStores });
    } catch (error) { return c.json({ error: error.message }, 500); }
});

// 5. 피드백 생성 (앱에서의 건의사항/문의 처리 포함 가능)
app.post("/make-server-26899706/feedback", async (c) => {
    try {
        const body = await c.req.json();
        const clientIp = c.req.header('x-forwarded-for')?.split(',')[0].trim() || 'unknown';
        const profile = await getOrCreateUser(null, null, clientIp);
        const { data: feedback, error } = await supabase.from('feedback').insert({ user_id: profile.id, email: body.email || null, message: body.message || body.content }).select(`*, profiles:user_id (*)`).single();
        if (error) throw error;
        return c.json(feedback, 201);
    } catch (error) { return c.json({ error: "피드백 저장 실패" }, 500); }
});

// 6. 재계산 (🚨 [Fixed] 타임아웃 방지 배치 처리 로직)
app.post("/make-server-26899706/recalculate-all", async (c) => {
    if (c.req.method === 'OPTIONS') return c.newResponse(null, 204);
    if (!verifyAdmin(c)) return c.json({ error: "Unauthorized" }, 401);

    try {
        // 모든 리뷰를 가져오지 않고, 재계산이 필요한 것들만 가져오거나 전체를 끊어서 처리
        // 1. Service Role Key 확인
        const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
        console.log(`[Recalculate] Service Role Key exists: ${!!serviceRoleKey}`);

        // 2. 리뷰 데이터 조회
        const { data: reviews, error: fetchError } = await supabase.from('reviews').select('*');

        if (fetchError) {
            console.error(`[Recalculate] Fetch Error:`, fetchError);
            throw fetchError;
        }

        console.log(`[Recalculate] Reviews found: ${reviews?.length ?? 0}`);

        let successCount = 0;
        let lastLogicVersion = "unknown";
        let lastError: any = null;
        const total = reviews?.length || 0;

        // 성능 최적화: 50개씩 묶어서 UPSERT 처리 (완전 빠름)
        const batchSize = 50;
        for (let i = 0; i < total; i += batchSize) {
            const chunk = reviews!.slice(i, i + batchSize);
            const updates = chunk.map(r => {
                // v17.2.0 recalculation
                const hasPhoto = r.photo_urls && Array.isArray(r.photo_urls) && r.photo_urls.length > 0;
                const analysis = analyzeReview({ text: r.review_text, userRating: Number(r.user_rating), hasPhoto: hasPhoto });

                lastLogicVersion = NEEDSFINE_VERSION;

                return {
                    id: r.id,
                    store_name: r.store_name,
                    user_id: r.user_id,
                    review_text: r.review_text,
                    user_rating: r.user_rating,
                    needsfine_score: analysis.needsFineScore,
                    trust_level: analysis.trust,
                    authenticity: analysis.trust >= 70,
                    advertising_words: false,
                    tags: analysis.tags.map(t => t.label),
                    is_critical: analysis.needsFineScore <= 2.0 || (analysis.evidence.strongNegative?.flag ?? false),
                    is_hidden: analysis.trust <= 2,
                    logic_version: NEEDSFINE_VERSION,
                    recalculated_at: new Date().toISOString()
                };
            });

            const { error: updateError } = await supabase.from('reviews').upsert(updates);
            if (updateError) {
                console.error(`Batch ${i} update error:`, updateError);
                lastError = updateError;
            }
            else successCount += chunk.length;
        }

        if (successCount === 0 && total > 0) {
            return c.json({
                success: false,
                count: 0,
                total: total,
                logic_version: lastLogicVersion,
                error: `Recalculation failed. Last error: ${JSON.stringify(lastError)}`
            }, 400);
        }

        return c.json({
            success: true,
            count: successCount,
            total: total,
            logic_version: lastLogicVersion
        });
    } catch (e) {
        return c.json({ error: e.message, last_error: lastError }, 500);
    }
});

// 7. 건의사항 전송 (앱 전용 엔드포인트 호환성)
app.post("/make-server-26899706/send-suggestion", async (c) => {
    try {
        const body = await c.req.json();
        const { data, error } = await supabase.from('suggestions').insert({
            user_id: body.userId,
            email: body.email,
            content: body.content
        });
        if (error) throw error;
        if (error) throw error;
        await sendAdminPush("새로운 건의사항", body.content, body.userId);
        return c.json({ success: true });
    } catch (e) { return c.json({ error: e.message }, 500); }
});

// 8. 1:1 문의 전송 (앱 전용 엔드포인트 호환성)
app.post("/make-server-26899706/send-inquiry", async (c) => {
    try {
        const body = await c.req.json();
        const { data, error } = await supabase.from('feedback').insert({
            user_id: body.userId,
            email: body.email,
            content: body.content,
            message: body.content // 기존 호환성 유지
        });
        if (error) throw error;
        await sendAdminPush("새로운 1:1 문의", body.content, body.userId);
        return c.json({ success: true });
    } catch (e) { return c.json({ error: e.message }, 500); }
});

// 9. 분석 (실시간 미리보기용)
app.post("/make-server-26899706/analyze", async (c) => {
    if (c.req.method === 'OPTIONS') return c.newResponse(null, 204);
    try {
        const body = await c.req.json();
        const reviewText = body.review_text || body.reviewText;
        const userRating = body.user_rating || body.userRating;
        const hasPhoto = body.has_photo || body.hasPhoto || false;

        const analysis = analyzeReview({ text: reviewText, userRating: Number(userRating), hasPhoto: hasPhoto });

        // Map for App compatibility (review_service.dart expects snake_case)
        const result = {
            needsfine_score: analysis.needsFineScore,
            trust_level: analysis.trust,
            tags: analysis.tags.map(t => t.label),
            is_warning: analysis.needsFineScore <= 2.0 || (analysis.evidence.strongNegative?.flag ?? false)
        };
        return c.json(result);
    } catch (error) { return c.json({ error: "분석 실패" }, 500); }
});

// [추가] FCM 푸시 발송 유틸
async function sendAdminPush(title: string, body: string, referenceId: string | null) {
    try {
        const adminEmail = 'ineedsfine@gmail.com';

        // 1. 관리자 ID 조회
        const { data: adminProfile } = await supabase.from('profiles').select('id').eq('email', adminEmail).single();
        if (!adminProfile) {
            console.log("Admin profile not found");
            return;
        }

        // 2. 알림 DB 저장 (기존 트리거와 중복될 수 있으나, 확실한 보장을 위해)
        // 트리거가 있다면 중복될 수 있으므로, 트리거가 없는 경우 유용.
        // 하지만 중복 방지를 위해 여기서는 insert를 생략하거나, type을 다르게 할 수 있음.
        // 사용자가 알림이 안 온다고 했으므로, 여기서 명시적으로 저장.
        await supabase.from('notifications').insert({
            receiver_id: adminProfile.id,
            type: 'admin_alert',
            title: title,
            content: body,
            reference_id: referenceId,
            is_read: false
        });

        // 3. FCM 토큰 조회
        const { data: tokens } = await supabase.from('fcm_tokens').select('token').eq('user_id', adminProfile.id);
        if (!tokens || tokens.length === 0) {
            console.log("No FCM tokens for admin");
            return;
        }

        const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');
        if (!fcmServerKey) {
            console.log("FCM_SERVER_KEY not set env");
            return;
        }

        // 4. FCM 발송 (Legacy API 사용 - 간단함)
        const pushPromises = tokens.map(t =>
            fetch('https://fcm.googleapis.com/fcm/send', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `key=${fcmServerKey}`
                },
                body: JSON.stringify({
                    to: t.token,
                    notification: {
                        title: title,
                        body: body,
                        sound: 'default',
                        badge: 1
                    },
                    data: {
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        type: 'admin_alert',
                        reference_id: referenceId
                    }
                })
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
        const results: { store_name: string, photo_url: string }[] = [];

        // 2. DB 조회
        const { data: exactMatches, error: exactError } = await supabase
            .from('reviews')
            .select('store_name, photo_urls')
            .in('store_name', targets)
            .not('photo_urls', 'is', null)
            .order('created_at', { ascending: false });

        if (exactError) throw exactError;

        // 3. 매칭된 데이터 처리
        const foundMap = new Map<string, string>();

        if (exactMatches) {
            for (const row of (exactMatches as any[])) {
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

        // 4. (Optional) 미발견 상점에 대해 Fuzzy Match (공백 제거) 시도
        // 상위 랭킹 등 중요한 경우 클라이언트가 재요청하거나, 여기서 처리.
        // 성능을 위해 여기서는 정확한 매칭만 반환하고, 클라이언트가 못 찾은 건에 대해 
        // 2차로 '공백 제거 이름'으로 다시 요청하는 패턴이 나을 수 있음.
        // 하지만 요청 수 줄이는게 목표므로, 남은 것들에 대해 서버에서 공백 제거 매칭 시도.

        const missing = targets.filter(t => !foundMap.has(t));
        if (missing.length > 0) {
            // 공백 제거된 이름 매핑: { "Starbucks Coffee": "StarbucksCoffee" }
            const cleanToOriginal = new Map<string, string>();
            const cleanTargets: string[] = [];

            for (const m of missing) {
                const clean = m.replace(/\s+/g, '');
                if (clean !== m) {
                    cleanToOriginal.set(clean, m);
                    cleanTargets.push(clean);
                }
            }

            if (cleanTargets.length > 0) {
                const { data: fuzzyMatches } = await supabase
                    .from('reviews')
                    .select('store_name, photo_urls')
                    .in('store_name', cleanTargets)
                    .not('photo_urls', 'is', null)
                    .order('created_at', { ascending: false });

                if (fuzzyMatches) {
                    for (const row of fuzzyMatches) {
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
    // Re-initializing Supabase Admin Client
    const adminSupabase = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );
    return await applyReferralCode(c, adminSupabase);
});

Deno.serve(app.fetch);
