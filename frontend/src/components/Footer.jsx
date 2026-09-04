import React from 'react';

export default function Footer({ isDark = true }) {
  return (
    <footer className={`border-t py-4 text-center text-xs transition ${
      isDark 
        ? 'bg-gray-950 border-gray-900 text-white/60' 
        : 'bg-slate-200 border-slate-300 text-slate-600'
    }`}>
      <p>© 2026 ICEIBank • Instituto de Ciências Exatas e Informática (ICEI) • PUC Minas</p>
      <p className={`text-[10px] mt-1 ${isDark ? 'text-white/40' : 'text-slate-400'}`}>
        Desenvolvido como atividade prática de Sistemas Distribuídos
      </p>
    </footer>
  );
}
