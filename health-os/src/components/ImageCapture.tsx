import { createId } from "../core/id";
import { createMediaEvent } from "../core/eventFactory";
import { putEvent, putMedia } from "../core/db";

export default function ImageCapture({ onSaved }: { onSaved: () => void }) {
  async function handleFile(file?: File) {
    if (!file) return;
    const mediaId = createId("media");
    await putMedia(mediaId, file);
    await putEvent(createMediaEvent("image", mediaId, file.type || "image/*"));
    onSaved();
  }

  return (
    <section className="card">
      <h2>תמונה</h2>
      <input
        type="file"
        accept="image/*"
        capture="environment"
        onChange={(e) => handleFile(e.target.files?.[0])}
      />
    </section>
  );
}
