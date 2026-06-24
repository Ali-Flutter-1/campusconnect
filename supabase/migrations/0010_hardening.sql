-- ---------------------------------------------------------------------------
-- Security + performance hardening (run after 0009).
--
-- 1. Index complaints.created_at so the admin "Approvals" list (ordered by
--    created_at with no user_id filter) uses an index instead of a full seq
--    scan + sort of the whole table.
-- 2. Validate option_index inside vote_poll so a crafted RPC call can't write a
--    count at an out-of-range position and corrupt the poll's options jsonb.
-- 3. Server-derive chat sender_name from the profile (clients can otherwise
--    spoof any display name while keeping their own sender_id).
-- 4. Let admins delete chat messages (moderation); students still cannot.
-- ---------------------------------------------------------------------------

-- 1. Performance: admin approvals query ------------------------------------
create index if not exists idx_complaints_created_at
  on public.complaints (created_at desc);

-- 2. Security: bounds-check poll votes -------------------------------------
create or replace function public.vote_poll(poll_id uuid, option_index integer)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  current_count integer;
  option_count  integer;
begin
  if auth.uid() is null then
    return 'unauthenticated';
  end if;

  -- Reject indexes outside the poll's option list before any write.
  select jsonb_array_length(options) into option_count
    from public.polls where id = vote_poll.poll_id;
  if option_count is null then
    return 'not_found';
  end if;
  if vote_poll.option_index < 0 or vote_poll.option_index >= option_count then
    return 'invalid_option';
  end if;

  if exists (
    select 1 from public.user_poll_votes v
    where v.user_id = auth.uid() and v.poll_id = vote_poll.poll_id
  ) then
    return 'already_voted';
  end if;

  insert into public.user_poll_votes (user_id, poll_id, option_index)
  values (auth.uid(), vote_poll.poll_id, vote_poll.option_index);

  select coalesce((options -> option_index ->> 'count')::int, 0)
    into current_count
    from public.polls where id = vote_poll.poll_id;

  update public.polls
    set options = jsonb_set(
          options,
          array[option_index::text, 'count'],
          to_jsonb(current_count + 1)
        ),
        total_votes = total_votes + 1
    where id = vote_poll.poll_id;

  return 'ok';
end;
$$;

grant execute on function public.vote_poll(uuid, integer) to authenticated;

-- 3. Security: derive chat sender_name server-side -------------------------
create or replace function public.set_chat_sender_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.sender_name := coalesce(
    (select full_name from public.profiles where id = new.sender_id),
    'Student'
  );
  return new;
end;
$$;

drop trigger if exists trg_chat_sender_name on public.chat_messages;
create trigger trg_chat_sender_name
  before insert on public.chat_messages
  for each row execute function public.set_chat_sender_name();

-- 4. Security: admin moderation of chat ------------------------------------
drop policy if exists "admins delete chat" on public.chat_messages;
create policy "admins delete chat" on public.chat_messages
  for delete to authenticated using (public.is_admin());
