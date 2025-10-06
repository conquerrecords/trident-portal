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
