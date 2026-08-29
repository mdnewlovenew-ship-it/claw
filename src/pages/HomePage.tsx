import { Link } from 'react-router-dom';
import { useHos } from '../context/HosContext';
import { ArchitectureRail, ConfidenceBadge } from '../components/Shared';
import { Layout } from '../components/Layout';
import {
  CONFIDENCE_LABELS,
  SAFE_ACTIONS,
  SIGNAL_CHAIN,
  buildHomeInsights,
  personalFastingGlucoseBaseline,
  personalSleepBaseline,
  personalStepsBaseline,
} from '../lib/engines';

export function HomePage() {
  const { state } = useHos();
  const insights = buildHomeInsights(state);
  const sleepBase = personalSleepBaseline(state);
  const gluBase = personalFastingGlucoseBaseline(state);
  const stepsBase = personalStepsBaseline(state);

  return (
    <Layout>
      <section className="panel hero-panel">
        <div className="eyebrow">שכבת הפעלה לבריאות אישית</div>
        <h1>HOS</h1>
        <p>HOS היא שכבת ההפעלה שבין האדם, הגוף והמערכת הרפואית.</p>
      </section>

      <section className="panel">
        <ArchitectureRail />
      </section>

      <section className="panel">
        <div className="section-label">מה השתנה?</div>
        <div className="stack">
          {insights.changed.map((t, i) => (
            <p key={`c-${i}`} style={{ fontWeight: 600, color: 'var(--ink)' }}>
              {t}
            </p>
          ))}
        </div>
      </section>

      <section className="panel">
        <div className="section-label">מה אנחנו יודעים?</div>
        <div className="stack">
          {insights.known.map((t, i) => (
            <p key={`k-${i}`}>{t}</p>
          ))}
        </div>
        <div style={{ marginTop: 12 }}>
          <ConfidenceBadge level={CONFIDENCE_LABELS.hypothesis} />
        </div>
      </section>

      <section className="panel">
        <div className="section-label">מה כדאי לבדוק הלאה?</div>
        <div className="stack">
          {insights.next.map((t, i) => (
            <p key={`n-${i}`}>{t}</p>
          ))}
        </div>
        {insights.questions[0] ? (
          <div className="list-item" style={{ marginTop: 12 }}>
            <p style={{ fontWeight: 600, color: 'var(--ink)' }}>{insights.questions[0].prompt}</p>
            <p className="small muted" style={{ marginTop: 6 }}>
              {insights.questions[0].reason}
            </p>
          </div>
        ) : null}
      </section>

      <section className="panel">
        <div className="section-label">הרגיל שלך</div>
        <div className="metric-strip">
          <div className="metric">
            <div className="val">{sleepBase ? sleepBase.toFixed(1) : '—'}</div>
            <div className="lbl">שינה שע׳</div>
          </div>
          <div className="metric">
            <div className="val">{gluBase ? Math.round(gluBase) : '—'}</div>
            <div className="lbl">צום מ״ג/ד״ל</div>
          </div>
          <div className="metric">
            <div className="val">{stepsBase ? Math.round(stepsBase) : '—'}</div>
            <div className="lbl">צעדים</div>
          </div>
        </div>
        <p className="small muted" style={{ marginTop: 12 }}>
          השינוי נמדד ביחס לרגיל האישי — לא רק לממוצע אוכלוסייה. לעולם לא הופכים תצפית לאבחנה.
        </p>
      </section>

      <section className="panel">
        <div className="section-label">Signal → Meaning → Boundary → Action</div>
        <div className="chain-grid">
          {SIGNAL_CHAIN.map((c) => (
            <div key={c.key} className="chain-card">
              <div className="en">{c.title}</div>
              <h3 style={{ margin: '6px 0' }}>{c.he}</h3>
              <p className="small">{c.desc}</p>
            </div>
          ))}
        </div>
        <div className="map-steps" style={{ marginTop: 14 }}>
          {SAFE_ACTIONS.slice(0, 5).map((a) => (
            <span key={a} className="map-step">
              {a}
            </span>
          ))}
        </div>
      </section>

      <section className="panel">
        <p className="quote" style={{ marginBottom: 12 }}>
          HOS מזהה שינוי, בונה הקשר, מצמצם אי־ודאות ומוביל את האדם לצעד הבא הנכון.
        </p>
        <p className="small muted">
          HOS היא שכבת העבודה הרציפה שמחברת בין האדם למטפל גם בין המפגשים.
        </p>
        <div className="btn-row" style={{ marginTop: 14 }}>
          <Link className="btn btn-primary" to="/add" style={{ textAlign: 'center' }}>
            הוספה מהירה
          </Link>
          <Link className="btn btn-secondary" to="/clinician" style={{ textAlign: 'center' }}>
            סיכום לרופא
          </Link>
        </div>
      </section>

      <div className="disclaimer">
        HOS אינה מחליפה רופא, מטפל, רוקח או רב. אינה מאבחנת, אינה רושמת תרופות, אינה משנה מינון
        אינסולין, ואינה פוסקת הלכה.
      </div>
    </Layout>
  );
}
