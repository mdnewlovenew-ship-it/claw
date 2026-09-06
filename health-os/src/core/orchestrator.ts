import type {
  AnalysisResult,
  ClarificationRequest,
  HealthAction,
  HealthEvent
} from "./types";
import { createId } from "./id";

export interface OrchestratorResult {
  analysis: AnalysisResult[];
  clarification: ClarificationRequest[];
  actions: HealthAction[];
}

export function runOrchestrator(events: HealthEvent[]): OrchestratorResult {
  const analysis: AnalysisResult[] = [];
  const clarification: ClarificationRequest[] = [];
  const actions: HealthAction[] = [];

  const numeric = events.filter((e) => e.payload.numeric);

  if (numeric.length > 1) {
    analysis.push({
      id: createId("analysis"),
      createdAt: new Date().toISOString(),
      derivedFrom: numeric.map((e) => e.id),
      type: "summary",
      title: "Numeric health data available",
      explanation: `${numeric.length} structured health measurements are available for future trend analysis.`,
      confidence: 1,
      requiresClarification: false
    });
  }

  return { analysis, clarification, actions };
}
