-- Connect — image support for announcements & events. Run AFTER 0001_init.sql.
--
-- Adds an `image_url` column to both tables and a public-read `media` storage
-- bucket. Uploads are restricted to admins (reuses the is_admin() helper).

alter table public.announcements add column if not exists image_url text;
alter table public.events add column if not exists image_url text;

-- Create the public bucket (id = name = 'media').
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

-- Storage policies live on storage.objects, scoped to the 'media' bucket.
drop policy if exists "media public read" on storage.objects;
create policy "media public read"
  on storage.objects for select
  using (bucket_id = 'media');

drop policy if exists "media admin insert" on storage.objects;
create policy "media admin insert"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'media' and public.is_admin());

drop policy if exists "media admin update" on storage.objects;
create policy "media admin update"
  on storage.objects for update to authenticated
  using (bucket_id = 'media' and public.is_admin());

drop policy if exists "media admin delete" on storage.objects;
create policy "media admin delete"
  on storage.objects for delete to authenticated
  using (bucket_id = 'media' and public.is_admin());
