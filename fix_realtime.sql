-- Notifications 테이블의 실시간(Realtime) 활성화
-- Badge 업데이트가 즉시 반영되려면 UPDATE 이벤트가 전송되어야 함.

-- 1. Realtime Publication에 notifications 테이블 추가
-- (이미 있는데 중복 추가해도 에러나지 않게 처리하거나, 그냥 alter publication 수행 - supabase에서는 보통 UI나 alter publication으로 함)
-- 여기서는 publication에 추가하는 명령어를 사용.
alter publication supabase_realtime add table notifications;

-- 2. (선택사항) RLS 확인 - 사용자가 자신의 알림은 볼 수 있어야 함.
-- 기존 정책이 있을 것이므로 패스하거나, 혹시 모르니 정책 확인용 주석.
-- create policy "Users can view their own notifications" on notifications for select using (auth.uid() = receiver_id);
-- create policy "Users can update their own notifications" on notifications for update using (auth.uid() = receiver_id);

-- 3. 관리자 알림 트리거 확인 (이전 단계에서 Index.ts에서 처리하므로 SQL Trigger는 제거 권장)
-- 중복 알림 방지를 위해 기존 트리거 제거
DROP TRIGGER IF EXISTS on_suggestion_created_admin_notify ON public.suggestions;
DROP TRIGGER IF EXISTS on_feedback_created_admin_notify ON public.feedback;
