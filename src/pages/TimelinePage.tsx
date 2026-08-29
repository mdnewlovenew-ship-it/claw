import { useMemo, useState } from 'react';
import { Layout } from '../components/Layout';
import { useHos } from '../context/HosContext';
import { buildTimeline } from '../lib/engines';
import { formatHeDate } from '../lib/storage';

export function TimelinePage() {
  const { state } = useHos();
  const [days, setDays] = useState(7);
  const events = useMemo(() => buildTimeline(state, days), [state, days]);

  return (
    <Layout title="ציר זמן">
      <section className="panel">
        <p>בריאות היא סדרת זמן. HOS מחבר מה קרה לפני ואחרי אירוע.</p>
      </section>
      <div className="tabs">
        {[7, 14, 30].map((d) => (
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
        <div className="timeline">
          {events.length === 0 ? (
            <div className="empty">אין אירועים עדיין</div>
          ) : (
            events.map((ev) => (
              <div key={ev.id} className="tl-item">
                <div className="tl-meta">
                  {formatHeDate(ev.date)} · {ev.time} · {ev.kind}
                </div>
                <strong>{ev.title}</strong>
                {ev.value ? <p className="small">{ev.value}</p> : null}
                {ev.detail ? <p className="small muted">{ev.detail}</p> : null}
              </div>
            ))
          )}
        </div>
      </section>
    </Layout>
  );
}
