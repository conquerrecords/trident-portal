import { NextResponse } from "next/server";
import { createSupabaseServer } from "@/lib/supabase-server-ssr";

export async function GET() {
  const supabase = createSupabaseServer();
  const { data: { user } } = await supabase.auth.getUser();
  const userId = user?.id ?? null;

  const { data: modules, error: e1 } = await supabase
    .from("modules")
    .select("*")
    .eq("is_published", true)
    .order("level", { ascending: true });
  if (e1) return NextResponse.json({ error: e1.message }, { status: 500 });

  let progressById = new Map<string, { progress:number; status:string }>();
  if (userId) {
    const { data: progress, error: e2 } = await supabase
      .from("student_modules")
      .select("module_id,progress,status")
      .eq("student_id", userId);
    if (!e2 && progress) {
      progressById = new Map(progress.map((p:any)=>[p.module_id,{progress:p.progress,status:p.status}]));
    }
  }
  const merged = (modules || []).map((m:any)=>({
    ...m,
    progress: progressById.get(m.id)?.progress ?? 0,
    status:   progressById.get(m.id)?.status   ?? (userId ? "not_started" : "locked"),
  }));

  return NextResponse.json(merged);
}
