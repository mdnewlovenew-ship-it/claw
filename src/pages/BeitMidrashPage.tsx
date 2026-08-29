import { useState } from 'react';
import { Layout } from '../components/Layout';
import { BEIT_MIDRASH_FLOW, beitMidrashCases } from '../data/beitMidrash';
import {
  SOURCE_HIERARCHY,
  optionalEthicsVoice,
  sevenHalachicVoices,
} from '../data/advisors';

export function BeitMidrashPage() {
  const [caseId, setCaseId] = useState(beitMidrashCases[0].id);
  const selected = beitMidrashCases.find((c) => c.id === caseId) ?? beitMidrashCases[0];

  return (
    <Layout title="HOS Beit Midrash Engine">
      <section className="panel">
        <span className="badge brand">לא AI רב</span>
        <p style={{ marginTop: 12 }}>
          מנוע מיפוי מקורות ובניית שאלות. אינו פוסק. אינו מחליף פוסק אנושי.
        </p>
        <div className="map-steps" style={{ marginTop: 12 }}>
          {BEIT_MIDRASH_FLOW.map((s) => (
            <span key={s} className="map-step">
              {s}
            </span>
          ))}
        </div>
      </section>

      <section className="panel">
        <h2>היררכיית מקורות</h2>
        <div className="hierarchy">
          {SOURCE_HIERARCHY.map((node, i) => (
            <div key={node}>
              <div className="hierarchy-node">{node}</div>
              {i < SOURCE_HIERARCHY.length - 1 ? <div className="hierarchy-arrow">↓</div> : null}
            </div>
          ))}
        </div>
        <p className="small muted" style={{ marginTop: 12 }}>
          המנוע ממפה את העולם ההלכתי סביב המקרה; אינו מחליף פוסק.
        </p>
      </section>

      <section className="panel">
        <h2>שבעה קולות — שכבת מקורות בהשראת סנהדרין</h2>
        <p className="small muted" style={{ marginBottom: 8 }}>
          אין טענה שזו סנהדרין ממשית.
        </p>
        {sevenHalachicVoices.map((v, i) => (
          <div key={v.id} className="voice-card">
            <strong>
              {i + 1}. {v.name}
            </strong>
            <p className="small muted">{v.role}</p>
            <p className="small">מקורות: {v.sources.join(' · ')}</p>
            <p className="small">מיקוד: {v.focus}</p>
          </div>
        ))}
        <div className="voice-card">
          <span className="badge potential">אופציונלי לעתיד</span>
          <p style={{ marginTop: 8 }}>
            <strong>{optionalEthicsVoice.name}</strong> — {optionalEthicsVoice.focus}
          </p>
        </div>
      </section>

      <section className="panel">
        <h2>מקרי DEMO</h2>
        <div className="tabs" style={{ flexWrap: 'wrap' }}>
          {beitMidrashCases.map((c) => (
            <button
              key={c.id}
              type="button"
              className={`tab${caseId === c.id ? ' active' : ''}`}
              onClick={() => setCaseId(c.id)}
              style={{ flex: '1 1 30%' }}
            >
              {c.title}
            </button>
          ))}
        </div>
        <span className="badge warn">DEMO</span>
        <h3 style={{ marginTop: 12 }}>{selected.title}</h3>
        <p style={{ marginTop: 8 }}>{selected.question}</p>
        <div className="section-label" style={{ marginTop: 14 }}>
          מפת הסוגיה
        </div>
        <div className="map-steps">
          {selected.mapSteps.map((s) => (
            <span key={s} className="map-step">
              {s}
            </span>
          ))}
        </div>
        <div className="section-label" style={{ marginTop: 14 }}>
          ניסוחים מותרים
        </div>
        {selected.principles.map((p) => (
          <div key={p} className="list-item">
            <p>{p}</p>
          </div>
        ))}
        <div className="disclaimer" style={{ marginTop: 12 }}>
          המנוע לעולם לא פולט «פסק ההלכה הוא…». נדרש בירור אצל פוסק המכיר את פרטי המקרה.
        </div>
      </section>
    </Layout>
  );
}
