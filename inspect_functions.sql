-- ==========================================
-- [inspect_functions.sql]
-- 알림 관련 트리거 함수 소스코드 조회
-- ==========================================

-- 1. 팔로우 알림 함수 확인
SELECT 'handle_follow_notification' as func_name, pg_get_functiondef('public.handle_follow_notification'::regproc) as source_code
UNION ALL
-- 2. 소셜 알림 (댓글/좋아요) 함수 확인
SELECT 'handle_social_notifications', pg_get_functiondef('public.handle_social_notifications'::regproc)
UNION ALL
-- 3. (의심) 팔로우 카운트 함수에 알림 로직이 숨어있는지 확인
SELECT 'handle_follow_count', pg_get_functiondef('public.handle_follow_count'::regproc)
UNION ALL
-- 4. 댓글 카운트 함수 확인
SELECT 'handle_comment_count', pg_get_functiondef('public.handle_comment_count'::regproc);
