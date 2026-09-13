import { useState } from "react";
import { createTextEvent } from "../core/eventFactory";
import { putEvent } from "../core/db";

export default function TextCapture({
  onSaved,
  embedded
}: {
  onSaved: (label: string) => void;
  embedded?: boolean;
}) {
  const [text, setText] = useState("");
  const [saving, setSaving] = useState(false);

  async function save() {
    if (!text.trim() || saving) return;
    setSaving(true);
    try {
      await putEvent(createTextEvent(text));
      setText("");
      onSaved("נשמר אירוע טקסט");
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className={embedded ? "panelBody" : "card"}>
      {!embedded && <h2>טקסט</h2>}
      <p className="panelHint">כתוב מה קורה עכשיו. נשמר כאירוע גולמי — בלי פרשנות.</p>
      <textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        onKeyDown={(e) => {
          if ((e.metaKey || e.ctrlKey) && e.key === "Enter") void save();
        }}
        placeholder="מה קורה עכשיו?"
        rows={5}
        autoFocus={embedded}
      />
      <div className="panelActions">
        <button onClick={save} disabled={!text.trim() || saving}>
          {saving ? "שומר…" : "שמור אירוע"}
        </button>
        <small>⌘/Ctrl + Enter</small>
      </div>
    </section>
  );
}
