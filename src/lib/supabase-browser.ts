import { createBrowserClient } from "@supabase/ssr";

const url  = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export function createSupabaseBrowser() {
  return createBrowserClient(url, anon);
}
