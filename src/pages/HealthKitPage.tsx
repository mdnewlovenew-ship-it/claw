import { Layout } from '../components/Layout';

export function HealthKitPage() {
  return (
    <Layout title="HOS HealthKit Bridge">
      <section className="panel">
        <span className="badge potential">אינטגרציה עתידית</span>
        <p style={{ marginTop: 12 }}>
          אפליקציית ווב בדפדפן אינה יכולה לקרוא ישירות מ־Apple HealthKit. גשר iOS מקורי עתידי יוכל
          לייבא נתונים באישור המשתמש.
        </p>
      </section>

      <section className="panel">
        <h2>ארכיטקטורה מתוכננת</h2>
        <div className="hierarchy">
          {[
            'iPhone / Apple Watch',
            'HealthKit',
            'HOS HealthKit Bridge',
            'HOS Data Layer',
            'Personal Baseline',
            'Context Engine',
          ].map((node, i, arr) => (
            <div key={node}>
              <div className="hierarchy-node">{node}</div>
              {i < arr.length - 1 ? <div className="hierarchy-arrow">↓</div> : null}
            </div>
          ))}
        </div>
      </section>

      <section className="panel">
        <h2>מדדים פוטנציאליים</h2>
        <div className="map-steps">
          {[
            'צעדים',
            'מרחק הליכה/ריצה',
            'אנרגיה פעילה',
            'דופק',
            'אימונים',
            'שינה',
            'נתוני Apple Watch',
            'מדדי HealthKit מאושרים נוספים',
          ].map((m) => (
            <span key={m} className="map-step">
              {m}
            </span>
          ))}
        </div>
      </section>

      <section className="panel">
        <p className="small muted">
          עד אז — הזנה ידנית מהירה במסך «הוספה». פרטיות: הסכמה מפורשת, הרשאות גרנולריות, ייצוא,
          מחיקה, ושיתוף עם מטפל בשליטת המשתמש.
        </p>
      </section>
    </Layout>
  );
}
