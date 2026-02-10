-- ==========================================
-- [09_FINAL_SOLUTION.sql]
-- 해결될 때까지 모든 권한과 연결고리를 강제로 맞추는 최종 스크립트
-- + 리뷰 카드 숫자(좋아요/댓글/저장) 자동 업데이트 트리거 포함
-- + 저장(Save) 기능 RLS 포함
-- ==========================================

-- 0. [사전 준비] reviews 테이블에 save_count 컬럼 추가
-- (없으면 에러가 날 수 있으므로 미리 확인하여 생성)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='reviews' AND column_name='save_count') THEN
        ALTER TABLE public.reviews ADD COLUMN save_count integer DEFAULT 0;
    END IF;
END $$;


-- 1. [핵심] 앱이 찾는 외래키 이름 강제 생성 (좋아요 알림 해결용)
-- 앱 코드는 'review_votes_user_id_fkey'라는 이름을 통해 유저 닉네임을 가져옵니다.
-- 이 이름이 없으면 앱이 유저 정보를 아예 못 읽어옵니다.
DO $$
BEGIN
    -- 이름이 틀린 제약조건이 있다면 삭제
    ALTER TABLE public.review_votes DROP CONSTRAINT IF EXISTS review_votes_user_id_fkey;
    
    -- 앱이 원하는 이름으로 다시 생성
    ALTER TABLE public.review_votes
        ADD CONSTRAINT review_votes_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
        
    RAISE NOTICE '✅ 외래키(review_votes_user_id_fkey) 복구 완료';
END $$;


-- 2. [핵심] 조회 권한(GRANT) 강제 부여 (RLS보다 상위 권한)
-- 정책(Policy)이 있어도 이 기본 권한이 없으면 조회가 안 됩니다.
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
-- 시퀀스 권한도 부여 (혹시 모를 에러 방지)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;


-- 3. [핵심] RLS 정책 완전 개방 및 기능 활성화
-- "로그인한 사람은 누구나 읽을 수 있다"로 통일합니다.

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.review_saves ENABLE ROW LEVEL SECURITY; -- [추가] 저장 기능

-- 기존 정책 삭제 (충돌 방지)
DROP POLICY IF EXISTS "Allow Read Access Profiles" ON public.profiles;
DROP POLICY IF EXISTS "Allow Read Access Reviews" ON public.reviews;
DROP POLICY IF EXISTS "Allow Read Access Comments" ON public.comments;
DROP POLICY IF EXISTS "Allow Read Access Votes" ON public.review_votes;
DROP POLICY IF EXISTS "Allow Read Access Notifications" ON public.notifications;

-- [추가] review_saves 정책 삭제
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.review_saves;
DROP POLICY IF EXISTS "Enable select for authenticated users" ON public.review_saves;
DROP POLICY IF EXISTS "Enable delete for users own saves" ON public.review_saves;


-- 새 정책 생성 (읽기 전용은 모두에게 개방)
CREATE POLICY "Allow Read Access Profiles" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Allow Read Access Reviews" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Allow Read Access Comments" ON public.comments FOR SELECT USING (true);
CREATE POLICY "Allow Read Access Votes" ON public.review_votes FOR SELECT USING (true);

-- 내 알림만 보기
CREATE POLICY "Allow Read Access Notifications" ON public.notifications FOR SELECT USING (auth.uid() = receiver_id);

-- [추가] review_saves (저장 기능 권한)
-- (1) 저장하기 (Insert)
CREATE POLICY "Enable insert for authenticated users" ON public.review_saves FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
-- (2) 내가 저장한거 보기 (Select)
CREATE POLICY "Enable select for authenticated users" ON public.review_saves FOR SELECT TO authenticated USING (auth.uid() = user_id);
-- (3) 저장 취소 (Delete)
CREATE POLICY "Enable delete for users own saves" ON public.review_saves FOR DELETE TO authenticated USING (auth.uid() = user_id);


-- 4. [트리거 통합] 알림 생성 + 숫자 자동 업데이트(좋아요/댓글/저장)

-- (1) 알림 생성 함수 (닉네임 방어 로직 추가됨)
CREATE OR REPLACE FUNCTION public.handle_social_notifications()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
    sender_nickname TEXT;
    target_store_name TEXT;
    target_review_id TEXT;  -- UUID 대신 TEXT로 변환하여 저장
BEGIN
    -- 닉네임 가져오기 (없으면 '알 수 없음'으로 처리하여 에러 방지)
    SELECT COALESCE(nickname, '알 수 없음') INTO sender_nickname 
    FROM public.profiles WHERE id = NEW.user_id;

    IF (TG_TABLE_NAME = 'comments') THEN
        SELECT user_id, store_name INTO target_user_id, target_store_name 
        FROM public.reviews WHERE id = NEW.review_id;
        target_review_id := NEW.id::text; -- 댓글은 댓글 ID를 참조

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
        target_review_id := NEW.review_id::text; -- 좋아요는 리뷰 ID를 참조

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


-- (2) 좋아요 카운트 자동화 함수
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

-- (3) 저장 카운트 자동화 함수
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

-- (4) 댓글 카운트 자동화 함수
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


-- 5. [트리거 연결] 테이블에 함수 부착
-- 기존 트리거 제거 후 재생성
DROP TRIGGER IF EXISTS tr_vote_count_update ON public.review_votes;
CREATE TRIGGER tr_vote_count_update AFTER INSERT OR DELETE ON public.review_votes FOR EACH ROW EXECUTE FUNCTION public.handle_review_vote_count();

DROP TRIGGER IF EXISTS tr_save_count_update ON public.review_saves;
CREATE TRIGGER tr_save_count_update AFTER INSERT OR DELETE ON public.review_saves FOR EACH ROW EXECUTE FUNCTION public.handle_review_save_count();

DROP TRIGGER IF EXISTS on_comment_change ON public.comments; -- 구버전 트리거 삭제
DROP TRIGGER IF EXISTS tr_comment_count_update ON public.comments;
CREATE TRIGGER tr_comment_count_update AFTER INSERT OR DELETE ON public.comments FOR EACH ROW EXECUTE FUNCTION public.handle_comment_count();


-- 6. [데이터 보정] 기존 숫자가 안 맞을 수 있으니 싹 다시 계산
-- (정확한 카운트 동기화)
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


-- 7. 캐시 초기화 및 완료 확인
NOTIFY pgrst, 'reload schema';

DO $$
BEGIN
    RAISE NOTICE '==================================================';
    RAISE NOTICE '✅ [최종 해결]';
    RAISE NOTICE '   1. 댓글/좋아요 알림 문제 해결 (외래키, RLS, 닉네임 방어)';
    RAISE NOTICE '   2. 리뷰 카드 숫자(좋아요/댓글/저장) 자동 업데이트 적용';
    RAISE NOTICE '   3. 저장(Save) 기능 권한 적용';
    RAISE NOTICE '==================================================';
    RAISE NOTICE '👉 이제 앱을 [완전히 껐다가] 다시 켜서 테스트해주세요.';
END $$;
