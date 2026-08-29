import { Layout } from '../components/Layout';
import { useHos } from '../context/HosContext';
import { SAFETY_LADDER, SAFE_ACTIONS } from '../lib/engines';

export function SettingsPage() {
  const { state, loadDemo, clearDemo } = useHos();

  function exportAll() {
    const blob = new Blob([JSON.stringify(state, null, 2)], {
      type: 'application/json',
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'hos-local-export.json';
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <Layout title="הגדרות ופרטיות">
      <section className="panel">
        <h2>פרטיות — MVP</h2>
        <p>המידע נשמר במכשיר בדמו הנוכחי (localStorage). אין הרשמה. אין העלאה לענן כברירת מחדל.</p>
        <div className="map-steps" style={{ marginTop: 12 }}>
          {['הסכמה מפורשת', 'הרשאות גרנולריות', 'ייצוא', 'מחיקת נתונים', 'שיתוף בשליטת המשתמש'].map(
            (x) => (
              <span key={x} className="map-step">
                {x}
              </span>
            ),
          )}
        </div>
      </section>

      <section className="panel">
        <h2>בטיחות — מתי HOS עוצר</h2>
        <div className="hierarchy">
          {SAFETY_LADDER.map((node, i, arr) => (
            <div key={node}>
              <div className="hierarchy-node">{node}</div>
              {i < arr.length - 1 ? <div className="hierarchy-arrow">↓</div> : null}
            </div>
          ))}
        </div>
        <p className="small muted" style={{ marginTop: 12 }}>
          אין אבחון חירום אוטונומי. הסלמה מוצעת עם הסבר — לא במקום טיפול דחוף.
        </p>
        <div className="map-steps" style={{ marginTop: 10 }}>
          {SAFE_ACTIONS.map((a) => (
            <span key={a} className="map-step">
              {a}
            </span>
          ))}
        </div>
      </section>

      <section className="panel">
        <h2>נתוני דמו</h2>
        <p className="small muted" style={{ marginBottom: 12 }}>
          סטטוס: {state.demoLoaded ? 'דמו טעון (בדיוני)' : 'ללא דמו / נתונים מקומיים'}
        </p>
        <div className="stack">
          <button type="button" className="btn btn-primary btn-block" onClick={loadDemo}>
            טען נתוני דמו (14 ימים)
          </button>
          <button type="button" className="btn btn-ghost btn-block" onClick={clearDemo}>
            נקה נתוני דמו
          </button>
          <button type="button" className="btn btn-secondary btn-block" onClick={exportAll}>
            ייצוא נתונים מקומיים
          </button>
        </div>
      </section>

      <div className="disclaimer">
        HOS אינה מחליפה איש מקצוע מורשה. אינה מאבחנת, אינה רושמת, אינה משנה מינון, ואינה פוסקת
        הלכה.
      </div>
    </Layout>
  );
}
