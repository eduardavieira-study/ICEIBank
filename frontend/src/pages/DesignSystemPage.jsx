import React from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowLeft,
  CheckCircle,
  AlertTriangle,
  Building2,
  Wallet,
  PlusCircle,
  Coins,
  ArrowRightLeft,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import ThemeToggle from '../components/ThemeToggle';
import Logo from '../components/Logo';

// Os valores abaixo espelham as cores definidas em tailwind.config.js.
// Usamos hex diretamente (em vez de classes Tailwind montadas dinamicamente,
// como `bg-primary-${shade}`) porque o compilador JIT do Tailwind não
// consegue detectar classes geradas em tempo de execução.
const PALETTES = [
  {
    name: 'Primária — Roxo',
    prefix: 'primary',
    shades: {
      50: '#F5F1FE', 100: '#EBE2FD', 200: '#D3C0FA', 300: '#B695F6', 400: '#9B6EF3',
      500: '#8146EE', 600: '#6D28D9', 700: '#5B1EB8', 800: '#481894', 900: '#37136F', 950: '#220A47',
    },
  },
  {
    name: 'Secundária — Rosa',
    prefix: 'secondary',
    shades: {
      50: '#FEF1F8', 100: '#FDE3F1', 200: '#FBC6E3', 300: '#F894CB', 400: '#F45FAF',
      500: '#EC4899', 600: '#D42E7D', 700: '#B01E64', 800: '#8F1B53', 900: '#771A48',
    },
  },
  {
    name: 'Complementar — Verde-água',
    prefix: 'accent',
    shades: {
      50: '#EDFDFA', 100: '#D2FAF3', 200: '#A9F2E6', 300: '#71E4D4', 400: '#3ECEBE',
      500: '#22B2A3', 600: '#178F85', 700: '#17726C', 800: '#185B57', 900: '#184B49',
    },
  },
];

const SEMANTIC = [
  { label: 'Sucesso', className: 'bg-accent-500' },
  { label: 'Erro', className: 'bg-red-500' },
  { label: 'Aviso', className: 'bg-amber-500' },
  { label: 'Informação', className: 'bg-primary-500' },
];

function Section({ id, title, description, children }) {
  return (
    <section id={id} className="scroll-mt-24 py-10 border-b" style={{ borderColor: 'rgb(var(--border))' }}>
      <div className="mb-6 max-w-2xl">
        <h2 className="font-display text-2xl font-bold mb-1.5">{title}</h2>
        {description && <p className="text-sm text-muted">{description}</p>}
      </div>
      {children}
    </section>
  );
}

const TOC = [
  { id: 'cores', label: 'Cores' },
  { id: 'tipografia', label: 'Tipografia' },
  { id: 'botoes', label: 'Botões' },
  { id: 'campos', label: 'Campos de formulário' },
  { id: 'badges', label: 'Badges & status' },
  { id: 'cartoes', label: 'Cartões' },
  { id: 'notificacoes', label: 'Notificações' },
];

