#!/usr/bin/env bash
set -e

APP_DIR="${1:-health-os}"

echo "==> Creating Health OS in: $APP_DIR"
mkdir -p "$APP_DIR/src/components" "$APP_DIR/src/core" "$APP_DIR/docs"
cd "$APP_DIR"

cat > package.json <<'EOF'
{
  "name": "health-os",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.5",
    "typescript": "^5.7.2",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/react": "^19.0.2",
    "@types/react-dom": "^19.0.2"
  }
}
EOF

cat > index.html <<'EOF'
<!doctype html>
<html lang="he" dir="rtl">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="theme-color" content="#111111" />
    <title>Health OS</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

cat > vite.config.ts <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
export default defineConfig({ plugins: [react()] });
EOF

cat > tsconfig.json <<'EOF'
{
  "files": [],
  "references": [{ "path": "./tsconfig.app.json" }]
}
EOF

cat > tsconfig.app.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "allowJs": false,
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx"
  },
  "include": ["src"]
}
EOF

cat > README.md <<'EOF'
# Health OS — Core v0.1

Health OS is a local-first multimodal personal health operating system prototype.

Core rule: **Everything is an Event.**

Inputs:
- Voice
- Text
- Image
- Video
- Sensor values
- Manual health metrics
- Future Apple Health / HealthKit import

Safety:
- No autonomous diagnosis.
- No independent medication changes.
- Clinical decisions remain with the user and qualified clinicians.
- Raw observations remain separate from interpretations.
EOF

cat > docs/ARCHITECTURE.md <<'EOF'
# Health OS Architecture

Observe → Normalize → Remember → Analyze → Clarify → Refer/Coach → Learn → Audit

## Observe
Voice, text, image, video, sensors, Apple Health, manual entries.

## Normalize
All input becomes a HealthEvent.

## Memory
IndexedDB local-first storage.

## Analyze
Future engines for temporal trends, multimodal correlations, confidence, anomalies.

## Clarify
Ask focused questions when uncertainty is high.

## Refer / Coach
Possible outputs:
- log
- reminder
- self-care suggestion
- question for clinician
- referral/escalation
- no action

## Cross-cutting
Privacy, consent, audit, explainability, governance, safety.
EOF

cat > src/core/types.ts <<'EOF'
export type EventKind =
  | "text"
  | "voice"
  | "image"
  | "video"
  | "sensor"
  | "health-data"
  | "document"
  | "system";

export interface HealthEvent {
  id: string;
  kind: EventKind;
  createdAt: string;
  source: {
    device?: string;
    app?: string;
    modality: EventKind;
  };
  payload: {
    text?: string;
    mediaId?: string;
    mimeType?: string;
    numeric?: {
      name: string;
      value: number;
      unit?: string;
    };
  };
  context?: {
    tags?: string[];
    note?: string;
  };
  confidence: number;
  privacy: {
    scope: "private" | "clinician-shareable" | "exportable";
  };
  derivedFrom?: string[];
  audit: {
    createdBy: "user" | "system" | "import";
    version: string;
  };
}

export interface AnalysisResult {
  id: string;
  createdAt: string;
  derivedFrom: string[];
  type: "trend" | "correlation" | "anomaly" | "summary" | "unknown";
  title: string;
  explanation: string;
  confidence: number;
  requiresClarification: boolean;
}

export interface ClarificationRequest {
  id: string;
  createdAt: string;
  question: string;
  reason: string;
  relatedEventIds: string[];
  priority: "low" | "normal" | "high";
}

export type ActionKind =
  | "none"
  | "log"
  | "reminder"
  | "coach"
  | "ask-clinician"
  | "refer";

export interface HealthAction {
  id: string;
  createdAt: string;
  kind: ActionKind;
  title: string;
  explanation: string;
  relatedEventIds: string[];
  confidence: number;
}
EOF

