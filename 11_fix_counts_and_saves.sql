-- ==========================================
-- [11_fix_counts_and_saves.sql]
-- 리뷰 카드의 숫자(좋아요/댓글/저장)가 안 올라가는 문제 해결
-- 저장(Save) 기능이 동작하도록 RLS 및 테이블 설정 보완
-- ==========================================

-- 1. [저장 기능] review_saves 테이블에 대한 권한(RLS) 확실히 부여
-- 테이블은 이미 존재하지만 정책이 없으면 저장이 안 됩니다.
ALTER TABLE public.review_saves ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제 (중복 방지)
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.review_saves;
DROP POLICY IF EXISTS "Enable select for authenticated users" ON public.review_saves;
DROP POLICY IF EXISTS "Enable delete for users own saves" ON public.review_saves;

-- 새 정책 생성
-- (1) 저장하기 (Insert)
CREATE POLICY "Enable insert for authenticated users"
ON public.review_saves FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- (2) 내가 저장한거 보기 (Select)
CREATE POLICY "Enable select for authenticated users"
ON public.review_saves FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- (3) 저장 취소 (Delete)
CREATE POLICY "Enable delete for users own saves"
ON public.review_saves FOR DELETE
TO authenticated
USING (auth.uid() = user_id);


-- 2. [숫자 업데이트] reviews 테이블에 save_count 컬럼 추가
-- (없으면 추가하고, 있으면 0으로 초기화하지 않고 유지)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='save_count') THEN
        ALTER TABLE public.reviews ADD COLUMN save_count integer DEFAULT 0;
    END IF;
END $$;


-- 3. [핵심] 자동으로 숫자를 세어주는 트리거(Trigger) 생성
-- 앱에서 숫자를 올리는게 아니라, DB가 알아서 세도록 합니다.

-- (1) 좋아요 카운트 자동화
CREATE OR REPLACE FUNCTION public.handle_review_vote_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') AND (NEW.vote_type = 'like') THEN
        UPDATE public.reviews SET like_count = like_count + 1 WHERE id = NEW.review_id;
    ELSIF (TG_OP = 'DELETE') AND (OLD.vote_type = 'like') THEN
        UPDATE public.reviews SET like_count = GREATEST(0, like_count - 1) WHERE id = OLD.review_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_vote_count_update ON public.review_votes;
CREATE TRIGGER tr_vote_count_update
AFTER INSERT OR DELETE ON public.review_votes
FOR EACH ROW EXECUTE FUNCTION public.handle_review_vote_count();


-- (2) 저장 카운트 자동화
CREATE OR REPLACE FUNCTION public.handle_review_save_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.reviews SET save_count = save_count + 1 WHERE id = NEW.review_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.reviews SET save_count = GREATEST(0, save_count - 1) WHERE id = OLD.review_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_save_count_update ON public.review_saves;
CREATE TRIGGER tr_save_count_update
AFTER INSERT OR DELETE ON public.review_saves
FOR EACH ROW EXECUTE FUNCTION public.handle_review_save_count();


-- (3) 댓글 카운트 자동화 (기존 함수 재확인)
CREATE OR REPLACE FUNCTION public.handle_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.reviews SET comment_count = comment_count + 1 WHERE id = NEW.review_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.reviews SET comment_count = GREATEST(0, comment_count - 1) WHERE id = OLD.review_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_comment_change ON public.comments; -- 구버전 트리거 삭제
DROP TRIGGER IF EXISTS tr_comment_count_update ON public.comments;
CREATE TRIGGER tr_comment_count_update
AFTER INSERT OR DELETE ON public.comments
FOR EACH ROW EXECUTE FUNCTION public.handle_comment_count();


-- 4. [알림 Fix] 알림 생성 시 닉네임이 없어도 죽지 않도록 방어 로직 추가
CREATE OR REPLACE FUNCTION public.handle_social_notifications()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
    sender_nickname TEXT;
    target_store_name TEXT;
    target_review_id TEXT;  -- UUID 대신 TEXT로 변환하여 저장
BEGIN
    -- 닉네임 가져오기 (없으면 '알 수 없음'으로 처리)
    SELECT COALESCE(nickname, '알 수 없음') INTO sender_nickname 
    FROM public.profiles WHERE id = NEW.user_id;

    IF (TG_TABLE_NAME = 'comments') THEN
        SELECT user_id, store_name INTO target_user_id, target_store_name 
        FROM public.reviews WHERE id = NEW.review_id;
        target_review_id := NEW.id::text; -- 댓글은 댓글 ID를 참조로 씀 (앱 로직상)

        -- 본인 댓글은 알림 X
        IF target_user_id IS NOT NULL AND target_user_id != NEW.user_id THEN
            INSERT INTO public.notifications (receiver_id, type, title, content, reference_id)
            VALUES (
                target_user_id,
                'comment',
                '새로운 댓글',
                sender_nickname || '님이 ' || COALESCE(target_store_name, '리뷰') || '에 댓글을 남겼습니다.',
                target_review_id
            );
        END IF;

    ELSIF (TG_TABLE_NAME = 'review_votes' AND NEW.vote_type = 'like') THEN
        SELECT user_id, store_name INTO target_user_id, target_store_name 
        FROM public.reviews WHERE id = NEW.review_id;
        target_review_id := NEW.review_id::text; -- 좋아요는 리뷰 ID를 참조로 씀

        -- 본인 좋아요는 알림 X
        IF target_user_id IS NOT NULL AND target_user_id != NEW.user_id THEN
            INSERT INTO public.notifications (receiver_id, type, title, content, reference_id)
            VALUES (
                target_user_id,
                'like',
                '리뷰 도움됨',
                sender_nickname || '님이 ' || COALESCE(target_store_name, '리뷰') || '를 좋아합니다.',
                target_review_id
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 5. [데이터 보정] 기존 숫자가 안 맞을 수 있으니 싹 다시 계산
-- (이 작업은 데이터가 많으면 오래 걸리지만, 정확도를 위해 필수입니다)
DO $$
BEGIN
    -- (1) 좋아요 수 재계산
    UPDATE public.reviews r
    SET like_count = (
        SELECT COUNT(*) FROM public.review_votes v 
        WHERE v.review_id = r.id AND v.vote_type = 'like'
    );

    -- (2) 댓글 수 재계산
    UPDATE public.reviews r
    SET comment_count = (
        SELECT COUNT(*) FROM public.comments c 
        WHERE c.review_id = r.id
    );

    -- (3) 저장 수 재계산
    UPDATE public.reviews r
    SET save_count = (
        SELECT COUNT(*) FROM public.review_saves s 
        WHERE s.review_id = r.id
    );

    RAISE NOTICE '✅ 모든 리뷰의 카운트(좋아요/댓글/저장)를 최신 상태로 갱신했습니다.';
END $$;


-- 6. 캐시 리로드
NOTIFY pgrst, 'reload schema';

DO $$
BEGIN
    RAISE NOTICE '==================================================';
    RAISE NOTICE '✅ [완료] 좋아요, 댓글, 저장 기능의 DB 연결이 끝났습니다.';
    RAISE NOTICE '👉 이제 랭킹 화면에서 "새로고침"을 하면 숫자가 정상적으로 바뀔 것입니다.';
    RAISE NOTICE '==================================================';
END $$;
