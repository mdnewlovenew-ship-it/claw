import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { HosProvider } from './context/HosContext';
import { HomePage } from './pages/HomePage';
import { AddPage } from './pages/AddPage';
import { DiabetesPage } from './pages/DiabetesPage';
import { SleepPage } from './pages/SleepPage';
import { ClinicianPage } from './pages/ClinicianPage';
import { AdvisoryPage } from './pages/AdvisoryPage';
import { BeitMidrashPage } from './pages/BeitMidrashPage';
import { BaselinePage } from './pages/BaselinePage';
import { ContextPage } from './pages/ContextPage';
import { TimelinePage } from './pages/TimelinePage';
import { CheckInPage } from './pages/CheckInPage';
import { HealthKitPage } from './pages/HealthKitPage';
import { SettingsPage } from './pages/SettingsPage';

export default function App() {
  return (
    <HosProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/add" element={<AddPage />} />
          <Route path="/diabetes" element={<DiabetesPage />} />
          <Route path="/sleep" element={<SleepPage />} />
          <Route path="/clinician" element={<ClinicianPage />} />
          <Route path="/advisory" element={<AdvisoryPage />} />
          <Route path="/beit-midrash" element={<BeitMidrashPage />} />
          <Route path="/baseline" element={<BaselinePage />} />
          <Route path="/context" element={<ContextPage />} />
          <Route path="/timeline" element={<TimelinePage />} />
          <Route path="/checkin" element={<CheckInPage />} />
          <Route path="/healthkit" element={<HealthKitPage />} />
          <Route path="/settings" element={<SettingsPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </HosProvider>
  );
}
