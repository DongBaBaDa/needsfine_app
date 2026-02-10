-- ==========================================
-- [04_triggers_and_init.sql]
-- 트리거 연결, Realtime 설정, 초기 데이터(Seed)
-- ==========================================

-- 1. 트리거 연결 (기존 트리거 정리 후 재생성)
drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles
for each row execute function public.handle_updated_at();

drop trigger if exists set_reviews_updated_at on public.reviews;
create trigger set_reviews_updated_at before update on public.reviews
for each row execute function public.handle_updated_at();

drop trigger if exists on_follow_changed on public.follows;
create trigger on_follow_changed
    after insert or delete on public.follows
    for each row execute function public.handle_follow_count();

DROP TRIGGER IF EXISTS on_action_log_insert ON public.action_logs;
CREATE TRIGGER on_action_log_insert
    AFTER INSERT ON public.action_logs
    FOR EACH ROW EXECUTE FUNCTION public.calculate_user_stats();

DROP TRIGGER IF EXISTS tr_new_notice_alert ON public.notices;
CREATE TRIGGER tr_new_notice_alert AFTER INSERT ON public.notices FOR EACH ROW EXECUTE FUNCTION public.handle_new_notice_notification();

DROP TRIGGER IF EXISTS tr_new_suggestion_alert ON public.suggestions;
CREATE TRIGGER tr_new_suggestion_alert AFTER INSERT ON public.suggestions FOR EACH ROW EXECUTE FUNCTION public.handle_admin_alert_notification();

DROP TRIGGER IF EXISTS tr_new_feedback_alert ON public.feedback;
CREATE TRIGGER tr_new_feedback_alert AFTER INSERT ON public.feedback FOR EACH ROW EXECUTE FUNCTION public.handle_admin_alert_notification();

-- 2. Realtime 활성화 (알림, 차트 실시간용)
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE tablename = 'notifications') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE tablename = 'user_stats') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE user_stats;
  END IF;
END $$;

-- 3. 초기 데이터 세팅 (관리자 권한 & 가중치 규칙)
-- 관리자 설정
UPDATE public.profiles
SET is_admin = true
WHERE id = (SELECT id FROM auth.users WHERE email = 'ineedsfine@gmail.com');

-- 가중치 규칙 (ON CONFLICT로 중복 에러 방지)
INSERT INTO public.weight_rules (action_type, description, impact_factors)
VALUES 
('SWIPE_LIKE_EXPENSIVE', '비싼 가게 좋아요', '{"wallet": -5.0, "vibe": 3.0}'),
('SWIPE_LIKE_CHEAP', '가성비 가게 좋아요', '{"wallet": 5.0, "grid": 2.0}')
ON CONFLICT (action_type) DO NOTHING;

do $$
begin
    raise notice '✅ NEEDSFINE System initialized successfully.';
end $$;

-- feedback 테이블 (1:1 문의)
ALTER TABLE feedback ADD COLUMN IF NOT EXISTS user_email TEXT;
ALTER TABLE feedback ADD COLUMN IF NOT EXISTS user_nickname TEXT;
ALTER TABLE feedback ADD COLUMN IF NOT EXISTS user_region TEXT;

-- suggestions 테이블 (건의사항)
ALTER TABLE suggestions ADD COLUMN IF NOT EXISTS user_email TEXT;
ALTER TABLE suggestions ADD COLUMN IF NOT EXISTS user_nickname TEXT;
ALTER TABLE suggestions ADD COLUMN IF NOT EXISTS user_region TEXT;

-- feedback 테이블에 content 컬럼 추가 (기존 message 대신 사용)
ALTER TABLE feedback ADD COLUMN IF NOT EXISTS content TEXT;

-- feedback 테이블 컬럼 확인 (주석 처리: 실행 결과에 혼동을 줄 수 있음)
-- SELECT column_name FROM information_schema.columns 
-- WHERE table_name = 'feedback';

-- feedback 테이블의 message 컬럼을 NULL 허용으로 변경
ALTER TABLE feedback ALTER COLUMN message DROP NOT NULL;


-- ==========================================
-- [추가 수정] 알림 데이터 로드 문제 해결 (RLS 정책 & 트리거)
-- ==========================================

-- 1. RLS 정책 수정 (알림에서 보낸 사람의 정보를 읽을 수 있도록 허용)
-- public.profiles
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.profiles;
CREATE POLICY "Enable read access for authenticated users"
ON public.profiles FOR SELECT TO authenticated USING (true);

-- public.reviews
DROP POLICY IF EXISTS "Enable read access for public reviews" ON public.reviews;
CREATE POLICY "Enable read access for public reviews"
ON public.reviews FOR SELECT TO authenticated USING (true);

-- public.comments
DROP POLICY IF EXISTS "Enable read access for comments" ON public.comments;
CREATE POLICY "Enable read access for comments"
ON public.comments FOR SELECT TO authenticated USING (true);

-- public.review_votes
DROP POLICY IF EXISTS "Enable read access for review_votes" ON public.review_votes;
CREATE POLICY "Enable read access for review_votes"
ON public.review_votes FOR SELECT TO authenticated USING (true);


-- 2. 좋아요(도움됨) 알림 트리거 추가
CREATE OR REPLACE FUNCTION public.handle_new_review_vote()
RETURNS TRIGGER AS $$
DECLARE
    v_receiver_id UUID;
    v_store_name TEXT;
BEGIN
    SELECT user_id, store_name INTO v_receiver_id, v_store_name
    FROM public.reviews
    WHERE id = NEW.review_id;

    IF v_receiver_id != NEW.user_id THEN
        INSERT INTO public.notifications (receiver_id, type, title, content, reference_id)
        VALUES (
            v_receiver_id,
            'like',
            '리뷰 도움됨', 
            '회원님의 리뷰가 도움 되었습니다.', 
            NEW.review_id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_review_vote_insert ON public.review_votes;
CREATE TRIGGER on_review_vote_insert
    AFTER INSERT ON public.review_votes
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_review_vote();


-- 3. 알림 테이블(notifications) RLS 재정비
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
ON public.notifications FOR SELECT
TO authenticated
USING (auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can insert notifications" ON public.notifications;
CREATE POLICY "Users can insert notifications"
ON public.notifications FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications"
ON public.notifications FOR UPDATE
TO authenticated
USING (auth.uid() = receiver_id);

-- 4. 최종 확인 메시지
DO $$
BEGIN
    RAISE NOTICE '✅ 모든 정책과 트리거 설정이 완료되었습니다! (All policies and triggers applied successfully)';
END $$;
