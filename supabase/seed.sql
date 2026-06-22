-- Demo data for Connect — ~25 records per content type (good for testing
-- pagination, which loads 20 at a time). Run after the migrations.
--
-- ⚠️ This first clears the content tables so re-running gives a clean ~25 each.
-- It does NOT touch profiles / auth users. Comment the TRUNCATE out if you want
-- to keep existing content and just add more.
truncate table
  public.announcements,
  public.events,
  public.notices,
  public.polls,
  public.chat_messages
restart identity cascade;

-- ---------------------------------------------------------------------------
-- Announcements (26)
-- ---------------------------------------------------------------------------
insert into public.announcements (title, content, author, category, likes, bookmarks, created_at)
select
  (array['Exam Update','Library Notice','Holiday Announcement','Workshop','Result Declared','Fee Reminder','Scholarship','Campus Drive'])[1 + (g % 8)]
    || ' #' || g,
  'Detailed information for announcement number ' || g
    || '. Please read carefully and reach out to the office for any questions.',
  (array['Admin Office','Examinations','Library','Student Affairs','IT Cell'])[1 + (g % 5)],
  (array['general','academic','urgent','event'])[1 + (g % 4)],
  (random() * 60)::int,
  (random() * 25)::int,
  now() - ((g * 3) || ' hours')::interval
from generate_series(1, 26) as g;

-- ---------------------------------------------------------------------------
-- Events (26)
-- ---------------------------------------------------------------------------
insert into public.events (title, description, date, time, location, category, rsvp_count)
select
  (array['Tech Talk','Music Night','Football Match','Hackathon','Career Fair','Art Expo','Coding Seminar','Sports Day'])[1 + (g % 8)]
    || ' ' || g,
  'Join us for this event (#' || g
    || '). A great chance to learn, network and have fun with the campus community.',
  current_date + ((g % 30))::int,
  (array['9:00 AM','11:30 AM','2:00 PM','4:30 PM','7:00 PM'])[1 + (g % 5)],
  (array['Auditorium A','Main Ground','The Quad','Lab 3','Seminar Hall'])[1 + (g % 5)],
  (array['academic','social','sports'])[1 + (g % 3)],
  (random() * 120)::int
from generate_series(1, 26) as g;

-- ---------------------------------------------------------------------------
-- Notices (26) — every 5th is high-priority (pinned)
-- ---------------------------------------------------------------------------
insert into public.notices (title, content, priority, department, category)
select
  (array['Exam Schedule','Holiday Notice','Fee Deadline','Event Registration','Maintenance Work'])[1 + (g % 5)]
    || ' #' || g,
  'Official notice number ' || g
    || '. Effective immediately until further communication from the department.',
  case when g % 5 = 0 then 'high' else 'normal' end,
  (array['Office of Registrar','Administration','Accounts','Innovation Cell','Hostel Office'])[1 + (g % 5)],
  (array['general','exams','holidays','fees','events'])[1 + (g % 5)]
from generate_series(1, 26) as g;

-- ---------------------------------------------------------------------------
-- Polls (24) — counts and total kept consistent for correct percentages
-- ---------------------------------------------------------------------------
with c as (
  select g,
         (5 + (g * 3) % 25) as a,
         (3 + (g * 2) % 18) as b,
         (1 + g % 12)       as d
  from generate_series(1, 24) as g
)
insert into public.polls (question, options, total_votes)
select
  'Poll #' || g || ': '
    || (array['Best fest theme?','Preferred class time?','Favorite cafeteria meal?','Next workshop topic?'])[1 + (g % 4)],
  jsonb_build_array(
    jsonb_build_object('text', 'Option A', 'count', a),
    jsonb_build_object('text', 'Option B', 'count', b),
    jsonb_build_object('text', 'Option C', 'count', d)
  ),
  a + b + d
from c;

-- ---------------------------------------------------------------------------
-- Chat messages (30) in the global room. sender_id is null (seeded), so they
-- render as "other" bubbles; real users' messages show as their own.
-- ---------------------------------------------------------------------------
insert into public.chat_messages (sender_name, content, room, created_at)
select
  (array['Sara','David','Ali','Maya','Omar','Hina','Zoya','Bilal'])[1 + (g % 8)],
  (array[
    'Hey everyone!',
    'Did you see the new notice?',
    'Anyone going to the event tonight?',
    'Good luck on the exams 🙌',
    'Library hours got extended btw',
    'See you all there!',
    'Can someone share the notes?',
    'That workshop was great'
  ])[1 + (g % 8)] || ' (' || g || ')',
  'global',
  now() - ((30 - g) || ' minutes')::interval
from generate_series(1, 30) as g;

-- Promote a user to admin (replace the email):
--   update public.profiles set role = 'admin'
--   where id = (select id from auth.users where email = 'you@campus.edu');
