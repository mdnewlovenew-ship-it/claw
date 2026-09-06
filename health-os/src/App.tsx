import { useState } from "react";
import TextCapture from "./components/TextCapture";
import MetricCapture from "./components/MetricCapture";
import MediaCapture from "./components/MediaCapture";
import ImageCapture from "./components/ImageCapture";
import Timeline from "./components/Timeline";
import { clearAllEvents, getEvents, putEvent } from "./core/db";
import type { HealthEvent } from "./core/types";
import { runOrchestrator } from "./core/orchestrator";

export default function App() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [analysis, setAnalysis] = useState("");
  const refresh = () => setRefreshKey((v) => v + 1);

  async function analyze() {
    const events = await getEvents();
    const result = runOrchestrator(events);
    setAnalysis(JSON.stringify(result, null, 2));
  }

  async function exportData() {
    const events = await getEvents();
    const blob = new Blob([JSON.stringify({ version: 1, events }, null, 2)], {
      type: "application/json"
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `health-os-export-${new Date().toISOString().slice(0, 10)}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }

  async function importData(file?: File) {
    if (!file) return;
    const raw = await file.text();
    const parsed = JSON.parse(raw) as { events?: HealthEvent[] };
    for (const event of parsed.events ?? []) {
      await putEvent(event);
    }
    refresh();
  }

  async function clearData() {
    if (!confirm("למחוק את כל האירועים המקומיים?")) return;
    await clearAllEvents();
    setAnalysis("");
    refresh();
  }

  return (
    <main className="shell">
      <header className="hero">
        <div>
          <p className="eyebrow">Health Operating System</p>
          <h1>Health OS</h1>
          <p>Core v0.1 — local-first multimodal event engine</p>
        </div>
        <div className="status"><span className="dot" />Local only</div>
      </header>

      <section className="notice">
        <strong>Everything is an Event.</strong> Raw observations remain separate from interpretation.
      </section>

      <div className="grid">
        <TextCapture onSaved={refresh} />
        <MetricCapture onSaved={refresh} />
        <MediaCapture mode="voice" onSaved={refresh} />
        <MediaCapture mode="video" onSaved={refresh} />
        <ImageCapture onSaved={refresh} />
      </div>

      <section className="card tools">
        <h2>Core tools</h2>
        <div className="row">
          <button onClick={analyze}>Run Orchestrator</button>
          <button onClick={exportData}>Export JSON</button>
          <label className="buttonLike">
            Import JSON
            <input type="file" accept="application/json" onChange={(e) => importData(e.target.files?.[0])} />
          </label>
          <button className="danger" onClick={clearData}>Clear Local Data</button>
        </div>
        {analysis && <pre>{analysis}</pre>}
      </section>

      <Timeline refreshKey={refreshKey} onChanged={refresh} />

      <footer>
        Prototype only. Health OS does not diagnose or independently change treatment.
      </footer>
    </main>
  );
}
