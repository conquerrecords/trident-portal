"use client";

import { useEffect, useState } from "react";

export default function LogsPage() {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/admin/logs")
      .then((res) => res.json())
      .then((data) => {
        setLogs(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="p-6 text-center">Loading logs…</div>;
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">📝 Audit Log</h1>
      {logs.length === 0 ? (
        <p>No logs found.</p>
      ) : (
        <table className="w-full border-collapse">
          <thead>
            <tr className="border-b">
              <th className="text-left p-2">Action</th>
              <th className="text-left p-2">User</th>
              <th className="text-left p-2">Details</th>
              <th className="text-left p-2">Time</th>
            </tr>
          </thead>
          <tbody>
            {logs.map((log) => (
              <tr key={log.id} className="border-b">
                <td className="p-2">{log.action}</td>
                <td className="p-2">{log.user_id || "—"}</td>
                <td className="p-2">{JSON.stringify(log.details)}</td>
                <td className="p-2">
                  {new Date(log.created_at).toLocaleString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

