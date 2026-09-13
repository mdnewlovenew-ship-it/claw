import { useCallback, useEffect, useState } from "react";
import TextCapture from "./components/TextCapture";
import MetricCapture from "./components/MetricCapture";
import MediaCapture from "./components/MediaCapture";
import ImageCapture from "./components/ImageCapture";
import Timeline from "./components/Timeline";
import Toast, { type ToastMessage } from "./components/Toast";
import { clearAllEvents, getEvents, putEvent } from "./core/db";
import type { HealthEvent } from "./core/types";
import { runOrchestrator, type OrchestratorResult } from "./core/orchestrator";

type CaptureMode = "text" | "metric" | "voice" | "video" | "image";

const MODES: { id: CaptureMode; label: string; hint: string }[] = [
  { id: "text", label: "טקסט", hint: "הערה חופשית" },
  { id: "metric", label: "מדד", hint: "ערך מספרי" },
  { id: "voice", label: "קול", hint: "הקלטה" },
  { id: "video", label: "וידאו", hint: "מצלמה" },
  { id: "image", label: "תמונה", hint: "צילום / קובץ" }
];

export default function App() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [mode, setMode] = useState<CaptureMode>("text");
  const [toast, setToast] = useState<ToastMessage | null>(null);
  const [result, setResult] = useState<OrchestratorResult | null>(null);
  const [eventCount, setEventCount] = useState(0);
  const [highlightId, setHighlightId] = useState<string | null>(null);
  const [toolsOpen, setToolsOpen] = useState(false);

  const refresh = useCallback(() => setRefreshKey((v) => v + 1), []);

  useEffect(() => {
    void getEvents().then((events) => setEventCount(events.length));
  }, [refreshKey]);

  function showToast(text: string) {
    setToast({ id: String(Date.now()), text });
  }

  async function onSaved(label: string) {
    const events = await getEvents();
    setHighlightId(events[0]?.id ?? null);
    showToast(label);
    refresh();
    window.setTimeout(() => setHighlightId(null), 1800);
  }

  async function analyze() {
    const events = await getEvents();
    const next = runOrchestrator(events);
    setResult(next);
    setToolsOpen(true);
    showToast("Orchestrator רץ");
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
    showToast("ייצוא JSON הורד");
  }

  async function importData(file?: File) {
    if (!file) return;
    const raw = await file.text();
    const parsed = JSON.parse(raw) as { events?: HealthEvent[] };
    for (const event of parsed.events ?? []) {
      await putEvent(event);
    }
    refresh();
    showToast(`יובאו ${parsed.events?.length ?? 0} אירועים`);
  }

  async function clearData() {
    if (!confirm("למחוק את כל האירועים המקומיים?")) return;
    await clearAllEvents();
    setResult(null);
    refresh();
    showToast("הנתונים המקומיים נמחקו");
  }

  const active = MODES.find((m) => m.id === mode)!;

  return (
    <div className="appRoot">
      <div className="atmosphere" aria-hidden />
      <main className="shell">
        <header className="topbar">
          <div className="brandBlock">
            <p className="eyebrow">Health Operating System</p>
            <h1>Health OS</h1>
            <p className="tagline">Core v0.1 — לכידה חיה, זיכרון מקומי, בלי אבחון אוטונומי</p>
          </div>
          <div className="topMeta">
            <div className="status">
              <span className="dot" />
              Local only
            </div>
            <div className="liveStat">
              <span className="liveStatNum">{eventCount}</span>
              <span className="liveStatLabel">events</span>
            </div>
          </div>
        </header>

        <section className="workspace">
          <div className="capturePane">
            <div className="modeRail" role="tablist" aria-label="מצב לכידה">
              {MODES.map((m) => (
                <button
                  key={m.id}
                  type="button"
                  role="tab"
                  aria-selected={mode === m.id}
                  className={`modeTab ${mode === m.id ? "modeTabActive" : ""}`}
                  onClick={() => setMode(m.id)}
                >
                  <strong>{m.label}</strong>
                  <span>{m.hint}</span>
                </button>
              ))}
            </div>

            <div className="captureStage" key={mode}>
              <div className="stageHeader">
                <h2>{active.label}</h2>
                <p>{active.hint}</p>
              </div>

              {mode === "text" && <TextCapture embedded onSaved={onSaved} />}
              {mode === "metric" && <MetricCapture embedded onSaved={onSaved} />}
              {mode === "voice" && <MediaCapture embedded mode="voice" onSaved={onSaved} />}
              {mode === "video" && <MediaCapture embedded mode="video" onSaved={onSaved} />}
              {mode === "image" && <ImageCapture embedded onSaved={onSaved} />}
            </div>

            <section className={`toolsDrawer ${toolsOpen ? "toolsOpen" : ""}`}>
              <button
                type="button"
                className="toolsToggle"
                onClick={() => setToolsOpen((v) => !v)}
                aria-expanded={toolsOpen}
              >
                Core tools
                <span>{toolsOpen ? "−" : "+"}</span>
              </button>

              {toolsOpen && (
                <div className="toolsBody">
                  <div className="row">
                    <button onClick={() => void analyze()}>Run Orchestrator</button>
                    <button onClick={() => void exportData()}>Export JSON</button>
                    <label className="buttonLike">
                      Import JSON
                      <input
                        type="file"
                        accept="application/json"
                        onChange={(e) => void importData(e.target.files?.[0])}
                      />
                    </label>
                    <button className="danger" onClick={() => void clearData()}>
                      Clear Local Data
                    </button>
                  </div>

                  {result && (
                    <div className="orchPanel">
                      <h3>Orchestrator</h3>
                      {result.analysis.length === 0 &&
                      result.clarification.length === 0 &&
                      result.actions.length === 0 ? (
                        <p className="orchEmpty">
                          אין פלט עדיין. שמור לפחות שני מדדים מספריים כדי לראות סיכום בסיסי.
                        </p>
                      ) : (
                        <ul className="orchList">
                          {result.analysis.map((a) => (
                            <li key={a.id}>
                              <strong>{a.title}</strong>
                              <p>{a.explanation}</p>
                            </li>
                          ))}
                        </ul>
                      )}
                      <details>
                        <summary>JSON גולמי</summary>
                        <pre>{JSON.stringify(result, null, 2)}</pre>
                      </details>
                    </div>
                  )}
                </div>
              )}
            </section>
          </div>

          <Timeline refreshKey={refreshKey} onChanged={refresh} highlightId={highlightId} />
        </section>

        <footer>
          Prototype only. Health OS does not diagnose or independently change treatment.
        </footer>
      </main>

      <Toast message={toast} onDone={() => setToast(null)} />
    </div>
  );
}
