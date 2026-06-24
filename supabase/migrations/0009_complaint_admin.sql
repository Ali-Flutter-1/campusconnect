-- ---------------------------------------------------------------------------
-- Admin approval workflow for complaints / requests.
--
-- Students file requests (status 'open'); admins triage them. The original
-- migration only granted INSERT + SELECT, so status changes were blocked for
-- everyone. This adds an admin-only UPDATE policy so admins can approve
-- ('in_progress'), resolve ('resolved') or reject ('rejected') a request.
-- ---------------------------------------------------------------------------

create policy "admins update complaints"
  on public.complaints for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());
