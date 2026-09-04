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
  addToast
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
    <div className="max-w-md mx-auto bg-gray-950 rounded-lg shadow-2xl border border-gray-800 overflow-hidden mt-8">
      <div className="bg-puc-blue p-6 text-white text-center border-b border-gray-800">
        <h2 className="text-lg font-bold">Portal de Acesso ICEIBank</h2>
        <p className="text-xs text-slate-300 mt-1">Conecte-se como titular ou administrador de sistema</p>
      </div>

      <div className="p-6">
        {/* TABS ADMIN/USER */}
        <div className="flex bg-gray-900 p-1.5 rounded-lg mb-6 border border-gray-800">
          <button
            type="button"
            onClick={() => setIsAdminMode(false)}
            className={`flex-1 flex justify-center items-center gap-2 py-2 text-xs font-semibold rounded-md transition ${!isAdminMode ? 'bg-gray-800 text-white shadow' : 'text-slate-400 hover:text-slate-200'}`}
          >
            <User size={14} />
            Área do Aluno (Titular)
          </button>
          <button
            type="button"
            onClick={() => setIsAdminMode(true)}
            className={`flex-1 flex justify-center items-center gap-2 py-2 text-xs font-semibold rounded-md transition ${isAdminMode ? 'bg-gray-800 text-white shadow' : 'text-slate-400 hover:text-slate-200'}`}
          >
            <Shield size={14} />
            Administração
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {isAdminMode ? (
            <>
              <div>
                <label className="block text-xs font-bold text-slate-200 mb-1">Nome de Usuário</label>
                <input 
                  type="text" 
                  value={loginUser}
                  onChange={(e) => setLoginUser(e.target.value)}
                  placeholder="admin" 
                  className="w-full text-sm border border-gray-800 bg-neutral-900/60 text-white rounded p-2 focus:ring-2 focus:ring-puc-accent focus:outline-none placeholder:text-gray-600"
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-200 mb-1">Senha Administrativa</label>
                <input 
                  type="password" 
                  value={loginPass}
                  onChange={(e) => setLoginPass(e.target.value)}
                  placeholder="••••••••" 
                  className="w-full text-sm border border-gray-800 bg-neutral-900/60 text-white rounded p-2 focus:ring-2 focus:ring-puc-accent focus:outline-none placeholder:text-gray-600"
                />
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="block text-xs font-bold text-slate-200 mb-1">Número da Conta</label>
                <input 
                  type="number" 
                  min="0"
                  onWheel={(e) => e.currentTarget.blur()}
                  onKeyDown={blockNegativeAndDecimals}
                  value={loginIdConta}
                  onChange={handleIdContaChange}
                  placeholder="Ex: 0" 
                  className="w-full text-sm border border-gray-800 bg-neutral-900/60 text-white rounded p-2 focus:ring-2 focus:ring-puc-accent focus:outline-none placeholder:text-gray-600"
                />
                <p className="text-[10px] text-neutral-400 mt-1">Sua conta deve ser associada a esta agência ativa (id_conta % 3 == ID_agencia)</p>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-200 mb-1">Nome Completo do Aluno</label>
                <input 
                  type="text" 
                  value={loginNomeAluno}
                  onChange={(e) => setLoginNomeAluno(e.target.value)}
                  placeholder="Ex: Ana" 
                  className="w-full text-sm border border-gray-800 rounded bg-neutral-900/60 text-white p-2 focus:ring-2 focus:ring-puc-accent focus:outline-none placeholder:text-gray-600"
                />
              </div>
            </>
          )}

          {/* SIMULADOR DE EXPIRAÇÃO - APENAS PARA FINS DE TESTE DO SPRINT */}
          <div className="bg-amber-950/40 rounded p-3 border border-amber-900/60 mt-4">
            <span className="block text-[11px] font-bold text-orange-300/90 mb-1.5 flex items-center gap-1">
              <AlertTriangle size={12} />
              Configuração de Testes (Validade do Token)
            </span>
            <div className="flex items-center gap-2">
              <label className="text-[10px] text-amber-100 font-semibold whitespace-nowrap">Tempo de expiração:</label>
              <select
                value={expirarEmSegundos}
                onChange={(e) => setExpirarEmSegundos(parseInt(e.target.value, 10))}
                className="w-full text-[11px] bg-amber-950 border border-amber-900/70 rounded py-1 px-1.5 focus:outline-none text-amber-50"
              >
                <option value="1800">Padrão (30 Minutos)</option>
                <option value="5">Curto (5 Segundos)</option>
                <option value="-10">Já Expirado (-10 Segundos)</option>
              </select>
            </div>
          </div>

          <button
            type="submit"
            className="w-full bg-puc-accent/80 hover:bg-puc-accent text-white font-bold py-2.5 rounded shadow-lg transition text-sm mt-6"
          >
            Entrar no Sistema
          </button>
        </form>
      </div>
    </div>
  );
}
