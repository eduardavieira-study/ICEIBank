import React from 'react';
import { Navigate, Outlet } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import Sidebar from '../components/Sidebar';
import Topbar from '../components/Topbar';
import BottomNav from '../components/BottomNav';
import { getNavItems } from '../config/navigation';

export default function AppLayout() {
  const { token, role } = useApp();

  if (!token) {
    return <Navigate to="/login" replace />;
  }

  const hasBottomNav = getNavItems(role).length > 1;

  return (
    <div className="min-h-screen flex" style={{ backgroundColor: 'rgb(var(--bg))' }}>
      <Sidebar />
      <div className={`flex-1 flex flex-col min-w-0 ${hasBottomNav ? 'pb-20 md:pb-0' : ''}`}>
        <Topbar />
        <main className="flex-1 px-4 sm:px-6 py-6 max-w-5xl w-full mx-auto">
          <Outlet />
        </main>
      </div>
      <BottomNav />
    </div>
  );
}
