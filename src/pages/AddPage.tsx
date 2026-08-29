import { useState } from 'react';
import { Layout } from '../components/Layout';
import { useHos } from '../context/HosContext';

export function AddPage() {
  const { quickEntry } = useHos();
  const [glucose, setGlucose] = useState('');
  const [timing, setTiming] = useState<'fasting' | 'pre_meal' | 'post_meal' | 'bedtime' | 'other'>(
    'fasting',
  );
  const [sleepHours, setSleepHours] = useState('');
  const [earlyAwakening, setEarlyAwakening] = useState(false);
  const [energy, setEnergy] = useState(6);
  const [mood, setMood] = useState(6);
  const [stress, setStress] = useState(5);
  const [steps, setSteps] = useState('');
  const [medicationTaken, setMedicationTaken] = useState(true);
  const [weight, setWeight] = useState('');
  const [sys, setSys] = useState('');
  const [dia, setDia] = useState('');
  const [note, setNote] = useState('');
  const [toast, setToast] = useState(false);

  function submit() {
    quickEntry({
      glucose: glucose ? Number(glucose) : undefined,
      glucoseTiming: timing,
      sleepHours: sleepHours ? Number(sleepHours) : undefined,
      earlyAwakening,
      energy,
      mood,
      stress,
      steps: steps ? Number(steps) : undefined,
      medicationTaken,
      weight: weight ? Number(weight) : undefined,
      bloodPressureSys: sys ? Number(sys) : undefined,
      bloodPressureDia: dia ? Number(dia) : undefined,
      note: note || undefined,
    });
    setToast(true);
    setTimeout(() => setToast(false), 2200);
    setGlucose('');
    setSleepHours('');
    setNote('');
  }

  return (
    <Layout title="הוספה מהירה">
      <section className="panel">
        <p>
          תיעוד מצב היום בפחות מ־30 שניות. עד ש־HealthKit מחובר — הזנה ידנית מהירה.
        </p>
      </section>

      <section className="panel">
        <div className="field">
          <label htmlFor="glu">סוכר (מ״ג/ד״ל)</label>
          <input
            id="glu"
            inputMode="numeric"
            placeholder="לדוגמה 120"
            value={glucose}
            onChange={(e) => setGlucose(e.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="timing">תזמון</label>
          <select id="timing" value={timing} onChange={(e) => setTiming(e.target.value as typeof timing)}>
            <option value="fasting">צום</option>
            <option value="pre_meal">לפני ארוחה</option>
            <option value="post_meal">אחרי ארוחה</option>
            <option value="bedtime">לפני שינה</option>
            <option value="other">אחר</option>
          </select>
        </div>
        <div className="field">
          <label htmlFor="sleep">שינה (שעות)</label>
          <input
            id="sleep"
            inputMode="decimal"
            placeholder="לדוגמה 6.5"
            value={sleepHours}
            onChange={(e) => setSleepHours(e.target.value)}
          />
        </div>
        <div className="toggle-grid" style={{ marginBottom: 14 }}>
          <button
            type="button"
            className={`toggle${earlyAwakening ? ' on' : ''}`}
            onClick={() => setEarlyAwakening((v) => !v)}
          >
            התעוררות מוקדמת
          </button>
          <button
            type="button"
            className={`toggle${medicationTaken ? ' on' : ''}`}
            onClick={() => setMedicationTaken((v) => !v)}
          >
            תרופות נלקחו
          </button>
        </div>

        <Scale label="אנרגיה" value={energy} onChange={setEnergy} />
        <Scale label="מצב רוח" value={mood} onChange={setMood} />
        <Scale label="לחץ" value={stress} onChange={setStress} />

        <div className="field">
          <label htmlFor="steps">צעדים / פעילות</label>
          <input
            id="steps"
            inputMode="numeric"
            placeholder="אופציונלי"
            value={steps}
            onChange={(e) => setSteps(e.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="weight">משקל (אופציונלי)</label>
          <input
            id="weight"
            inputMode="decimal"
            placeholder="לדוגמה 72.5"
            value={weight}
            onChange={(e) => setWeight(e.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="bp">לחץ דם (אופציונלי)</label>
          <div className="row">
            <input
              id="bp"
              inputMode="numeric"
              placeholder="סיסטולי"
              value={sys}
              onChange={(e) => setSys(e.target.value)}
              style={{ flex: 1, minWidth: 0 }}
            />
            <input
              inputMode="numeric"
              placeholder="דיאסטולי"
              value={dia}
              onChange={(e) => setDia(e.target.value)}
              style={{ flex: 1, minWidth: 0 }}
            />
          </div>
        </div>
        <div className="field">
          <label htmlFor="note">הערה חופשית</label>
          <textarea
            id="note"
            placeholder="מה השתנה? הקשר חסר?"
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
        </div>
        <button type="button" className="btn btn-primary btn-block" onClick={submit}>
          שמירה במכשיר
        </button>
      </section>

      {toast ? <div className="success-toast">נשמר מקומית במכשיר</div> : null}
    </Layout>
  );
}

function Scale({
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
        <label>{label} 1–10</label>
        <strong>{value}</strong>
      </div>
      <input
        type="range"
        min={1}
        max={10}
        value={value}
        onChange={(e) => onChange(Number(e.target.value))}
      />
    </div>
  );
}
