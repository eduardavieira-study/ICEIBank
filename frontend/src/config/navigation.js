import { LayoutDashboard, Banknote, Clock } from 'lucide-react';

export function getNavItems(role) {
  if (role === 'admin') {
    return [
      { path: '/app', label: 'Visão Geral', icon: LayoutDashboard, end: true },
    ];
  }

  return [
    { path: '/app', label: 'Visão Geral', icon: LayoutDashboard, end: true },
    { path: '/app/movimentacoes', label: 'Movimentações', icon: Banknote },
    { path: '/app/historico', label: 'Histórico', icon: Clock },
  ];
}
