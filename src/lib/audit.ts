import { supabaseServer } from "@/lib/supabase-server";

export async function logAudit(action: string, userId: string | null = null, details: any = {}) {
  const supabase = supabaseServer();
  const { error } = await supabase.from("audit_logs").insert([
    { user_id: userId, action, details }
  ]);
  if (error) {
    console.error("[AUDIT ERROR]", error);
    throw error;
  }
}
