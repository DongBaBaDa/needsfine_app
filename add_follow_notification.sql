-- ==========================================
-- [add_follow_notification.sql]
-- 팔로우 발생 시 알림 생성 트리거 추가
-- ==========================================

CREATE OR REPLACE FUNCTION public.handle_follow_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_nickname TEXT;
BEGIN
    -- 팔로우한 사람의 닉네임 가져오기
    SELECT COALESCE(nickname, '알 수 없음') INTO v_sender_nickname 
    FROM public.profiles WHERE id = NEW.follower_id;

    -- 알림 생성 (receiver_id: 팔로우 당한 사람, reference_id: 팔로우 한 사람의 ID)
    INSERT INTO public.notifications (receiver_id, type, title, content, reference_id)
    VALUES (
        NEW.following_id,
        'follow',
        '새로운 팔로워',
        v_sender_nickname || '님이 당신을 팔로우했습니다.',
        NEW.follower_id::text
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_follow_notification ON public.follows;
CREATE TRIGGER tr_follow_notification
AFTER INSERT ON public.follows
FOR EACH ROW EXECUTE FUNCTION public.handle_follow_notification();
