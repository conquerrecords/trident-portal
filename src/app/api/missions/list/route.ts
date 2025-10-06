import { NextResponse } from "next/server";
import { createSupabaseServer } from "@/lib/supabase-server-ssr";

export async function GET() {
  const supabase = createSupabaseServer();
  const { data: { user } } = await supabase.auth.getUser();
  const userId = user?.id ?? null;

  const { data, error } = await supabase
    .from("missions")
    .select("id,title,description,due_date,student_missions(status,student_id)")
    .order("due_date", { ascending: true });
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const shaped = (data || []).map((m:any) => ({
    id: m.id,
    title: m.title,
    description: m.description,
    due_date: m.due_date,
    status: (m.student_missions || []).find((s:any)=> s.student_id === userId)?.status ?? (userId ? "assigned":"locked"),
  }));
  return NextResponse.json(shaped);
}
