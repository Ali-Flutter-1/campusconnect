-- Connect — notice categories. Run AFTER 0001_init.sql.
--
-- Adds a `category` column to power the Notices filter pills (exams / holidays /
-- fees / events / general). Pinned notices reuse the existing `priority` column
-- (priority = 'high' renders in the "Pinned" section).

alter table public.notices
  add column if not exists category text not null default 'general';
