-- === Trident Portal Core Schema ===

-- profiles: extended user data (ties to auth.users.id; for now plain text id)
create table if not exists profiles (
  id text primary key,           -- use auth.users.id when you wire real auth
  role text not null default 'student' check (role in ('student','mentor','admin')),
  full_name text,
  created_at timestamptz default now()
);

-- modules: curriculum units
create table if not exists modules (
  id text primary key,
  title text not null,
  description text,
  level int not null default 1,
  is_published boolean not null default true,
  created_at timestamptz default now()
);

-- student_modules: progress per student per module
create table if not exists student_modules (
  id uuid primary key default gen_random_uuid(),
  student_id text not null references profiles (id) on delete cascade,
  module_id text not null references modules (id) on delete cascade,
  status text not null default 'not_started' check (status in ('not_started','in_progress','completed','locked')),
  progress int not null default 0 check (progress between 0 and 100),
  updated_at timestamptz default now(),
  unique (student_id, module_id)
);

-- missions: assignments/projects
create table if not exists missions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  due_date date,
  owner_id text references profiles (id) on delete set null,
  created_at timestamptz default now()
);

-- student_missions: enrollment/progress in missions
create table if not exists student_missions (
  id uuid primary key default gen_random_uuid(),
  student_id text not null references profiles (id) on delete cascade,
  mission_id uuid not null references missions (id) on delete cascade,
  status text not null default 'assigned' check (status in ('assigned','in_progress','submitted','approved','rejected')),
  updated_at timestamptz default now(),
  unique (student_id, mission_id)
);

-- (audit_logs table was created earlier; keep as-is)

-- ---------- DEV RLS (permissive) ----------
-- Enable RLS and allow anon reads/writes FOR DEV ONLY.
-- Replace with strict policies when real auth is wired.
alter table profiles         enable row level security;
alter table modules          enable row level security;
alter table student_modules  enable row level security;
alter table missions         enable row level security;
alter table student_missions enable row level security;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename='profiles' and policyname='dev all profiles') then
    create policy "dev all profiles" on profiles for all to anon using (true) with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename='modules' and policyname='dev all modules') then
    create policy "dev all modules" on modules for all to anon using (true) with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename='student_modules' and policyname='dev all student_modules') then
    create policy "dev all student_modules" on student_modules for all to anon using (true) with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename='missions' and policyname='dev all missions') then
    create policy "dev all missions" on missions for all to anon using (true) with check (true);
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename='student_missions' and policyname='dev all student_missions') then
    create policy "dev all student_missions" on student_missions for all to anon using (true) with check (true);
  end if;
end $$;

-- ---------- DEV SEED ----------
insert into profiles (id, role, full_name)
values
  ('demo-student', 'student', 'Demo Student'),
  ('demo-mentor',  'mentor',  'Demo Mentor'),
  ('demo-admin',   'admin',   'Demo Admin')
on conflict (id) do nothing;

insert into modules (id, title, description, level, is_published) values
  ('lead-101', 'Foundations of Leadership', 'Core principles and daily discipline.', 1, true),
  ('comm-201', 'Communication Under Pressure', 'High-stakes speaking and clarity.', 2, true),
  ('ops-301',  'Operational Excellence', 'Systems, cadence, and continuous improvement.', 3, true)
on conflict (id) do nothing;

insert into student_modules (student_id, module_id, status, progress) values
  ('demo-student', 'lead-101', 'in_progress', 40),
  ('demo-student', 'comm-201', 'locked', 0)
on conflict do nothing;

insert into missions (title, description, due_date, owner_id) values
  ('Chain of Command Drill', 'Simulate reporting protocols across divisions.', now() + interval '7 day', 'demo-mentor'),
  ('Ops After Action Review', 'AAR for last sprint operations.', now() + interval '14 day', 'demo-mentor')
on conflict do nothing;

insert into student_missions (student_id, mission_id, status)
select 'demo-student', id, 'assigned' from missions
on conflict do nothing;
