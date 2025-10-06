#!/usr/bin/env bash
set -euo pipefail

echo ">>> [PKG] Installing SSR helpers"
npm i @supabase/ssr >/dev/null 2>&1 || true

echo ">>> [ENV] Ensure these are in .env.local (edit manually if needed)"
echo 'NEXT_PUBLIC_SITE_URL="http://localhost:3000"  # change in prod' 
echo '# SUPABASE_SERVICE_ROLE_KEY="..."              # optional for admin jobs (never expose to client)'

echo ">>> [LIB] supabase-ssr client (server + browser)"
mkdir -p src/lib
cat > src/lib/supabase-ssr.ts <<'EOF'
import { createBrowserClient } from "@supabase/ssr";
import { createServerClient, type CookieOptions } from "@supabase/ssr";
import { cookies } from "next/headers";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export function createSupabaseBrowser() {
  return createBrowserClient(url, anon);
}

export function createSupabaseServer() {
  const cookieStore = cookies();
  return createServerClient(url, anon, {
    cookies: {
      get(name: string) {
        return cookieStore.get(name)?.value;
      },
      set(name: string, value: string, options: CookieOptions) {
        // Next.js App Router: mutate response cookies via headers (implicit)
        cookieStore.set({ name, value, ...options });
      },
      remove(name: string, options: CookieOptions) {
        cookieStore.set({ name, value: "", ...options, maxAge: 0 });
      },
    },
  });
}
EOF

echo ">>> [PAGES] Auth callback page – exchanges code for session"
mkdir -p src/app/auth/callback
cat > src/app/auth/callback/page.tsx <<'EOF'
"use client";
import { useEffect, useState } from "react";
import { createSupabaseBrowser } from "@/lib/supabase-ssr";

export default function AuthCallback() {
  const [status, setStatus] = useState<"working"|"ok"|"error">("working");

  useEffect(() => {
    (async () => {
      try {
        const supabase = createSupabaseBrowser();
        const { error } = await supabase.auth.exchangeCodeForSession(window.location.href);
        if (error) throw error;
        setStatus("ok");
        // Route by role via whoami
        const r = await fetch("/api/auth/whoami");
        const j = await r.json();
        const role = j.role ?? "student";
        const dest = role === "admin" ? "/admin" : role === "mentor" ? "/mentor" : "/dashboard";
        window.location.replace(dest);
      } catch {
        setStatus("error");
      }
    })();
  }, []);

  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="text-center space-y-2">
        <h1 className="text-2xl font-bold">Signing you in…</h1>
        {status === "working" && <p>Please wait.</p>}
        {status === "ok" && <p>Success. Redirecting…</p>}
        {status === "error" && <p>Could not complete sign-in.</p>}
      </div>
    </main>
  );
}
EOF

echo ">>> [API] whoami – returns authenticated user & role (creates profile if missing)"
mkdir -p src/app/api/auth/whoami
cat > src/app/api/auth/whoami/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { createSupabaseServer } from "@/lib/supabase-ssr";

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
EOF

echo ">>> [LOGIN] Replace login page with Supabase magic link"
mkdir -p src/app/login
cat > src/app/login/page.tsx <<'EOF'
"use client";
import { useState } from "react";
import { createSupabaseBrowser } from "@/lib/supabase-ssr";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string|null>(null);

  async function sendLink() {
    setError(null);
    try {
      const supabase = createSupabaseBrowser();
      const redirectTo = `${process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000"}/auth/callback`;
      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: { emailRedirectTo: redirectTo }
      });
      if (error) throw error;
      setSent(true);
    } catch (e:any) {
      setError(e.message || "Failed to send link");
    }
  }

  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="max-w-md space-y-5 text-center">
        <h1 className="text-3xl font-bold">Sign in</h1>
        <p className="text-gray-600">We’ll email you a one-time sign-in link.</p>

        <input
          type="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full max-w-sm px-3 py-2 border rounded"
        />

        {!sent ? (
          <button onClick={sendLink} className="px-4 py-2 bg-black text-white rounded">Send magic link</button>
        ) : (
          <div className="text-green-700">✅ Link sent. Check your email.</div>
        )}

        {error && <div className="text-red-600 text-sm">{error}</div>}

        <div className="text-xs text-gray-500">
          Tip: in Supabase → Auth → URL configuration, set Site URL to your app URL.
        </div>
      </div>
    </main>
  );
}
EOF

echo ">>> [MIDDLEWARE] Use real session + profile role for RBAC"
cat > middleware.ts <<'EOF'
import { NextResponse, type NextRequest } from "next/server";
import { createSupabaseServer } from "@/lib/supabase-ssr";

const RULES: Array<{ match: RegExp; allow: Array<"student"|"mentor"|"admin"> }> = [
  { match: /^\/admin(?:\/|$)/,      allow: ["admin"] },
  { match: /^\/mentor(?:\/|$)/,     allow: ["mentor","admin"] },
  { match: /^\/dashboard(?:\/|$)/,  allow: ["student","mentor","admin"] },
];

function allowedFor(pathname: string, role: string | null) {
  for (const r of RULES) {
    if (r.match.test(pathname)) {
      return role ? r.allow.includes(role as any) : false;
    }
  }
  return true; // unlisted paths public
}

export async function middleware(req: NextRequest) {
  const pathname = req.nextUrl.pathname;
  const supabase = createSupabaseServer();
  const { data: { user } } = await supabase.auth.getUser();

  // Public?
  const isPublic = allowedFor(pathname, null);
  if (isPublic) return NextResponse.next();

  // Require auth for protected paths
  if (!user) {
    const url = req.nextUrl.clone();
    url.pathname = "/login";
    url.search = "";
    return NextResponse.redirect(url);
  }

  // Fetch role from profiles; default to 'student' if missing
  let role: string | null = "student";
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).maybeSingle();
  if (profile?.role) role = profile.role;

  // Enforce RBAC
  if (!allowedFor(pathname, role)) {
    const url = req.nextUrl.clone();
    url.pathname = "/unauthorized";
    url.search = "";
    return NextResponse.redirect(url);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/mentor/:path*", "/dashboard/:path*"],
};
EOF

echo ">>> [APIs] Bind modules & missions to auth user"
cat > src/app/api/modules/list/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { createSupabaseServer } from "@/lib/supabase-ssr";

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
EOF

cat > src/app/api/missions/list/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { createSupabaseServer } from "@/lib/supabase-ssr";

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
EOF

echo ">>> [DONE] Auth kit installed. Next: SQL, env, and test."
