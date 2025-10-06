import { NextResponse } from 'next/server';

export async function GET() {
  const k = process.env.RESEND_API_KEY || '';
  const f = process.env.EMAIL_FROM || '';
  return NextResponse.json({
    has_RESEND_API_KEY: !!k,
    RESEND_API_KEY_prefix: k ? k.slice(0,3) : null,
    has_EMAIL_FROM: !!f,
    EMAIL_FROM_sample: f ? f.slice(0,30) + '…' : null,
  });
}
