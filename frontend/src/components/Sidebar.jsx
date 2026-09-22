import React from 'react';
import { Link, NavLink } from 'react-router-dom';
import { Palette, LogOut } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { getNavItems } from '../config/navigation';
import Logo from './Logo';

export default function Sidebar() {
  const { role, nomeAluno, idConta, handleLogout } = useApp();
  const navItems = getNavItems(role);

  return (
    <aside className="hidden md:flex md:flex-col md:w-60 lg:w-64 shrink-0 h-screen sticky top-0 surface border-r px-3 py-5">
      <Link to="/" className="px-2 mb-8 block">
        <Logo className="text-base" />
        <p className="text-[10px] text-muted mt-0.5">ICEI • PUC Minas</p>
      </Link>

      <div className="surface-alt rounded-md border p-3 mb-6 flex items-center gap-3">
        <div className="w-8 h-8 rounded-full bg-primary-600 flex items-center justify-center text-white font-bold text-xs shrink-0">
          {nomeAluno ? nomeAluno.charAt(0).toUpperCase() : '?'}
        </div>
        <div className="min-w-0">
          <p className="text-xs font-semibold truncate">{nomeAluno || '—'}</p>
          <p className="text-[10px] text-muted truncate">
            {role === 'admin' ? 'Administrador' : `Conta #${idConta}`}
          </p>
        </div>
      </div>

      <nav className="flex-1 space-y-0.5">
        <p className="px-2.5 text-[10px] font-bold uppercase tracking-wider text-muted mb-2">Navegação</p>
        {navItems.map(({ path, label, icon: Icon, end }) => (
          <NavLink
            key={path}
            to={path}
            end={end}
            className={({ isActive }) =>
              `flex items-center gap-3 px-2.5 py-2 rounded-md text-sm font-medium transition ${
                isActive
                  ? 'bg-primary-500/10 text-primary-700 dark:text-primary-300'
                  : 'text-muted hover:text-inherit hover:bg-primary-500/5'
              }`
            }
          >
            <Icon size={16} className="shrink-0" />
            {label}
          </NavLink>
        ))}
      </nav>

      <div className="space-y-0.5 pt-4 border-t" style={{ borderColor: 'rgb(var(--border))' }}>
        <NavLink
          to="/design-system"
          className={({ isActive }) =>
            `flex items-center gap-3 px-2.5 py-2 rounded-md text-sm font-medium transition ${
              isActive ? 'bg-primary-500/10 text-primary-700 dark:text-primary-300' : 'text-muted hover:text-inherit hover:bg-primary-500/5'
            }`
          }
        >
          <Palette size={16} className="shrink-0" />
          Design System
        </NavLink>
        <button
          onClick={() => handleLogout(true)}
          className="w-full flex items-center gap-3 px-2.5 py-2 rounded-md text-sm font-medium text-red-500 hover:bg-red-500/10 transition"
        >
          <LogOut size={16} className="shrink-0" />
          Sair
        </button>
      </div>
    </aside>
  );
}
