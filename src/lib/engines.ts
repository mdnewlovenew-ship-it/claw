import type {
  ClarifyingQuestion,
  ConfidenceLevel,
  HosState,
  PatternInsight,
  TimelineEvent,
} from '../types';
import { average, filterByDays, formatHeDate } from './storage';

export const CONFIDENCE_LABELS: Record<ConfidenceLevel, string> = {
  data: 'נתון',
  pattern: 'דפוס',
  hypothesis: 'השערה — לא אבחנה',
  concern: 'דאגה שכדאי לבדוק',
  professional_review: 'לבדיקת איש מקצוע',
};

export function personalSleepBaseline(state: HosState): number | null {
  const hours = state.sleep.map((s) => s.hours).filter((h): h is number => h != null);
  return average(hours);
}

export function personalFastingGlucoseBaseline(state: HosState): number | null {
  const vals = state.glucose
    .filter((g) => g.timing === 'fasting')
    .map((g) => g.value);
  return average(vals);
}

export function personalStepsBaseline(state: HosState): number | null {
  const vals = state.checkIns.map((c) => c.steps).filter((s): s is number => s != null);
  return average(vals);
}

export function buildHomeInsights(state: HosState): {
  changed: string[];
  known: string[];
  next: string[];
  patterns: PatternInsight[];
  questions: ClarifyingQuestion[];
} {
  const sleepBase = personalSleepBaseline(state);
  const gluBase = personalFastingGlucoseBaseline(state);
  const stepsBase = personalStepsBaseline(state);
  const recentSleep = filterByDays(state.sleep, 4);
  const recentGlu = filterByDays(
    state.glucose.filter((g) => g.timing === 'fasting'),
    4,
  );
  const lastSleep = [...state.sleep].sort((a, b) => b.date.localeCompare(a.date))[0];
  const lastCheck = [...state.checkIns].sort((a, b) => b.date.localeCompare(a.date))[0];

  const changed: string[] = [];
  const known: string[] = [];
  const next: string[] = [];
  const patterns: PatternInsight[] = [];
  const questions: ClarifyingQuestion[] = [];

  if (!state.sleep.length && !state.glucose.length) {
    return {
      changed: ['עדיין אין מספיק מידע.'],
      known: ['HOS לומד את «הרגיל שלך» לאורך זמן — לא רק ממוצעי אוכלוסייה.'],
      next: ['הוסיפו נתונים מהירים או טענו נתוני דמו.'],
      patterns: [],
      questions: [],
    };
  }

  if (lastSleep?.hours != null && sleepBase != null) {
    if (lastSleep.hours < sleepBase - 0.6) {
      changed.push(
        `השינה הייתה קצרה מהרגיל שלך (${lastSleep.hours.toFixed(1)} שע׳ מול ממוצע אישי ${sleepBase.toFixed(1)}).`,
      );
    } else if (lastSleep.hours > sleepBase + 0.6) {
      changed.push(`השינה הייתה ארוכה מהממוצע האישי שלך.`);
    }
    if (lastSleep.earlyAwakening) {
      changed.push('נרשמה התעוררות מוקדמת.');
      questions.push({
        id: 'q_early_wake',
        prompt:
          'התעוררת מוקדם מהרגיל. האם היו גלי חום, כאב, חרדה, צורך בשירותים, רעש, חלום, שינוי בתרופה או קושי אחר?',
        reason: 'Clarify before Interpret — חסר הקשר להתעוררות.',
      });
    }
  }

  if (lastCheck?.steps != null && stepsBase != null && lastCheck.steps < stepsBase * 0.65) {
    changed.push('רמת הפעילות נמוכה ביחס לשבועות האחרונים.');
  }

  // Pattern: short sleep days with higher morning glucose
  const paired = recentSleep
    .map((s) => {
      const g = recentGlu.find((x) => x.date === s.date);
      return s.hours != null && g ? { sleep: s.hours, glu: g.value, date: s.date } : null;
    })
    .filter(Boolean) as { sleep: number; glu: number; date: string }[];

  const shortHigh = paired.filter((p) => p.sleep < (sleepBase ?? 7) - 0.4 && p.glu > (gluBase ?? 120) + 8);
  if (shortHigh.length >= 2) {
    const body = `ערכי הסוכר בבוקר היו גבוהים יותר ב־${shortHigh.length} מתוך ${paired.length} ימים עם שינה קצרה.`;
    known.push(body);
    patterns.push({
      id: 'pat_sleep_glu',
      title: 'דפוס שינה ↔ סוכר בוקר',
      body,
      confidence: 'hypothesis',
      relatedDates: shortHigh.map((p) => p.date),
      actionHint: 'כדאי להמשיך לעקוב ולהציג את הדפוס לרופא אם הוא נמשך.',
    });
    known.push('השערה — לא אבחנה.');
    next.push('כדאי להמשיך לעקוב ולהציג את הדפוס לרופא אם הוא נמשך.');
  }

  if (lastSleep?.hotFlashes || lastSleep?.menopauseContext) {
    known.push('בהקשר השינה נרשמו גלי חום / הקשר הורמונלי אפשרי — לא אבחנה.');
    next.push('לברר עם המטפל/רופא אם הדפוס חוזר.');
  }

  if (!changed.length) {
    changed.push('אין סטייה חריגה מהרגיל שלך בנתונים האחרונים — או שעדיין אין מספיק מידע.');
  }
  if (!known.length) {
    known.push('אני רואה שינוי נקודתי, אבל לא יודע עדיין מה גורם לו.');
  }
  if (!next.length) {
    next.push('להמשיך תיעוד קצר, ולהבהיר הקשר חסר לפני פרשנות.');
  }

  return { changed, known, next, patterns, questions };
}

