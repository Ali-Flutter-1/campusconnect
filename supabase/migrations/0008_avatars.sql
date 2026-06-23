-- Connect — let users upload their own profile picture. Run after 0005_images.sql.
--
-- The `media` bucket is otherwise admin-write only (migration 0005). These add
-- permissive policies so any signed-in user can write objects under their own
-- `avatars/<uid>/…` path (public read already covers displaying them).

drop policy if exists "users upload own avatar" on storage.objects;
create policy "users upload own avatar"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'media'
    and name like ('avatars/' || auth.uid()::text || '/%')
  );

drop policy if exists "users update own avatar" on storage.objects;
create policy "users update own avatar"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'media'
    and name like ('avatars/' || auth.uid()::text || '/%')
  );

drop policy if exists "users delete own avatar" on storage.objects;
create policy "users delete own avatar"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'media'
    and name like ('avatars/' || auth.uid()::text || '/%')
  );
