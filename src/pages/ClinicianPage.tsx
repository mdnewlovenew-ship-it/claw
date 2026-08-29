import { useMemo, useState } from 'react';
import { Layout } from '../components/Layout';
import { useHos } from '../context/HosContext';
import { clinicianSummary } from '../lib/engines';
import { formatHeDate } from '../lib/storage';

export function ClinicianPage() {
  const { state } = useHos();
  const summary = useMemo(() => clinicianSummary(state, 14), [state]);
  const [copied, setCopied] = useState(false);

  async function copyText() {
    try {
      await navigator.clipboard.writeText(summary.text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      const area = document.createElement('textarea');
      area.value = summary.text;
      document.body.appendChild(area);
      area.select();
      document.execCommand('copy');
      document.body.removeChild(area);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  }

  function shareOrDownload() {
    const blob = new Blob([summary.text], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'hos-clinician-summary-14d.txt';
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <Layout title="שותפות קלינית">
      <section className="panel">
        <p>
          HOS לא מנהל את המטופל במקום המטפל — הוא עוזר לשניהם לראות מה קורה בין המפגשים.
        </p>
        <p className="small muted" style={{ marginTop: 8 }}>
          סיכום ברירת מחדל: 14 ימים. לרופא / מטפל / פסיכולוג / פסיכיאטר / רוקח.
        </p>
      </section>

      <section className="panel">
        <h2>3 דפוסים עיקריים</h2>
        {summary.topPatterns.map((p, i) => (
          <div key={`pattern-${i}`} className="list-item">
            <strong>
              {i + 1}. {p}
            </strong>
          </div>
        ))}
        <div style={{ marginTop: 10 }}>
          <span className="badge warn">השערה — לא אבחנה</span>
        </div>
      </section>

      <section className="panel">
        <h2>שינויים עיקריים</h2>
        {summary.majorChanges.map((x) => (
          <div key={x} className="list-item">
            <p>{x}</p>
          </div>
        ))}
      </section>

      <section className="panel">
        <h2>שאלות פתוחות</h2>
        {summary.unresolved.length ? (
          summary.unresolved.map((x) => (
            <div key={x} className="list-item">
              <p>{x}</p>
            </div>
          ))
        ) : (
          <p className="muted">אין שאלות הבהרה פתוחות כרגע.</p>
        )}
      </section>

      <section className="panel">
        <h2>אירועים חריגים</h2>
        {summary.unusual.length ? (
          summary.unusual.map((x) => (
            <div key={x} className="list-item">
              <p>{x}</p>
            </div>
          ))
        ) : (
          <p className="muted">לא נרשמו.</p>
        )}
      </section>

      <section className="panel">
        <h2>הקשר תרופתי</h2>
        <p className="small muted" style={{ marginBottom: 8 }}>
          HOS אינו משנה מינון.
        </p>
        {summary.medContext.map((x) => (
          <div key={x} className="list-item">
            <p className="small">{x}</p>
          </div>
        ))}
      </section>

      <section className="panel">
        <h2>שאלות לדיון</h2>
        {summary.questionsForClinician.map((x) => (
          <div key={x} className="list-item">
            <p>{x}</p>
          </div>
        ))}
      </section>

      <section className="panel">
        <h2>ציר זמן מקוצר</h2>
        <div className="timeline">
          {summary.timeline.slice(0, 8).map((ev) => (
            <div key={ev.id} className="tl-item">
              <div className="tl-meta">
                {formatHeDate(ev.date)} · {ev.time}
              </div>
              <strong>{ev.title}</strong>
              {ev.detail ? <p className="small muted">{ev.detail}</p> : null}
            </div>
          ))}
        </div>
      </section>

      <div className="btn-row" style={{ marginBottom: 12 }}>
        <button type="button" className="btn btn-primary" onClick={copyText}>
          העתקה
        </button>
        <button type="button" className="btn btn-secondary" onClick={shareOrDownload}>
          ייצוא / שיתוף
        </button>
      </div>
      {copied ? <div className="success-toast">הסיכום הועתק</div> : null}
    </Layout>
  );
}
