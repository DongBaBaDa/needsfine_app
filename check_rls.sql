-- check_rls.sql

-- 1. Check policies for user_lists
SELECT * FROM pg_policies WHERE tablename = 'user_lists';

-- 2. Check policies for user_list_items
SELECT * FROM pg_policies WHERE tablename = 'user_list_items';

-- 3. Check table definition for user_list_items to see foreign keys usually
-- (This is just a comment, I will rely on policies)