cat > src/core/id.ts <<'EOF'
export function createId(prefix = "evt"): string {
  if (crypto.randomUUID) return `${prefix}_${crypto.randomUUID()}`;
  return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2)}`;
}
EOF

cat > src/core/eventFactory.ts <<'EOF'
import type { EventKind, HealthEvent } from "./types";
import { createId } from "./id";

export function baseEvent(kind: EventKind): HealthEvent {
  return {
    id: createId(),
    kind,
    createdAt: new Date().toISOString(),
    source: {
      device: navigator.userAgent,
      app: "Health OS Web",
      modality: kind
    },
    payload: {},
    confidence: 1,
    privacy: { scope: "private" },
    audit: { createdBy: "user", version: "0.1.0" }
  };
}

export function createTextEvent(text: string): HealthEvent {
  const event = baseEvent("text");
  event.payload.text = text.trim();
  return event;
}

export function createMetricEvent(name: string, value: number, unit?: string): HealthEvent {
  const event = baseEvent("health-data");
  event.payload.numeric = { name, value, unit };
  return event;
}

export function createMediaEvent(
  kind: "voice" | "video" | "image",
  mediaId: string,
  mimeType: string
): HealthEvent {
  const event = baseEvent(kind);
  event.payload.mediaId = mediaId;
  event.payload.mimeType = mimeType;
  return event;
}
EOF

cat > src/core/db.ts <<'EOF'
import type { HealthEvent } from "./types";

const DB_NAME = "health-os";
const DB_VERSION = 1;
const EVENT_STORE = "events";
const MEDIA_STORE = "media";

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = () => {
      const db = request.result;

      if (!db.objectStoreNames.contains(EVENT_STORE)) {
        const store = db.createObjectStore(EVENT_STORE, { keyPath: "id" });
        store.createIndex("createdAt", "createdAt");
        store.createIndex("kind", "kind");
      }

      if (!db.objectStoreNames.contains(MEDIA_STORE)) {
        db.createObjectStore(MEDIA_STORE, { keyPath: "id" });
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function putEvent(event: HealthEvent): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(EVENT_STORE, "readwrite");
    tx.objectStore(EVENT_STORE).put(event);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function getEvents(): Promise<HealthEvent[]> {
  const db = await openDb();
  const result = await new Promise<HealthEvent[]>((resolve, reject) => {
    const tx = db.transaction(EVENT_STORE, "readonly");
    const request = tx.objectStore(EVENT_STORE).getAll();
    request.onsuccess = () => resolve(request.result as HealthEvent[]);
    request.onerror = () => reject(request.error);
  });
  db.close();
  return result.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export async function deleteEvent(id: string): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(EVENT_STORE, "readwrite");
    tx.objectStore(EVENT_STORE).delete(id);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function clearAllEvents(): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(EVENT_STORE, "readwrite");
    tx.objectStore(EVENT_STORE).clear();
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function putMedia(id: string, blob: Blob): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(MEDIA_STORE, "readwrite");
    tx.objectStore(MEDIA_STORE).put({ id, blob, createdAt: new Date().toISOString() });
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function getMedia(id: string): Promise<Blob | null> {
  const db = await openDb();
  const result = await new Promise<{ id: string; blob: Blob } | undefined>((resolve, reject) => {
    const tx = db.transaction(MEDIA_STORE, "readonly");
    const request = tx.objectStore(MEDIA_STORE).get(id);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  db.close();
  return result?.blob ?? null;
}
EOF

cat > src/core/orchestrator.ts <<'EOF'
import type {
  AnalysisResult,
  ClarificationRequest,
  HealthAction,
  HealthEvent
} from "./types";
import { createId } from "./id";

export interface OrchestratorResult {
  analysis: AnalysisResult[];
  clarification: ClarificationRequest[];
  actions: HealthAction[];
}

export function runOrchestrator(events: HealthEvent[]): OrchestratorResult {
  const analysis: AnalysisResult[] = [];
  const clarification: ClarificationRequest[] = [];
  const actions: HealthAction[] = [];

  const numeric = events.filter((e) => e.payload.numeric);

  if (numeric.length > 1) {
    analysis.push({
      id: createId("analysis"),
      createdAt: new Date().toISOString(),
      derivedFrom: numeric.map((e) => e.id),
      type: "summary",
      title: "Numeric health data available",
      explanation: `${numeric.length} structured health measurements are available for future trend analysis.`,
      confidence: 1,
      requiresClarification: false
    });
  }

  return { analysis, clarification, actions };
}
EOF

cat > src/components/TextCapture.tsx <<'EOF'
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
EOF

cat > src/components/MetricCapture.tsx <<'EOF'
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
EOF

cat > src/components/MediaCapture.tsx <<'EOF'
import { useRef, useState } from "react";
import { createMediaEvent } from "../core/eventFactory";
import { putEvent, putMedia } from "../core/db";
import { createId } from "../core/id";

export default function MediaCapture({
  mode,
  onSaved
}: {
  mode: "voice" | "video";
  onSaved: () => void;
}) {
  const recorderRef = useRef<MediaRecorder | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const chunksRef = useRef<BlobPart[]>([]);
  const [recording, setRecording] = useState(false);

  async function start() {
    const constraints =
      mode === "voice"
        ? { audio: true }
        : { audio: true, video: { facingMode: "user" } };

    const stream = await navigator.mediaDevices.getUserMedia(constraints);
    streamRef.current = stream;

    const recorder = new MediaRecorder(stream);
    recorderRef.current = recorder;
    chunksRef.current = [];

    recorder.ondataavailable = (e) => {
      if (e.data.size > 0) chunksRef.current.push(e.data);
    };

    recorder.onstop = async () => {
      const blob = new Blob(chunksRef.current, {
        type: recorder.mimeType || (mode === "voice" ? "audio/webm" : "video/webm")
      });

      const mediaId = createId("media");
      await putMedia(mediaId, blob);
      await putEvent(createMediaEvent(mode, mediaId, blob.type));

      streamRef.current?.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
      onSaved();
    };

    recorder.start();
    setRecording(true);
  }

  function stop() {
    recorderRef.current?.stop();
    setRecording(false);
  }

  return (
    <section className="card">
      <h2>{mode === "voice" ? "קול" : "וידאו"}</h2>
      {!recording ? (
        <button onClick={start}>
          {mode === "voice" ? "התחל הקלטת קול" : "התחל הקלטת וידאו"}
        </button>
      ) : (
        <button onClick={stop}>עצור ושמור</button>
      )}
      <small>נשמר מקומית בלבד.</small>
    </section>
  );
}
EOF

cat > src/components/ImageCapture.tsx <<'EOF'
import { createId } from "../core/id";
import { createMediaEvent } from "../core/eventFactory";
import { putEvent, putMedia } from "../core/db";

export default function ImageCapture({ onSaved }: { onSaved: () => void }) {
  async function handleFile(file?: File) {
    if (!file) return;
    const mediaId = createId("media");
    await putMedia(mediaId, file);
    await putEvent(createMediaEvent("image", mediaId, file.type || "image/*"));
    onSaved();
  }

  return (
    <section className="card">
      <h2>תמונה</h2>
      <input
        type="file"
        accept="image/*"
        capture="environment"
        onChange={(e) => handleFile(e.target.files?.[0])}
      />
    </section>
  );
}
EOF

cat > src/components/Timeline.tsx <<'EOF'
import { useEffect, useState } from "react";
import type { HealthEvent } from "../core/types";
import { deleteEvent, getEvents, getMedia } from "../core/db";

export default function Timeline({
  refreshKey,
  onChanged
}: {
  refreshKey: number;
  onChanged: () => void;
}) {
  const [events, setEvents] = useState<HealthEvent[]>([]);
  const [mediaUrls, setMediaUrls] = useState<Record<string, string>>({});

  useEffect(() => {
    void load();
  }, [refreshKey]);

  async function load() {
    const list = await getEvents();
    setEvents(list);

    const urls: Record<string, string> = {};
    for (const event of list) {
      const mediaId = event.payload.mediaId;
      if (mediaId) {
        const blob = await getMedia(mediaId);
        if (blob) urls[mediaId] = URL.createObjectURL(blob);
      }
    }
    setMediaUrls(urls);
  }

  async function remove(id: string) {
    await deleteEvent(id);
    onChanged();
  }

  return (
    <section className="timeline">
      <div className="timelineHeader">
        <h2>Timeline</h2>
        <span>{events.length} events</span>
      </div>

      {events.map((event) => {
        const mediaId = event.payload.mediaId;
        const mediaUrl = mediaId ? mediaUrls[mediaId] : undefined;

        return (
          <article className="event" key={event.id}>
            <div className="eventTop">
              <strong>{event.kind}</strong>
              <time>{new Date(event.createdAt).toLocaleString("he-IL")}</time>
            </div>

            {event.payload.text && <p>{event.payload.text}</p>}

            {event.payload.numeric && (
              <p>
                {event.payload.numeric.name}: <strong>{event.payload.numeric.value}</strong>{" "}
                {event.payload.numeric.unit}
              </p>
            )}

            {event.kind === "voice" && mediaUrl && <audio controls src={mediaUrl} />}
            {event.kind === "video" && mediaUrl && <video controls playsInline src={mediaUrl} />}
            {event.kind === "image" && mediaUrl && <img src={mediaUrl} alt="" />}

            <details>
              <summary>Metadata</summary>
              <pre>{JSON.stringify(event, null, 2)}</pre>
            </details>

            <button className="danger" onClick={() => remove(event.id)}>
              מחק
            </button>
          </article>
        );
      })}
    </section>
  );
}
EOF

cat > src/App.tsx <<'EOF'
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
EOF

cat > src/main.tsx <<'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

cat > src/styles.css <<'EOF'
:root {
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  color: #f5f5f5;
  background: #0b0b0c;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
  background: #0b0b0c;
}

button, input, textarea { font: inherit; }

button, .buttonLike {
  border: 0;
  border-radius: 14px;
  padding: 12px 16px;
  cursor: pointer;
  background: #f2f2f2;
  color: #111;
  font-weight: 700;
  display: inline-block;
}

.buttonLike input { display: none; }

input, textarea {
  width: 100%;
  border: 1px solid #333;
  border-radius: 14px;
  padding: 12px;
  background: #131315;
  color: #fff;
  margin-bottom: 10px;
}

.shell {
  width: min(1100px, calc(100% - 28px));
  margin: 0 auto;
  padding: 28px 0 60px;
}

.hero {
  display: flex;
  justify-content: space-between;
  gap: 20px;
  align-items: flex-start;
  margin-bottom: 20px;
}

.eyebrow { opacity: .55; text-transform: uppercase; letter-spacing: .1em; font-size: 12px; }

h1 { font-size: clamp(42px, 8vw, 82px); line-height: .95; margin: 8px 0 12px; }

.status {
  display: flex;
  gap: 8px;
  align-items: center;
  white-space: nowrap;
  padding: 10px 14px;
  background: #171719;
  border: 1px solid #2a2a2e;
  border-radius: 999px;
}

.dot {
  width: 9px;
  height: 9px;
  background: #7cff9b;
  border-radius: 50%;
}

.notice, .card, .event, .timeline {
  background: #141416;
  border: 1px solid #29292e;
  border-radius: 20px;
}

.notice { padding: 16px 18px; margin-bottom: 18px; }

.grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px;
  margin-bottom: 18px;
}

.card { padding: 18px; margin-bottom: 18px; }
.card h2 { margin-top: 0; }
.card small { display: block; opacity: .5; margin-top: 10px; }

.row { display: flex; flex-wrap: wrap; gap: 10px; }

.timeline { padding: 18px; }
.timelineHeader, .eventTop {
  display: flex;
  justify-content: space-between;
  gap: 14px;
}

.event { padding: 16px; margin-top: 12px; }

.event audio, .event video, .event img {
  width: 100%;
  margin-top: 12px;
  border-radius: 14px;
}

pre {
  overflow: auto;
  direction: ltr;
  text-align: left;
  background: #09090a;
  padding: 12px;
  border-radius: 12px;
  font-size: 12px;
}

.danger { background: #2a1717; color: #ffb1b1; }

footer { opacity: .45; font-size: 12px; text-align: center; margin-top: 22px; }

@media (max-width: 760px) {
  .hero { flex-direction: column; }
  .grid { grid-template-columns: 1fr; }
}
EOF

echo "==> Installing dependencies..."
npm install

echo "==> Running build check..."
npm run build

echo
echo "=============================================="
echo " Health OS created successfully"
echo "=============================================="
echo
echo "Starting development server..."
npm run dev
