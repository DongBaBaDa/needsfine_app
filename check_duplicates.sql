-- ==========================================
-- [check_duplicates.sql]
-- 중복 알림 원인 파악 (토큰 중복 vs 트리거 중복)
-- ==========================================

-- 1. 내 계정의 토큰 개수 및 목록 확인
SELECT count(*), array_agg(token) 
FROM public.fcm_tokens 
WHERE user_id = '1880eabb-ea80-4ef3-8e21-b7d7a2415670';

-- 2. 토큰 테이블 구조 확인 (PK가 무엇인지)
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu 
      ON tc.constraint_name = kcu.constraint_name 
      AND tc.table_schema = kcu.table_schema 
WHERE tc.table_name = 'fcm_tokens' AND tc.constraint_type = 'PRIMARY KEY';

-- 3. notifications 테이블에 걸린 트리거 목록 확인
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'notifications';
