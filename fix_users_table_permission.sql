-- 1. Grant SELECT permission on public.users to authenticated users
GRANT SELECT ON TABLE public.users TO authenticated;
GRANT SELECT ON TABLE public.users TO service_role;

-- 2. Enable RLS on users table (good practice if not already)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policy to avoid conflict
DROP POLICY IF EXISTS "Allow read access for all authenticated users" ON public.users;
DROP POLICY IF EXISTS "Users can see their own user data" ON public.users;

-- 4. Create a permissive policy for reading users (since it's public profile info usually)
-- Adjust this if 'users' contains sensitive data. Assuming it mirrors auth.users for profile linkage.
CREATE POLICY "Allow read access for all authenticated users" ON public.users
FOR SELECT
TO authenticated
USING (true);
