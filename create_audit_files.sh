#!/usr/bin/env bash
set -euo pipefail

echo ">>> [1/3] Creating src/lib/audit.ts"
mkdir -p src/lib
cat > src/lib/audit.ts <<'EOF'
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
EOF

echo ">>> [2/3] Creating src/app/api/audit/seed/route.ts"
mkdir -p src/app/api/audit/seed
cat > src/app/api/audit/seed/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { logAudit } from "@/lib/audit";

export async function POST() {
  await logAudit("SEED_INIT", null, { env: "dev" });
  await logAudit("MODULE_OPEN", "demo-student", { module: "Foundations" });
  await logAudit("PAYMENT_TEST", "demo-student", { amount: 250, currency: "USD" });
  return NextResponse.json({ ok: true, seeded: 3 });
}
EOF

echo ">>> [3/3] Creating src/app/api/audit/login/route.ts"
mkdir -p src/app/api/audit/login
cat > src/app/api/audit/login/route.ts <<'EOF'
import { NextResponse } from "next/server";
import { logAudit } from "@/lib/audit";

export async function POST(req: Request) {
  const { role } = await req.json();
  await logAudit("LOGIN_SIMULATED", null, { role });
  return NextResponse.json({ ok: true });
}
EOF

echo "✅ All audit-related files created successfully."
echo "👉 Run your dev server and seed logs with:"
echo "   curl -X POST http://localhost:3000/api/audit/seed   # or replace 3000 with your active port"

