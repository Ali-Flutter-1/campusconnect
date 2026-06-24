-- ---------------------------------------------------------------------------
-- Security hardening, round 2 (run after 0010).
--
-- 1. Stop exposing every user's email + academic PII to all authenticated
--    users. The only cross-user profile read in the app is the admin complaint
--    join (which runs as an admin), so reads can be scoped to "own row, or an
--    admin". Self-profile reads (auth, chat) and the admin join still work.
-- 2. Make the like/bookmark counters tamper-proof. The old RPCs blindly did
--    `likes = likes + 1`, so any authenticated user could call them in a loop
--    to inflate a counter without a matching `user_likes` row. Recomputing the
--    counter from the join table makes the call idempotent and unforgeable:
--    calling it repeatedly just re-derives the true count. Clients are
--    unchanged — they still insert/delete the join row, then call the RPC.
-- ---------------------------------------------------------------------------

-- 1. Restrict profile visibility ------------------------------------------
drop policy if exists "profiles are readable by authenticated users"
  on public.profiles;
create policy "profiles readable by owner or admin"
  on public.profiles for select to authenticated
  using (auth.uid() = id or public.is_admin());

-- 2. Tamper-proof counters -------------------------------------------------
create or replace function public.increment_likes(announcement_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.announcements set likes = (
    select count(*) from public.user_likes ul
    where ul.announcement_id = increment_likes.announcement_id
  ) where id = increment_likes.announcement_id;
$$;

create or replace function public.decrement_likes(announcement_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.announcements set likes = (
    select count(*) from public.user_likes ul
    where ul.announcement_id = decrement_likes.announcement_id
  ) where id = decrement_likes.announcement_id;
$$;

create or replace function public.increment_bookmarks(announcement_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.announcements set bookmarks = (
    select count(*) from public.user_bookmarks ub
    where ub.announcement_id = increment_bookmarks.announcement_id
  ) where id = increment_bookmarks.announcement_id;
$$;

create or replace function public.decrement_bookmarks(announcement_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.announcements set bookmarks = (
    select count(*) from public.user_bookmarks ub
    where ub.announcement_id = decrement_bookmarks.announcement_id
  ) where id = decrement_bookmarks.announcement_id;
$$;
