import type { ConceptualAdvisor, HalachicVoice } from '../types';

/** Potential / Conceptual Advisors — NOT formal HOS team until explicitly confirmed. */
export const conceptualAdvisors: ConceptualAdvisor[] = [
  {
    id: 'yoram',
    name: 'ד״ר יורם לבנון',
    role: 'Signal / Emotion',
    principle: 'Signal',
    principleHe: 'אות',
    status: 'potential',
    chainLine: 'יורם עוזר ל־HOS לשמוע.',
    contributions: [
      'קול',
      'אותות רגשיים',
      'מאפיינים אקוסטיים',
      'שינויים בקול לאורך זמן',
      'קשר בין קול למצב רגשי',
      'גבולות ההסקה מקול',
      'הגדרת שכבת אות רגשי',
      'עיצוב ניסויים סביב קול',
    ],
  },
  {
    id: 'michal',
    name: 'ד״ר מיכל לימור',
    role: 'Meaning / Human Experience',
    principle: 'Meaning',
    principleHe: 'משמעות',
    status: 'potential',
    chainLine: 'מיכל עוזרת לה להבין.',
    contributions: [
      'חוויה אנושית',
      'קשר גוף־נפש',
      'הקשר רגשי',
      'תקשורת קלינית',
      'אי־ודאות',
      'חרדה',
      'טראומה',
      'מערכות יחסים',
      'שאילת שאלות טובות יותר',
      'הבחנה בין חוויה לפרשנות',
      'מניעת פרשנות־יתר של AI',
    ],
  },
  {
    id: 'stern',
    name: 'הרב שמואל אליעזר שטרן',
    role: 'Boundary / Halacha / Ethics',
    principle: 'Boundary',
    principleHe: 'גבול',
    status: 'potential',
    chainLine: 'הרב שטרן עוזר לה לדעת מתי לעצור.',
    contributions: [
      'גבולות הלכתיים',
      'אתיקה רפואית',
      'שאלות של סיכון',
      'פיקוח נפש',
      'אחריות',
      'פרטיות',
      'מתי מערכת אוטומטית צריכה לעצור',
      'מתי רב או מטפל אנושי חייבים להיכנס',
    ],
  },
];

export const ADVISORY_CHAIN_HE = `יורם עוזר ל־HOS לשמוע.
מיכל עוזרת לה להבין.
הרב שטרן עוזר לה לדעת מתי לעצור.`;

export const sevenHalachicVoices: HalachicVoice[] = [
  {
    id: 'yehuda',
    name: 'רבי יהודה הנשיא',
    role: 'משנה / מבנה הלכתי יסודי',
    sources: ['משנה'],
    focus: 'מבנה הלכתי יסודי',
  },
  {
    id: 'rambam',
    name: 'הרמב״ם — רבי משה בן מימון',
    role: 'ראשונים',
    sources: ['משנה תורה', 'הלכות דעות'],
    focus: 'בריאות, מניעה, שמירת הגוף והחיים',
  },
  {
    id: 'feinstein',
    name: 'הרב משה פיינשטיין',
    role: 'אחרונים / שו״ת מודרני',
    sources: ['אגרות משה'],
    focus: 'רפואה מודרנית, סיכון, טיפול, טכנולוגיה חדשה',
  },
  {
    id: 'auerbach',
    name: 'הרב שלמה זלמן אויערבאך',
    role: 'אחרונים / שו״ת מודרני',
    sources: ['מנחת שלמה'],
    focus: 'רפואה, טכנולוגיה, חשמל, ניטור והתערבות רפואית',
  },
  {
    id: 'ovadia',
    name: 'הרב עובדיה יוסף',
    role: 'אחרונים / מסורת ספרדית',
    sources: ['יביע אומר', 'יחווה דעת'],
    focus: 'השוואת מקורות רחבה ומסורת הלכתית ספרדית',
  },
  {
    id: 'weiss',
    name: 'הרב אשר וייס',
    role: 'פוסק בן־זמננו',
    sources: ['שו״ת ומאמרים בני־זמננו'],
    focus: 'רפואה, טכנולוגיות מתהוות ודילמות רפואיות־הלכתיות עכשוויות',
    living: true,
  },
  {
    id: 'stern',
    name: 'הרב שמואל אליעזר שטרן',
    role: 'סמכות רבנית חיה — ייעוץ אנושי',
    sources: ['התייעצות אנושית עכשווית'],
    focus: 'התייעצות הלכתית אנושית ויישום עכשווי',
    living: true,
  },
];

export const optionalEthicsVoice: HalachicVoice = {
  id: 'cherlow',
  name: 'הרב יובל שרלו',
  role: 'קול אתיקה חיצוני אפשרי לעתיד',
  sources: ['אתיקה רפואית עכשווית'],
  focus: 'אתיקה רפואית בת־זמננו',
  living: true,
};

export const SOURCE_HIERARCHY = [
  'משנה',
  'תלמוד',
  'ראשונים',
  'אחרונים',
  'שו״ת מודרני',
  'פוסקים בני־זמננו',
  'רב אנושי',
] as const;
