-- ==========================================
-- [check_fcm_pk.sql]
-- fcm_tokens 테이블에 PK가 제대로 걸려있는지 확인
-- ==========================================

-- 1. 제약 조건 확인
SELECT 
    conname AS constraint_name, 
    pg_get_constraintdef(c.oid) as constraint_definition
FROM pg_constraint c 
JOIN pg_namespace n ON n.oid = c.connamespace 
WHERE conrelid = 'public.fcm_tokens'::regclass;

-- 2. 중복된(user_id, token) 쌍이 있는지 확인
SELECT user_id, token, count(*) 
FROM public.fcm_tokens 
GROUP BY user_id, token 
HAVING count(*) > 1;
