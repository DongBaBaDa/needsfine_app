
-- 1. Check columns of feedback and suggestions tables
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('feedback', 'suggestions');

-- 2. Check if admin user exists (obscured id)
SELECT email, id FROM auth.users WHERE email IN ('ineedsfine@gmail.com', 'ineedsdfine@gmail.com');

-- 3. Check if any notifications have been created recently
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 5;
