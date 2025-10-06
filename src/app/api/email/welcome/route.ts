import { NextResponse } from "next/server";
import { Resend } from "resend";

const RESEND_API_KEY = process.env.RESEND_API_KEY!;
const EMAIL_FROM = process.env.EMAIL_FROM!; // e.g. "Trident Portal <noreply@tridentportal.org>"

export async function POST() {
  try {
    if (!RESEND_API_KEY) throw new Error("Missing RESEND_API_KEY");
    if (!EMAIL_FROM) throw new Error("Missing EMAIL_FROM");

    const resend = new Resend(RESEND_API_KEY);

    const { error } = await resend.emails.send({
      from: EMAIL_FROM,
      to: "you@example.com", // TODO: replace or accept from request body
      subject: "Welcome to Trident Portal",
      html: `
        <div style="font-family:Arial, sans-serif; line-height:1.5;">
          <h1>Welcome aboard</h1>
          <p>Your account is ready. Log in with your magic link from the portal.</p>
          <p style="color:#6b7280;font-size:12px;">If you did not request this, you can ignore this email.</p>
        </div>
      `,
    });

    if (error) throw new Error(error.message);

    return NextResponse.json({ ok: true });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
