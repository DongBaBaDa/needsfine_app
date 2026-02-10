-- 1. Grant SELECT permission on public.users view to authenticated users
GRANT SELECT ON public.users TO authenticated;
GRANT SELECT ON public.users TO service_role;

-- 2. Since 'users' is a view, we cannot enable RLS.
-- Instead, ensure that the view itself is accessible.

-- 3. (Optional) Check the definition of the view to understand what it exposes
-- SELECT definition FROM pg_views WHERE viewname = 'users';

-- 4. If the error "permission denied for table users" persists, it might be because the view queries 'auth.users'
-- and the user (authenticated) does not have permission to read 'auth.users'.
-- In that case, we might need to make the view SECURITY DEFINER (run as owner).
-- BUT, we cannot easily alter that without recreating.
-- For now, retry the Admin Dashboard after running Step 1.
