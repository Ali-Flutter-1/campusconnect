-- Connect — initial schema.
-- Run in the Supabase SQL editor (or `supabase db push`). Mirrors the entities
-- the Flutter app expects. Role-based access (admin/student) is enforced via the
-- `profiles.role` column and the RLS policies below.

-- ---------------------------------------------------------------------------
-- profiles  (1 row per auth user)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text,
  full_name   text,
  avatar_url  text,
  course      text,
  department  text,
  year        text,
  role        text not null default 'student' check (role in ('student', 'admin')),
  created_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are readable by authenticated users"
  on public.profiles for select to authenticated using (true);

create policy "users manage their own profile"
  on public.profiles for insert to authenticated with check (auth.uid() = id);

create policy "users update their own profile"
  on public.profiles for update to authenticated using (auth.uid() = id);

-- Helper: is the current user an admin? (defined after `profiles` exists, since
-- a SQL function body is validated against referenced tables at creation time).
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- Auto-create a student profile when a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data ->> 'full_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- announcements (+ likes / bookmarks)
-- ---------------------------------------------------------------------------
create table if not exists public.announcements (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  content    text not null,
  author     text not null default 'Admin',
  category   text not null default 'general',
  likes      integer not null default 0,
  bookmarks  integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.announcements enable row level security;

create policy "announcements are public to authenticated users"
  on public.announcements for select to authenticated using (true);

create policy "only admins write announcements"
  on public.announcements for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create table if not exists public.user_likes (
  user_id         uuid not null references auth.users (id) on delete cascade,
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  created_at      timestamptz not null default now(),
  primary key (user_id, announcement_id)
);

create table if not exists public.user_bookmarks (
  user_id         uuid not null references auth.users (id) on delete cascade,
  announcement_id uuid not null references public.announcements (id) on delete cascade,
  created_at      timestamptz not null default now(),
  primary key (user_id, announcement_id)
);

alter table public.user_likes enable row level security;
alter table public.user_bookmarks enable row level security;

create policy "users manage their own likes"
  on public.user_likes for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "users manage their own bookmarks"
  on public.user_bookmarks for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Count RPCs called from the app.
create or replace function public.increment_likes(announcement_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.announcements set likes = likes + 1 where id = announcement_id;
$$;

create or replace function public.decrement_likes(announcement_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.announcements set likes = greatest(0, likes - 1) where id = announcement_id;
$$;

create or replace function public.increment_bookmarks(announcement_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.announcements set bookmarks = bookmarks + 1 where id = announcement_id;
$$;

create or replace function public.decrement_bookmarks(announcement_id uuid)
returns void language sql security definer set search_path = public as $$
  update public.announcements set bookmarks = greatest(0, bookmarks - 1) where id = announcement_id;
$$;

-- ---------------------------------------------------------------------------
-- events / user_rsvps
-- ---------------------------------------------------------------------------
create table if not exists public.events (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text not null default '',
  date        date not null,
  time        text,
  location    text,
  category    text not null default 'general',
  rsvp_count  integer not null default 0,
  created_at  timestamptz not null default now()
);

create table if not exists public.user_rsvps (
  user_id    uuid not null references auth.users (id) on delete cascade,
  event_id   uuid not null references public.events (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, event_id)
);

alter table public.events enable row level security;
alter table public.user_rsvps enable row level security;

create policy "events are public to authenticated users"
  on public.events for select to authenticated using (true);
create policy "only admins write events"
  on public.events for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy "users manage their own rsvps"
  on public.user_rsvps for all to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- polls / notices / chat_messages / complaints / notifications
-- ---------------------------------------------------------------------------
create table if not exists public.polls (
  id          uuid primary key default gen_random_uuid(),
  question    text not null,
  options     jsonb not null default '[]'::jsonb,
  total_votes integer not null default 0,
  created_at  timestamptz not null default now(),
  expires_at  timestamptz
);

create table if not exists public.notices (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  content    text not null,
  priority   text not null default 'normal',
  department text,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id          uuid primary key default gen_random_uuid(),
  sender_id   uuid references auth.users (id) on delete set null,
  sender_name text not null default 'Anonymous',
  content     text not null,
  room        text not null default 'global',
  created_at  timestamptz not null default now()
);

create table if not exists public.complaints (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  title       text not null,
  description text not null,
  category    text not null default 'general',
  status      text not null default 'open',
  created_at  timestamptz not null default now()
);

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users (id) on delete cascade,
  title      text not null,
  body       text not null default '',
  type       text not null default 'general',
  read       boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.polls enable row level security;
alter table public.notices enable row level security;
alter table public.chat_messages enable row level security;
alter table public.complaints enable row level security;
alter table public.notifications enable row level security;

create policy "polls public read" on public.polls for select to authenticated using (true);
create policy "admins write polls" on public.polls for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "notices public read" on public.notices for select to authenticated using (true);
create policy "admins write notices" on public.notices for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy "chat readable by authenticated" on public.chat_messages
  for select to authenticated using (true);
create policy "users send their own chat messages" on public.chat_messages
  for insert to authenticated with check (auth.uid() = sender_id);

create policy "users read their own complaints" on public.complaints
  for select to authenticated using (auth.uid() = user_id or public.is_admin());
create policy "users file their own complaints" on public.complaints
  for insert to authenticated with check (auth.uid() = user_id);

create policy "users read their own notifications" on public.notifications
  for select to authenticated using (auth.uid() = user_id);
create policy "users update their own notifications" on public.notifications
  for update to authenticated using (auth.uid() = user_id);

-- Realtime for the global chat.
alter publication supabase_realtime add table public.chat_messages;
