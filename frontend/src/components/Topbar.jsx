import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import { LogOut } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { getNavItems } from '../config/navigation';
import AgencySelector from './AgencySelector';
import ThemeToggle from './ThemeToggle';
import Logo from './Logo';

export default function Topbar() {
  const { handleLogout, role } = useApp();
  const location = useLocation();

  const navItems = getNavItems(role);
  const current = navItems.find((item) => (item.end ? location.pathname === item.path : location.pathname.startsWith(item.path)));
  const title = current ? current.label : 'ICEIBank';

  return (
    <header className="sticky top-0 z-30 surface border-b px-4 sm:px-6 py-3.5 flex items-center justify-between gap-3">
      <Link to="/" className="md:hidden">
        <Logo className="text-sm" />
      </Link>

      <h1 className="hidden md:block font-display font-bold text-lg truncate">{title}</h1>

      <div className="flex items-center gap-2">
        <AgencySelector compact />
        <ThemeToggle compact />
        <button
          onClick={() => handleLogout(true)}
          className="md:hidden inline-flex items-center justify-center rounded-md border surface-alt p-2.5 text-red-500"
          title="Sair"
        >
          <LogOut size={16} />
        </button>
      </div>
    </header>
  );
}
