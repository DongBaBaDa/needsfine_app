-- ==========================================
-- [clean_my_tokens.sql]
-- 중복 알림 해결을 위한 내 토큰 전체 삭제
-- ==========================================

-- 1. 내 계정의 모든 토큰 삭제 (초기화)
DELETE FROM public.fcm_tokens
WHERE user_id = '1880eabb-ea80-4ef3-8e21-b7d7a2415670';

-- 2. 삭제 확인
SELECT count(*) FROM public.fcm_tokens
WHERE user_id = '1880eabb-ea80-4ef3-8e21-b7d7a2415670';
