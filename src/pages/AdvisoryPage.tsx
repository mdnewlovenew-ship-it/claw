import { Layout } from '../components/Layout';
import { ADVISORY_CHAIN_HE, conceptualAdvisors } from '../data/advisors';

export function AdvisoryPage() {
  return (
    <Layout title="מסגרת ייעוץ">
      <section className="panel">
        <span className="badge potential">Potential / Conceptual Advisors</span>
        <p style={{ marginTop: 12 }}>
          האנשים כאן מוצגים כיועצים פוטנציאליים / רעיוניים בלבד. לא כחברי צוות רשמיים של HOS —
          עד שיסומן במפורש אחרת אחרי הסכמה.
        </p>
      </section>

      <section className="panel hero-panel">
        <p className="quote" style={{ color: '#f4f8f8', whiteSpace: 'pre-line' }}>
          {ADVISORY_CHAIN_HE}
        </p>
      </section>

      {conceptualAdvisors.map((a) => (
        <section key={a.id} className="panel">
          <div className="row" style={{ justifyContent: 'space-between', marginBottom: 8 }}>
            <h2 style={{ margin: 0 }}>{a.name}</h2>
            <span className="badge potential">
              {a.status === 'potential' ? 'פוטנציאלי' : 'מאושר'}
            </span>
          </div>
          <p className="small muted">
            {a.role} · עקרון HOS: {a.principleHe} / {a.principle}
          </p>
          <p style={{ marginTop: 10, fontWeight: 600 }}>{a.chainLine}</p>
          <div className="section-label" style={{ marginTop: 14 }}>
            תרומה אפשרית
          </div>
          <div className="map-steps">
            {a.contributions.map((c) => (
              <span key={c} className="map-step">
                {c}
              </span>
            ))}
          </div>
          {a.id === 'michal' ? (
            <p className="small muted" style={{ marginTop: 12 }}>
              אין כאן טענות על הסמכה רפואית פורמלית מעבר למידע שאושר במפורש מאוחר יותר.
            </p>
          ) : null}
        </section>
      ))}
    </Layout>
  );
}
