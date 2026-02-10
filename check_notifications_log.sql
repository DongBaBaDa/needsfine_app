-- ==========================================
-- [check_notifications_log.sql]
-- 최근 생성된 알림 데이터 확인 (중복 생성 여부 파악)
-- ==========================================

SELECT 
    id, 
    receiver_id, 
    title, 
    content, 
    created_at 
FROM public.notifications 
ORDER BY created_at DESC 
LIMIT 10;
