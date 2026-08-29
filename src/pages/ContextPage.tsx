import { Layout } from '../components/Layout';
import { ArchitectureRail } from '../components/Shared';
import { useHos } from '../context/HosContext';
import { buildHomeInsights } from '../lib/engines';

export function ContextPage() {
  const { state } = useHos();
  const insights = buildHomeInsights(state);

  const signals = [
    'סוכר',
    'שינה',
    'פעילות',
    'צעדים',
    'דופק',
    'מצב רוח',
    'מצב רגשי',
    'לחץ',
    'חרדה',
    'כאב',
    'תרופות',
    'הקשר מזון',
    'קפאין',
    'משקל',
    'לחץ דם',
    'מחלה',
    'אירועים חריגים',
    'הערות חופשיות',
  ];

  return (
    <Layout title="מנוע הקשר">
      <section className="panel">
        <p className="quote">Clarify before Interpret.</p>
        <p style={{ marginTop: 10 }}>
          כל אות בריאותי מתפרש יחד עם הקשר — לא כמספר בודד.
        </p>
      </section>
      <section className="panel">
        <ArchitectureRail />
      </section>
      <section className="panel">
        <h2>שכבות אות</h2>
        <div className="map-steps">
          {signals.map((s) => (
            <span key={s} className="map-step">
              {s}
            </span>
          ))}
        </div>
      </section>
      <section className="panel">
        <h2>שאלות הבהרה פעילות</h2>
        {insights.questions.length ? (
          insights.questions.map((q) => (
            <div key={q.id} className="list-item">
              <p style={{ fontWeight: 600 }}>{q.prompt}</p>
              <p className="small muted" style={{ marginTop: 6 }}>
                {q.reason}
              </p>
            </div>
          ))
        ) : (
          <p className="muted">אין שאלת הבהרה דחופה כרגע — או שעדיין אין מספיק מידע.</p>
        )}
      </section>
      <section className="panel">
        <h2>מנוע ביטחון</h2>
        <div className="map-steps">
          <span className="map-step">DATA</span>
          <span className="map-step">PATTERN</span>
          <span className="map-step">HYPOTHESIS</span>
          <span className="map-step">CONCERN</span>
          <span className="map-step">PROFESSIONAL REVIEW</span>
        </div>
        <p style={{ marginTop: 12 }}>
          <span className="badge warn">השערה — לא אבחנה</span>
        </p>
        <p className="small muted" style={{ marginTop: 10 }}>
          מתאם סטטיסטי אינו סיבתיות רפואית.
        </p>
      </section>
    </Layout>
  );
}
