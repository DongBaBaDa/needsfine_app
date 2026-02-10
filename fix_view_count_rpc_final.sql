-- Function to increment review view count
CREATE OR REPLACE FUNCTION public.increment_review_view_count(row_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.reviews
  SET view_count = view_count + 1
  WHERE id = row_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.increment_review_view_count(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_review_view_count(uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.increment_review_view_count(uuid) TO anon;
