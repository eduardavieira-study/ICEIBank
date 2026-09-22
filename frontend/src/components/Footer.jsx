import React from 'react';
import { Link } from 'react-router-dom';
import Logo from './Logo';

const COLUNAS = [
  {
    titulo: 'Produto',
    links: [
      { label: 'Recursos', href: '/#recursos' },
      { label: 'Agências', href: '/#agencias' },
      { label: 'Design System', to: '/design-system' },
    ],
  },
  {
    titulo: 'Institucional',
    links: [
      { label: 'ICEI', href: 'https://www.pucminas.br' },
      { label: 'PUC Minas', href: 'https://www.pucminas.br' },
      { label: 'Sistemas Distribuídos', href: '#' },
    ],
  },
  {
    titulo: 'Acesso',
    links: [
      { label: 'Área do aluno', to: '/login' },
      { label: 'Administração', to: '/login' },
    ],
  },
];

export default function Footer() {
  return (
    <footer className="border-t surface">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-12 grid sm:grid-cols-2 lg:grid-cols-4 gap-10">
        <div>
          <Logo className="text-lg" />
          <p className="text-xs text-muted mt-3 max-w-[16rem]">
            Sistema bancário distribuído desenvolvido como atividade prática de Sistemas Distribuídos.
          </p>
        </div>

        {COLUNAS.map((coluna) => (
          <div key={coluna.titulo}>
            <p className="text-xs font-bold uppercase tracking-wider text-muted mb-3">{coluna.titulo}</p>
            <ul className="space-y-2">
              {coluna.links.map((link) => (
                <li key={link.label}>
                  {link.to ? (
                    <Link to={link.to} className="text-sm text-muted hover:text-inherit transition">
                      {link.label}
                    </Link>
                  ) : (
                    <a href={link.href} className="text-sm text-muted hover:text-inherit transition">
                      {link.label}
                    </a>
                  )}
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>

      <div className="border-t" style={{ borderColor: 'rgb(var(--border))' }}>
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-5 flex flex-col sm:flex-row items-center justify-between gap-2 text-xs text-muted">
          <p>© 2026 ICEIBank • Instituto de Ciências Exatas e Informática (ICEI) • PUC Minas</p>
          <p>Desenvolvido como atividade prática de Sistemas Distribuídos</p>
        </div>
      </div>
    </footer>
  );
}
