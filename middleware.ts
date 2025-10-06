import { NextResponse, type NextRequest } from "next/server";
import { createServerClient, type CookieOptions } from "@supabase/ssr";

const url  = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

const RULES: Array<{ match: RegExp; allow: Array<"student"|"mentor"|"admin"> }> = [
  { match: /^\/admin(?:\/|$)/,      allow: ["admin"] },
  { match: /^\/mentor(?:\/|$)/,     allow: ["mentor","admin"] },
  { match: /^\/dashboard(?:\/|$)/,  allow: ["student","mentor","admin"] },
];

function allowedFor(pathname: string, role: string | null) {
  for (const r of RULES) if (r.match.test(pathname)) return role ? r.allow.includes(role as any) : false;
  return true;
}

export async function middleware(req: NextRequest) {
  const res = NextResponse.next();

  // Create Supabase client with explicit cookie adapter for middleware
  const supabase = createServerClient(url, anon, {
    cookies: {
      get(name: string) {
        return req.cookies.get(name)?.value;
      },
      set(name: string, value: string, options: CookieOptions) {
        res.cookies.set({ name, value, ...options });
      },
      remove(name: string, options: CookieOptions) {
        res.cookies.set({ name, value: "", ...options, maxAge: 0 });
      },
    },
  });

  const pathname = req.nextUrl.pathname;

  // Public route?
  if (allowedFor(pathname, null)) return res;

  // Require session
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    url.search = "";
    return NextResponse.redirect(url);
  }

  // Fetch role from profiles (default to student)
  let role: "student"|"mentor"|"admin" = "student";
  const { data: prof } = await supabase.from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (prof?.role) role = prof.role;

  if (!allowedFor(pathname, role)) {
    const url = req.nextUrl.clone();
    url.pathname = "/unauthorized";
    url.search = "";
    return NextResponse.redirect(url);
  }

  return res;
}

export const config = {
  matcher: ["/admin/:path*", "/mentor/:path*", "/dashboard/:path*"],
};
