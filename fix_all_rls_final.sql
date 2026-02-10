-- fix_all_rls_final.sql

-- Enable RLS
ALTER TABLE user_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_list_items ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 1. user_lists Policies
-- =========================================================

-- Allow everyone to view public lists
DROP POLICY IF EXISTS "Public lists are viewable by everyone" ON user_lists;
CREATE POLICY "Public lists are viewable by everyone"
ON user_lists FOR SELECT
USING ( is_public = true );

-- Allow users to view their own lists (private or public)
DROP POLICY IF EXISTS "Users can view their own lists" ON user_lists;
CREATE POLICY "Users can view their own lists"
ON user_lists FOR SELECT
USING ( auth.uid() = user_id );

-- Allow users to insert their own lists
DROP POLICY IF EXISTS "Users can insert their own lists" ON user_lists;
CREATE POLICY "Users can insert their own lists"
ON user_lists FOR INSERT
WITH CHECK ( auth.uid() = user_id );

-- Allow users to update their own lists
DROP POLICY IF EXISTS "Users can update their own lists" ON user_lists;
CREATE POLICY "Users can update their own lists"
ON user_lists FOR UPDATE
USING ( auth.uid() = user_id );

-- Allow users to delete their own lists
DROP POLICY IF EXISTS "Users can delete their own lists" ON user_lists;
CREATE POLICY "Users can delete their own lists"
ON user_lists FOR DELETE
USING ( auth.uid() = user_id );


-- =========================================================
-- 2. user_list_items Policies
-- =========================================================

-- Allow everyone to view items in a public list
DROP POLICY IF EXISTS "Public list items are viewable by everyone" ON user_list_items;
CREATE POLICY "Public list items are viewable by everyone"
ON user_list_items FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM user_lists
    WHERE user_lists.id = user_list_items.list_id
    AND user_lists.is_public = true
  )
);

-- Allow users to view their own list items
DROP POLICY IF EXISTS "Users can view their own list items" ON user_list_items;
CREATE POLICY "Users can view their own list items"
ON user_list_items FOR SELECT
USING ( auth.uid() = user_id );

-- Allow users to insert their own list items
DROP POLICY IF EXISTS "Users can insert their own list items" ON user_list_items;
CREATE POLICY "Users can insert their own list items"
ON user_list_items FOR INSERT
WITH CHECK ( auth.uid() = user_id );

-- Allow users to delete their own list items
DROP POLICY IF EXISTS "Users can delete their own list items" ON user_list_items;
CREATE POLICY "Users can delete their own list items"
ON user_list_items FOR DELETE
USING ( auth.uid() = user_id );

-- (Optional) If you have a separate store_saves table needing access?
-- Usually store_saves is personal, but if listing depends on it... 
-- actually user_list_items has review_id or store info directly? 
-- user_list_items -> review_id -> reviews (public). So this should be enough.
