"use client";

import DashboardLayout from "@/components/dashboard/Layout";
import Card from "@/components/dashboard/Card";
import { useEffect, useState } from "react";

type ModuleRow = { id: string; title: string; description: string; level: number; status: string; progress: number };
type MissionRow = { id: string; title: string; description: string; due_date: string; status: string };

export default function Dashboard() {
  const [modules, setModules] = useState<ModuleRow[]>([]);
  const [missions, setMissions] = useState<MissionRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetch("/api/modules/list").then(r => r.json()),
      fetch("/api/missions/list").then(r => r.json()),
    ]).then(([mods, miss]) => {
      setModules(Array.isArray(mods) ? mods : []);
      setMissions(Array.isArray(miss) ? miss : []);
      setLoading(false);
    }).catch(() => setLoading(false));
  }, []);

  return (
    <DashboardLayout>
      <section className="max-w-5xl mx-auto space-y-6">
        <div className="text-center space-y-2">
          <h1 className="text-3xl font-bold">🧭 Student Dashboard</h1>
          <p className="text-gray-600">Your command center for modules, tuition, and missions.</p>
        </div>

        {loading ? (
          <div className="text-center text-gray-600">Loading...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card title="📚 Modules">
              {modules.length === 0 ? (
                <p>No modules yet.</p>
              ) : (
                <ul className="space-y-2">
                  {modules.map(m => (
                    <li key={m.id} className="flex items-center justify-between">
                      <div>
                        <div className="font-medium">{m.title}</div>
                        <div className="text-xs text-gray-500">{m.description}</div>
                      </div>
                      <span className="text-xs text-gray-600">{m.status} • {m.progress}%</span>
                    </li>
                  ))}
                </ul>
              )}
            </Card>

            <Card title="💰 Tuition" cta={
              <button
                className="px-4 py-2 bg-black text-white rounded"
                onClick={async () => {
                  try {
                    const r = await fetch("/api/checkout", {
                      method: "POST",
                      headers: { "Content-Type": "application/json" },
                      body: JSON.stringify({ role: "student" })
                    });
                    const j = await r.json();
                    if (j.url) location.href = j.url;
                  } catch (e) { console.error(e); }
                }}
              >
                Pay Tuition
              </button>
            }>
              <p>Manage tuition contributions and view payment history.</p>
            </Card>

            <Card title="🎯 Missions">
              {missions.length === 0 ? (
                <p>No missions assigned.</p>
              ) : (
                <ul className="space-y-2">
                  {missions.map(ms => (
                    <li key={ms.id} className="flex items-center justify-between">
                      <div>
                        <div className="font-medium">{ms.title}</div>
                        <div className="text-xs text-gray-500">{ms.description}</div>
                      </div>
                      <span className="text-xs text-gray-600">{ms.status}</span>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
          </div>
        )}
      </section>
    </DashboardLayout>
  );
}
