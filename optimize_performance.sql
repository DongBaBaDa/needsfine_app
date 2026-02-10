
-- 1. Create RPC for efficient 'Mark All as Read'
CREATE OR REPLACE FUNCTION mark_all_notifications_as_read(target_user_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE notifications
  SET is_read = true
  WHERE receiver_id = target_user_id
    AND is_read = false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create Indices for Customer Center Performance
CREATE INDEX IF NOT EXISTS idx_suggestions_user_id_created ON suggestions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_user_id_created ON feedback(user_id, created_at DESC);

-- 3. Create Index for Notifications (if not exists)
CREATE INDEX IF NOT EXISTS idx_notifications_receiver_is_read ON notifications(receiver_id, is_read);
