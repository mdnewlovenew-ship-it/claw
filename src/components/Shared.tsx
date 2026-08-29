import { ARCHITECTURE_STEPS } from '../lib/engines';

export function ArchitectureRail() {
  return (
    <div className="flow-rail" aria-label="ארכיטקטורת HOS">
      {ARCHITECTURE_STEPS.map((s) => (
        <div key={s.key} className="flow-step">
          <div className="en">{s.en}</div>
          <div className="he">{s.he}</div>
        </div>
      ))}
    </div>
  );
}

export function ConfidenceBadge({ level }: { level: string }) {
  const warn = level.includes('השערה') || level.includes('מקצוע');
  return <span className={`badge${warn ? ' warn' : ' brand'}`}>{level}</span>;
}
