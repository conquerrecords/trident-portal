"use client";
import { useEffect, useRef, useState } from "react";
import { createSupabaseBrowser } from "@/lib/supabase-browser";

type OtpType = "magiclink" | "recovery" | "signup" | "invite" | "email_change";

type HashParams = {
  access_token: string | null;
  refresh_token: string | null;
  expires_in: string | null;
  token_type: string | null;
  type: string | null;
};

function parseHashParams(hash: string): HashParams {
  const q = new URLSearchParams(hash.startsWith("#") ? hash.slice(1) : hash);
  return {
    access_token: q.get("access_token"),
    refresh_token: q.get("refresh_token"),
    expires_in: q.get("expires_in"),
    token_type: q.get("token_type"),
    type: q.get("type"),
  };
}

export default function AuthCallback() {
  const [status, setStatus] = useState<"working" | "ok" | "error">("working");
  const once = useRef(false);

  useEffect(() => {
    if (once.current) return;
    once.current = true;

    (async () => {
      const supabase = createSupabaseBrowser();
      try {
        const url = new URL(window.location.href);
        const qp = Object.fromEntries(url.searchParams.entries()) as Record<string, string>;
        const hp = parseHashParams(url.hash);

        // 1) Magic link tokens in hash (legacy/mobile style)
        if (hp.access_token && hp.refresh_token) {
          const { error } = await supabase.auth.setSession({
            access_token: hp.access_token,
            refresh_token: hp.refresh_token,
          });
          if (error) throw error;
          setStatus("ok");
        }
        // 2) Magic link / recovery / invite / email_change via token_hash
        else if (qp.token_hash && qp.type) {
          const allowed: ReadonlyArray<OtpType> = ["magiclink", "recovery", "signup", "invite", "email_change"];
          if (allowed.includes(qp.type as OtpType)) {
            const { error } = await supabase.auth.verifyOtp({
              type: qp.type as OtpType,
              token_hash: qp.token_hash,
            });
            if (error) throw error;
            setStatus("ok");
          } else {
            throw new Error(`Unsupported OTP type: ${qp.type}`);
          }
        }
        // 3) OAuth/PKCE providers (code in query)
        else if (qp.code) {
          const { error } = await supabase.auth.exchangeCodeForSession(url.toString());
          if (error) throw error;
          setStatus("ok");
        } else {
          throw new Error("No tokens, token_hash, or code present in callback URL");
        }

        // Who am I? -> redirect by role
        const r = await fetch("/api/auth/whoami", { cache: "no-store" });
        const j: { role?: "student" | "mentor" | "admin" } = await r.json();
        const role = j?.role ?? "student";
        const dest = role === "admin" ? "/admin" : role === "mentor" ? "/mentor" : "/dashboard";
        window.location.replace(dest);
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        // eslint-disable-next-line no-console
        console.error("[auth/callback] failure:", message);
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
        {status === "error" && (
          <div className="space-y-2">
            <p>Could not complete sign-in.</p>
            <p className="text-xs text-gray-500">Open DevTools → Console for details.</p>
          </div>
        )}
      </div>
    </main>
  );
}
