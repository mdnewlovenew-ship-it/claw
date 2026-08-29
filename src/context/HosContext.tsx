import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { buildDemoState } from '../lib/demoData';
import {
  applyQuickEntry,
  clearState,
  loadState,
  saveState,
  type QuickEntryInput,
} from '../lib/storage';
import type { HosState } from '../types';

type HosContextValue = {
  state: HosState;
  loadDemo: () => void;
  clearDemo: () => void;
  quickEntry: (input: QuickEntryInput) => void;
  setOnboarded: () => void;
  replaceState: (next: HosState) => void;
};

const HosContext = createContext<HosContextValue | null>(null);

export function HosProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<HosState>(() => {
    const loaded = loadState();
    if (!loaded.demoLoaded && !loaded.glucose.length && !loaded.checkIns.length) {
      return buildDemoState();
    }
    return loaded;
  });

  useEffect(() => {
    saveState(state);
  }, [state]);

  const loadDemo = useCallback(() => {
    setState(buildDemoState());
  }, []);

  const clearDemo = useCallback(() => {
    setState(clearState());
  }, []);

  const quickEntry = useCallback((input: QuickEntryInput) => {
    setState((prev) => applyQuickEntry(prev, input));
  }, []);

  const setOnboarded = useCallback(() => {
    setState((prev) => ({ ...prev, onboarded: true }));
  }, []);

  const replaceState = useCallback((next: HosState) => {
    setState(next);
  }, []);

  const value = useMemo(
    () => ({ state, loadDemo, clearDemo, quickEntry, setOnboarded, replaceState }),
    [state, loadDemo, clearDemo, quickEntry, setOnboarded, replaceState],
  );

  return <HosContext.Provider value={value}>{children}</HosContext.Provider>;
}

export function useHos() {
  const ctx = useContext(HosContext);
  if (!ctx) throw new Error('useHos must be used within HosProvider');
  return ctx;
}
