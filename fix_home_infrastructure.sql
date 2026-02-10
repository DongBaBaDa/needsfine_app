-- 1. [리뷰] Missing view_count column 추가
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='view_count') THEN
        ALTER TABLE public.reviews ADD COLUMN view_count INTEGER DEFAULT 0;
    END IF;
END $$;

-- 2. [배너] banners 테이블 존재 확인 및 생성
CREATE TABLE IF NOT EXISTS public.banners (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    image_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. [배너] 관리자 권한 설정 (이미 04_triggers_and_init.sql에 있지만 재확인)
ALTER TABLE public.banners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read banners" ON public.banners;
CREATE POLICY "Anyone can read banners" ON public.banners FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can manage banners" ON public.banners;
CREATE POLICY "Admins can manage banners" ON public.banners FOR ALL 
TO authenticated 
USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
);

-- 4. [배너] Storage Bucket 확인 안내 (SQL로 생성 불가, 대시보드에서 'banners' 버킷 생성 및 공개 설정 필요)
DO $$
BEGIN
    RAISE NOTICE '✅ Home Screen 인프라 수정이 완료되었습니다.';
    RAISE NOTICE '👉 Supabase Dashboard에서 [Storage] -> [banners] 버킷을 생성하고 [Public]으로 설정해 주세요.';
END $$;
