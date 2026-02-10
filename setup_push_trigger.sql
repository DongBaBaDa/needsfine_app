-- ==========================================
-- [setup_push_trigger.sql]
-- pg_net을 사용하여 DB 트리거에서 Edge Function 호출
-- ==========================================

-- 1. pg_net 확장 활성화 (HTTP 요청용)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. 푸시 발송 트리거 함수 정의
CREATE OR REPLACE FUNCTION public.notify_push_webhook()
RETURNS TRIGGER AS $$
DECLARE
    v_url TEXT := 'https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/send-push';
    v_api_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhva2prbWFwcWJpbmhzaXZrYm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMDAzMDgsImV4cCI6MjA3OTY3NjMwOH0.2QEm4vp65dReMyWhSOm8_ZnQj3Sqh2fB84DM0rTfWzg'; -- Anon Key
    request_id BIGINT;
BEGIN
    -- Edge Function 호출 (비동기)
    -- record 필드에 NEW 레코드 전체를 포함하여 전송
    SELECT
        net.http_post(
            url := v_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || v_api_key
            ),
            body := jsonb_build_object('record', row_to_json(NEW))
        )
    INTO request_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. notifications 테이블에 트리거 부착
DROP TRIGGER IF EXISTS tr_notify_push ON public.notifications;

CREATE TRIGGER tr_notify_push
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.notify_push_webhook();
