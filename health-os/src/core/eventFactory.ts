import type { EventKind, HealthEvent } from "./types";
import { createId } from "./id";

export function baseEvent(kind: EventKind): HealthEvent {
  return {
    id: createId(),
    kind,
    createdAt: new Date().toISOString(),
    source: {
      device: navigator.userAgent,
      app: "Health OS Web",
      modality: kind
    },
    payload: {},
    confidence: 1,
    privacy: { scope: "private" },
    audit: { createdBy: "user", version: "0.1.0" }
  };
}

export function createTextEvent(text: string): HealthEvent {
  const event = baseEvent("text");
  event.payload.text = text.trim();
  return event;
}

export function createMetricEvent(name: string, value: number, unit?: string): HealthEvent {
  const event = baseEvent("health-data");
  event.payload.numeric = { name, value, unit };
  return event;
}

export function createMediaEvent(
  kind: "voice" | "video" | "image",
  mediaId: string,
  mimeType: string
): HealthEvent {
  const event = baseEvent(kind);
  event.payload.mediaId = mediaId;
  event.payload.mimeType = mimeType;
  return event;
}
