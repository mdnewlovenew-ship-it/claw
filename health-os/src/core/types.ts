export type EventKind =
  | "text"
  | "voice"
  | "image"
  | "video"
  | "sensor"
  | "health-data"
  | "document"
  | "system";

export interface HealthEvent {
  id: string;
  kind: EventKind;
  createdAt: string;
  source: {
    device?: string;
    app?: string;
    modality: EventKind;
  };
  payload: {
    text?: string;
    mediaId?: string;
    mimeType?: string;
    numeric?: {
      name: string;
      value: number;
      unit?: string;
    };
  };
  context?: {
    tags?: string[];
    note?: string;
  };
  confidence: number;
  privacy: {
    scope: "private" | "clinician-shareable" | "exportable";
  };
  derivedFrom?: string[];
  audit: {
    createdBy: "user" | "system" | "import";
    version: string;
  };
}

export interface AnalysisResult {
  id: string;
  createdAt: string;
  derivedFrom: string[];
  type: "trend" | "correlation" | "anomaly" | "summary" | "unknown";
  title: string;
  explanation: string;
  confidence: number;
  requiresClarification: boolean;
}

export interface ClarificationRequest {
  id: string;
  createdAt: string;
  question: string;
  reason: string;
  relatedEventIds: string[];
  priority: "low" | "normal" | "high";
}

export type ActionKind =
  | "none"
  | "log"
  | "reminder"
  | "coach"
  | "ask-clinician"
  | "refer";

export interface HealthAction {
  id: string;
  createdAt: string;
  kind: ActionKind;
  title: string;
  explanation: string;
  relatedEventIds: string[];
  confidence: number;
}
