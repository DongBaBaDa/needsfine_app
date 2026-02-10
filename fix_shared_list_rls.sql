-- fix_shared_list_rls.sql

-- Drop existing policy if it conflicts (optional, but safer to start fresh or alter)
DROP POLICY IF EXISTS "Public list items are viewable by everyone" ON user_list_items;

-- Create policy to allow SELECT on user_list_items if the parent list is public
CREATE POLICY "Public list items are viewable by everyone"
ON user_list_items
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM user_lists
    WHERE user_lists.id = user_list_items.list_id
    AND user_lists.is_public = true
  )
);

-- Ensure RLS is enabled
ALTER TABLE user_list_items ENABLE ROW LEVEL SECURITY;
