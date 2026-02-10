-- [v14.3_GEM] 리뷰 테이블 점수 산정 관련 신규 컬럼 추가
-- Edge Function (make-server-26899706)의 원활한 작동을 위해 필요한 컬럼들을 추가합니다.

DO $$
BEGIN
    -- 1. recalculated_at: 재계산 시점 기록
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='recalculated_at') THEN
        ALTER TABLE public.reviews ADD COLUMN recalculated_at TIMESTAMP WITH TIME ZONE;
    END IF;

    -- 2. debug_reason: 점수 산정 근거 (디버깅용)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='debug_reason') THEN
        ALTER TABLE public.reviews ADD COLUMN debug_reason TEXT DEFAULT 'NORMAL';
    END IF;

    -- 3. is_malicious: 악성 리뷰 여부
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='is_malicious') THEN
        ALTER TABLE public.reviews ADD COLUMN is_malicious BOOLEAN DEFAULT FALSE;
    END IF;

    -- 4. entropy_score: 정보 밀도 점수
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='entropy_score') THEN
        ALTER TABLE public.reviews ADD COLUMN entropy_score NUMERIC DEFAULT 0;
    END IF;

    RAISE NOTICE '✅ 리뷰 테이블 스키마 업데이트 완료 (recalculated_at, debug_reason, is_malicious, entropy_score 추가됨)';
END $$;
