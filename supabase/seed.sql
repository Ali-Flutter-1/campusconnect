-- Demo data for Connect. Run after 0001_init.sql.

insert into public.announcements (title, content, author, category, likes, bookmarks)
values
  ('Welcome to Connect', 'Your new campus hub for announcements, events and chat is live!', 'Admin Office', 'general', 12, 4),
  ('Midterm schedule released', 'Check the portal for your midterm timetable. Good luck!', 'Examinations', 'academic', 31, 18),
  ('Library hours extended', 'The main library is now open until midnight during exam week.', 'Library', 'general', 8, 9);

insert into public.events (title, description, date, time, location, category, rsvp_count)
values
  ('Tech Talk: AI in 2026', 'Industry speakers on the latest in AI.', current_date + 7, '4:00 PM', 'Auditorium A', 'academic', 42),
  ('Spring Music Night', 'Live performances by student bands.', current_date + 10, '7:30 PM', 'Quad', 'social', 88),
  ('Inter-Dept Football', 'Cheer your department to victory.', current_date + 3, '5:00 PM', 'Main Ground', 'sports', 25);

insert into public.polls (question, options, total_votes)
values
  ('Which event should we host next?', '[{"text":"Hackathon","count":18},{"text":"Career Fair","count":24},{"text":"Cultural Fest","count":31}]'::jsonb, 73);

-- Promote a user to admin (replace the email):
--   update public.profiles set role = 'admin'
--   where id = (select id from auth.users where email = 'you@campus.edu');
