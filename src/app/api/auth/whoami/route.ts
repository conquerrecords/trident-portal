import { NextResponse } from "next/server";
import { createSupabaseServer } from "@/lib/supabase-server-ssr";

export async function GET() {
  const supabase = createSupabaseServer();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) return NextResponse.json({ authenticated: false });

  // Ensure profile exists; default role 'student'
  const { data: profile } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", user.id)
    .maybeSingle();

  if (!profile) {
    await supabase.from("profiles").insert({ id: user.id, role: "student", full_name: user.email });
    return NextResponse.json({ authenticated: true, user, role: "student" });
  }

  return NextResponse.json({ authenticated: true, user, role: profile.role, profile });
}
