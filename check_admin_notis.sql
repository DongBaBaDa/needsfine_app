
-- 1. Check for admin_alert notifications
SELECT * FROM notifications WHERE type = 'admin_alert' ORDER BY created_at DESC LIMIT 5;

-- 2. Check current RLS policies on suggestions and feedback
SELECT date(created_at), count(*) FROM suggestions GROUP BY date(created_at) ORDER BY date(created_at) DESC LIMIT 5;
SELECT date(created_at), count(*) FROM feedback GROUP BY date(created_at) ORDER BY date(created_at) DESC LIMIT 5;

-- 3. Check policies
SELECT tablename, policyname, permissive, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename IN ('suggestions', 'feedback', 'notifications');

-- 4. Check trigger definition (function source)
SELECT prosrc FROM pg_proc WHERE proname = 'handle_admin_alert_notification';
