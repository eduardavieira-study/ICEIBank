import React from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowRight,
  Network,
  ShieldCheck,
  Clock3,
  ArrowRightLeft,
  Users,
  Palette,
  Menu,
  X,
  Building2,
  KeyRound,
  LayoutDashboard,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import ThemeToggle from '../components/ThemeToggle';
import Footer from '../components/Footer';
import Logo from '../components/Logo';
import BankCard from '../components/BankCard';

const FEATURES = [
  {
    icon: Network,
    title: 'Agências distribuídas',
    text: 'Três agências independentes, cada uma com seu próprio serviço, sincronizadas por rede.',
  },
  {
    icon: Clock3,
    title: 'Relógios de Lamport',
    text: 'Histórico de eventos ordenado por relógios lógicos, ideal para estudar sistemas distribuídos.',
  },
  {
    icon: ArrowRightLeft,
    title: 'Transferências locais e remotas',
    text: 'Movimentações entre contas da mesma agência ou entre agências diferentes, via rede.',
  },
  {
    icon: ShieldCheck,
    title: 'Autenticação por token',
    text: 'Acesso de alunos e administradores protegido com autenticação JWT e expiração configurável.',
  },
  {
    icon: Users,
    title: 'Painel do aluno e do admin',
    text: 'Área do titular para depósitos, saques e extrato; painel administrativo para gestão de contas.',
  },
  {
    icon: Palette,
    title: 'Tema claro & escuro',
    text: 'Interface adaptável com paleta consistente em modo claro e escuro, em qualquer tamanho de tela.',
  },
];

const PASSOS = [
  {
    icon: Building2,
    title: 'Escolha sua agência',
    text: 'Selecione a agência de entrada — Central, Leste ou Norte — de acordo com o ID da sua conta.',
  },
  {
    icon: KeyRound,
    title: 'Acesse com sua conta',
    text: 'Entre com o número da conta e seu nome, ou use as credenciais de administrador do sistema.',
  },
  {
    icon: LayoutDashboard,
    title: 'Gerencie tudo em um painel',
    text: 'Deposite, saque, transfira entre contas e acompanhe o extrato ordenado por relógios lógicos.',
  },
];

