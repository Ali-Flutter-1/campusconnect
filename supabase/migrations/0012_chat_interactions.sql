-- ---------------------------------------------------------------------------
-- 0012 — chat interactions: replies, edits, soft deletes and emoji reactions.
--
-- 1. chat_messages gains reply_to_id / edited_at / deleted_at.
-- 2. Authors may update (edit / soft-delete) their own messages; the update is
--    constrained by a trigger so a client cannot rewrite authorship or history.
-- 3. chat_reactions: one row per (message, user, emoji), denormalized `room`
--    so the client can subscribe to a single room's reactions.
-- 4. Both tables replicate with REPLICA IDENTITY FULL so realtime UPDATE and
--    DELETE payloads carry the columns we filter and reconcile on.
-- ---------------------------------------------------------------------------

-- 1. Message columns ---------------------------------------------------------
alter table public.chat_messages
  add column if not exists reply_to_id uuid
    references public.chat_messages (id) on delete set null,
  add column if not exists edited_at  timestamptz,
  add column if not exists deleted_at timestamptz;

create index if not exists idx_chat_messages_reply_to
  on public.chat_messages (reply_to_id);

-- 2. Authors edit / soft-delete their own messages ---------------------------
drop policy if exists "users update their own chat messages" on public.chat_messages;
create policy "users update their own chat messages" on public.chat_messages
  for update to authenticated
  using (auth.uid() = sender_id)
  with check (auth.uid() = sender_id);

drop policy if exists "users delete their own chat messages" on public.chat_messages;
create policy "users delete their own chat messages" on public.chat_messages
  for delete to authenticated using (auth.uid() = sender_id);

-- Only content / edited_at / deleted_at may change, and a delete is final:
-- everything else is pinned to its stored value.
create or replace function public.guard_chat_message_update()
returns trigger
language plpgsql
as $$
begin
  if old.deleted_at is not null then
    raise exception 'message already deleted';
  end if;

  new.id          := old.id;
  new.sender_id   := old.sender_id;
  new.sender_name := old.sender_name;
  new.room        := old.room;
  new.reply_to_id := old.reply_to_id;
  new.created_at  := old.created_at;

  if new.deleted_at is not null then
    new.content   := '';
    new.edited_at := old.edited_at;
  elsif new.content is distinct from old.content then
    new.edited_at := now();
  else
    new.edited_at := old.edited_at;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_chat_message_update on public.chat_messages;
create trigger trg_chat_message_update
  before update on public.chat_messages
  for each row execute function public.guard_chat_message_update();

-- 3. Reactions ---------------------------------------------------------------
create table if not exists public.chat_reactions (
  message_id uuid not null references public.chat_messages (id) on delete cascade,
  user_id    uuid not null references auth.users (id) on delete cascade,
  emoji      text not null,
  room       text not null default 'global',
  created_at timestamptz not null default now(),
  primary key (message_id, user_id, emoji)
);

create index if not exists idx_chat_reactions_room
  on public.chat_reactions (room, message_id);

alter table public.chat_reactions enable row level security;

drop policy if exists "reactions readable by authenticated" on public.chat_reactions;
create policy "reactions readable by authenticated" on public.chat_reactions
  for select to authenticated using (true);

drop policy if exists "users add their own reactions" on public.chat_reactions;
create policy "users add their own reactions" on public.chat_reactions
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists "users remove their own reactions" on public.chat_reactions;
create policy "users remove their own reactions" on public.chat_reactions
  for delete to authenticated using (auth.uid() = user_id);

-- Keep `room` honest: derive it from the message rather than trusting the client.
create or replace function public.set_chat_reaction_room()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.room := (select room from public.chat_messages where id = new.message_id);
  return new;
end;
$$;

drop trigger if exists trg_chat_reaction_room on public.chat_reactions;
create trigger trg_chat_reaction_room
  before insert on public.chat_reactions
  for each row execute function public.set_chat_reaction_room();

-- 4. Realtime ----------------------------------------------------------------
-- UPDATE/DELETE payloads need the full old row (we filter on `room` and match
-- on `id`), which Postgres only ships under REPLICA IDENTITY FULL.
alter table public.chat_messages  replica identity full;
alter table public.chat_reactions replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.chat_reactions;
exception
  when duplicate_object then null;
end;
$$;
