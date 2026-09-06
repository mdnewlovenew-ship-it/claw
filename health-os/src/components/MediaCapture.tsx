import { useRef, useState } from "react";
import { createMediaEvent } from "../core/eventFactory";
import { putEvent, putMedia } from "../core/db";
import { createId } from "../core/id";

export default function MediaCapture({
  mode,
  onSaved
}: {
  mode: "voice" | "video";
  onSaved: () => void;
}) {
  const recorderRef = useRef<MediaRecorder | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const chunksRef = useRef<BlobPart[]>([]);
  const [recording, setRecording] = useState(false);

  async function start() {
    const constraints =
      mode === "voice"
        ? { audio: true }
        : { audio: true, video: { facingMode: "user" } };

    const stream = await navigator.mediaDevices.getUserMedia(constraints);
    streamRef.current = stream;

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

      streamRef.current?.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
      onSaved();
    };

    recorder.start();
    setRecording(true);
  }

  function stop() {
    recorderRef.current?.stop();
    setRecording(false);
  }

  return (
    <section className="card">
      <h2>{mode === "voice" ? "קול" : "וידאו"}</h2>
      {!recording ? (
        <button onClick={start}>
          {mode === "voice" ? "התחל הקלטת קול" : "התחל הקלטת וידאו"}
        </button>
      ) : (
        <button onClick={stop}>עצור ושמור</button>
      )}
      <small>נשמר מקומית בלבד.</small>
    </section>
  );
}