export default function DesignSystemPage() {
  const { token, isDark } = useApp();

  return (
    <div style={{ backgroundColor: 'rgb(var(--bg))' }} className="min-h-screen">
      <header className="sticky top-0 z-40 surface border-b backdrop-blur">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-2 text-sm font-medium text-muted hover:text-inherit transition">
            <ArrowLeft size={16} />
            Voltar
          </Link>
          <div className="flex items-center gap-2">
            <Logo className="text-base" />
            <span className="text-muted text-sm">/ Design System</span>
          </div>
          <div className="flex items-center gap-3">
            <ThemeToggle compact />
            <Link to={token ? '/app' : '/login'} className="hidden sm:inline-flex btn-secondary text-xs px-4 py-2">
              {token ? 'Painel' : 'Entrar'}
            </Link>
          </div>
        </div>
      </header>

      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-10 grid lg:grid-cols-[200px_1fr] gap-10">
        {/* TOC */}
        <nav className="hidden lg:block sticky top-24 self-start space-y-1">
          <p className="text-[10px] font-bold uppercase tracking-wider text-muted mb-3 px-2">Nesta página</p>
          {TOC.map((item) => (
            <a
              key={item.id}
              href={`#${item.id}`}
              className="block px-2.5 py-2 rounded-lg text-sm text-muted hover:text-inherit hover:bg-primary-500/10 transition"
            >
              {item.label}
            </a>
          ))}
        </nav>

        <div>
          <div className="mb-4">
            <span className="badge bg-primary-500/10 text-primary-600 dark:text-primary-300">
              Modo atual: {isDark ? 'Escuro' : 'Claro'}
            </span>
          </div>
          <h1 className="font-display text-4xl font-extrabold mb-3">Design System do ICEIBank</h1>
          <p className="text-muted max-w-2xl">
            Tokens, componentes e padrões visuais usados em todo o sistema — construídos para funcionar de forma consistente tanto no modo claro quanto no escuro, em qualquer tamanho de tela.
          </p>

          {/* CORES */}
          <Section
            id="cores"
            title="Cores"
            description="Roxo como cor de marca, rosa como cor secundária de destaque e verde-água como cor complementar. Cores semânticas seguem a paleta padrão para garantir reconhecimento imediato."
          >
            <div className="space-y-8">
              {PALETTES.map((palette) => (
                <div key={palette.prefix}>
                  <h3 className="text-sm font-bold mb-3">{palette.name}</h3>
                  <div className="grid grid-cols-4 sm:grid-cols-6 lg:grid-cols-11 gap-2">
                    {Object.entries(palette.shades).map(([shade, hex]) => (
                      <div key={shade} className="text-center">
                        <div
                          className="h-14 rounded-lg border mb-1.5"
                          style={{ backgroundColor: hex, borderColor: 'rgb(var(--border))' }}
                        />
                        <span className="text-[10px] text-muted">{shade}</span>
                      </div>
                    ))}
                  </div>
                </div>
              ))}

              <div>
                <h3 className="text-sm font-bold mb-3">Cores semânticas</h3>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  {SEMANTIC.map((s) => (
                    <div key={s.label} className="card p-4 text-center">
                      <div className={`h-10 rounded-lg mb-2 ${s.className}`} />
                      <span className="text-xs font-semibold">{s.label}</span>
                    </div>
                  ))}
                </div>
              </div>

              <div>
                <h3 className="text-sm font-bold mb-3">Gradiente de marca</h3>
                <div className="h-16 rounded-md bg-brand-gradient" />
              </div>
            </div>
          </Section>

          {/* TIPOGRAFIA */}
          <Section
            id="tipografia"
            title="Tipografia"
            description="Sora para títulos e elementos de destaque (font-display), Inter para textos e interface (font-sans)."
          >
            <div className="space-y-5">
              <div>
                <h1 className="font-display text-4xl font-extrabold">Título H1 — Sora Extrabold</h1>
                <span className="text-[11px] text-muted">text-4xl · font-extrabold · font-display</span>
              </div>
              <div>
                <h2 className="font-display text-2xl font-bold">Título H2 — Sora Bold</h2>
                <span className="text-[11px] text-muted">text-2xl · font-bold · font-display</span>
              </div>
              <div>
                <h3 className="font-display text-lg font-bold">Título H3 — Sora Bold</h3>
                <span className="text-[11px] text-muted">text-lg · font-bold · font-display</span>
              </div>
              <div>
                <p className="text-base">Texto de corpo — Inter Regular, usado em parágrafos e descrições.</p>
                <span className="text-[11px] text-muted">text-base · font-sans</span>
              </div>
              <div>
                <p className="text-sm text-muted">Texto secundário / muted — usado em legendas e metadados.</p>
                <span className="text-[11px] text-muted">text-sm · text-muted</span>
              </div>
              <div>
                <p className="gradient-text font-display text-2xl font-bold">Texto com gradiente de marca</p>
                <span className="text-[11px] text-muted">.gradient-text</span>
              </div>
            </div>
          </Section>

          {/* BOTÕES */}
          <Section id="botoes" title="Botões" description="Estados e variantes utilizados em ações primárias, secundárias e destrutivas.">
            <div className="flex flex-wrap gap-3">
              <button className="btn-primary">Ação primária</button>
              <button className="btn-secondary">Ação secundária</button>
              <button className="btn text-white bg-accent-600 hover:bg-accent-700">Confirmar</button>
              <button className="btn text-white bg-secondary-500 hover:bg-secondary-600">Destacar</button>
              <button className="btn bg-red-500 text-white hover:bg-red-600">Excluir</button>
              <button className="btn-primary" disabled>Desabilitado</button>
            </div>
          </Section>

          {/* CAMPOS */}
          <Section id="campos" title="Campos de formulário" description="Inputs com estado de foco consistente, usados em login, depósito, saque e transferências.">
            <div className="grid sm:grid-cols-2 gap-4 max-w-2xl">
              <div>
                <label className="block text-[11px] font-bold mb-1.5 text-muted">Campo de texto</label>
                <input className="input-base" placeholder="Ex: Ana Beatriz" />
              </div>
              <div>
                <label className="block text-[11px] font-bold mb-1.5 text-muted">Campo numérico</label>
                <input type="number" className="input-base" placeholder="0,00" />
              </div>
              <div>
                <label className="block text-[11px] font-bold mb-1.5 text-muted">Seleção</label>
                <select className="input-base">
                  <option>Agência Central (0)</option>
                  <option>Agência Leste (1)</option>
                </select>
              </div>
              <div>
                <label className="block text-[11px] font-bold mb-1.5 text-muted">Desabilitado</label>
                <input className="input-base opacity-50 cursor-not-allowed" placeholder="Indisponível" disabled />
              </div>
            </div>
          </Section>

          {/* BADGES */}
          <Section id="badges" title="Badges & status" description="Usados para sinalizar status de transações, conexão e papéis de usuário.">
            <div className="flex flex-wrap gap-2.5">
              <span className="badge bg-accent-500/15 text-accent-600 dark:text-accent-400">Concluído</span>
              <span className="badge bg-red-500/15 text-red-500">Falhou</span>
              <span className="badge bg-amber-500/15 text-amber-600 dark:text-amber-400">Pendente</span>
              <span className="badge bg-primary-500/15 text-primary-600 dark:text-primary-300">Lamport: 12</span>
              <span className="badge bg-secondary-500/15 text-secondary-600 dark:text-secondary-300">Administrador</span>
            </div>
          </Section>

          {/* CARTÕES */}
          <Section id="cartoes" title="Cartões" description="Base de superfície usada em painéis, formulários e blocos de conteúdo.">
            <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
              <div className="card p-6">
                <h3 className="font-display font-bold text-sm mb-1.5">Cartão padrão</h3>
                <p className="text-xs text-muted">Superfície neutra com borda sutil, usada na maior parte da interface.</p>
              </div>
              <div className="card p-6">
                <span className="icon-tile bg-primary-500/10 mb-3">
                  <Wallet size={16} className="text-primary-600 dark:text-primary-300" />
                </span>
                <span className="text-xs text-muted font-semibold">Saldo Disponível</span>
                <p className="text-2xl font-display font-extrabold mt-1">R$ 4.309,02</p>
              </div>
              <div className="card p-6 flex items-center gap-3">
                <span className="icon-tile bg-primary-500/10">
                  <Building2 size={18} className="text-primary-600 dark:text-primary-300" />
                </span>
                <div>
                  <p className="text-xs text-muted">Agência</p>
                  <p className="font-bold text-sm">Central (0)</p>
                </div>
              </div>
            </div>
            <div className="grid sm:grid-cols-3 gap-4 mt-5">
              {[
                { icon: PlusCircle, label: 'Depósito', color: 'text-accent-600 dark:text-accent-400', bg: 'bg-accent-500/10' },
                { icon: Coins, label: 'Saque', color: 'text-secondary-500', bg: 'bg-secondary-500/10' },
                { icon: ArrowRightLeft, label: 'Transferência', color: 'text-primary-600 dark:text-primary-300', bg: 'bg-primary-500/10' },
              ].map(({ icon: Icon, label, color, bg }) => (
                <div key={label} className="card p-5 flex items-center gap-3">
                  <span className={`icon-tile ${bg}`}>
                    <Icon size={16} className={color} />
                  </span>
                  <span className="text-sm font-semibold">{label}</span>
                </div>
              ))}
            </div>
          </Section>

          {/* NOTIFICAÇÕES */}
          <Section id="notificacoes" title="Notificações (toasts)" description="Feedback de ações do usuário, com variação de cor por tipo de mensagem.">
            <div className="space-y-3 max-w-md">
              <div className="border rounded-md p-4 flex gap-2.5 items-start bg-accent-500/10 border-accent-500/30">
                <CheckCircle size={18} className="text-accent-500 shrink-0" />
                <p className="text-xs font-semibold text-accent-700 dark:text-accent-300">Depósito de R$ 100,00 realizado!</p>
              </div>
              <div className="border rounded-md p-4 flex gap-2.5 items-start bg-red-500/10 border-red-500/30">
                <AlertTriangle size={18} className="text-red-500 shrink-0" />
                <p className="text-xs font-semibold text-red-600 dark:text-red-300">Erro 401: Sessão expirada ou inválida.</p>
              </div>
              <div className="border rounded-md p-4 flex gap-2.5 items-start bg-primary-500/10 border-primary-500/30">
                <Building2 size={18} className="text-primary-500 shrink-0" />
                <p className="text-xs font-semibold text-primary-700 dark:text-primary-300">Sessão encerrada com sucesso.</p>
              </div>
            </div>
          </Section>
        </div>
      </div>
    </div>
  );
}
