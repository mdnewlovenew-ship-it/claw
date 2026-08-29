import { Layout } from '../components/Layout';
import { useHos } from '../context/HosContext';
import { sleepCauseMap } from '../lib/engines';
import { filterByDays, formatHeDate } from '../lib/storage';

export function SleepPage() {
  const { state } = useHos();
  const recent = filterByDays(state.sleep, 14).slice().reverse();
  const causes = sleepCauseMap(state);

  return (
    <Layout title="מודול שינה">
      <section className="panel hero-panel">
        <p className="quote" style={{ color: '#f4f8f8' }}>
          HOS לא מחפש חומר שיעזור לישון — הוא מחפש למה האדם לא ישן.
        </p>
      </section>

      <section className="panel">
        <h2>מפת סיבות אפשריות</h2>
        <p className="small muted" style={{ marginBottom: 12 }}>
          מפה ≠ אבחנה. Clarify before Interpret.
        </p>
        <div className="map-steps">
          {causes.map((c) => (
            <span key={c} className="map-step">
              {c}
            </span>
          ))}
        </div>
      </section>

      <section className="panel">
        <h2>14 ימי שינה</h2>
        {recent.map((s) => (
          <div key={s.id} className="list-item">
            <div className="row" style={{ justifyContent: 'space-between' }}>
              <strong>{s.hours?.toFixed(1) ?? '—'} שע׳</strong>
              <span className="small muted">{formatHeDate(s.date)}</span>
            </div>
            <p className="small muted">
              {[
                s.earlyAwakening ? 'התעוררות מוקדמת' : null,
                s.hotFlashes ? 'גלי חום' : null,
                s.nightSweats ? 'הזעות לילה' : null,
                s.menopauseContext ? 'הקשר הורמונלי אפשרי' : null,
                s.awakenings != null ? `${s.awakenings} התעוררויות` : null,
                s.daytimeFatigue != null ? `עייפות יום ${s.daytimeFatigue}/10` : null,
              ]
                .filter(Boolean)
                .join(' · ') || 'ללא פירוט נוסף'}
            </p>
            {s.note ? <p style={{ marginTop: 6 }}>{s.note}</p> : null}
          </div>
        ))}
      </section>
    </Layout>
  );
}
