import { supabaseServer } from "@/lib/supabase-server";

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json }
  | Json[];

/**
 * Insert an audit log row.
 * @param event short event key (e.g., "login", "module_view")
 * @param details optional JSON payload
 */
export async function logAudit(event: string, details?: Json) {
  const supabase = supabaseServer();
  const payload: { event: string; details?: Json } = { event };
  if (typeof details !== "undefined") payload.details = details;

  const { error } = await supabase.from("audit_logs").insert(payload);
  return { ok: !error, error: error?.message ?? null };
}
