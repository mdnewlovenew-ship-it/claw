import { useState } from "react";
import { createMetricEvent } from "../core/eventFactory";
import { putEvent } from "../core/db";

export default function MetricCapture({ onSaved }: { onSaved: () => void }) {
  const [name, setName] = useState("glucose");
  const [value, setValue] = useState("");
  const [unit, setUnit] = useState("mg/dL");

  async function save() {
    const n = Number(value);
    if (!name.trim() || !Number.isFinite(n)) return;
    await putEvent(createMetricEvent(name.trim(), n, unit.trim() || undefined));
    setValue("");
    onSaved();
  }

  return (
    <section className="card">
      <h2>מדד בריאות</h2>
      <input value={name} onChange={(e) => setName(e.target.value)} placeholder="glucose / sleep / steps..." />
      <input value={value} onChange={(e) => setValue(e.target.value)} inputMode="decimal" placeholder="ערך" />
      <input value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="יחידה" />
      <button onClick={save}>שמור מדד</button>
    </section>
  );
}
