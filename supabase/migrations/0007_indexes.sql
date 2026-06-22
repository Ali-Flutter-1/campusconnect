-- Connect — performance indexes. Run anytime (safe, idempotent).
--
-- Adds indexes on the columns each feed/query actually filters and sorts by, so
-- Postgres uses Index Scans instead of Seq Scans as the tables grow.

-- Feeds ordered newest-first.
create index if not exists idx_announcements_created_at
  on public.announcements (created_at desc);
create index if not exists idx_notices_created_at
  on public.notices (created_at desc);
create index if not exists idx_polls_created_at
  on public.polls (created_at desc);

-- Events: sorted by date, filtered by category.
create index if not exists idx_events_date on public.events (date);
create index if not exists idx_events_category on public.events (category);

-- Chat: the room feed query is `where room order by created_at`.
create index if not exists idx_chat_messages_room_created
  on public.chat_messages (room, created_at desc);

-- Complaints: `where user_id order by created_at`.
create index if not exists idx_complaints_user_created
  on public.complaints (user_id, created_at desc);

-- FK reverse-lookups not covered by a leading PK column.
create index if not exists idx_user_likes_announcement
  on public.user_likes (announcement_id);
create index if not exists idx_user_bookmarks_announcement
  on public.user_bookmarks (announcement_id);
create index if not exists idx_user_poll_votes_poll
  on public.user_poll_votes (poll_id);
