set -euo pipefail

echo ">>> [PATCH] src/app/login/page.tsx (role-based redirect)"
cat > src/app/login/page.tsx <<'EOF'
"use client";
export default function LoginPage() {
  const go = (role: "student"|"mentor"|"admin") => {
    document.cookie = `tis-role=${role}; path=/; max-age=86400; samesite=lax`;
    const dest = role === "admin" ? "/admin" : role === "mentor" ? "/mentor" : "/dashboard";
    window.location.href = dest;
  };
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="max-w-md space-y-4 text-center">
        <h1 className="text-3xl font-bold">Login (Demo)</h1>
        <p className="text-neutral-600">Pick a role; you’ll be routed to the right area.</p>
        <div className="flex items-center justify-center gap-3">
          <button onClick={() => go('student')} className="px-4 py-2 border rounded">Student</button>
          <button onClick={() => go('mentor')}  className="px-4 py-2 border rounded">Mentor</button>
          <button onClick={() => go('admin')}   className="px-4 py-2 border rounded">Admin</button>
        </div>
      </div>
    </main>
  );
}
EOF

echo ">>> [WRITE] src/app/whoami/page.tsx (cookie check)"
mkdir -p src/app/whoami
cat > src/app/whoami/page.tsx <<'EOF'
"use client";
import { useEffect, useState } from "react";
export default function WhoAmI() {
  const [role, setRole] = useState<string | null>(null);
  useEffect(() => {
    const m = document.cookie.match(/(?:^|;\s*)tis-role=([^;]+)/);
    setRole(m ? decodeURIComponent(m[1]) : null);
  }, []);
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="text-center space-y-2">
        <h1 className="text-2xl font-bold">Identity Probe</h1>
        <p>tis-role cookie: <b>{role ?? "none"}</b></p>
        <div className="flex gap-2 justify-center">
          <button onClick={() => { document.cookie="tis-role=; Max-Age=0; path=/"; location.reload(); }} className="px-3 py-1 border rounded">Clear Role</button>
          <button onClick={() => { document.cookie="tis-role=admin; path=/; max-age=86400"; location.reload(); }} className="px-3 py-1 border rounded">Set Admin</button>
          <button onClick={() => { document.cookie="tis-role=mentor; path=/; max-age=86400"; location.reload(); }} className="px-3 py-1 border rounded">Set Mentor</button>
          <button onClick={() => { document.cookie="tis-role=student; path=/; max-age=86400"; location.reload(); }} className="px-3 py-1 border rounded">Set Student</button>
        </div>
      </div>
    </main>
  );
}
EOF

echo ">>> [DONE] Patch applied"
