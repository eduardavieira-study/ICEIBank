import React from 'react';
import { Sun, Moon } from 'lucide-react';
import { useApp } from '../context/AppContext';

export default function ThemeToggle({ compact = false }) {
  const { isDark, toggleTheme } = useApp();

  return (
    <button
      type="button"
      onClick={toggleTheme}
      title={isDark ? 'Ativar modo claro' : 'Ativar modo escuro'}
      className={`inline-flex items-center gap-2 rounded-md border font-semibold transition
        surface-alt hover:border-primary-400/60 text-muted hover:text-inherit
        ${compact ? 'p-2.5' : 'px-3.5 py-2.5 text-xs'}`}
    >
      {isDark ? <Sun size={16} className="text-secondary-400 shrink-0" /> : <Moon size={16} className="text-primary-600 shrink-0" />}
      {!compact && <span>{isDark ? 'Claro' : 'Escuro'}</span>}
    </button>
  );
}
