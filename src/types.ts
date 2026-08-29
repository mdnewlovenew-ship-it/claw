export type ConfidenceLevel =
  | 'data'
  | 'pattern'
  | 'hypothesis'
  | 'concern'
  | 'professional_review';

export type GlucoseTiming =
  | 'fasting'
  | 'pre_meal'
  | 'post_meal'
  | 'bedtime'
  | 'other';

export interface GlucoseReading {
  id: string;
  date: string; // YYYY-MM-DD
  time: string; // HH:mm
  value: number;
  timing: GlucoseTiming;
  foodContext?: string;
  note?: string;
}

export interface SleepEntry {
  id: string;
  date: string;
  bedtime?: string;
  sleepOnsetMinutes?: number;
  awakenings?: number;
  earlyAwakening?: boolean;
  couldFallAsleepAgain?: boolean;
  wakeTime?: string;
  hours?: number;
  daytimeFatigue?: number; // 1-10
  hotFlashes?: boolean;
  nightSweats?: boolean;
  menopauseContext?: boolean;
  pain?: number;
  anxiety?: number;
  stress?: number;
  mood?: number;
  caffeine?: boolean;
  medicationNote?: string;
  activityNote?: string;
  glucoseRelevant?: boolean;
  note?: string;
}

export interface DailyCheckIn {
  id: string;
  date: string;
  energy: number;
  mood: number;
  stress: number;
  anxiety?: number;
  pain?: number;
  steps?: number;
  activityNote?: string;
  medicationTaken?: boolean;
  medicationNote?: string;
  weight?: number;
  bloodPressureSys?: number;
  bloodPressureDia?: number;
  caffeine?: boolean;
  illness?: boolean;
  unusualEvent?: string;
  foodContext?: string;
  note?: string;
}

export interface TimelineEvent {
  id: string;
  date: string;
  time: string;
  kind:
    | 'glucose'
    | 'sleep'
    | 'mood'
    | 'activity'
    | 'medication'
    | 'food'
    | 'note'
    | 'checkin'
    | 'unusual';
  title: string;
  detail?: string;
  value?: string;
}

export interface HosState {
  glucose: GlucoseReading[];
  sleep: SleepEntry[];
  checkIns: DailyCheckIn[];
  notes: { id: string; date: string; time: string; text: string }[];
  demoLoaded: boolean;
  onboarded: boolean;
}

export interface PatternInsight {
  id: string;
  title: string;
  body: string;
  confidence: ConfidenceLevel;
  relatedDates?: string[];
  actionHint?: string;
}

export interface ClarifyingQuestion {
  id: string;
  prompt: string;
  reason: string;
}

export type AdvisorStatus = 'potential' | 'confirmed';

export interface ConceptualAdvisor {
  id: string;
  name: string;
  role: string;
  principle: string;
  principleHe: string;
  contributions: string[];
  status: AdvisorStatus;
  chainLine: string;
}

export interface HalachicVoice {
  id: string;
  name: string;
  role: string;
  sources: string[];
  focus: string;
  living?: boolean;
}

export interface BeitMidrashCase {
  id: string;
  title: string;
  isDemo: boolean;
  question: string;
  mapSteps: string[];
  principles: string[];
  uncertaintyNotes: string[];
  neverSay: string[];
}
