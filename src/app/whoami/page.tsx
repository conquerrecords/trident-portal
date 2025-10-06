"use client";
import { useEffect, useState } from "react";
export default function WhoAmI() {
  const [role, setRole] = useState<string | null>(null);
  useEffect(() => {
    const m = document.cookie.match(/(?:^|;\s*)tis-role=([^;]+)/);
    setRole(m ? decodeURIComponent(m[1]) : null);
  }, []);
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="text-center space-y-2">
        <h1 className="text-2xl font-bold">Identity Probe</h1>
        <p>tis-role cookie: <b>{role ?? "none"}</b></p>
        <div className="flex gap-2 justify-center">
          <button onClick={() => { document.cookie="tis-role=; Max-Age=0; path=/"; location.reload(); }} className="px-3 py-1 border rounded">Clear Role</button>
          <button onClick={() => { document.cookie="tis-role=admin; path=/; max-age=86400"; location.reload(); }} className="px-3 py-1 border rounded">Set Admin</button>
          <button onClick={() => { document.cookie="tis-role=mentor; path=/; max-age=86400"; location.reload(); }} className="px-3 py-1 border rounded">Set Mentor</button>
          <button onClick={() => { document.cookie="tis-role=student; path=/; max-age=86400"; location.reload(); }} className="px-3 py-1 border rounded">Set Student</button>
        </div>
      </div>
    </main>
  );
}
