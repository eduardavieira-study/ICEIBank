import React from 'react';
import { Navigate, Link, useNavigate } from 'react-router-dom';
import { ShieldCheck, Network, Clock3 } from 'lucide-react';
import { useApp } from '../context/AppContext';
import LoginForm from '../components/LoginForm';
import ThemeToggle from '../components/ThemeToggle';
import AgencySelector from '../components/AgencySelector';
import Logo from '../components/Logo';

const HIGHLIGHTS = [
  { icon: Network, text: 'Simulação de 3 agências distribuídas em rede' },
  { icon: Clock3, text: 'Histórico com relógios lógicos de Lamport' },
  { icon: ShieldCheck, text: 'Autenticação protegida por token JWT' },
];

export default function LoginPage() {
  const { token } = useApp();
  const navigate = useNavigate();

  if (token) {
    return <Navigate to="/app" replace />;
  }

  return (
    <div className="min-h-screen flex" style={{ backgroundColor: 'rgb(var(--bg))' }}>
      {/* PAINEL DE MARCA */}
      <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden bg-brand-gradient text-white p-12 flex-col justify-between">
        <div className="noise-overlay" />

        <Link to="/" className="relative">
          <Logo inverted className="text-xl" />
        </Link>

        <div className="relative space-y-6 max-w-md">
          <h1 className="font-display text-4xl font-bold leading-tight">
            Seu sistema bancário distribuído, na palma da mão.
          </h1>
          <p className="text-white/75 text-sm">
            Acesse sua conta de aluno ou o painel administrativo do ICEIBank e explore uma arquitetura real de agências distribuídas.
          </p>
          <ul className="space-y-3 pt-2">
            {HIGHLIGHTS.map(({ icon: Icon, text }) => (
              <li key={text} className="flex items-center gap-3 text-sm">
                <span className="w-8 h-8 rounded-md bg-white/10 flex items-center justify-center shrink-0">
                  <Icon size={15} />
                </span>
                {text}
              </li>
            ))}
          </ul>
        </div>

        <p className="relative text-xs text-white/60">© 2026 ICEIBank • ICEI, PUC Minas</p>
      </div>

      {/* PAINEL DE FORMULÁRIO */}
      <div className="flex-1 flex flex-col">
        <div className="flex items-center justify-between p-4 sm:p-6 gap-3">
          <Link to="/" className="lg:hidden">
            <Logo className="text-base" />
          </Link>
          <div className="flex items-center gap-2 lg:ml-auto">
            <AgencySelector />
            <ThemeToggle compact />
          </div>
        </div>

        <div className="flex-1 flex flex-col items-center justify-center px-4 sm:px-6 pb-10">
          <div className="w-full max-w-md mb-6 text-center lg:text-left">
            <h2 className="font-display text-2xl font-bold">Portal de Acesso</h2>
            <p className="text-sm text-muted mt-1">Conecte-se como titular ou administrador do sistema</p>
          </div>
          <LoginForm onSuccess={() => navigate('/app')} />
        </div>
      </div>
    </div>
  );
}