export function diabetesInsights(state: HosState, days: 7 | 14 | 30): PatternInsight[] {
  const sleep = filterByDays(state.sleep, days);
  const fasting = filterByDays(
    state.glucose.filter((g) => g.timing === 'fasting'),
    days,
  );
  const sleepBase = average(sleep.map((s) => s.hours).filter((h): h is number => h != null));
  const gluBase = average(fasting.map((g) => g.value));
  const out: PatternInsight[] = [];

  if (fasting.length) {
    out.push({
      id: 'd_avg',
      title: `ממוצע צום — ${days} ימים`,
      body: `ממוצע ערכי צום: ${average(fasting.map((g) => g.value))?.toFixed(0)} מ״ג/ד״ל (נתון אישי בתקופה).`,
      confidence: 'data',
    });
  }

  const shortDays = sleep.filter((s) => s.hours != null && sleepBase != null && s.hours < sleepBase - 0.5);
  const shortWithHigh = shortDays.filter((s) => {
    const g = fasting.find((x) => x.date === s.date);
    return g && gluBase != null && g.value > gluBase + 10;
  });

  if (shortWithHigh.length >= 2) {
    out.push({
      id: 'd_pattern',
      title: 'דפוס שכדאי להציג לרופא',
      body: `בימים שבהם השינה הייתה קצרה יותר נרשמו ערכי בוקר גבוהים יותר (${shortWithHigh.length} ימים). השערה — לא אבחנה. לא משנים מינון או אינסולין ללא רופא.`,
      confidence: 'professional_review',
      relatedDates: shortWithHigh.map((s) => s.date),
      actionHint: 'להכין סיכום לרופא — ללא שינוי טיפול עצמאי.',
    });
  } else if (fasting.length < 5) {
    out.push({
      id: 'd_insufficient',
      title: 'עדיין אין מספיק מידע',
      body: 'יש כמה הסברים אפשריים לערכים — נדרש מעקב נוסף לפני פרשנות.',
      confidence: 'hypothesis',
    });
  }

  return out;
}

export function sleepCauseMap(state: HosState): string[] {
  const recent = filterByDays(state.sleep, 14);
  const causes: string[] = [];
  if (recent.some((s) => s.hotFlashes || s.menopauseContext)) causes.push('גלי חום / שינוי הורמונלי אפשרי');
  if (recent.some((s) => (s.anxiety ?? 0) >= 6)) causes.push('חרדה');
  if (recent.some((s) => (s.stress ?? 0) >= 6)) causes.push('לחץ');
  if (recent.some((s) => (s.pain ?? 0) >= 4)) causes.push('כאב');
  if (recent.some((s) => s.caffeine)) causes.push('קפאין');
  if (recent.some((s) => s.medicationNote)) causes.push('תרופות / שינוי אפשרי');
  if (recent.some((s) => s.earlyAwakening)) causes.push('התעוררות מוקדמת');
  causes.push('דום נשימה בשינה (לבדיקה מקצועית אם רלוונטי)');
  causes.push('קצב צירקדי / PTSD / דיכאון — רק כשאלות לבירור, לא כאבחנה');
  return causes;
}

