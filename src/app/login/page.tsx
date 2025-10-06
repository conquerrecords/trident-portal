"use client";
import { useState } from "react";
import { createSupabaseBrowser } from "@/lib/supabase-browser";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function sendLink() {
    setError(null);
    try {
      const supabase = createSupabaseBrowser();
      const redirectTo = `${window.location.origin}/auth/callback`;
      const { error } = await supabase.auth.signInWithOtp({
        email,
        options: { emailRedirectTo: redirectTo },
      });
      if (error) throw error;
      setSent(true);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      setError(message);
    }
  }

  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="max-w-md space-y-5 text-center">
        <h1 className="text-3xl font-bold">Sign in</h1>
        <p className="text-gray-600">We’ll email you a one-time sign-in link.</p>

        <input
          type="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.currentTarget.value)}
          className="w-full max-w-sm px-3 py-2 border rounded"
        />

        {!sent ? (
          <button onClick={sendLink} className="px-4 py-2 bg-black text-white rounded">Send magic link</button>
        ) : (
          <div className="text-green-700">✅ Link sent. Check your email.</div>
        )}

        {error && <div className="text-red-600 text-sm">{error}</div>}
      </div>
    </main>
  );
}
