-- ==========================================
-- [debug_push_status.sql]
-- 푸시 알림 관련 DB 상태 점검 스크립트
-- ==========================================

-- 1. pg_net 확장 설치 확인
SELECT * FROM pg_available_extensions WHERE name = 'pg_net';

-- 2. 현재 저장된 FCM 토큰 수 확인 (내용은 보안상 제외, 개수만)
SELECT count(*) as total_tokens FROM public.fcm_tokens;

-- 3. 최근 5건의 알림 (notifications) 확인
-- 트리거가 정상 동작했다면 net.http_post 요청이 발생했어야 함 (여기선 확인 불가하지만 데이터는 확인)
SELECT id, type, title, created_at 
FROM public.notifications 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. 트리거 존재 여부 확인
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'notifications';

-- 5. pg_net 요청 로그 (http_request_queue 테이블이 있다면 확인 - pg_net 버전에 따라 다름)
-- SELECT * FROM net.http_request_queue ORDER BY created DESC LIMIT 5;
-- (실패 시 에러 무시)
