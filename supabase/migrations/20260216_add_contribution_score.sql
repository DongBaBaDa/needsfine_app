-- Add contribution_score column to profiles
alter table public.profiles
add column if not exists contribution_score float default 0.0;
