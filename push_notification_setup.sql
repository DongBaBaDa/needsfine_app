-- ==========================================
-- [push_notification_setup.sql]
-- 푸시 알림을 위한 FCM 토큰 저장 및 전송 트리거 설정
-- ==========================================

-- 1. FCM 토큰 저장 테이블 생성
CREATE TABLE IF NOT EXISTS public.fcm_tokens (
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type TEXT, -- 'ios', 'android' 등
    last_updated_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (user_id, token)
);

-- RLS 설정
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own tokens" ON public.fcm_tokens;
CREATE POLICY "Users can manage their own tokens"
ON public.fcm_tokens FOR ALL
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 2. 알림 발생 시 Edge Function 호출 로직 (Database Webhook 사용 권장)
-- 여기서는 Supabase Dashboard에서 Edge Function 웹훅을 설정하는 것을 제안하거나,
-- 트리거에서 직접 http를 통해 호출할 수도 있습니다.

-- 3. 관리자 알림(suggestions, feedback) 트리거 수정
-- handle_admin_alert_notification 함수는 이미 존재하므로
-- 여기에 푸시 알림 관련 로직이 담긴 notifications 테이블 insert가 발생하면
-- 그 notifications 테이블에 트리거를 걸어 Edge Function을 호출하는 방식이 깔끔합니다.

-- 4. notifications 테이블에 트리거 추가 (새 알림이 들어오면 푸시 발송 시도)
CREATE OR REPLACE FUNCTION public.notify_push_webhook()
RETURNS TRIGGER AS $$
BEGIN
    -- receiver_id의 FCM 토큰이 있는지 확인
    -- (실제 발송은 Edge Function에서 수행하므로 여기서는 웹훅 요청만 발생시킴)
    -- Supabase Dashboard -> Database -> Webhooks에서 
    -- 'notifications' 테이블 'INSERT' 이벤트에 대해 Edge Function을 호출하도록 설정하세요.
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. 기존 handle_admin_alert_notification 수정 (content 컬럼 반영 및 알림 생성)
CREATE OR REPLACE FUNCTION public.handle_admin_alert_notification()
RETURNS TRIGGER AS $$
DECLARE
    admin_id UUID;
    v_content TEXT;
BEGIN
    -- 관리자 ID 가져오기 (ineedsfine@gmail.com)
    SELECT id INTO admin_id FROM auth.users WHERE email = 'ineedsfine@gmail.com';

    IF (TG_TABLE_NAME = 'suggestions') THEN
        v_content := '새로운 건의사항: ' || LEFT(NEW.content, 50);
    ELSIF (TG_TABLE_NAME = 'feedback') THEN
        v_content := '새로운 1:1 문의: ' || LEFT(NEW.content, 50);
    END IF;

    IF admin_id IS NOT NULL THEN
        INSERT INTO public.notifications (receiver_id, type, title, content, reference_id)
        VALUES (admin_id, 'admin_alert', '관리자 알림', v_content, NEW.id::text);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
