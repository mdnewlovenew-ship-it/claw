import { useRef, useState } from "react";
import { createId } from "../core/id";
import { createMediaEvent } from "../core/eventFactory";
import { putEvent, putMedia } from "../core/db";

export default function ImageCapture({
  onSaved,
  embedded
}: {
  onSaved: (label: string) => void;
  embedded?: boolean;
}) {
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);
  const [saving, setSaving] = useState(false);

  async function handleFile(file?: File) {
    if (!file || saving) return;
    setSaving(true);
    try {
      const url = URL.createObjectURL(file);
      setPreview(url);
      const mediaId = createId("media");
      await putMedia(mediaId, file);
      await putEvent(createMediaEvent("image", mediaId, file.type || "image/*"));
      onSaved("נשמרה תמונה");
    } finally {
      setSaving(false);
    }
  }

  return (
    <section className={embedded ? "panelBody" : "card"}>
      {!embedded && <h2>תמונה</h2>}
      <p className="panelHint">גרור תמונה לכאן, או בחר מהמכשיר / מצלמה.</p>

      <div
        className={`dropzone ${dragging ? "dropzoneActive" : ""}`}
        onDragOver={(e) => {
          e.preventDefault();
          setDragging(true);
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          void handleFile(e.dataTransfer.files?.[0]);
        }}
        onClick={() => inputRef.current?.click()}
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") inputRef.current?.click();
        }}
      >
        {preview ? (
          <img src={preview} alt="" className="dropPreview" />
        ) : (
          <div>
            <strong>{saving ? "שומר…" : "שחרר כאן או לחץ לבחירה"}</strong>
            <p>JPG, PNG, HEIC</p>
          </div>
        )}
      </div>

      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        capture="environment"
        hidden
        onChange={(e) => void handleFile(e.target.files?.[0])}
      />
    </section>
  );
}
