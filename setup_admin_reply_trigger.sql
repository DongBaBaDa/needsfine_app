-- ==========================================
-- [setup_admin_reply_trigger.sql]
-- 관리자가 문의에 답변(answer) 등록 시 유저에게 알림 발송
-- ==========================================

CREATE OR REPLACE FUNCTION public.handle_admin_reply_notification()
RETURNS TRIGGER AS $$
DECLARE
    v_title TEXT := '문의 답변 등록 알림';
    v_content TEXT;
BEGIN
    -- 답변(answer)이 새로 달리거나 수정되었을 때 확인
    IF (NEW.answer IS NOT NULL AND (OLD.answer IS NULL OR NEW.answer <> OLD.answer)) THEN
        
        v_content := '고객님의 문의에 답변이 등록되었습니다: ' || LEFT(NEW.answer, 30);
        
        -- notifications 테이블에 추가 (이것이 다시 push 트리거를 동작시킴)
        INSERT INTO public.notifications (
            receiver_id, 
            type, 
            title, 
            content, 
            reference_id,
            is_read
        ) VALUES (
            NEW.user_id, 
            'inquiry_reply', 
            v_title, 
            v_content, 
            NEW.id::text,
            false
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 등록
DROP TRIGGER IF EXISTS tr_admin_reply_alert ON public.feedback;

CREATE TRIGGER tr_admin_reply_alert
AFTER UPDATE ON public.feedback
FOR EACH ROW
EXECUTE FUNCTION public.handle_admin_reply_notification();
