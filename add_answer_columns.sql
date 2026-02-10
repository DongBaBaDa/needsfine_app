-- suggestions 테이블에 답변 관련 컬럼 추가
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='suggestions' AND column_name='answer') THEN
        ALTER TABLE public.suggestions ADD COLUMN answer TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='suggestions' AND column_name='answered_at') THEN
        ALTER TABLE public.suggestions ADD COLUMN answered_at TIMESTAMPTZ;
    END IF;
END $$;

-- feedback 테이블에 답변 관련 컬럼 추가
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='feedback' AND column_name='answer') THEN
        ALTER TABLE public.feedback ADD COLUMN answer TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='feedback' AND column_name='answered_at') THEN
        ALTER TABLE public.feedback ADD COLUMN answered_at TIMESTAMPTZ;
    END IF;
END $$;

-- RLS 정책 업데이트 (사용자가 자신의 문의/건의사항의 답변을 볼 수 있도록)
-- 이미 select 정책이 auth.uid() = user_id 로 되어 있다면 추가 작업 불필요하지만, 확인 차원.

-- 관리자(ineedsfine@gmail.com)가 답변을 UPDATE 할 수 있도록 정책 확인
-- (Supabase 대시보드에서 전역 서비스 롤을 쓰거나, 앱 내에서 로직 처리 시 관리자 여부 체크)
