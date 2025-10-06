#!/usr/bin/env bash
set -euo pipefail

echo ">>> [DIRS] Creating folders"
mkdir -p supabase src/app/api/modules/{list,seed} src/app/api/missions/{list,seed}

echo ">>> [SQL] Writing supabase/schema.sql"
cat > supabase/schema.sql <<'EOF'
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
EOF

echo ">>> [API] Writing modules list route"
cat > src/app/api/modules/list/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase-server";

export async function GET() {
  const supabase = supabaseServer();

  const { data: modules, error: e1 } = await supabase
    .from("modules")
    .select("*")
    .eq("is_published", true)
    .order("level", { ascending: true });

  if (e1) return NextResponse.json({ error: e1.message }, { status: 500 });

  const { data: progress, error: e2 } = await supabase
    .from("student_modules")
    .select("*")
    .eq("student_id", "demo-student");

  if (e2) return NextResponse.json({ error: e2.message }, { status: 500 });

  const byId = new Map(progress.map(p => [p.module_id, p]));
  const merged = modules.map(m => ({
    ...m,
    progress: byId.get(m.id)?.progress ?? 0,
    status: byId.get(m.id)?.status ?? "not_started",
  }));

  return NextResponse.json(merged);
}
EOF

echo ">>> [API] Writing modules seed route (idempotent)"
cat > src/app/api/modules/seed/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase-server";

export async function POST() {
  const supabase = supabaseServer();

  const { error: e1 } = await supabase.from("profiles").upsert([
    { id: "demo-student", role: "student", full_name: "Demo Student" },
    { id: "demo-mentor",  role: "mentor",  full_name: "Demo Mentor"  },
    { id: "demo-admin",   role: "admin",   full_name: "Demo Admin"   },
  ]);
  if (e1) return NextResponse.json({ error: e1.message }, { status: 500 });

  const { error: e2 } = await supabase.from("modules").upsert([
    { id: "lead-101", title: "Foundations of Leadership", description: "Core principles and daily discipline.", level: 1, is_published: true },
    { id: "comm-201", title: "Communication Under Pressure", description: "High-stakes speaking and clarity.", level: 2, is_published: true },
    { id: "ops-301",  title: "Operational Excellence", description: "Systems, cadence, and continuous improvement.", level: 3, is_published: true },
  ]);
  if (e2) return NextResponse.json({ error: e2.message }, { status: 500 });

  const { data: missions, error: e3 } = await supabase.from("missions").upsert([
    { title: "Chain of Command Drill", description: "Simulate reporting protocols across divisions.", due_date: new Date(Date.now()+7*864e5).toISOString().slice(0,10), owner_id: "demo-mentor" },
    { title: "Ops After Action Review", description: "AAR for last sprint operations.", due_date: new Date(Date.now()+14*864e5).toISOString().slice(0,10), owner_id: "demo-mentor" },
  ]).select();
  if (e3) return NextResponse.json({ error: e3.message }, { status: 500 });

  const { error: e4 } = await supabase.from("student_modules").upsert([
    { student_id: "demo-student", module_id: "lead-101", status: "in_progress", progress: 40 },
    { student_id: "demo-student", module_id: "comm-201", status: "locked",      progress: 0 },
  ]);
  if (e4) return NextResponse.json({ error: e4.message }, { status: 500 });

  if (missions?.length) {
    const rows = missions.map(m => ({ student_id: "demo-student", mission_id: m.id, status: "assigned" }));
    const { error: e5 } = await supabase.from("student_missions").upsert(rows);
    if (e5) return NextResponse.json({ error: e5.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
EOF

echo ">>> [API] Writing missions list route"
cat > src/app/api/missions/list/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase-server";

export async function GET() {
  const supabase = supabaseServer();

  const { data, error } = await supabase
    .from("missions")
    .select("id,title,description,due_date,student_missions(status,student_id)")
    .order("due_date", { ascending: true });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  // Focus the view on demo-student for now
  const shaped = (data || []).map(m => ({
    id: m.id,
    title: m.title,
    description: m.description,
    due_date: m.due_date,
    status: (m as any).student_missions?.find((s:any)=>s.student_id==='demo-student')?.status ?? 'assigned'
  }));

  return NextResponse.json(shaped);
}
EOF

echo ">>> [API] Writing missions seed route"
cat > src/app/api/missions/seed/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { supabaseServer } from "@/lib/supabase-server";

export async function POST() {
  const supabase = supabaseServer();
  const { error } = await supabase.from("missions").insert([
    { title: "Field Exercise Alpha", description: "Team leadership under time constraints.", due_date: new Date(Date.now()+10*864e5).toISOString().slice(0,10), owner_id: "demo-mentor" }
  ]);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
EOF

echo ">>> [PATCH] Updating dashboard to pull live data"
cat > src/app/dashboard/page.tsx <<'EOF'
"use client";

import DashboardLayout from "@/components/dashboard/Layout";
import Card from "@/components/dashboard/Card";
import { useEffect, useState } from "react";

type ModuleRow = { id: string; title: string; description: string; level: number; status: string; progress: number };
type MissionRow = { id: string; title: string; description: string; due_date: string; status: string };

export default function Dashboard() {
  const [modules, setModules] = useState<ModuleRow[]>([]);
  const [missions, setMissions] = useState<MissionRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetch("/api/modules/list").then(r => r.json()),
      fetch("/api/missions/list").then(r => r.json()),
    ]).then(([mods, miss]) => {
      setModules(Array.isArray(mods) ? mods : []);
      setMissions(Array.isArray(miss) ? miss : []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  return (
    <DashboardLayout>
      <section className="max-w-5xl mx-auto space-y-6">
        <div className="text-center space-y-2">
          <h1 className="text-3xl font-bold">🧭 Student Dashboard</h1>
          <p className="text-gray-600">Your command center for modules, tuition, and missions.</p>
        </div>

        {loading ? (
          <div className="text-center text-gray-600">Loading...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card title="📚 Modules">
              {modules.length === 0 ? (
                <p>No modules yet.</p>
              ) : (
                <ul className="space-y-2">
                  {modules.map(m => (
                    <li key={m.id} className="flex items-center justify-between">
                      <div>
                        <div className="font-medium">{m.title}</div>
                        <div className="text-xs text-gray-500">{m.description}</div>
                      </div>
                      <span className="text-xs text-gray-600">{m.status} • {m.progress}%</span>
                    </li>
                  ))}
                </ul>
              )}
            </Card>

            <Card title="💰 Tuition" cta={
              <button
                className="px-4 py-2 bg-black text-white rounded"
                onClick={async () => {
                  try {
                    const r = await fetch("/api/checkout", {
                      method: "POST",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify({ role: "student" })
                    });
                    const j = await r.json();
                    if (j.url) location.href = j.url;
                  } catch (e) { console.error(e); }
                }}
              >
                Pay Tuition
              </button>
            }>
              <p>Manage tuition contributions and view payment history.</p>
            </Card>

            <Card title="🎯 Missions">
              {missions.length === 0 ? (
                <p>No missions assigned.</p>
              ) : (
                <ul className="space-y-2">
                  {missions.map(ms => (
                    <li key={ms.id} className="flex items-center justify-between">
                      <div>
                        <div className="font-medium">{ms.title}</div>
                        <div className="text-xs text-gray-500">{ms.description}</div>
                      </div>
                      <span className="text-xs text-gray-600">{ms.status}</span>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
          </div>
        )}
      </section>
    </DashboardLayout>
  );
}
EOF

echo ">>> [DONE] Files created. Next: apply SQL in Supabase, then seed."
