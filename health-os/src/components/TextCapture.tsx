import { useState } from "react";
import { createTextEvent } from "../core/eventFactory";
import { putEvent } from "../core/db";

export default function TextCapture({ onSaved }: { onSaved: () => void }) {
  const [text, setText] = useState("");

  async function save() {
    if (!text.trim()) return;
    await putEvent(createTextEvent(text));
    setText("");
    onSaved();
  }

  return (
    <section className="card">
      <h2>טקסט</h2>
      <textarea
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="מה קורה עכשיו?"
        rows={4}
      />
      <button onClick={save}>שמור</button>
    </section>
  );
}
