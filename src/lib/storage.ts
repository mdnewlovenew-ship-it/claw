import type { DailyCheckIn, GlucoseReading, HosState, SleepEntry } from '../types';

const STORAGE_KEY = 'hos.mvp.v2';

export const emptyState = (): HosState => ({
  glucose: [],
  sleep: [],
  checkIns: [],
  notes: [],
  demoLoaded: false,
  onboarded: false,
});

export function loadState(): HosState {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return emptyState();
    return { ...emptyState(), ...JSON.parse(raw) } as HosState;
  } catch {
    return emptyState();
  }
}

export function saveState(state: HosState): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

export function clearState(): HosState {
  localStorage.removeItem(STORAGE_KEY);
  return emptyState();
}

export function uid(prefix = 'id'): string {
  return `${prefix}_${Math.random().toString(36).slice(2, 9)}_${Date.now().toString(36)}`;
}

export function todayISO(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function daysAgoISO(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function formatHeDate(iso: string): string {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('he-IL', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
  });
}

export function average(nums: number[]): number | null {
  if (!nums.length) return null;
  return nums.reduce((a, b) => a + b, 0) / nums.length;
}

export function filterByDays<T extends { date: string }>(items: T[], days: number): T[] {
  const cutoff = daysAgoISO(days - 1);
  return items.filter((i) => i.date >= cutoff).sort((a, b) => a.date.localeCompare(b.date));
}

export type QuickEntryInput = {
  glucose?: number;
  glucoseTiming?: GlucoseReading['timing'];
  sleepHours?: number;
  earlyAwakening?: boolean;
  energy: number;
  mood: number;
  stress: number;
  steps?: number;
  medicationTaken?: boolean;
  weight?: number;
  bloodPressureSys?: number;
  bloodPressureDia?: number;
  note?: string;
};

export function applyQuickEntry(state: HosState, input: QuickEntryInput): HosState {
  const date = todayISO();
  const time = new Date().toTimeString().slice(0, 5);
  const next: HosState = { ...state };

  if (input.glucose != null) {
    const g: GlucoseReading = {
      id: uid('glu'),
      date,
      time,
      value: input.glucose,
      timing: input.glucoseTiming ?? 'other',
      note: input.note,
    };
    next.glucose = [...state.glucose, g];
  }

  if (input.sleepHours != null) {
    const s: SleepEntry = {
      id: uid('slp'),
      date,
      hours: input.sleepHours,
      earlyAwakening: input.earlyAwakening,
      stress: input.stress,
      mood: input.mood,
      note: input.note,
    };
    next.sleep = [...state.sleep.filter((x) => x.date !== date), s];
  }

  const check: DailyCheckIn = {
    id: uid('chk'),
    date,
    energy: input.energy,
    mood: input.mood,
    stress: input.stress,
    steps: input.steps,
    medicationTaken: input.medicationTaken,
    weight: input.weight,
    bloodPressureSys: input.bloodPressureSys,
    bloodPressureDia: input.bloodPressureDia,
    note: input.note,
  };
  next.checkIns = [...state.checkIns.filter((x) => x.date !== date), check];

  if (input.note?.trim()) {
    next.notes = [
      ...state.notes,
      { id: uid('note'), date, time, text: input.note.trim() },
    ];
  }

  return next;
}
