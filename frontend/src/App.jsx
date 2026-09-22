import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

import { AppProvider } from './context/AppContext';
import AppLayout from './layouts/AppLayout';

import LandingPage from './pages/LandingPage';
import LoginPage from './pages/LoginPage';
import DesignSystemPage from './pages/DesignSystemPage';

import Overview from './pages/app/Overview';
import Movimentacoes from './pages/app/Movimentacoes';
import Historico from './pages/app/Historico';

import ToastContainer from './components/ToastContainer';

export default function App() {
  return (
    <AppProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/design-system" element={<DesignSystemPage />} />
          <Route path="/app" element={<AppLayout />}>
            <Route index element={<Overview />} />
            <Route path="movimentacoes" element={<Movimentacoes />} />
            <Route path="historico" element={<Historico />} />
          </Route>
        </Routes>
        <ToastContainer />
      </BrowserRouter>
    </AppProvider>
  );
}
