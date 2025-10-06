import { NextResponse } from "next/server";
import { logAudit } from "@/lib/audit";

export async function POST() {
  await logAudit("SEED_INIT", null, { env: "dev" });
  await logAudit("MODULE_OPEN", "demo-student", { module: "Foundations" });
  await logAudit("PAYMENT_TEST", "demo-student", { amount: 250, currency: "USD" });
  return NextResponse.json({ ok: true, seeded: 3 });
}
