
-- 1. Enable Users to see their own history (Fixes 'Inquiry history is empty')
-- Drop existing policies to avoid conflicts (or use 'do' block, but simplistic drop is okay for now if we recreate)
DROP POLICY IF EXISTS "Users can view their own suggestions" ON suggestions;
CREATE POLICY "Users can view their own suggestions" 
ON suggestions FOR SELECT 
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view their own feedback" ON feedback;
CREATE POLICY "Users can view their own feedback" 
ON feedback FOR SELECT 
USING (auth.uid() = user_id);

-- 2. Ensure Admins can see ALL suggestions/feedback (for the Admin Dashboard)
DROP POLICY IF EXISTS "Admins can view all suggestions" ON suggestions;
CREATE POLICY "Admins can view all suggestions" 
ON suggestions FOR SELECT 
USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  OR
  (SELECT email FROM auth.users WHERE id = auth.uid()) IN ('ineedsfine@gmail.com', 'ineedsdfine@gmail.com')
);

DROP POLICY IF EXISTS "Admins can view all feedback" ON feedback;
CREATE POLICY "Admins can view all feedback" 
ON feedback FOR SELECT 
USING (
  EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND is_admin = true)
  OR
  (SELECT email FROM auth.users WHERE id = auth.uid()) IN ('ineedsfine@gmail.com', 'ineedsdfine@gmail.com')
);

-- 3. Fix Admin Alert Trigger (Fixes 'Admin alerts not appearing')
CREATE OR REPLACE FUNCTION handle_admin_alert_notification()
RETURNS TRIGGER AS $$
DECLARE
  admin_id uuid;
  msg_content text;
  msg_title text;
BEGIN
  -- Determine content based on table
  IF TG_TABLE_NAME = 'suggestions' THEN
    msg_content := NEW.content;
    msg_title := '새로운 건의사항';
  ELSIF TG_TABLE_NAME = 'feedback' THEN
    msg_content := NEW.message; -- feedback table might use 'message' column
    msg_title := '새로운 1:1 문의';
  ELSE
    msg_content := '새로운 내용';
    msg_title := '알림';
  END IF;

  -- 1. Try to find admin by specific email
  SELECT id INTO admin_id FROM auth.users WHERE email = 'ineedsfine@gmail.com' LIMIT 1;
  
  -- 2. If not found, try the other email (typo version)
  IF admin_id IS NULL THEN
     SELECT id INTO admin_id FROM auth.users WHERE email = 'ineedsdfine@gmail.com' LIMIT 1;
  END IF;

  -- 3. If still null, try to find ANY admin from profiles
  IF admin_id IS NULL THEN
     SELECT id INTO admin_id FROM profiles WHERE is_admin = true LIMIT 1;
  END IF;
  
  -- Insert notification if admin found
  IF admin_id IS NOT NULL THEN
    INSERT INTO notifications (receiver_id, type, title, content, reference_id, is_read)
    VALUES (
      admin_id, 
      'admin_alert', 
      msg_title, 
      substring(msg_content from 1 for 100), -- Truncate content
      NEW.id,
      false
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create triggers to ensure they are active
DROP TRIGGER IF EXISTS on_suggestion_created_alert ON suggestions;
CREATE TRIGGER on_suggestion_created_alert
AFTER INSERT ON suggestions
FOR EACH ROW
EXECUTE FUNCTION handle_admin_alert_notification();

DROP TRIGGER IF EXISTS on_feedback_created_alert ON feedback;
CREATE TRIGGER on_feedback_created_alert
AFTER INSERT ON feedback
FOR EACH ROW
EXECUTE FUNCTION handle_admin_alert_notification();

-- 4. Ensure Notification Policies are Open for Admin Alert
-- (Assuming standard notification policies exist: "Users can view their own notifications")
-- No change needed if receiver_id is set correctly to the admin's UUID.
