import { useState } from 'react';
import { Layout } from '../components/Layout';
import { useHos } from '../context/HosContext';
import { buildHomeInsights } from '../lib/engines';

export function CheckInPage() {
  const { state, quickEntry } = useHos();
  const insights = buildHomeInsights(state);
  const questions = [
    'בוקר טוב. מה השתנה מאז אתמול?',
    ...insights.questions.slice(0, 2).map((q) => q.prompt),
    'איך האנרגיה היום ביחס לרגיל שלך?',
    'האם נלקחו התרופות כרגיל? (ללא שינוי מינון ע״י HOS)',
  ].slice(0, 5);

  const [answers, setAnswers] = useState<Record<number, string>>({});
  const [energy, setEnergy] = useState(6);
  const [mood, setMood] = useState(6);
  const [stress, setStress] = useState(5);
  const [done, setDone] = useState(false);

  function save() {
    const note = Object.entries(answers)
      .map(([i, v]) => `${questions[Number(i)]}: ${v}`)
      .filter((l) => !l.endsWith(': '))
      .join(' | ');
    quickEntry({ energy, mood, stress, note: note || undefined });
    setDone(true);
  }

  return (
    <Layout title="צ׳ק־אין יומי">
      <section className="panel hero-panel">
        <h2 style={{ color: '#f4f8f8', marginTop: 0 }}>בוקר טוב. מה השתנה מאז אתמול?</h2>
        <p>לא יותר מ־4–5 שאלות חשובות — לפי מידע חסר ודפוסים אחרונים.</p>
      </section>

      {questions.map((q, i) => (
        <section key={q} className="panel">
          <label style={{ fontWeight: 600 }}>{q}</label>
          <textarea
            style={{ marginTop: 10, width: '100%' }}
            placeholder="תשובה קצרה / דלג"
            value={answers[i] ?? ''}
            onChange={(e) => setAnswers((prev) => ({ ...prev, [i]: e.target.value }))}
          />
        </section>
      ))}

      <section className="panel">
        <FieldRange label="אנרגיה" value={energy} onChange={setEnergy} />
        <FieldRange label="מצב רוח" value={mood} onChange={setMood} />
        <FieldRange label="לחץ" value={stress} onChange={setStress} />
        <button type="button" className="btn btn-primary btn-block" onClick={save}>
          סיום צ׳ק־אין
        </button>
      </section>
      {done ? <div className="success-toast">הצ׳ק־אין נשמר במכשיר</div> : null}
    </Layout>
  );
}

function FieldRange({
  label,
  value,
  onChange,
}: {
  label: string;
  value: number;
  onChange: (n: number) => void;
}) {
  return (
    <div className="field">
      <div className="slider-row">
        <span>{label}</span>
        <strong>{value}</strong>
      </div>
      <input type="range" min={1} max={10} value={value} onChange={(e) => onChange(Number(e.target.value))} />
    </div>
  );
}
