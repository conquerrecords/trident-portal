#!/usr/bin/env bash
# 1) Install dependency
npm i resend

# 2) Add env vars (append if file exists)
cat >> .env.local <<'EOF'

# --- Email (Resend) ---
RESEND_API_KEY="YOUR-RESEND-API-KEY"
EMAIL_FROM="Trident Institution <noreply@yourdomain.com>"
EOF

# 3) Email utility
mkdir -p src/lib
cat > src/lib/email.ts <<'EOF'
import { Resend } from 'resend';

const RESEND_API_KEY = process.env.RESEND_API_KEY!;
const EMAIL_FROM = process.env.EMAIL_FROM!;

const resend = new Resend(RESEND_API_KEY);

/**
 * Minimal HTML mailer. Extend with templates as needed.
 */
export async function sendEmail(to: string, subject: string, html: string) {
  if (!RESEND_API_KEY) throw new Error('RESEND_API_KEY not set');
  if (!EMAIL_FROM) throw new Error('EMAIL_FROM not set');
  const { data, error } = await resend.emails.send({
    from: EMAIL_FROM,
    to,
    subject,
    html,
  });
  if (error) throw error;
  return data;
}
EOF

# 4) Welcome email API route
mkdir -p src/app/api/email/welcome
cat > src/app/api/email/welcome/route.ts <<'EOF'
import { NextResponse } from 'next/server';
import { sendEmail } from '@/lib/email';

export async function POST(req: Request) {
  try {
    const { email, name = 'Student', role = 'student' } = await req.json();

    if (!email) {
      return NextResponse.json({ ok: false, error: 'email required' }, { status: 400 });
    }

    const html = `
      <div style="font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;line-height:1.5">
        <h2 style="margin:0 0 8px">Welcome to Trident Institution</h2>
        <p>Hi ${name},</p>
        <p>Your access has been initialized with role: <b>${role}</b>.</p>
        <hr style="border:none;border-top:1px solid #ddd;margin:16px 0" />
        <p>Links:</p>
        <ul>
          <li>Dashboard: <a href="${process.env.NEXT_PUBLIC_BASE_URL ?? 'http://localhost:3000'}/dashboard">/dashboard</a></li>
          <li>Mentor Console: <a href="${process.env.NEXT_PUBLIC_BASE_URL ?? 'http://localhost:3000'}/mentor">/mentor</a></li>
          <li>Admin Ops Center: <a href="${process.env.NEXT_PUBLIC_BASE_URL ?? 'http://localhost:3000'}/admin">/admin</a></li>
        </ul>
        <p style="margin-top:16px">— Chairman’s Office</p>
      </div>
    `;

    const data = await sendEmail(email, 'Welcome to Trident Institution', html);
    return NextResponse.json({ ok: true, id: data?.id ?? null });
  } catch (err: any) {
    return NextResponse.json({ ok: false, error: String(err?.message ?? err) }, { status: 500 });
  }
}
EOF

# 5) Patch login screen to capture email and trigger welcome email
cat > src/app/login/page.tsx <<'EOF'
"use client";
import { useState } from "react";

export default function LoginPage() {
  const [email, setEmail] = useState("");

  const go = async (role: "student"|"mentor"|"admin") => {
    // Set demo role cookie
    document.cookie = `tis-role=${role}; path=/; max-age=86400; samesite=lax`;
    // Fire welcome email if address provided
    if (email) {
      try {
        await fetch("/api/email/welcome", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email, role }),
        });
      } catch (_) { /* non-blocking */ }
    }
    // Route by role
    const dest = role === "admin" ? "/admin" : role === "mentor" ? "/mentor" : "/dashboard";
    window.location.href = dest;
  };

  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="max-w-md space-y-5 text-center">
        <h1 className="text-3xl font-bold">Login (Demo)</h1>
        <p className="text-neutral-600">
          Temporary shim — real Supabase auth next. Enter an email to receive a welcome message.
        </p>
        <input
          type="email"
          placeholder="you@example.com (optional)"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full max-w-sm px-3 py-2 border rounded"
        />
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

