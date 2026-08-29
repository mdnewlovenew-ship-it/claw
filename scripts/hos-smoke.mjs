import { chromium } from 'playwright';

const out = '/opt/cursor/artifacts/screenshots';
const errors = [];
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width: 390, height: 844 },
  locale: 'he-IL',
  isMobile: true,
  hasTouch: true,
});
const page = await context.newPage();
page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
page.on('console', (msg) => {
  if (msg.type() === 'error') errors.push('console: ' + msg.text());
});

async function shot(name) {
  await page.waitForTimeout(350);
  await page.screenshot({ path: `${out}/${name}.png`, fullPage: false });
  console.log('SHOT', name, page.url());
}

await page.goto('http://127.0.0.1:5173/', { waitUntil: 'networkidle' });
await page.evaluate(() => localStorage.clear());
await page.reload({ waitUntil: 'networkidle' });
await shot('01-home');

await page.getByRole('link', { name: 'סוכרת' }).click();
await page.waitForURL('**/diabetes');
await shot('02-diabetes');

await page.getByRole('link', { name: 'שינה' }).click();
await page.waitForURL('**/sleep');
await shot('03-sleep');

await page.getByRole('link', { name: 'סיכום' }).click();
await page.waitForURL('**/clinician');
await shot('04-clinician');

await page.getByRole('link', { name: 'הוספה' }).click();
await page.waitForURL('**/add');
await page.fill('#glu', '130');
await page.getByRole('button', { name: 'שמירה במכשיר' }).click({ force: true });
await page.waitForSelector('.success-toast');
await shot('05-add-saved');

await page.getByRole('button', { name: 'תפריט' }).click();
await page.getByRole('button', { name: 'Advisory' }).click();
await page.waitForURL('**/advisory');
await shot('06-advisory');

await page.getByRole('button', { name: 'תפריט' }).click();
await page.getByRole('button', { name: 'Beit Midrash' }).click();
await page.waitForURL('**/beit-midrash');
await shot('07-beit-midrash');

await page.getByRole('button', { name: 'תפריט' }).click();
await page.getByRole('button', { name: 'Settings' }).click();
await page.waitForURL('**/settings');
await shot('08-settings');

await page.goto('http://127.0.0.1:5173/', { waitUntil: 'networkidle' });
const home = await page.locator('body').innerText();
await page.goto('http://127.0.0.1:5173/advisory', { waitUntil: 'networkidle' });
const adv = await page.locator('body').innerText();
await page.goto('http://127.0.0.1:5173/beit-midrash', { waitUntil: 'networkidle' });
const bm = await page.locator('body').innerText();
await page.goto('http://127.0.0.1:5173/settings', { waitUntil: 'networkidle' });
const settings = await page.locator('body').innerText();

const checks = {
  shortSleep: home.includes('קצרה מהרגיל') || home.includes('קצרה מהממוצע'),
  hypothesis: home.includes('השערה — לא אבחנה') || home.includes('השערה'),
  potential: adv.includes('פוטנציאלי'),
  chain: adv.includes('יורם עוזר') && adv.includes('מיכל') && adv.includes('שטרן'),
  notOfficial: adv.includes('לא כחברי צוות רשמיים'),
  demo: bm.includes('DEMO'),
  neverPsak: bm.includes('לעולם לא פולט'),
  clearDemo: settings.includes('נקה נתוני דמו'),
  privacy: settings.includes('המידע נשמר במכשיר'),
  errors,
};
console.log('CHECKS', JSON.stringify(checks, null, 2));
await browser.close();
if (errors.length || !checks.potential || !checks.chain || !checks.demo) process.exit(2);
