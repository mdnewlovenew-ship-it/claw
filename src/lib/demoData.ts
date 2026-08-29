import type { DailyCheckIn, GlucoseReading, HosState, SleepEntry } from '../types';
import { daysAgoISO, uid } from './storage';

/** Realistic fictional demo spanning 14 days. Clearly fictional. */
export function buildDemoState(): HosState {
  const glucose: GlucoseReading[] = [];
  const sleep: SleepEntry[] = [];
  const checkIns: DailyCheckIn[] = [];
  const notes: HosState['notes'] = [];

  // Pattern: shorter sleep → higher morning glucose on several days
  // Most recent days intentionally short+high so Home tells the story.
  const sleepHours = [7.4, 5.8, 7.1, 6.0, 7.8, 5.5, 7.2, 6.1, 7.5, 5.9, 7.0, 5.7, 6.0, 5.8];
  const morningGlu = [118, 148, 122, 139, 115, 155, 120, 144, 116, 151, 124, 149, 146, 152];
  const energy = [7, 4, 7, 5, 8, 3, 7, 5, 8, 4, 6, 4, 5, 4];
  const mood = [7, 4, 6, 5, 8, 3, 7, 5, 7, 4, 6, 4, 5, 4];
  const stress = [4, 7, 4, 6, 3, 8, 4, 6, 3, 7, 5, 7, 6, 7];
  const steps = [7800, 3100, 8500, 5100, 9200, 2800, 8000, 4500, 8800, 3600, 7200, 3400, 4100, 3900];

  for (let i = 13; i >= 0; i--) {
    const date = daysAgoISO(i);
    const idx = 13 - i;
    const shortSleep = sleepHours[idx] < 6.5;

    sleep.push({
      id: uid('slp'),
      date,
      bedtime: shortSleep ? '00:40' : '23:15',
      sleepOnsetMinutes: shortSleep ? 45 : 20,
      awakenings: shortSleep ? 2 + (idx % 2) : 1,
      earlyAwakening: shortSleep,
      couldFallAsleepAgain: !shortSleep,
      wakeTime: shortSleep ? '05:50' : '06:40',
      hours: sleepHours[idx],
      daytimeFatigue: shortSleep ? 7 : 4,
      hotFlashes: idx === 2 || idx === 6 || idx === 10,
      nightSweats: idx === 6,
      menopauseContext: idx === 2 || idx === 6 || idx === 10,
      pain: shortSleep ? 4 : 2,
      anxiety: stress[idx],
      stress: stress[idx],
      mood: mood[idx],
      caffeine: idx % 3 === 0,
      note: shortSleep
        ? 'התעוררות מוקדמת. עדיין לא ברור מה גרם.'
        : undefined,
    });

    glucose.push({
      id: uid('glu'),
      date,
      time: '07:15',
      value: morningGlu[idx],
      timing: 'fasting',
      foodContext: 'צום',
    });

    glucose.push({
      id: uid('glu'),
      date,
      time: '13:30',
      value: 110 + (idx % 5) * 8 + (shortSleep ? 12 : 0),
      timing: 'post_meal',
      foodContext: idx % 2 === 0 ? 'ארוחת צהריים עם פחמימות' : 'ארוחה מאוזנת',
    });

    if (idx % 2 === 0) {
      glucose.push({
        id: uid('glu'),
        date,
        time: '22:00',
        value: 105 + (idx % 4) * 6,
        timing: 'bedtime',
      });
    }

    checkIns.push({
      id: uid('chk'),
      date,
      energy: energy[idx],
      mood: mood[idx],
      stress: stress[idx],
      anxiety: Math.min(10, stress[idx] + (shortSleep ? 1 : 0)),
      pain: shortSleep ? 3 : 1,
      steps: steps[idx],
      activityNote: steps[idx] > 7000 ? 'הליכה / פעילות' : 'יום שקט יותר',
      medicationTaken: true,
      medicationNote: 'תרופות כרגיל — ללא שינוי מינון',
      weight: 72.4 + (idx % 3) * 0.2,
      caffeine: idx % 3 === 0,
      unusualEvent:
        idx === 6
          ? 'לילה סוער — התעוררות מוקדמת עם גלי חום'
          : idx === 10
            ? 'יום עמוס ולחץ בעבודה'
            : undefined,
      foodContext: idx % 2 === 0 ? 'יותר פחמימות בצהריים' : undefined,
      note: shortSleep ? 'עייפות ביום' : undefined,
    });

    if (shortSleep) {
      notes.push({
        id: uid('note'),
        date,
        time: '06:10',
        text: 'התעוררתי מוקדם מהרגיל. ייתכן גלי חום / חרדה / רעש — צריך להבהיר.',
      });
    }
  }

  notes.push({
    id: uid('note'),
    date: daysAgoISO(1),
    time: '20:40',
    text: 'DEMO — נתונים בדיוניים למטרות הדגמה בלבד.',
  });

  return {
    glucose,
    sleep,
    checkIns,
    notes,
    demoLoaded: true,
    onboarded: true,
  };
}
