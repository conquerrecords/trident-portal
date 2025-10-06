"use client";

export default function Card(props: { title: string; children?: React.ReactNode; cta?: React.ReactNode }) {
  return (
    <div className="p-4 bg-white border rounded shadow-sm hover:shadow-md transition-shadow">
      <h2 className="font-semibold mb-2">{props.title}</h2>
      <div className="text-sm text-gray-700">{props.children}</div>
      {props.cta && <div className="mt-3">{props.cta}</div>}
    </div>
  );
}
