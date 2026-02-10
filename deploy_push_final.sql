-- ==========================================
-- [deploy_push_final.sql]
-- 푸시 알림 및 성능 최적화를 위한 통합 배포 스크립트
-- ==========================================

-- 1. notifications 테이블 컬럼 추가 (title, content)
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS content TEXT;

-- 2. FCM 토큰 저장 테이블 생성
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type TEXT, -- 'ios', 'android'
    last_updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, token)
);

-- RLS 설정 for fcm_tokens
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own tokens" ON public.fcm_tokens;
CREATE POLICY "Users can manage their own tokens"
ON public.fcm_tokens FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 3. '모두 읽음' 처리를 위한 RPC 함수
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read(target_user_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE notifications
  SET is_read = true
  WHERE receiver_id = target_user_id
    AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 성능 최적화 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_suggestions_user_id_created ON suggestions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_user_id_created ON feedback(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_is_read ON notifications(receiver_id, is_read);

-- 5. pg_net 확장 확인
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 6. Edge Function 호출 트리거 함수 (Push Notification)
CREATE OR REPLACE FUNCTION public.trigger_send_push_notification()
RETURNS TRIGGER AS $$
DECLARE
    -- 프로젝트 ID: hokjkmapqbinhsivkbnj
    found_anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhva2prbWFwcWJpbmhzaXZrYm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMDAzMDgsImV4cCI6MjA3OTY3NjMwOH0.2QEm4vp65dReMyWhSOm8_ZnQj3Sqh2fB84DM0rTfWzg';
    function_url TEXT := 'https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/send-push';
    payload JSONB;
    request_id BIGINT;
BEGIN
    -- payload 구성: { "record": { ... } }
    payload := jsonb_build_object('record', row_to_json(NEW));

    -- 비동기 호출
    SELECT net.http_post(
        url := function_url,
        body := payload,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || found_anon_key
        )
    ) INTO request_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 트리거 연결 (notifications INSERT 시)
DROP TRIGGER IF EXISTS on_notification_created_push ON public.notifications;
CREATE TRIGGER on_notification_created_push
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.trigger_send_push_notification();


-- 8. 관리자 알림(Suggestions/Feedback) 트리거 함수 수정 (Title, Content 포함)
CREATE OR REPLACE FUNCTION public.handle_admin_alert_notification()
RETURNS TRIGGER AS $$
DECLARE
    admin_id UUID;
    v_title TEXT := '관리자 알림';
    v_content TEXT;
BEGIN
    -- 관리자 ID 가져오기 (ineedsfine@gmail.com)
    SELECT id INTO admin_id FROM auth.users WHERE email = 'ineedsfine@gmail.com';

    IF (TG_TABLE_NAME = 'suggestions') THEN
        v_title := '새로운 건의사항';
        v_content := LEFT(NEW.content, 50);
    ELSIF (TG_TABLE_NAME = 'feedback') THEN
        v_title := '새로운 1:1 문의';
        v_content := LEFT(NEW.content, 50);
    END IF;

    IF admin_id IS NOT NULL THEN
        INSERT INTO public.notifications (receiver_id, type, title, content, reference_id)
        VALUES (admin_id, 'admin_alert', v_title, v_content, NEW.id::text);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- (이미 존재하는 Trigger 연결은 유지됨을 가정, 필요 시 아래 주석 해제하여 트리거 재생성)
-- DROP TRIGGER IF EXISTS on_suggestion_created ON public.suggestions;
-- CREATE TRIGGER on_suggestion_created AFTER INSERT ON public.suggestions FOR EACH ROW EXECUTE FUNCTION public.handle_admin_alert_notification();
-- DROP TRIGGER IF EXISTS on_feedback_created ON public.feedback;
-- CREATE TRIGGER on_feedback_created AFTER INSERT ON public.feedback FOR EACH ROW EXECUTE FUNCTION public.handle_admin_alert_notification();
