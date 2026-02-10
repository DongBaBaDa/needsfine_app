-- ==========================================
-- [check_all_tokens.sql]
-- 모든 유저의 토큰 저장 현황 확인
-- ==========================================

SELECT 
    user_id, 
    count(*) as token_count,
    array_agg(substring(token, 1, 10) || '...') as token_previews 
FROM public.fcm_tokens 
GROUP BY user_id;
