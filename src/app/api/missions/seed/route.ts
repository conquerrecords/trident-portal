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