export default function LandingPage() {
  const { token } = useApp();
  const [menuOpen, setMenuOpen] = React.useState(false);

  return (
    <div style={{ backgroundColor: 'rgb(var(--bg))' }} className="min-h-screen">
      {/* NAV */}
      <header className="sticky top-0 z-40 surface border-b">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link to="/">
            <Logo className="text-lg" />
          </Link>

          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-muted">
            <a href="#recursos" className="hover:text-inherit transition">Recursos</a>
            <a href="#agencias" className="hover:text-inherit transition">Agências</a>
            <Link to="/design-system" className="hover:text-inherit transition">Design System</Link>
          </nav>

          <div className="hidden md:flex items-center gap-3">
            <ThemeToggle compact />
            <Link to={token ? '/app' : '/login'} className="btn-primary text-sm px-5 py-2.5">
              {token ? 'Ir para o painel' : 'Entrar'}
              <ArrowRight size={15} />
            </Link>
          </div>

          <button className="md:hidden p-2 -mr-2" onClick={() => setMenuOpen((v) => !v)}>
            {menuOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>

        {menuOpen && (
          <div className="md:hidden border-t px-4 py-4 space-y-3 surface">
            <a href="#recursos" onClick={() => setMenuOpen(false)} className="block text-sm font-medium py-1.5">Recursos</a>
            <a href="#agencias" onClick={() => setMenuOpen(false)} className="block text-sm font-medium py-1.5">Agências</a>
            <Link to="/design-system" onClick={() => setMenuOpen(false)} className="block text-sm font-medium py-1.5">Design System</Link>
            <div className="flex items-center gap-3 pt-2">
              <ThemeToggle />
              <Link to={token ? '/app' : '/login'} className="btn-primary flex-1 justify-center text-sm">
                {token ? 'Ir para o painel' : 'Entrar'}
              </Link>
            </div>
          </div>
        )}
      </header>

      {/* HERO */}
      <section className="max-w-6xl mx-auto px-4 sm:px-6 pt-16 sm:pt-24 pb-16 grid lg:grid-cols-2 gap-14 items-center">
        <div>
          <span className="text-xs font-semibold uppercase tracking-wider text-muted">
            ICEI • PUC Minas — Sistemas Distribuídos
          </span>
          <h1 className="font-poppins text-4xl sm:text-5xl font-bold leading-[1.1] tracking-tight mt-4 mb-5">
            Um banco distribuído, <span className="gradient-text">feito para aprender</span> de verdade.
          </h1>
          <p className="text-muted text-base sm:text-lg mb-8 max-w-lg">
            O ICEIBank simula três agências bancárias independentes que trocam eventos em rede, com autenticação segura, extrato ordenado por relógios lógicos e um painel administrativo completo.
          </p>
          <div className="flex flex-wrap items-center gap-3">
            <Link to={token ? '/app' : '/login'} className="btn-primary px-6 py-3 text-sm rounded-full">
              {token ? 'Ir para o painel' : 'Acessar minha conta'}
              <ArrowRight size={16} />
            </Link>
            <Link to="/design-system" className="btn-secondary px-6 py-3 text-sm rounded-full">
              Ver Design System
            </Link>
          </div>
        </div>

        <div className="flex justify-center lg:justify-end">
          <BankCard />
        </div>
      </section>

      {/* TIRA DE ESTATÍSTICAS */}
      <section className="border-y" style={{ borderColor: 'rgb(var(--border))' }}>
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-8 grid grid-cols-3 gap-4 text-center">
          <div>
            <p className="font-display text-2xl sm:text-3xl font-extrabold">3</p>
            <p className="text-xs text-muted mt-1">Agências distribuídas</p>
          </div>
          <div>
            <p className="font-display text-2xl sm:text-3xl font-extrabold">JWT</p>
            <p className="text-xs text-muted mt-1">Autenticação por token</p>
          </div>
          <div>
            <p className="font-display text-2xl sm:text-3xl font-extrabold">Lamport</p>
            <p className="text-xs text-muted mt-1">Extrato ordenado por relógios lógicos</p>
          </div>
        </div>
      </section>

      {/* COMO FUNCIONA */}
      <section className="max-w-6xl mx-auto px-4 sm:px-6 py-16">
        <div className="max-w-xl mb-12">
          <h2 className="font-display text-2xl sm:text-3xl font-bold mb-3">Como funciona</h2>
          <p className="text-muted text-sm">Do acesso à primeira transferência, em três passos.</p>
        </div>

        <div className="grid sm:grid-cols-3 gap-8">
          {PASSOS.map(({ icon: Icon, title, text }, idx) => (
            <div key={title} className="relative pl-12">
              <span className="absolute left-0 top-0 w-9 h-9 rounded-md bg-primary-500/10 flex items-center justify-center text-primary-600 dark:text-primary-300 font-display font-bold text-sm">
                {idx + 1}
              </span>
              <Icon size={16} className="text-muted mb-2" />
              <h3 className="font-display font-bold text-sm mb-1.5">{title}</h3>
              <p className="text-xs text-muted leading-relaxed">{text}</p>
            </div>
          ))}
        </div>
      </section>

      {/* FEATURES */}
      <section id="recursos" className="surface-alt border-y scroll-mt-20">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-16">
          <div className="max-w-xl mb-12">
            <h2 className="font-display text-2xl sm:text-3xl font-bold mb-3">Tudo que um sistema distribuído precisa</h2>
            <p className="text-muted text-sm">Recursos pensados tanto para a experiência do usuário quanto para o aprendizado de conceitos de sistemas distribuídos.</p>
          </div>

          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {FEATURES.map(({ icon: Icon, title, text }) => (
              <div key={title} className="card p-6">
                <span className="icon-tile bg-primary-500/10 mb-4">
                  <Icon size={17} className="text-primary-600 dark:text-primary-300" />
                </span>
                <h3 className="font-display font-bold text-sm mb-1.5">{title}</h3>
                <p className="text-xs text-muted leading-relaxed">{text}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* AGÊNCIAS */}
      <section id="agencias" className="scroll-mt-20">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 py-16">
          <div className="max-w-xl mb-12">
            <h2 className="font-display text-2xl sm:text-3xl font-bold mb-3">Três agências, uma só rede</h2>
            <p className="text-muted text-sm">Cada agência atende as contas cujo ID segue a mesma regra de partição, e conversa com as demais para transferências entre elas.</p>
          </div>
          <div className="grid sm:grid-cols-3 gap-5">
            {[
              { nome: 'Agência Central', id: 0, porta: 4074 },
              { nome: 'Agência Leste', id: 1, porta: 4075 },
              { nome: 'Agência Norte', id: 2, porta: 4076 },
            ].map((ag) => (
              <div key={ag.id} className="card p-6 flex flex-col items-center text-center">
                <span className="icon-tile bg-primary-500/10 mb-4">
                  <Building2 size={17} className="text-primary-600 dark:text-primary-300" />
                </span>
                <h3 className="font-display font-bold text-sm">{ag.nome}</h3>
                <p className="text-xs text-muted mt-1">Porta {ag.porta} • id_conta % 3 == {ag.id}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA FINAL */}
      <section className="max-w-6xl mx-auto px-4 sm:px-6 pb-16">
        <div className="relative overflow-hidden rounded-lg bg-brand-gradient text-white p-10 sm:p-14 text-center">
          <div className="noise-overlay" />
          <div className="relative">
            <h2 className="font-display text-2xl sm:text-3xl font-bold mb-4">Pronto para explorar o ICEIBank?</h2>
            <p className="text-white/80 max-w-md mx-auto mb-8 text-sm sm:text-base">
              Acesse com sua conta de aluno ou entre como administrador para gerenciar o sistema.
            </p>
            <Link to={token ? '/app' : '/login'} className="inline-flex items-center gap-2 bg-white text-primary-700 font-semibold text-sm px-6 py-3 rounded-full hover:bg-white/90 transition">
              {token ? 'Ir para o painel' : 'Acessar o sistema'}
              <ArrowRight size={16} />
            </Link>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
