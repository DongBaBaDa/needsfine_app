-- ==========================================
-- [diagnose_admin_duplication.sql]
-- 관리자 알림 중복 원인 정밀 분석
-- ==========================================

-- 1. 관리자 토큰 개수 재확인 (혹시 2개인지)
SELECT 'Admin Token Count' as check_item, count(*) as count_val 
FROM public.fcm_tokens 
WHERE user_id = '1880eabb-ea80-4ef3-8e21-b7d7a2415670';

-- 2. 최근 1:1 문의(feedback) 데이터 확인 (앱에서 2번 보냈는지)
SELECT 'Recent Feedbacks' as check_item, id, content, created_at 
FROM public.feedback 
ORDER BY created_at DESC 
LIMIT 5;

-- 3. 최근 관리자 알림(notifications) 데이터 확인 (트리거가 2번 돌았는지)
SELECT 'Recent Notifications' as check_item, id, title, content, created_at 
FROM public.notifications 
WHERE receiver_id = '1880eabb-ea80-4ef3-8e21-b7d7a2415670'
ORDER BY created_at DESC 
LIMIT 5;
