import React from 'react';
import { NavLink } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { getNavItems } from '../config/navigation';

export default function BottomNav() {
  const { role } = useApp();
  const navItems = getNavItems(role);

  if (navItems.length <= 1) return null;

  return (
    <nav
      className="md:hidden fixed bottom-0 inset-x-0 z-40 surface border-t px-2 pt-1.5 pb-[calc(0.4rem+env(safe-area-inset-bottom))]"
      aria-label="Navegação principal"
    >
      <div className="grid" style={{ gridTemplateColumns: `repeat(${navItems.length}, minmax(0, 1fr))` }}>
        {navItems.map(({ path, label, icon: Icon, end }) => (
          <NavLink
            key={path}
            to={path}
            end={end}
            className="flex flex-col items-center justify-center gap-1 py-1.5 px-0.5"
          >
            {({ isActive }) => (
              <>
                <Icon size={17} className={isActive ? 'text-primary-600 dark:text-primary-300' : 'text-muted'} />
                <span className={`text-[9px] font-medium leading-tight text-center ${isActive ? 'text-primary-600 dark:text-primary-300' : 'text-muted'}`}>
                  {label}
                </span>
              </>
            )}
          </NavLink>
        ))}
      </div>
    </nav>
  );
}
