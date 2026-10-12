-- ---------------------------------------------------------------------------
-- 0013 — four-word admin phrase, and campus-only email addresses.
--
-- 1. The admin code becomes a four-word phrase, and only its SHA-256 hash is
--    stored. 0002 kept the plaintext secret ('hello') in this repository, so
--    anyone who could read the code could make themselves an admin.
--    Matching is forgiving about case and spacing: four words are easy to
--    mistype, and a capital letter should not cost someone admin access.
-- 2. verify_admin_code() lets the sign-up form check the phrase *before* the
--    account is created. Previously a wrong code silently produced a student
--    account for someone who had chosen "Admin".
-- 3. Sign-ups must use an @root.edu (or *.root.edu) address. Enforced on
--    auth.users itself, because the form's check can be bypassed by calling
--    the auth API directly.
--
-- To rotate the phrase, replace the hash below with
--   encode(extensions.digest('<four words, lower case, single spaces>', 'sha256'), 'hex')
-- and re-run this file.
-- ---------------------------------------------------------------------------

create extension if not exists pgcrypto with schema extensions;

-- 1. Phrase matching ---------------------------------------------------------
create or replace function public._admin_phrase_matches(code text)
returns boolean
language sql
immutable
set search_path = public, extensions
as $$
  select encode(
           extensions.digest(
             regexp_replace(lower(trim(coalesce(code, ''))), '\s+', ' ', 'g'),
             'sha256'
           ),
           'hex'
         )
       = '7e546e7fe38b78ecb4552a0e0a74163b6d78cbd1ffb159d0871145276c168077';
$$;

-- Internal helper: not callable from the API.
revoke all on function public._admin_phrase_matches(text) from public, anon, authenticated;

-- Same contract as 0002 ('admin' | 'invalid' | 'unauthenticated'), new check.
create or replace function public.redeem_admin_code(code text)
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    return 'unauthenticated';
  end if;

  if not public._admin_phrase_matches(code) then
    return 'invalid';
  end if;

  update public.profiles set role = 'admin' where id = auth.uid();
  return 'admin';
end;
$$;

grant execute on function public.redeem_admin_code(text) to authenticated;

-- 2. Pre-sign-up check -------------------------------------------------------
-- Callable signed out, since it runs before the account exists. It reveals only
-- whether a guess is right; the phrase carries ~43 bits of randomness, which
-- puts guessing it over the network out of reach.
create or replace function public.verify_admin_code(code text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public._admin_phrase_matches(code);
$$;

grant execute on function public.verify_admin_code(text) to anon, authenticated;

-- 3. Campus email domain -----------------------------------------------------
create or replace function public.enforce_campus_email()
returns trigger
language plpgsql
as $$
begin
  -- Accepts name@root.edu and name@<anything>.root.edu.
  if new.email is null
     or lower(new.email) !~ '^[^@\s]+@([a-z0-9-]+\.)*root\.edu$' then
    raise exception 'Use your campus email address ending in root.edu'
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_campus_email on auth.users;
create trigger enforce_campus_email
  before insert or update of email on auth.users
  for each row execute function public.enforce_campus_email();
