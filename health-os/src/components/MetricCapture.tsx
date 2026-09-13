import { useState } from "react";
import { createMetricEvent } from "../core/eventFactory";
import { putEvent } from "../core/db";

const PRESETS = [
  { name: "glucose", unit: "mg/dL", label: "גלוקוז" },
  { name: "sleep", unit: "hours", label: "שינה" },
  { name: "steps", unit: "steps", label: "צעדים" },
  { name: "hr", unit: "bpm", label: "דופק" },
  { name: "pain", unit: "/10", label: "כאב" }
];

export default function MetricCapture({
  onSaved,
  embedded
}: {
  onSaved: (label: string) => void;
  embedded?: boolean;
}) {
  const [name, setName] = useState("glucose");
  const [value, setValue] = useState("");
  const [unit, setUnit] = useState("mg/dL");
  const [saving, setSaving] = useState(false);

  async function save() {
    const n = Number(value);
    if (!name.trim() || !Number.isFinite(n) || saving) return;
    setSaving(true);
    try {
      await putEvent(createMetricEvent(name.trim(), n, unit.trim() || undefined));
      setValue("");
      onSaved(`נשמר מדד: ${name.trim()} ${n}`);
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className={embedded ? "panelBody" : "card"}>
      {!embedded && <h2>מדד בריאות</h2>}
      <p className="panelHint">בחר מדד מהיר או הזן ידנית. ערך מספרי בלבד.</p>

      <div className="chipRow" role="list">
        {PRESETS.map((p) => (
          <button
            key={p.name}
            type="button"
            role="listitem"
            className={`chip ${name === p.name ? "chipActive" : ""}`}
            onClick={() => {
              setName(p.name);
              setUnit(p.unit);
            }}
          >
            {p.label}
          </button>
        ))}
      </div>

      <div className="fieldGrid">
        <label>
          <span>שם</span>
          <input value={name} onChange={(e) => setName(e.target.value)} placeholder="glucose / sleep / steps..." />
        </label>
        <label>
          <span>ערך</span>
          <input
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") void save();
            }}
            inputMode="decimal"
            placeholder="98"
            autoFocus={embedded}
          />
        </label>
        <label>
          <span>יחידה</span>
          <input value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="mg/dL" />
        </label>
      </div>

      <div className="panelActions">
        <button onClick={save} disabled={!name.trim() || !value || saving}>
          {saving ? "שומר…" : "שמור מדד"}
        </button>
      </div>
    </section>
  );
}
