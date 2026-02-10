-- ==========================================
-- [fix_feedback_trigger.sql]
-- feedback 테이블의 남은 중복 트리거 제거
-- ==========================================

-- 1. 중복 트리거 삭제
DROP TRIGGER IF EXISTS on_feedback_created ON public.feedback;

-- 2. 확인: feedback 테이블의 트리거가 1개만 남았는지 확인
SELECT 
    event_object_table,
    trigger_name
FROM information_schema.triggers 
WHERE event_object_table = 'feedback';
