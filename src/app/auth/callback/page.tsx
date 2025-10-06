"use client";
import { useEffect, useState } from "react";
import { createSupabaseBrowser } from "@/lib/supabase-browser";

function parseHashParams(hash: string) {
  const q = new URLSearchParams(hash.startsWith("#") ? hash.slice(1) : hash);
  return {
    access_token: q.get("access_token"),
    refresh_token: q.get("refresh_token"),
  };
}

export default function AuthCallback() {
  const [status, setStatus] = useState<"working"|"ok"|"error">("working");

  useEffect(() => {
    (async () => {
      const supabase = createSupabaseBrowser();
      try {
        const url = new URL(window.location.href);

        // 1) Magic link tokens in hash (legacy / mobile deep link style)
        const { access_token, refresh_token } = parseHashParams(url.hash);
        if (access_token && refresh_token) {
          const { error } = await supabase.auth.setSession({ access_token, refresh_token });
          if (error) throw error;
          setStatus("ok");
        } else {
          // 2) Magic link / recovery / invite / email_change via token_hash in query
          const token_hash = url.searchParams.get("token_hash");
          const type = url.searchParams.get("type"); // magiclink | recovery | signup | invite | email_change
          if (token_hash && type) {
            const { error } = await supabase.auth.verifyOtp({
              type: type as any,
              token_hash,
            });
            if (error) throw error;
            setStatus("ok");
          } else {
            // 3) OAuth / PKCE flow (has code + verifier in storage)
            const code = url.searchParams.get("code");
            if (code) {
              const { error } = await supabase.auth.exchangeCodeForSession(url.toString());
              if (error) throw error;
              setStatus("ok");
            } else {
              throw new Error("No tokens, token_hash, or code in callback URL");
            }
          }
        }

        // Resolve role and redirect
        const r = await fetch("/api/auth/whoami");
        const j = await r.json();
        const role = j?.role ?? "student";
        const dest = role === "admin" ? "/admin" : role === "mentor" ? "/mentor" : "/dashboard";
        window.location.replace(dest);
      } catch (e: any) {
        console.error("[auth/callback] failure:", e?.message || e);
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
        {status === "error" && <p>Could not complete sign-in.</p>}
      </div>
    </main>
  );
}
