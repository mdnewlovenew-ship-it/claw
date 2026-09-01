import type { HealthEvent } from "./types";

const DB_NAME = "health-os";
const DB_VERSION = 1;
const EVENT_STORE = "events";
const MEDIA_STORE = "media";

function openDb(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = () => {
      const db = request.result;

      if (!db.objectStoreNames.contains(EVENT_STORE)) {
        const store = db.createObjectStore(EVENT_STORE, { keyPath: "id" });
        store.createIndex("createdAt", "createdAt");
        store.createIndex("kind", "kind");
      }

      if (!db.objectStoreNames.contains(MEDIA_STORE)) {
        db.createObjectStore(MEDIA_STORE, { keyPath: "id" });
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function putEvent(event: HealthEvent): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(EVENT_STORE, "readwrite");
    tx.objectStore(EVENT_STORE).put(event);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function getEvents(): Promise<HealthEvent[]> {
  const db = await openDb();
  const result = await new Promise<HealthEvent[]>((resolve, reject) => {
    const tx = db.transaction(EVENT_STORE, "readonly");
    const request = tx.objectStore(EVENT_STORE).getAll();
    request.onsuccess = () => resolve(request.result as HealthEvent[]);
    request.onerror = () => reject(request.error);
  });
  db.close();
  return result.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export async function deleteEvent(id: string): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(EVENT_STORE, "readwrite");
    tx.objectStore(EVENT_STORE).delete(id);
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function clearAllEvents(): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(EVENT_STORE, "readwrite");
    tx.objectStore(EVENT_STORE).clear();
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function putMedia(id: string, blob: Blob): Promise<void> {
  const db = await openDb();
  await new Promise<void>((resolve, reject) => {
    const tx = db.transaction(MEDIA_STORE, "readwrite");
    tx.objectStore(MEDIA_STORE).put({ id, blob, createdAt: new Date().toISOString() });
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
  });
  db.close();
}

export async function getMedia(id: string): Promise<Blob | null> {
  const db = await openDb();
  const result = await new Promise<{ id: string; blob: Blob } | undefined>((resolve, reject) => {
    const tx = db.transaction(MEDIA_STORE, "readonly");
    const request = tx.objectStore(MEDIA_STORE).get(id);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  db.close();
  return result?.blob ?? null;
}