export function buildTimeline(state: HosState, days = 7): TimelineEvent[] {
  const events: TimelineEvent[] = [];
  const sleep = filterByDays(state.sleep, days);
  const glucose = filterByDays(state.glucose, days);
  const checks = filterByDays(state.checkIns, days);
  const notes = filterByDays(state.notes, days);

  for (const g of glucose) {
    events.push({
      id: g.id,
      date: g.date,
      time: g.time,
      kind: 'glucose',
      title: `סוכר ${g.value}`,
      detail: timingHe(g.timing) + (g.foodContext ? ` · ${g.foodContext}` : ''),
      value: `${g.value} מ״ג/ד״ל`,
    });
  }
  for (const s of sleep) {
    events.push({
      id: s.id,
      date: s.date,
      time: s.wakeTime ?? '07:00',
      kind: 'sleep',
      title: `שינה ${s.hours?.toFixed(1) ?? '—'} שע׳`,
      detail: [
        s.earlyAwakening ? 'התעוררות מוקדמת' : null,
        s.hotFlashes ? 'גלי חום' : null,
        s.awakenings ? `${s.awakenings} התעוררויות` : null,
      ]
        .filter(Boolean)
        .join(' · '),
    });
  }
  for (const c of checks) {
    events.push({
      id: c.id,
      date: c.date,
      time: '12:00',
      kind: 'checkin',
      title: 'צ׳ק־אין יומי',
      detail: `אנרגיה ${c.energy} · מצב רוח ${c.mood} · לחץ ${c.stress}`,
      value: c.steps != null ? `${c.steps} צעדים` : undefined,
    });
    if (c.medicationTaken) {
      events.push({
        id: `${c.id}_med`,
        date: c.date,
        time: '09:00',
        kind: 'medication',
        title: 'תרופות נלקחו',
        detail: c.medicationNote ?? 'ללא שינוי מינון ע״י HOS',
      });
    }
    if (c.unusualEvent) {
      events.push({
        id: `${c.id}_u`,
        date: c.date,
        time: '18:00',
        kind: 'unusual',
        title: 'אירוע חריג',
        detail: c.unusualEvent,
      });
    }
    if (c.foodContext) {
      events.push({
        id: `${c.id}_food`,
        date: c.date,
        time: '13:00',
        kind: 'food',
        title: 'הקשר מזון',
        detail: c.foodContext,
      });
    }
  }
  for (const n of notes) {
    events.push({
      id: n.id,
      date: n.date,
      time: n.time,
      kind: 'note',
      title: 'הערה',
      detail: n.text,
    });
  }

  return events.sort((a, b) => {
    const d = b.date.localeCompare(a.date);
    if (d !== 0) return d;
    return b.time.localeCompare(a.time);
  });
}

