import React from 'react';
import { User, Shield, AlertTriangle, ArrowRight } from 'lucide-react';
import { useApp } from '../context/AppContext';
import PasswordInput from './PasswordInput';

export default function LoginForm({ onSuccess }) {
  const {
    isAdminMode,
    setIsAdminMode,
    loginUser,
    setLoginUser,
    loginPass,
    setLoginPass,
    loginNomeAluno,
    setLoginNomeAluno,
    loginSenhaAluno,
    setLoginSenhaAluno,
    expirarEmSegundos,
    setExpirarEmSegundos,
    handleLogin,
    addToast,
  } = useApp();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!isAdminMode) {
      if (!loginNomeAluno.trim() || !loginSenhaAluno) {
        addToast('Preencha o nome do aluno e a senha.', 'error');
        return;
      }
    } else {
      if (!loginUser.trim() || !loginPass) {
        addToast('Preencha o usuário e senha do admin.', 'error');
        return;
      }
    }
    const success = await handleLogin(e);
    if (success && onSuccess) onSuccess();
  };

  return (
    <div className="w-full max-w-md">
      <div className="flex p-1 rounded-full mb-6 surface-alt border">
        <button
          type="button"
          onClick={() => setIsAdminMode(false)}
          className={`flex-1 flex justify-center items-center gap-2 py-3 text-xs font-semibold rounded-full transition ${
            !isAdminMode ? 'bg-primary-600 text-white' : 'text-muted hover:text-inherit'
          }`}
        >
          <User size={14} />
          Área do Aluno
        </button>
        <button
          type="button"
          onClick={() => setIsAdminMode(true)}
          className={`flex-1 flex justify-center items-center gap-2 py-3 text-xs font-semibold rounded-full transition ${
            isAdminMode ? 'bg-primary-600 text-white' : 'text-muted hover:text-inherit'
          }`}
        >
          <Shield size={14} />
          Administração
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {isAdminMode ? (
          <>
            <div>
              <label className="block text-xs font-bold mb-1.5">Nome de Usuário</label>
              <input
                type="text"
                value={loginUser}
                onChange={(e) => setLoginUser(e.target.value)}
                placeholder="admin"
                className="input-base rounded-full"
              />
            </div>
            <div>
              <label className="block text-xs font-bold mb-1.5">Senha Administrativa</label>
              <PasswordInput
                value={loginPass}
                onChange={(e) => setLoginPass(e.target.value)}
                placeholder="••••••••"
                className="input-base rounded-full"
              />
            </div>
          </>
        ) : (
          <>
            <div>
              <label className="block text-xs font-bold mb-1.5">Nome do Aluno</label>
              <input
                type="text"
                value={loginNomeAluno}
                onChange={(e) => setLoginNomeAluno(e.target.value)}
                placeholder="Ex: Ana"
                autoComplete="username"
                className="input-base rounded-full"
              />
              <p className="text-[10px] mt-1 text-muted">
                Escolha no topo da página a agência onde sua conta foi cadastrada.
              </p>
            </div>
            <div>
              <label className="block text-xs font-bold mb-1.5">Senha</label>
              <PasswordInput
                value={loginSenhaAluno}
                onChange={(e) => setLoginSenhaAluno(e.target.value)}
                placeholder="••••••••"
                className="input-base rounded-full"
              />
            </div>
          </>
        )}

        <div className="rounded-md p-3.5 border bg-amber-500/10 border-amber-500/30">
          <span className="flex items-center gap-1.5 text-[11px] font-bold mb-1.5 text-amber-600 dark:text-amber-300">
            <AlertTriangle size={12} />
            Configuração de Testes (Validade do Token)
          </span>
          <div className="flex items-center gap-2">
            <label className="text-[10px] font-semibold whitespace-nowrap text-amber-700 dark:text-amber-200">
              Tempo de expiração:
            </label>
            <select
              value={expirarEmSegundos}
              onChange={(e) => setExpirarEmSegundos(parseInt(e.target.value, 10))}
              className="w-full text-[11px] rounded-md py-1 px-1.5 outline-none bg-transparent border border-amber-500/30 text-amber-700 dark:text-amber-200"
            >
              <option value="1800" className="text-slate-900">Padrão (30 Minutos)</option>
              <option value="5" className="text-slate-900">Curto (5 Segundos)</option>
              <option value="-10" className="text-slate-900">Já Expirado (-10 Segundos)</option>
            </select>
          </div>
        </div>

        <button type="submit" className="btn-primary w-full py-4 mt-2 rounded-full">
          Entrar no Sistema
          <ArrowRight size={15} />
        </button>
      </form>
    </div>
  );
}
