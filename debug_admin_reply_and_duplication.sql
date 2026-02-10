-- ==========================================
-- [debug_admin_reply_and_duplication.sql]
-- 문의 중복 및 답변 트리거 확인
-- ==========================================

-- 1. 최근 문의글 중복 확인 (제목이 같고 생성시간이 매우 비슷한 글 찾기)
SELECT id, content, created_at, user_id
FROM public.feedback
ORDER BY created_at DESC
LIMIT 10;

-- 2. 답변 알림 트리거가 제대로 걸려있는지 확인
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table,
    action_statement 
FROM information_schema.triggers 
WHERE trigger_name = 'tr_admin_reply_alert';

-- 3. (테스트) 답변 업데이트 시뮬레이션
-- 가장 최근 문의글 하나에 답변을 달아서 알림이 생성되는지 확인
-- (주의: 실제 데이터가 변경되므로 테스트용으로만 확인 후 롤백 필요하지만, 여기선 트리거 동작 확인용)
-- UPDATE public.feedback 
-- SET answer = '답변 알림 테스트입니다.' 
-- WHERE id = (SELECT id FROM public.feedback ORDER BY created_at DESC LIMIT 1);
