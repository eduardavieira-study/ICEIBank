import React from 'react';
import { User, Shield, AlertTriangle } from 'lucide-react';

export default function LoginForm({
  isAdminMode,
  setIsAdminMode,
  loginUser,
  setLoginUser,
  loginPass,
  setLoginPass,
  loginIdConta,
  setLoginIdConta,
  loginNomeAluno,
  setLoginNomeAluno,
  expirarEmSegundos,
  setExpirarEmSegundos,
  handleLogin,
  addToast,
  isDark = true
}) {
  const handleSubmit = (e) => {
    e.preventDefault();
    if (!isAdminMode) {
      if (loginIdConta === '' || !loginNomeAluno.trim()) {
        addToast('Preencha o ID da conta e o Nome do titular.', 'error');
        return;
      }
      if (parseInt(loginIdConta, 10) < 0) {
        addToast('O número da conta não pode ser negativo.', 'error');
        return;
      }
    } else {
      if (!loginUser.trim() || !loginPass) {
        addToast('Preencha o usuário e senha do admin.', 'error');
        return;
      }
    }
    handleLogin(e);
  };

  const handleIdContaChange = (e) => {
    const val = e.target.value;
    if (val === '' || (!val.includes('-') && Number(val) >= 0)) {
      setLoginIdConta(val);
    }
  };

  const blockNegativeAndDecimals = (e) => {
    if (e.key === '-' || e.key === 'e' || e.key === '+' || e.key === '.') {
      e.preventDefault();
    }
  };

  return (
    <div className={`max-w-md mx-auto rounded-lg shadow-lg border overflow-hidden mt-8 transition ${
      isDark ? 'bg-gray-950 border-gray-800' : 'bg-white border-slate-200'
    }`}>
      <div className={`bg-puc-blue p-6 text-white text-center border-b ${isDark ? 'border-gray-800' : 'border-slate-200'}`}>
        <h2 className="text-lg font-bold">Portal de Acesso ICEIBank</h2>
        <p className="text-xs text-slate-300 mt-1">Conecte-se como titular ou administrador de sistema</p>
      </div>

      <div className="p-6">
        {/* TABS ADMIN/USER */}
        <div className={`flex p-1.5 rounded-lg mb-6 ${isDark ? 'bg-gray-900' : 'bg-slate-100'}`}>
          <button
            type="button"
            onClick={() => setIsAdminMode(false)}
            className={`flex-1 flex justify-center items-center gap-2 py-2 text-xs font-semibold rounded-md transition ${
              !isAdminMode 
                ? (isDark ? 'bg-gray-800 text-white shadow' : 'bg-white text-puc-blue shadow') 
                : (isDark ? 'text-slate-500 hover:text-slate-300' : 'text-slate-500 hover:text-slate-800')
            }`}
          >
            <User size={14} />
            Área do Aluno (Titular)
          </button>
          <button
            type="button"
            onClick={() => setIsAdminMode(true)}
            className={`flex-1 flex justify-center items-center gap-2 py-2 text-xs font-semibold rounded-md transition ${
              isAdminMode 
                ? (isDark ? 'bg-gray-800 text-white shadow' : 'bg-white text-puc-blue shadow') 
                : (isDark ? 'text-slate-500 hover:text-slate-300' : 'text-slate-500 hover:text-slate-800')
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
                <label className={`block text-xs font-bold mb-1 ${isDark ? 'text-slate-100' : 'text-slate-700'}`}>
                  Nome de Usuário
                </label>
                <input 
                  type="text" 
                  value={loginUser}
                  onChange={(e) => setLoginUser(e.target.value)}
                  placeholder="admin" 
                  className={`w-full text-sm border rounded p-2 focus:ring-2 focus:ring-puc-blue focus:outline-none ${
                    isDark 
                      ? 'border-gray-800 bg-neutral-900/50 text-white' 
                      : 'border-slate-300 bg-white text-slate-900'
                  }`}
                />
              </div>
              <div>
                <label className={`block text-xs font-bold mb-1 ${isDark ? 'text-slate-100' : 'text-slate-700'}`}>
                  Senha Administrativa
                </label>
                <input 
                  type="password" 
                  value={loginPass}
                  onChange={(e) => setLoginPass(e.target.value)}
                  placeholder="••••••••" 
                  className={`w-full text-sm border rounded p-2 focus:ring-2 focus:ring-puc-blue focus:outline-none ${
                    isDark 
                      ? 'border-gray-800 bg-neutral-900/50 text-white' 
                      : 'border-slate-300 bg-white text-slate-900'
                  }`}
                />
              </div>
            </>
          ) : (
            <>
              <div>
                <label className={`block text-xs font-bold mb-1 ${isDark ? 'text-slate-100' : 'text-slate-700'}`}>
                  Número da Conta
                </label>
                <input 
                  type="number" 
                  min="0"
                  onWheel={(e) => e.currentTarget.blur()}
                  onKeyDown={blockNegativeAndDecimals}
                  value={loginIdConta}
                  onChange={handleIdContaChange}
                  placeholder="Ex: 0" 
                  className={`w-full text-sm border rounded p-2 focus:ring-2 focus:ring-puc-blue focus:outline-none ${
                    isDark 
                      ? 'border-gray-800 bg-neutral-900/50 text-white' 
                      : 'border-slate-300 bg-white text-slate-900'
                  }`}
                />
                <p className={`text-[10px] mt-0.5 ${isDark ? 'text-neutral-300' : 'text-slate-400'}`}>
                  Sua conta deve ser associada a esta agência ativa (id_conta % 3 == ID_agencia)
                </p>
              </div>
              <div>
                <label className={`block text-xs font-bold mb-1 ${isDark ? 'text-slate-100' : 'text-slate-700'}`}>
                  Nome Completo do Aluno
                </label>
                <input 
                  type="text" 
                  value={loginNomeAluno}
                  onChange={(e) => setLoginNomeAluno(e.target.value)}
                  placeholder="Ex: Ana" 
                  className={`w-full text-sm border rounded p-2 focus:ring-2 focus:ring-puc-blue focus:outline-none ${
                    isDark 
                      ? 'border-gray-800 bg-neutral-900/50 text-white' 
                      : 'border-slate-300 bg-white text-slate-900'
                  }`}
                />
              </div>
            </>
          )}

          {/* SIMULADOR DE EXPIRAÇÃO - APENAS PARA FINS DE TESTE DO SPRINT */}
          <div className={`rounded p-3 border mt-4 ${
            isDark 
              ? 'bg-amber-950/90 border-amber-900' 
              : 'bg-amber-50 border-amber-200'
          }`}>
            <span className={`block text-[11px] font-bold mb-1.5 flex items-center gap-1 ${
              isDark ? 'text-amber-100' : 'text-amber-800'
            }`}>
              <AlertTriangle size={12} />
              Configuração de Testes (Validade do Token)
            </span>
            <div className="flex items-center gap-2">
              <label className={`text-[10px] font-semibold whitespace-nowrap ${
                isDark ? 'text-amber-100' : 'text-amber-800'
              }`}>
                Tempo de expiração:
              </label>
              <select
                value={expirarEmSegundos}
                onChange={(e) => setExpirarEmSegundos(parseInt(e.target.value, 10))}
                className={`w-full text-[11px] border rounded py-0.5 px-1 focus:outline-none ${
                  isDark 
                    ? 'bg-amber-900/65 border-amber-800 text-amber-100' 
                    : 'bg-amber-100/60 border-amber-300 text-amber-900'
                }`}
              >
                <option value="1800">Padrão (30 Minutos)</option>
                <option value="5">Curto (5 Segundos)</option>
                <option value="-10">Já Expirado (-10 Segundos)</option>
              </select>
            </div>
          </div>

          <button
            type="submit"
            className={`w-full text-white font-bold py-3 rounded shadow transition text-sm mt-6 ${
              isDark 
                ? 'bg-puc-accent/50 hover:bg-puc-accent/80' 
                : 'bg-puc-blue hover:bg-blue-800'
            }`}
          >
            Entrar no Sistema
          </button>
        </form>
      </div>
    </div>
  );
}
