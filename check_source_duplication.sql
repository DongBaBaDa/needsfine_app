-- ==========================================
-- [check_source_duplication.sql]
-- 원천 테이블(feedback) 데이터 및 트리거 중복 확인
-- ==========================================

-- 1. feedback (1:1 문의) 테이블 최근 데이터 확인
-- (여기에도 5개가 쌓여있으면 앱에서 버튼 클릭 시 여러 번 전송된 것임)
SELECT id, content, created_at 
FROM public.feedback 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. feedback 테이블에 걸린 트리거 전체 확인
-- (데이터는 1개인데 알림이 5개면, 여기서 트리거가 중복일 확률 높음)
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'feedback';

-- 3. suggestions (건의사항) 테이블 트리거 확인
SELECT 
    trigger_name, 
    event_manipulation, 
    action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'suggestions';
