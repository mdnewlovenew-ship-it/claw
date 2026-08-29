import { NavLink, useNavigate } from 'react-router-dom';
import { useState, type ReactNode } from 'react';

const MENU = [
  { to: '/baseline', label: 'Baseline' },
  { to: '/context', label: 'Context' },
  { to: '/timeline', label: 'Timeline' },
  { to: '/clinician', label: 'Clinician' },
  { to: '/advisory', label: 'Advisory' },
  { to: '/beit-midrash', label: 'Beit Midrash' },
  { to: '/healthkit', label: 'HealthKit' },
  { to: '/checkin', label: 'צ׳ק־אין' },
  { to: '/settings', label: 'Settings' },
];

const BOTTOM = [
  { to: '/', label: 'בית', glyph: '◉' },
  { to: '/add', label: 'הוספה', glyph: '+' },
  { to: '/diabetes', label: 'סוכרת', glyph: '◈' },
  { to: '/sleep', label: 'שינה', glyph: '☾' },
  { to: '/clinician', label: 'סיכום', glyph: '☰' },
];

export function Layout({ children, title }: { children: ReactNode; title?: string }) {
  const [open, setOpen] = useState(false);
  const navigate = useNavigate();

  return (
    <div className={`app-shell${open ? ' menu-open' : ''}`}>
      <header className="topbar">
        <div className="brand-lockup">
          <div className="brand-mark">HOS</div>
          <div className="brand-sub">Health Operating System</div>
        </div>
        <button
          type="button"
          className="icon-btn"
          aria-label="תפריט"
          onClick={() => setOpen(true)}
        >
          ☰
        </button>
      </header>

      <div className="privacy-chip">המידע נשמר במכשיר בדמו הנוכחי.</div>

      {title ? (
        <div style={{ marginBottom: 12 }}>
          <h1
            style={{
              fontFamily: 'var(--display)',
              fontSize: '1.55rem',
              margin: 0,
              color: 'var(--brand-deep)',
            }}
          >
            {title}
          </h1>
        </div>
      ) : null}

      {children}

      <nav className="bottom-nav" aria-label="ניווט ראשי">
        {BOTTOM.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}
          >
            <span className="glyph">{item.glyph}</span>
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      {open ? (
        <>
          <div className="drawer-backdrop" onClick={() => setOpen(false)} />
          <aside className="drawer" role="dialog" aria-label="תפריט נוסף">
            <div className="row" style={{ justifyContent: 'space-between', marginBottom: 8 }}>
              <h2>תפריט</h2>
              <button type="button" className="icon-btn" onClick={() => setOpen(false)}>
                ✕
              </button>
            </div>
            {MENU.map((item) => (
              <button
                key={item.to}
                type="button"
                className="drawer-link"
                onClick={() => {
                  setOpen(false);
                  navigate(item.to);
                }}
              >
                {item.label}
              </button>
            ))}
            <p className="small muted" style={{ marginTop: 18, lineHeight: 1.5 }}>
              HOS אינה מחליפה רופא, מטפל, רוקח או רב. אינה מאבחנת, אינה רושמת ואינה משנה מינון.
            </p>
          </aside>
        </>
      ) : null}
    </div>
  );
}
