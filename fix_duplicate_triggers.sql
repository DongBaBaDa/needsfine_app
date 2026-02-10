-- ==========================================
-- [fix_duplicate_triggers.sql]
-- 중복 트리거 제거 (알림 5회 발송 원인 해결)
-- ==========================================

-- 1. suggestions (건의사항) 테이블 중복 트리거 삭제
DROP TRIGGER IF EXISTS on_new_suggestion ON public.suggestions;
DROP TRIGGER IF EXISTS on_suggestion_created_alert ON public.suggestions;
-- 'tr_new_suggestion_alert' 하나만 남김

-- 2. feedback (1:1 문의) 테이블 중복 트리거 삭제 (예상되는 중복 이름들)
DROP TRIGGER IF EXISTS on_new_feedback ON public.feedback;
DROP TRIGGER IF EXISTS on_feedback_created_alert ON public.feedback;
DROP TRIGGER IF EXISTS tr_feedback_created_alert ON public.feedback; 
-- 'tr_new_feedback_alert' (또는 유사한 신규 트리거) 하나만 남겨야 함.
-- 만약 'tr_new_feedback_alert'가 없다면 create 문이 필요할 수 있으나, 
-- 일단 중복 제거가 우선이므로 삭제만 수행.

-- 3. 확인: 남은 트리거 목록 조회
SELECT 
    event_object_table,
    trigger_name
FROM information_schema.triggers 
WHERE event_object_table IN ('suggestions', 'feedback');
