-- ==========================================
-- [check_activity_triggers.sql]
-- 팔로우, 좋아요, 댓글 테이블의 트리거 조회 (중복 발송 원인 파악)
-- ==========================================

SELECT 
    event_object_table,
    trigger_name, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table IN ('follows', 'likes', 'comments', 'review_likes');
