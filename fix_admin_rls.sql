-- 1. 관리자(ineedsfine@gmail.com)가 suggestions, feedback 테이블을 UPDATE 할 수 있도록 RLS 추가
-- 기존 정책이 있을 수 있으므로 DO 블록 사용 또는 IF NOT EXISTS 구문 활용

-- Suggestions 테이블 정책
DROP POLICY IF EXISTS "Admin can update suggestions" ON public.suggestions;
CREATE POLICY "Admin can update suggestions"
ON public.suggestions
FOR UPDATE
TO authenticated
USING (
  (SELECT email FROM auth.users WHERE id = auth.uid()) = 'ineedsfine@gmail.com'
)
WITH CHECK (
  (SELECT email FROM auth.users WHERE id = auth.uid()) = 'ineedsfine@gmail.com'
);

-- Feedback 테이블 정책
DROP POLICY IF EXISTS "Admin can update feedback" ON public.feedback;
CREATE POLICY "Admin can update feedback"
ON public.feedback
FOR UPDATE
TO authenticated
USING (
  (SELECT email FROM auth.users WHERE id = auth.uid()) = 'ineedsfine@gmail.com'
)
WITH CHECK (
  (SELECT email FROM auth.users WHERE id = auth.uid()) = 'ineedsfine@gmail.com'
);


-- 2. 관리자 알림(suggestions, feedback) 트리거가 notifications 테이블에 'admin_alert' 타입으로 잘 들어가는지 확인
-- 이미 index.ts에서 sendAdminPush가 insert를 수행하므로 트리거는 중복일 수 있으나,
-- 트리거가 있다면 중복 알림이 발생할 수 있음. 기존 트리거 확인 필요.

-- 만약 기존 트리거가 있다면 삭제하거나 조정.
DROP TRIGGER IF EXISTS on_suggestion_created_admin_alert ON public.suggestions;
DROP TRIGGER IF EXISTS on_feedback_created_admin_alert ON public.feedback;

-- 3. Notification 리스트 조회 시 admin_alert 타입도 보여야 함 (RLS)
-- notifications 테이블의 Select 정책이 "Users can only see their own notifications" 라면
-- receive_id가 admin_id로 되어 있으므로, 관리자가 로그인하면 보여야 함.
-- 별도 조치 불필요.

