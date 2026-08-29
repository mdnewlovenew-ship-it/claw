import { Layout } from '../components/Layout';
import { useHos } from '../context/HosContext';
import {
  personalFastingGlucoseBaseline,
  personalSleepBaseline,
  personalStepsBaseline,
} from '../lib/engines';
import { average, filterByDays } from '../lib/storage';

export function BaselinePage() {
  const { state } = useHos();
  const sleep = personalSleepBaseline(state);
  const glu = personalFastingGlucoseBaseline(state);
  const steps = personalStepsBaseline(state);
  const recentSleep = filterByDays(state.sleep, 7);
  const recentEnergy = average(
    filterByDays(state.checkIns, 7).map((c) => c.energy),
  );

  return (
    <Layout title="Personal Baseline">
      <section className="panel">
        <p>
          HOS לומד את הדפוסים האישיים הרגילים לאורך זמן — «הרגיל שלך» — במקום להסתמך רק על
          ממוצעי אוכלוסייה.
        </p>
      </section>
      <section className="panel">
        <div className="metric-strip">
          <div className="metric">
            <div className="val">{sleep?.toFixed(1) ?? '—'}</div>
            <div className="lbl">שינה אישית</div>
          </div>
          <div className="metric">
            <div className="val">{glu ? Math.round(glu) : '—'}</div>
            <div className="lbl">צום אישי</div>
          </div>
          <div className="metric">
            <div className="val">{steps ? Math.round(steps) : '—'}</div>
            <div className="lbl">צעדים</div>
          </div>
        </div>
        <p className="small muted" style={{ marginTop: 12 }}>
          דוגמאות לניסוח: «ערך הסוכר הבוקר גבוה מהרגיל שלך.» · «השינה הייתה קצרה מהממוצע האישי
          שלך.» · «רמת הפעילות נמוכה ביחס לשבועות האחרונים.»
        </p>
      </section>
      <section className="panel">
        <h2>7 ימים אחרונים</h2>
        <p>
          ממוצע שינה: {average(recentSleep.map((s) => s.hours).filter((h): h is number => h != null))?.toFixed(1) ?? '—'} שע׳
        </p>
        <p style={{ marginTop: 8 }}>ממוצע אנרגיה: {recentEnergy?.toFixed(1) ?? '—'}/10</p>
        <div className="disclaimer" style={{ marginTop: 12 }}>
          תצפית ביחס לרגיל ≠ אבחנה.
        </div>
      </section>
    </Layout>
  );
}
