import { useEffect } from "react";

export type ToastMessage = {
  id: string;
  text: string;
};

export default function Toast({
  message,
  onDone
}: {
  message: ToastMessage | null;
  onDone: () => void;
}) {
  useEffect(() => {
    if (!message) return;
    const t = window.setTimeout(onDone, 2400);
    return () => window.clearTimeout(t);
  }, [message, onDone]);

  if (!message) return null;

  return (
    <div className="toast" role="status" aria-live="polite">
      <span className="toastDot" />
      {message.text}
    </div>
  );
}
