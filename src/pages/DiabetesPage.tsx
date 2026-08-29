import { useMemo, useState } from 'react';
import { Layout } from '../components/Layout';
import { ConfidenceBadge } from '../components/Shared';
import { useHos } from '../context/HosContext';
import { CONFIDENCE_LABELS, diabetesInsights } from '../lib/engines';
import { filterByDays, formatHeDate } from '../lib/storage';

export function DiabetesPage() {
  const { state } = useHos();
  const [days, setDays] = useState<7 | 14 | 30>(14);
  const insights = useMemo(() => diabetesInsights(state, days), [state, days]);
  const readings = filterByDays(state.glucose, days).slice().reverse();

  return (
    <Layout title="מודול סוכרת">
      <section className="panel">
        <p>
          מעקב סוכר בהקשר: שינה, פעילות, לחץ, מזון ותרופות. HOS מזהה דפוסים — לא משנה טיפול.
        </p>
        <div className="disclaimer" style={{ marginTop: 12 }}>
          לעולם לא: «תעלה אינסולין», «תוריד מינון», «שנה טיפול». שינוי תרופתי — רק עם הרופא.
        </div>
      </section>

      <div className="tabs">
        {([7, 14, 30] as const).map((d) => (
          <button
            key={d}
            type="button"
            className={`tab${days === d ? ' active' : ''}`}
            onClick={() => setDays(d)}
          >
            {d} ימים
          </button>
        ))}
      </div>

      <section className="panel">
        <h2>תובנות</h2>
        {insights.map((ins) => (
          <div key={ins.id} className="list-item">
            <div className="row" style={{ marginBottom: 6 }}>
              <strong>{ins.title}</strong>
              <ConfidenceBadge level={CONFIDENCE_LABELS[ins.confidence]} />
            </div>
            <p>{ins.body}</p>
            {ins.actionHint ? (
              <p className="small muted" style={{ marginTop: 6 }}>
                {ins.actionHint}
              </p>
            ) : null}
          </div>
        ))}
      </section>

      <section className="panel">
        <h2>מדידות</h2>
        {readings.length === 0 ? (
          <div className="empty">אין מדידות בתקופה זו</div>
        ) : (
          readings.map((g) => (
            <div key={g.id} className="list-item">
              <div className="row" style={{ justifyContent: 'space-between' }}>
                <strong>
                  {g.value} מ״ג/ד״ל
                </strong>
                <span className="small muted">
                  {formatHeDate(g.date)} · {g.time}
                </span>
              </div>
              <p className="small muted">
                {labelTiming(g.timing)}
                {g.foodContext ? ` · ${g.foodContext}` : ''}
              </p>
            </div>
          ))
        )}
      </section>
    </Layout>
  );
}

function labelTiming(t: string) {
  switch (t) {
    case 'fasting':
      return 'צום';
    case 'pre_meal':
      return 'לפני ארוחה';
    case 'post_meal':
      return 'אחרי ארוחה';
    case 'bedtime':
      return 'לפני שינה';
    default:
      return 'אחר';
  }
}
