-- ==========================================
-- [fix_notification_trigger_final.sql]
-- 알림 트리거 중복 제거 및 최종 정상화 스크립트
-- ==========================================

-- 1. 기존에 존재할 수 있는 모든 알림 발송 트리거 삭제 (중복 방지)
DROP TRIGGER IF EXISTS tr_notify_push ON public.notifications;
DROP TRIGGER IF EXISTS on_notification_created_push ON public.notifications;
DROP TRIGGER IF EXISTS tr_push_notification ON public.notifications;

-- 2. 기존 함수들 삭제 (혼동 방지)
DROP FUNCTION IF EXISTS public.notify_push_webhook();
DROP FUNCTION IF EXISTS public.trigger_send_push_notification();
DROP FUNCTION IF EXISTS public.handle_push_notification_webhook();

-- 3. pg_net 확장 확인
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 4. 최종 알림 발송 함수 정의 (Edge Function 호출)
CREATE OR REPLACE FUNCTION public.handle_push_notification_webhook()
RETURNS TRIGGER AS $$
DECLARE
    -- 프로젝트 정보 (deploy_push_final.sql 참조)
    v_url TEXT := 'https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/send-push';
    v_anon_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhva2prbWFwcWJpbmhzaXZrYm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMDAzMDgsImV4cCI6MjA3OTY3NjMwOH0.2QEm4vp65dReMyWhSOm8_ZnQj3Sqh2fB84DM0rTfWzg';
    request_id BIGINT;
BEGIN
    -- net.http_post를 통해 Edge Function 호출
    SELECT
        net.http_post(
            url := v_url,
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || v_anon_key
            ),
            body := jsonb_build_object('record', row_to_json(NEW))
        )
    INTO request_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 최종 트리거 생성 (단 하나만 존재해야 함)
CREATE TRIGGER tr_push_notification
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.handle_push_notification_webhook();

-- 6. 확인 메시지
DO $$
BEGIN
    RAISE NOTICE '✅ 알림 트리거가 성공적으로 재설정되었습니다. (Old triggers removed, New single trigger created.)';
END $$;
