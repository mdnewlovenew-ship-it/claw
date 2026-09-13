import { useEffect, useState } from "react";
import type { EventKind, HealthEvent } from "../core/types";
import { deleteEvent, getEvents, getMedia } from "../core/db";

const FILTERS: { id: "all" | EventKind; label: string }[] = [
  { id: "all", label: "הכל" },
  { id: "text", label: "טקסט" },
  { id: "health-data", label: "מדדים" },
  { id: "voice", label: "קול" },
  { id: "video", label: "וידאו" },
  { id: "image", label: "תמונה" }
];

const KIND_LABEL: Record<string, string> = {
  text: "טקסט",
  "health-data": "מדד",
  voice: "קול",
  video: "וידאו",
  image: "תמונה",
  sensor: "חיישן",
  document: "מסמך",
  system: "מערכת"
};

export default function Timeline({
  refreshKey,
  onChanged,
  highlightId
}: {
  refreshKey: number;
  onChanged: () => void;
  highlightId?: string | null;
}) {
  const [events, setEvents] = useState<HealthEvent[]>([]);
  const [mediaUrls, setMediaUrls] = useState<Record<string, string>>({});
  const [filter, setFilter] = useState<"all" | EventKind>("all");
  const [expanded, setExpanded] = useState<string | null>(null);

  useEffect(() => {
    void load();
  }, [refreshKey]);

  async function load() {
    const list = await getEvents();
    setEvents(list);

    const urls: Record<string, string> = {};
    for (const event of list) {
      const mediaId = event.payload.mediaId;
      if (mediaId) {
        const blob = await getMedia(mediaId);
        if (blob) urls[mediaId] = URL.createObjectURL(blob);
      }
    }
    setMediaUrls((prev) => {
      Object.values(prev).forEach((u) => URL.revokeObjectURL(u));
      return urls;
    });
  }

  async function remove(id: string) {
    await deleteEvent(id);
    onChanged();
  }

  const filtered = filter === "all" ? events : events.filter((e) => e.kind === filter);

  return (
    <section className="timeline">
      <div className="timelineHeader">
        <div>
          <h2>Timeline</h2>
          <p className="timelineSub">{events.length} אירועים מקומיים</p>
        </div>
        <div className="countBubble" aria-live="polite">
          {filtered.length}
        </div>
      </div>

      <div className="filterRow" role="tablist" aria-label="סינון טיימליין">
        {FILTERS.map((f) => (
          <button
            key={f.id}
            type="button"
            role="tab"
            aria-selected={filter === f.id}
            className={`filterChip ${filter === f.id ? "filterActive" : ""}`}
            onClick={() => setFilter(f.id)}
          >
            {f.label}
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <div className="emptyState">
          <strong>עדיין אין אירועים כאן</strong>
          <p>שמור טקסט, מדד או מדיה — והם יופיעו מיד בטיימליין.</p>
        </div>
      ) : (
        filtered.map((event, index) => {
          const mediaId = event.payload.mediaId;
          const mediaUrl = mediaId ? mediaUrls[mediaId] : undefined;
          const isOpen = expanded === event.id;
          const isNew = highlightId === event.id;

          return (
            <article
              className={`event ${isNew ? "eventNew" : ""}`}
              key={event.id}
              style={{ animationDelay: `${Math.min(index, 8) * 40}ms` }}
            >
              <button
                type="button"
                className="eventHit"
                onClick={() => setExpanded(isOpen ? null : event.id)}
              >
                <div className="eventTop">
                  <span className={`kindTag kind-${event.kind}`}>
                    {KIND_LABEL[event.kind] ?? event.kind}
                  </span>
                  <time>{new Date(event.createdAt).toLocaleString("he-IL")}</time>
                </div>

                {event.payload.text && <p className="eventBody">{event.payload.text}</p>}

                {event.payload.numeric && (
                  <p className="eventMetric">
                    <span>{event.payload.numeric.name}</span>
                    <strong>
                      {event.payload.numeric.value}
                      {event.payload.numeric.unit ? ` ${event.payload.numeric.unit}` : ""}
                    </strong>
                  </p>
                )}

                {event.kind === "image" && mediaUrl && (
                  <img src={mediaUrl} alt="" className="eventThumb" />
                )}
                {event.kind === "voice" && <p className="eventBody">הקלטה קולית · לחץ לפתיחה</p>}
                {event.kind === "video" && <p className="eventBody">הקלטת וידאו · לחץ לפתיחה</p>}
              </button>

              {isOpen && (
                <div className="eventDetails">
                  {event.kind === "voice" && mediaUrl && <audio controls src={mediaUrl} />}
                  {event.kind === "video" && mediaUrl && (
                    <video controls playsInline src={mediaUrl} />
                  )}
                  {event.kind === "image" && mediaUrl && <img src={mediaUrl} alt="" />}

                  <details>
                    <summary>Metadata</summary>
                    <pre>{JSON.stringify(event, null, 2)}</pre>
                  </details>

                  <button className="danger" onClick={() => void remove(event.id)}>
                    מחק אירוע
                  </button>
                </div>
              )}
            </article>
          );
        })
      )}
    </section>
  );
}
