set -euo pipefail

echo ">>> [DIRS] Ensuring structure"
mkdir -p src/lib src/app/{login,unauthorized,admin,dashboard,mentor}

echo ">>> [WRITE] src/lib/supabase-server.ts"
cat > src/lib/supabase-server.ts <<'EOF'
import { createClient } from '@supabase/supabase-js';
const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;
export const supabaseServer = () =>
  createClient(SUPABASE_URL, SUPABASE_ANON_KEY, { auth: { persistSession: false } });
EOF

echo ">>> [WRITE] src/lib/auth.ts"
cat > src/lib/auth.ts <<'EOF'
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
EOF

echo ">>> [WRITE] middleware.ts"
cat > middleware.ts <<'EOF'
import type { NextRequest } from 'next/server';
import { NextResponse } from 'next/server';

function pathRoleAllowed(pathname: string, role: string | null) {
  const rules: Array<{ match: RegExp; allow: string[] }> = [
    { match: /^\/admin/,     allow: ['admin'] },
    { match: /^\/mentor/,    allow: ['mentor','admin'] },
    { match: /^\/dashboard/, allow: ['student','mentor','admin'] },
  ];
  for (const r of rules) if (r.match.test(pathname)) return !!role && r.allow.includes(role);
  return true;
}

export function middleware(req: NextRequest) {
  const { pathname, origin } = req.nextUrl;
  const role = req.cookies.get('tis-role')?.value ?? null;
  const isPublic = pathRoleAllowed(pathname, null);
  const allowed  = pathRoleAllowed(pathname, role);
  if (!isPublic && !allowed) {
    const dest = role ? '/unauthorized' : '/login';
    return NextResponse.redirect(new URL(dest, origin));
  }
  return NextResponse.next();
}

export const config = { matcher: ['/admin/:path*','/mentor/:path*','/dashboard/:path*'] };
EOF

echo ">>> [WRITE] src/app/unauthorized/page.tsx"
cat > src/app/unauthorized/page.tsx <<'EOF'
export default function UnauthorizedPage() {
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="max-w-md text-center">
        <h1 className="text-3xl font-bold mb-2">🚫 Access Denied</h1>
        <p className="text-neutral-600">You don’t have permission to view this page.</p>
      </div>
    </main>
  );
}
EOF

echo ">>> [WRITE] src/app/login/page.tsx"
cat > src/app/login/page.tsx <<'EOF'
"use client";
export default function LoginPage() {
  const setRole = (role: string) => {
    document.cookie = `tis-role=\${role}; path=/; max-age=86400; samesite=lax`;
    window.location.href = '/dashboard';
  };
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="max-w-md space-y-4 text-center">
        <h1 className="text-3xl font-bold">Login (Demo)</h1>
        <p className="text-neutral-600">Temporary shim. Real Supabase auth next.</p>
        <div className="flex items-center justify-center gap-3">
          <button onClick={() => setRole('student')} className="px-4 py-2 border rounded">Student</button>
          <button onClick={() => setRole('mentor')}  className="px-4 py-2 border rounded">Mentor</button>
          <button onClick={() => setRole('admin')}   className="px-4 py-2 border rounded">Admin</button>
        </div>
      </div>
    </main>
  );
}
EOF

echo ">>> [WRITE] src/app/dashboard/page.tsx"
cat > src/app/dashboard/page.tsx <<'EOF'
export default function Dashboard() {
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <h1 className="text-3xl font-bold">Student Dashboard 🧭</h1>
    </main>
  );
}
EOF

echo ">>> [WRITE] src/app/admin/page.tsx"
cat > src/app/admin/page.tsx <<'EOF'
export default function Admin() {
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <h1 className="text-3xl font-bold">Admin Ops Center 🛡️</h1>
    </main>
  );
}
EOF

echo ">>> [WRITE] src/app/mentor/page.tsx"
cat > src/app/mentor/page.tsx <<'EOF'
export default function Mentor() {
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <h1 className="text-3xl font-bold">Mentor Console 🎓</h1>
    </main>
  );
}
EOF

echo ">>> [DONE] Auth perimeter applied"
