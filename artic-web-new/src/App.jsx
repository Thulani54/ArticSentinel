import { lazy, Suspense } from 'react';
import { Spinner } from './components/bits';
import { Navigate, Route, Routes } from 'react-router-dom';
import Layout from './components/Layout';
import { useAuth } from './auth';
const Login = lazy(() => import('./pages/Login'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Devices = lazy(() => import('./pages/Devices'));
const DeviceDetail = lazy(() => import('./pages/DeviceDetail'));
const Performance = lazy(() => import('./pages/Performance'));
const Units = lazy(() => import('./pages/Units'));
const Communication = lazy(() => import('./pages/Communication'));
const Alerts = lazy(() => import('./pages/Alerts'));
const Maintenance = lazy(() => import('./pages/Maintenance'));
const Reports = lazy(() => import('./pages/Reports'));
const Control = lazy(() => import('./pages/Control'));
const Access = lazy(() => import('./pages/Access'));
const Settings = lazy(() => import('./pages/Settings'));

function RequireAuth({ children }) {
  const { auth } = useAuth();
  return auth ? children : <Navigate to="/login" replace />;
}

export default function App() {
  return (
    <Suspense fallback={<Spinner />}><Routes>
      <Route
        path="/login"
        element={<Login />}
      />
      <Route
        element={
          <RequireAuth>
            <Layout />
          </RequireAuth>
        }
      >
        <Route path="/" element={<Dashboard />} />
        <Route path="/devices" element={<Devices />} />
        <Route path="/devices/:id" element={<DeviceDetail />} />
        <Route path="/performance" element={<Performance />} />
        <Route path="/units" element={<Units />} />
        <Route path="/communication" element={<Communication />} />
        <Route path="/alerts" element={<Alerts />} />
        <Route path="/maintenance" element={<Maintenance />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="/control" element={<Control />} />
        <Route path="/access" element={<Access />} />
        <Route path="/roles" element={<Access />} />
        <Route path="/settings" element={<Settings />} />
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes></Suspense>
  );
}