export function clinicianSummary(state: HosState, days = 14) {
  const insights = diabetesInsights(state, days as 7 | 14 | 30);
  const home = buildHomeInsights(state);
  const sleep = filterByDays(state.sleep, days);
  const fasting = filterByDays(
    state.glucose.filter((g) => g.timing === 'fasting'),
    days,
  );
  const checks = filterByDays(state.checkIns, days);

  const topPatterns = [
    ...home.patterns.map((p) => p.body),
    ...insights.filter((i) => i.confidence !== 'data').map((i) => i.body),
  ].slice(0, 3);

  while (topPatterns.length < 3) {
    topPatterns.push('עדיין אין מספיק מידע לדפוס נוסף בתקופה זו.');
  }

  const majorChanges = home.changed;
  const unresolved = home.questions.map((q) => q.prompt);
  const unusual = checks
    .filter((c) => c.unusualEvent)
    .map((c) => `${formatHeDate(c.date)}: ${c.unusualEvent}`);
  const timeline = buildTimeline(state, days).slice(0, 12);
  const medContext = checks
    .filter((c) => c.medicationNote || c.medicationTaken)
    .slice(-5)
    .map(
      (c) =>
        `${formatHeDate(c.date)}: ${c.medicationTaken ? 'נלקח' : 'לא סומן'} — ${c.medicationNote ?? 'ללא פירוט'}. HOS לא משנה מינון.`,
    );

  const questionsForClinician = [
    'האם דפוס שינה קצרה וערכי בוקר גבוהים דורש בירור נוסף?',
    'האם יש מקום לבדוק גורמי שינה (גלי חום, חרדה, כאב) לפני שינוי טיפול?',
    'אילו מדדים כדאי להדגיש במעקב בין המפגשים?',
  ];

  const text = [
    `סיכום HOS לרופא/מטפל — ${days} ימים`,
    '',
    'שלושת הדפוסים העיקריים:',
    ...topPatterns.map((p, i) => `${i + 1}. ${p}`),
    '',
    'שינויים עיקריים:',
    ...majorChanges.map((x) => `• ${x}`),
    '',
    'שאלות פתוחות:',
    ...(unresolved.length ? unresolved.map((x) => `• ${x}`) : ['• אין שאלות הבהרה פתוחות כרגע.']),
    '',
    'אירועים חריגים:',
    ...(unusual.length ? unusual.map((x) => `• ${x}`) : ['• לא נרשמו.']),
    '',
    'הקשר תרופתי (ללא המלצת שינוי מ־HOS):',
    ...(medContext.length ? medContext.map((x) => `• ${x}`) : ['• אין תיעוד.']),
    '',
    'שאלות לדיון במפגש:',
    ...questionsForClinician.map((x) => `• ${x}`),
    '',
    'ממוצע שינה:',
    `• ${average(sleep.map((s) => s.hours).filter((h): h is number => h != null))?.toFixed(1) ?? '—'} שע׳`,
    'ממוצע סוכר צום:',
    `• ${average(fasting.map((g) => g.value))?.toFixed(0) ?? '—'} מ״ג/ד״ל`,
    '',
    'HOS אינה מחליפה רופא, מטפל או רוקח. השערה — לא אבחנה.',
    'המידע נשמר במכשיר בדמו הנוכחי.',
  ].join('\n');

  return {
    topPatterns,
    majorChanges,
    unresolved,
    unusual,
    timeline,
    medContext,
    questionsForClinician,
    text,
  };
}

function timingHe(t: string): string {
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

export const ARCHITECTURE_STEPS = [
  { key: 'observe', he: 'תצפית', en: 'OBSERVE' },
  { key: 'context', he: 'הקשר', en: 'CONTEXT' },
  { key: 'clarify', he: 'הבהרה', en: 'CLARIFY' },
  { key: 'understand', he: 'הבנה', en: 'UNDERSTAND' },
  { key: 'boundary', he: 'גבול', en: 'BOUNDARY' },
  { key: 'action', he: 'פעולה', en: 'ACTION' },
  { key: 'human', he: 'אדם', en: 'HUMAN' },
] as const;

export const SIGNAL_CHAIN = [
  {
    key: 'signal',
    title: 'SIGNAL',
    he: 'מה השתנה?',
    desc: 'זיהוי שינוי ביחס לרגיל שלך.',
  },
  {
    key: 'meaning',
    title: 'MEANING',
    he: 'מה עשוי להסביר?',
    desc: 'הקשר אפשרי — לא סיבתיות רפואית אוטומטית.',
  },
  {
    key: 'boundary',
    title: 'BOUNDARY',
    he: 'מה הגבול?',
    desc: 'גבולות פרשנות והתערבות של AI.',
  },
  {
    key: 'action',
    title: 'ACTION',
    he: 'מה הצעד הבטוח?',
    desc: 'הצעד הבא השימושי — לא אבחנה ולא מרשם.',
  },
] as const;

export const SAFE_ACTIONS = [
  'להמשיך לצפות',
  'לשאול שאלה נוספת',
  'להמשיך מעקב',
  'להכין מידע',
  'לדון עם רופא/מטפל',
  'לדון עם רוקח',
  'לדון עם רב',
  'לפנות לטיפול דחוף אם יש סימני מצוקה',
] as const;

export const SAFETY_LADDER = [
  'תצפית עצמית',
  'רופא / מטפל',
  'רוקח',
  'מומחה',
  'טיפול רפואי דחוף',
] as const;
