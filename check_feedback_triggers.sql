-- ==========================================
-- [check_feedback_triggers.sql]
-- feedback 테이블의 모든 트리거 조회 (범인 색출)
-- ==========================================

SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'feedback';
