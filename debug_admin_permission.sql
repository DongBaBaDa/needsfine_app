-- 1. Check if 'users' table exists in public schema
SELECT * FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users';

-- 2. Check Policies on suggestions and feedback
SELECT m.relname AS table_name, p.polname AS policy_name, p.polcmd, p.polroles, p.polqual, p.polwithcheck
FROM pg_policy p
JOIN pg_class m ON m.oid = p.polrelid
WHERE m.relname IN ('suggestions', 'feedback', 'profiles');

-- 3. Check if 'profiles' is a view or table
SELECT table_type FROM information_schema.tables WHERE table_name = 'profiles';

-- 4. Create a fix for RLS if needed (Allow admins to view all suggestions/feedback)
-- Drop existing policies to avoid "already exists" error
DROP POLICY IF EXISTS "Admins can view all suggestions" ON suggestions;
DROP POLICY IF EXISTS "Admins can view all feedback" ON feedback;
DROP POLICY IF EXISTS "Enable read access for all users" ON suggestions;
DROP POLICY IF EXISTS "Enable read access for all users" ON feedback;

-- Create comprehensive policies
CREATE POLICY "Admins can view all suggestions" ON suggestions
  FOR SELECT
  USING (
    (SELECT is_admin FROM profiles WHERE id = auth.uid()) = true
    OR auth.uid() = user_id -- Users see their own
  );

CREATE POLICY "Admins can view all feedback" ON feedback
  FOR SELECT
  USING (
    (SELECT is_admin FROM profiles WHERE id = auth.uid()) = true
    OR auth.uid() = user_id
  );

-- 5. Grant permissions to authenticated users for 'users' (if it exists and is needed, but typically likely an error in RLS referencing auth.users)
-- If 'users' referenced in the error is actually auth.users, we cannot grant select on it easily.
-- Instead, ensure we rely on public.profiles.

-- 6. Check if any trigger references 'users'
SELECT tgname, tgrelid::regclass 
FROM pg_trigger 
WHERE tgname ILIKE '%user%';
