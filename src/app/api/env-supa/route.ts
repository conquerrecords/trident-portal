import { NextResponse } from "next/server";

export async function GET() {
  const url  = process.env.NEXT_PUBLIC_SUPABASE_URL || "";
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || "";

  return NextResponse.json({
    has_url: !!url,
    url_host: (url && /^https?:\/\//i.test(url)) ? new URL(url).host : null,
    has_anon: !!anon,
    anon_prefix: anon ? anon.slice(0, 8) : null
  });
}

