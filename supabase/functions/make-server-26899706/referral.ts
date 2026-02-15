import { createClient } from "jsr:@supabase/supabase-js@2";

// [Referral Endpoint] Get or Generate Referral Code
export async function getMyReferralCode(c: any, supabase: any) {
    try {
        const { user_id } = await c.req.json();
        if (!user_id) return c.json({ error: "Missing user_id" }, 400);

        // 1. Check existing code
        const { data: profile, error: fetchError } = await supabase
            .from('profiles')
            .select('my_referral_code, referral_count, contribution_score')
            .eq('id', user_id)
            .single();

        if (fetchError) throw fetchError;

        if (profile.my_referral_code) {
            return c.json({
                code: profile.my_referral_code,
                count: profile.referral_count,
                contribution_score: profile.contribution_score || 0
            });
        }

        // 2. Generate new unique code
        let newCode = "";
        let isUnique = false;
        let retries = 0;

        while (!isUnique && retries < 5) {
            // Generate 6-char alphanumeric (A-Z, 0-9)
            newCode = Math.random().toString(36).substring(2, 8).toUpperCase();

            // Check uniqueness
            const { data: duplicate } = await supabase
                .from('profiles')
                .select('id')
                .eq('my_referral_code', newCode)
                .maybeSingle();

            if (!duplicate) isUnique = true;
            retries++;
        }

        if (!isUnique) throw new Error("Failed to generate unique code");

        // 3. Save new code
        const { error: updateError } = await supabase
            .from('profiles')
            .update({ my_referral_code: newCode })
            .eq('id', user_id);

        if (updateError) throw updateError;

        return c.json({
            code: newCode,
            count: 0,
            contribution_score: profile.contribution_score || 0
        });

    } catch (e: any) {
        console.error("get-my-referral-code error:", e);
        return c.json({ error: e.message }, 500);
    }
}

// [Referral Endpoint] Apply Referral Code
export async function applyReferralCode(c: any, supabase: any) {
    try {
        const { user_id, referral_code } = await c.req.json();
        if (!user_id || !referral_code) return c.json({ error: "Missing data" }, 400);

        const targetCode = referral_code.toString().trim().toUpperCase();

        // 1. Validate User
        const { data: me, error: meError } = await supabase
            .from('profiles')
            .select('id, referred_by, my_referral_code, contribution_score')
            .eq('id', user_id)
            .single();

        if (meError) {
            console.error("Referral Error (Validate User):", meError);
            return c.json({ success: false, message: "사용자 정보를 찾을 수 없습니다." });
        }
        if (me.referred_by) {
            return c.json({ success: false, message: "이미 추천인을 등록했습니다." });
        }
        if (me.my_referral_code === targetCode) {
            return c.json({ success: false, message: "본인의 코드는 입력할 수 없습니다." });
        }

        // 2. Find Referrer
        const { data: referrer, error: referrerError } = await supabase
            .from('profiles')
            .select('id, referral_count, contribution_score')
            .eq('my_referral_code', targetCode)
            .maybeSingle();

        if (referrerError) {
            console.error("Referral Error (Find Referrer):", referrerError);
        }

        if (!referrer) {
            return c.json({ success: false, message: "유효하지 않은 추천인 코드입니다." });
        }

        // 3. Apply Referral (Update both profiles)

        // Update Me
        // Use current score from 'me' fetched above
        const myNewScore = (me.contribution_score || 0) + 10;

        const { error: updateMeError } = await supabase.from('profiles').update({
            referred_by: referrer.id,
            contribution_score: myNewScore
        }).eq('id', user_id);

        if (updateMeError) console.error("Referral Update Me Error:", updateMeError);

        // Update Referrer
        const referrerNewScore = (referrer.contribution_score || 0) + 10;
        const referrerNewCount = (referrer.referral_count || 0) + 1;

        const { error: updateReferrerError } = await supabase.from('profiles').update({
            contribution_score: referrerNewScore,
            referral_count: referrerNewCount
        }).eq('id', referrer.id);

        if (updateReferrerError) console.error("Referral Update Referrer Error:", updateReferrerError);

        return c.json({ success: true, message: "추천인 등록 완료! 기여도가 10 상승했습니다." });

    } catch (e: any) {
        console.error("apply-referral-code error:", e);
        return c.json({ error: e.message }, 500);
    }
}
