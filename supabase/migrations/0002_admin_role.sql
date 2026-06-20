-- Connect — admin role claiming via a secret phrase.
-- Run AFTER 0001_init.sql.
--
-- Security model: a user must NEVER be able to set their own `role` directly
-- (the UI gate is not enough — anyone could call the REST API). So we:
--   1. Revoke the ability for normal users to write the `role` column.
--   2. Provide a SECURITY DEFINER function that promotes the caller ONLY when
--      they present the correct secret phrase.

-- 1. Lock down the role column. The signup trigger / table default still set
--    'student'; only the function below (which runs as the table owner) can
--    change it afterwards.
revoke insert (role), update (role) on public.profiles from authenticated, anon;

-- 2. Redeem an admin code. Returns 'admin' on success, 'invalid' otherwise.
--    >>> Change ADMIN_SECRET to your own phrase before going live. <<<
create or replace function public.redeem_admin_code(code text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  admin_secret constant text := 'hello';
begin
  if auth.uid() is null then
    return 'unauthenticated';
  end if;

  if code is distinct from admin_secret then
    return 'invalid';
  end if;

  update public.profiles set role = 'admin' where id = auth.uid();
  return 'admin';
end;
$$;

-- Allow signed-in users to call it (it self-guards via the secret).
grant execute on function public.redeem_admin_code(text) to authenticated;
