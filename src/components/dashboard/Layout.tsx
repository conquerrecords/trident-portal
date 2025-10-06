"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [role, setRole] = useState<string | null>(null);

  useEffect(() => {
    const m = document.cookie.match(/(?:^|;\s*)tis-role=([^;]+)/);
    setRole(m ? decodeURIComponent(m[1]) : null);
  }, []);

  return (
    <div className="min-h-screen flex flex-col">
      <header className="px-6 py-4 flex justify-between items-center border-b">
        <div className="font-bold text-lg">🎓 Trident Portal</div>
        <nav className="flex gap-4">
          <Link href="/dashboard">Dashboard</Link>
          {role === "admin" && <Link href="/admin">Admin</Link>}
          {(role === "mentor" || role === "admin") && <Link href="/mentor">Mentor</Link>}
          <a href="/login" onClick={(e) => { e.preventDefault(); document.cookie = "tis-role=; Max-Age=0; path=/"; location.href="/login"; }}>Sign out</a>
        </nav>
      </header>
      <main className="flex-1 p-6">{children}</main>
      <footer className="text-center py-3 text-sm border-t">© Trident Institution Portal</footer>
    </div>
  );
}
