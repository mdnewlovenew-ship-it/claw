import { useEffect, useState } from "react";
import type { HealthEvent } from "../core/types";
import { deleteEvent, getEvents, getMedia } from "../core/db";

export default function Timeline({
  refreshKey,
  onChanged
}: {
  refreshKey: number;
  onChanged: () => void;
}) {
  const [events, setEvents] = useState<HealthEvent[]>([]);
  const [mediaUrls, setMediaUrls] = useState<Record<string, string>>({});

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
    setMediaUrls(urls);
  }

  async function remove(id: string) {
    await deleteEvent(id);
    onChanged();
  }

  return (
    <section className="timeline">
      <div className="timelineHeader">
        <h2>Timeline</h2>
        <span>{events.length} events</span>
      </div>

      {events.map((event) => {
        const mediaId = event.payload.mediaId;
        const mediaUrl = mediaId ? mediaUrls[mediaId] : undefined;

        return (
          <article className="event" key={event.id}>
            <div className="eventTop">
              <strong>{event.kind}</strong>
              <time>{new Date(event.createdAt).toLocaleString("he-IL")}</time>
            </div>

            {event.payload.text && <p>{event.payload.text}</p>}

            {event.payload.numeric && (
              <p>
                {event.payload.numeric.name}: <strong>{event.payload.numeric.value}</strong>{" "}
                {event.payload.numeric.unit}
              </p>
            )}

            {event.kind === "voice" && mediaUrl && <audio controls src={mediaUrl} />}
            {event.kind === "video" && mediaUrl && <video controls playsInline src={mediaUrl} />}
            {event.kind === "image" && mediaUrl && <img src={mediaUrl} alt="" />}

            <details>
              <summary>Metadata</summary>
              <pre>{JSON.stringify(event, null, 2)}</pre>
            </details>

            <button className="danger" onClick={() => remove(event.id)}>
              מחק
            </button>
          </article>
        );
      })}
    </section>
  );
}
