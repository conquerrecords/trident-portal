import { cookies } from "next/headers";
import { supabaseServer } from "@/lib/supabase-server";

export type AppRole = 'student' | 'mentor' | 'admin';
export function hasAccess(pathname: string, role: AppRole | null) {
  const rules: Array<{ match: RegExp; allow: AppRole[] }> = [
    { match: /^\/admin/,     allow: ['admin'] },
    { match: /^\/mentor/,    allow: ['mentor','admin'] },
    { match: /^\/dashboard/, allow: ['student','mentor','admin'] },
  ];
  for (const r of rules) if (r.match.test(pathname)) return !!role && r.allow.includes(role);
  return true;
}
