-- ==========================================
-- [check_final_status.sql]
-- "3개씩 오는" 원인 최종 점검
-- ==========================================

-- 1. 내 토큰 개수 확인 (이게 3개면 토큰 문제)
SELECT user_id, count(*) as token_count, array_agg(token)
FROM public.fcm_tokens
WHERE user_id = '1880eabb-ea80-4ef3-8e21-b7d7a2415670'
GROUP BY user_id;

-- 2. notifications 테이블 트리거 (이게 여러개면 발송 요청이 여러번 됨)
SELECT event_object_table, trigger_name, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'notifications';

-- 3. 원천 테이블 트리거 재확인
SELECT event_object_table, trigger_name
FROM information_schema.triggers
WHERE event_object_table IN ('feedback', 'suggestions');
