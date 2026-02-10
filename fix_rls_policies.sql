-- ==========================================
-- [fix_rls_policies.sql]
-- 무한 로딩 해결을 위한 RLS 정책 수정
-- ==========================================

-- 1. Profiles: 인증된 모든 사용자가 프로필을 읽을 수 있도록 허용 (닉네임 표시용)
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- 2. Feedback (1:1 문의): 본인 및 관리자만 볼 수 있도록 허용
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own feedback" ON public.feedback;
CREATE POLICY "Users can view their own feedback"
ON public.feedback FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id OR 
  auth.email() = 'ineedsfine@gmail.com' -- 관리자 이메일 하드코딩 (또는 관리자 테이블/Role 사용 권장)
);

-- 3. Suggestions (건의사항): 본인 및 관리자만 볼 수 있도록 허용
ALTER TABLE public.suggestions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own suggestions" ON public.suggestions;
CREATE POLICY "Users can view their own suggestions"
ON public.suggestions FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id OR 
  auth.email() = 'ineedsfine@gmail.com'
);

-- 4. Notifications: 본인 것만 볼 수 있도록 (이미 되어있을 수 있으나 확실히)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (auth.uid() = receiver_id);

-- 5. Feedback 테이블에 email 컬럼 확인 (없으면 추가)
ALTER TABLE public.feedback ADD COLUMN IF NOT EXISTS email TEXT;
