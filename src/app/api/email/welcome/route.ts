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
