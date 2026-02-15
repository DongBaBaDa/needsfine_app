-- Add referral columns to profiles
alter table public.profiles
add column if not exists my_referral_code text unique,
add column if not exists referred_by uuid references public.profiles(id),
add column if not exists referral_count int default 0;

-- Index for performance
create index if not exists idx_profiles_referral_code on public.profiles(my_referral_code);
