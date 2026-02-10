-- 1. [리뷰] Missing view_count column 추가 및 초기화
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='view_count') THEN
        ALTER TABLE public.reviews ADD COLUMN view_count INTEGER DEFAULT 0;
    ELSE
        -- 혹시라도 NULL인 경우를 대비해 0으로 초기화
        UPDATE public.reviews SET view_count = 0 WHERE view_count IS NULL;
    END IF;
END $$;

-- 2. [RPC] increment_counter 함수 생성
-- 모든 테이블의 특정 컬럼 숫자를 1씩 증가시키는 범용 함수
CREATE OR REPLACE FUNCTION public.increment_counter(table_name text, column_name text, row_id_text text)
RETURNS void AS $$
BEGIN
    EXECUTE format('UPDATE public.%I SET %I = COALESCE(%I, 0) + 1 WHERE id = $1', table_name, column_name, column_name)
    USING row_id_text::uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. [권한] 익명 유저도 조회수를 올릴 수 있도록 권한 부여 (필요 시)
GRANT EXECUTE ON FUNCTION public.increment_counter(text, text, text) TO anon, authenticated, service_role;

-- 4. 확인 메시지
DO $$
BEGIN
    RAISE NOTICE '✅ 조회수 증가 RPC(increment_counter)가 생성되었습니다.';
END $$;
