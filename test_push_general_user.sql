-- ==========================================
-- [test_push_general_user.sql]
-- 일반 유저 계정으로 테스트 알림 발송
-- ==========================================

INSERT INTO public.notifications (
    receiver_id,
    type,
    title,
    content,
    is_read,
    reference_id
) VALUES (
    '36ff160a-19d0-495c-8b03-e74dc635f70e', -- 일반 유저 ID (스크린샷 참조)
    'admin_alert',
    '🔔 일반 계정 테스트',
    '이 알림이 보이면 일반 계정도 수신 성공입니다!',
    false,
    'test_gen_1'
);
