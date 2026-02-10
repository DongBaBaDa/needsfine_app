-- 1. Check FCM Tokens count
SELECT count(*) as total_tokens FROM fcm_tokens;

-- 2. Check recent FCM tokens (limit 5)
-- Note: 'created_at' column might not exist, simply selecting all
SELECT * FROM fcm_tokens LIMIT 5;

-- 3. Check recent notifications (limit 5)
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5;

-- 4. Check if the 'send-push' function is being called (This is harder to check via SQL, usually managed via Dashboard Logs)
-- Instead, check if the trigger exists
SELECT tgname, tgrelid::regclass 
FROM pg_trigger 
WHERE tgname = 'on_notification_created';

-- 5. Check net extension (required for http calls in triggers if used directly, though we use edge functions)
-- SELECT * FROM pg_extension WHERE extname = 'net';

-- 6. Check permissions for service_role to access fcm_tokens (RLS)
-- If RLS is enabled on fcm_tokens, service_role usually bypasses it, but good to check policy.
SELECT * FROM pg_policies WHERE tablename = 'fcm_tokens';
