import { useEffect, useRef, useState } from "react";
import { createMediaEvent } from "../core/eventFactory";
import { putEvent, putMedia } from "../core/db";
import { createId } from "../core/id";

export default function MediaCapture({
  mode,
  onSaved,
  embedded
}: {
  mode: "voice" | "video";
  onSaved: (label: string) => void;
  embedded?: boolean;
}) {
  const recorderRef = useRef<MediaRecorder | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const chunksRef = useRef<BlobPart[]>([]);
  const videoPreviewRef = useRef<HTMLVideoElement | null>(null);
  const [recording, setRecording] = useState(false);
  const [seconds, setSeconds] = useState(0);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!recording) {
      setSeconds(0);
      return;
    }
    const id = window.setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => window.clearInterval(id);
  }, [recording]);

  useEffect(() => {
    return () => {
      streamRef.current?.getTracks().forEach((t) => t.stop());
    };
  }, []);

  async function start() {
    setError("");
    try {
      const constraints =
        mode === "voice"
          ? { audio: true }
          : { audio: true, video: { facingMode: "user" } };

      const stream = await navigator.mediaDevices.getUserMedia(constraints);
      streamRef.current = stream;

      if (mode === "video" && videoPreviewRef.current) {
        videoPreviewRef.current.srcObject = stream;
        void videoPreviewRef.current.play();
      }

      const recorder = new MediaRecorder(stream);
      recorderRef.current = recorder;
      chunksRef.current = [];

      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };

      recorder.onstop = async () => {
        const blob = new Blob(chunksRef.current, {
          type: recorder.mimeType || (mode === "voice" ? "audio/webm" : "video/webm")
        });

        const mediaId = createId("media");
        await putMedia(mediaId, blob);
        await putEvent(createMediaEvent(mode, mediaId, blob.type));

        if (videoPreviewRef.current) {
          videoPreviewRef.current.srcObject = null;
        }
        streamRef.current?.getTracks().forEach((track) => track.stop());
        streamRef.current = null;
        onSaved(mode === "voice" ? "נשמרה הקלטת קול" : "נשמרה הקלטת וידאו");
      };

      recorder.start();
      setRecording(true);
    } catch {
      setError("אין גישה למיקרופון/מצלמה בדפדפן זה.");
    }
  }

  function stop() {
    recorderRef.current?.stop();
    setRecording(false);
  }

  const title = mode === "voice" ? "קול" : "וידאו";

  return (
    <section className={embedded ? "panelBody" : "card"}>
      {!embedded && <h2>{title}</h2>}
      <p className="panelHint">
        {mode === "voice"
          ? "הקלט הערה קולית. הקובץ נשמר מקומית בלבד."
          : "הקלט וידאו קצר עם תצוגה חיה בזמן ההקלטה."}
      </p>

      {mode === "video" && (
        <div className={`previewShell ${recording ? "previewLive" : ""}`}>
          <video ref={videoPreviewRef} muted playsInline className="previewVideo" />
          {!recording && <div className="previewPlaceholder">מצלמה תופיע כאן</div>}
        </div>
      )}

      {mode === "voice" && recording && (
        <div className="voicePulse" aria-hidden>
          <span />
          <span />
          <span />
        </div>
      )}

      <div className="panelActions">
        {!recording ? (
          <button onClick={start}>{mode === "voice" ? "התחל הקלטה" : "התחל וידאו"}</button>
        ) : (
          <button className="recordStop" onClick={stop}>
            עצור ושמור · {seconds}ש׳
          </button>
        )}
        {recording && <span className="liveBadge">REC</span>}
      </div>

      {error && <p className="errorText">{error}</p>}
      <small>נשמר מקומית בלבד.</small>
    </section>
  );
}
