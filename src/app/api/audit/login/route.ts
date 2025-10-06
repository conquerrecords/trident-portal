import { NextResponse } from "next/server";
import { logAudit } from "@/lib/audit";

export async function POST(req: Request) {
  const { role } = await req.json();
  await logAudit("LOGIN_SIMULATED", null, { role });
  return NextResponse.json({ ok: true });
}
