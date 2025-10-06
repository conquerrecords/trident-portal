export default function UnauthorizedPage() {
  return (
    <main className="min-h-dvh grid place-items-center p-8">
      <div className="max-w-md text-center">
        <h1 className="text-3xl font-bold mb-2">🚫 Access Denied</h1>
        <p className="text-neutral-600">You don’t have permission to view this page.</p>
      </div>
    </main>
  );
}
