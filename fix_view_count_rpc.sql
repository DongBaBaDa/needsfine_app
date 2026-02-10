-- Function to safely increment view count for a review
create or replace function increment_review_view_count(row_id uuid)
returns void as $$
begin
  update reviews
  set view_count = view_count + 1
  where id = row_id;
end;
$$ language plpgsql;

-- Grant execute permission to authenticated users and anon (if needed for public views)
grant execute on function increment_review_view_count(uuid) to authenticated;
grant execute on function increment_review_view_count(uuid) to anon;
grant execute on function increment_review_view_count(uuid) to service_role;
