-- Connect — poll voting. Run AFTER 0001_init.sql.
--
-- Polls are admin-write only, so students vote through a SECURITY DEFINER
-- function that (a) records one vote per user and (b) bumps the chosen option's
-- count + the poll's total inside the `options` jsonb.

create table if not exists public.user_poll_votes (
  user_id      uuid not null references auth.users (id) on delete cascade,
  poll_id      uuid not null references public.polls (id) on delete cascade,
  option_index integer not null,
  created_at   timestamptz not null default now(),
  primary key (user_id, poll_id)
);

alter table public.user_poll_votes enable row level security;

create policy "users read their own poll votes" on public.user_poll_votes
  for select to authenticated using (auth.uid() = user_id);

create or replace function public.vote_poll(poll_id uuid, option_index integer)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  current_count integer;
begin
  if auth.uid() is null then
    return 'unauthenticated';
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
