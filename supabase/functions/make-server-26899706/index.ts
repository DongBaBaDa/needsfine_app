import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { Hono } from "npm:hono";
import { cors } from "npm:hono/cors";
import { logger } from "npm:hono/logger";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { calculateNeedsFineScore } from "./logic.ts";

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

        // logic.ts 호출
        const calculated = calculateNeedsFineScore(review_text, user_rating, hasPhoto);

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
        const { data: reviews, error: fetchError } = await supabase.from('reviews').select('*');
        if (fetchError) throw fetchError;

        let successCount = 0;
        let lastLogicVersion = "unknown";
        const total = reviews?.length || 0;

        // 성능 최적화: 50개씩 묶어서 UPSERT 처리 (완전 빠름)
        const batchSize = 50;
        for (let i = 0; i < total; i += batchSize) {
            const chunk = reviews!.slice(i, i + batchSize);
            const updates = chunk.map(r => {
                const hasPhoto = (r.photo_urls && r.photo_urls.length > 0);
                const calculated = calculateNeedsFineScore(r.review_text, Number(r.user_rating), hasPhoto);
                lastLogicVersion = calculated.logic_version;

                return {
                    id: r.id,
                    ...calculated,
                    logic_version: calculated.logic_version,
                    recalculated_at: new Date().toISOString()
                };
            });

            const { error: updateError } = await supabase.from('reviews').upsert(updates);
            if (updateError) console.error(`Batch ${i} update error:`, updateError);
            else successCount += chunk.length;
        }

        return c.json({
            success: true,
            count: successCount,
            total: total,
            logic_version: lastLogicVersion
        });
    } catch (e) {
        return c.json({ error: e.message }, 500);
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

        const result = calculateNeedsFineScore(reviewText, userRating, hasPhoto);
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

Deno.serve(app.fetch);
