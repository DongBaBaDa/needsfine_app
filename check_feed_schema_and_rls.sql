-- Check if 'post_saves' or 'bookmarks' exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('posts', 'post_likes', 'post_saves', 'bookmarks', 'reviews');

-- Check columns of 'posts' and 'reviews' to compare structure
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('posts', 'reviews');

-- Check RLS policies for relevant tables
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename IN ('posts', 'post_likes', 'post_saves', 'bookmarks', 'reviews');
