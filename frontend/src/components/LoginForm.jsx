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
      if (!loginIdConta || !loginNomeAluno) {
        addToast('Preencha o ID da conta e o Nome do titular.', 'error');
        return;
      }
    } else {
      if (!loginUser || !loginPass) {
        addToast('Preencha o usuário e senha do admin.', 'error');
        return;
      }
    }
    handleLogin(e);
  };

  return (
    <div className="max-w-md mx-auto bg-white rounded-lg shadow-lg border border-slate-200 overflow-hidden mt-8">
      <div className="bg-puc-blue p-6 text-white text-center border-b border-slate-200">
        <h2 className="text-lg font-bold">Portal de Acesso ICEIBank</h2>
        <p className="text-xs text-slate-300 mt-1">Conecte-se como titular ou administrador de sistema</p>
      </div>

      <div className="p-6">
        {/* TABS ADMIN/USER */}
        <div className="flex bg-slate-100 p-1.5 rounded-lg mb-6">
          <button
            type="button"
            onClick={() => setIsAdminMode(false)}
            className={`flex-1 flex justify-center items-center gap-2 py-2 text-xs font-semibold rounded-md transition ${!isAdminMode ? 'bg-white text-puc-blue shadow' : 'text-slate-500 hover:text-slate-800'}`}
          >
            <User size={14} />
            Área do Aluno (Titular)
          </button>
          <button
            type="button"
            onClick={() => setIsAdminMode(true)}
            className={`flex-1 flex justify-center items-center gap-2 py-2 text-xs font-semibold rounded-md transition ${isAdminMode ? 'bg-white text-puc-blue shadow' : 'text-slate-500 hover:text-slate-800'}`}
          >
            <Shield size={14} />
            Administração
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          {isAdminMode ? (
            <>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Nome de Usuário</label>
                <input 
                  type="text" 
                  value={loginUser}
                  onChange={(e) => setLoginUser(e.target.value)}
                  placeholder="admin" 
                  className="w-full text-sm border border-slate-300 rounded p-2 focus:ring-2 focus:ring-puc-blue focus:outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Senha Administrativa</label>
                <input 
                  type="password" 
                  value={loginPass}
                  onChange={(e) => setLoginPass(e.target.value)}
                  placeholder="••••••••" 
                  className="w-full text-sm border border-slate-300 rounded p-2 focus:ring-2 focus:ring-puc-blue focus:outline-none"
                />
              </div>
            </>
          ) : (
            <>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Número da Conta</label>
                <input 
                  type="number" 
                  value={loginIdConta}
                  onChange={(e) => setLoginIdConta(e.target.value)}
                  placeholder="Ex: 0" 
                  className="w-full text-sm border border-slate-300 rounded p-2 focus:ring-2 focus:ring-puc-blue focus:outline-none"
                />
                <p className="text-[10px] text-slate-400 mt-0.5">Sua conta deve ser associada a esta agência ativa (id_conta % 3 == ID_agencia)</p>
              </div>
              <div>
                <label className="block text-xs font-bold text-slate-700 mb-1">Nome Completo do Aluno</label>
                <input 
                  type="text" 
                  value={loginNomeAluno}
                  onChange={(e) => setLoginNomeAluno(e.target.value)}
                  placeholder="Ex: Ana" 
                  className="w-full text-sm border border-slate-300 rounded p-2 focus:ring-2 focus:ring-puc-blue focus:outline-none"
                />
              </div>
            </>
          )}

          {/* SIMULADOR DE EXPIRAÇÃO - APENAS PARA FINS DE TESTE DO SPRINT */}
          <div className="bg-amber-50 rounded p-3 border border-amber-200 mt-4">
            <span className="block text-[11px] font-bold text-amber-800 mb-1.5 flex items-center gap-1">
              <AlertTriangle size={12} />
              Configuração de Testes (Validade do Token)
            </span>
            <div className="flex items-center gap-2">
              <label className="text-[10px] text-amber-800 font-semibold whitespace-nowrap">Tempo de expiração:</label>
              <select
                value={expirarEmSegundos}
                onChange={(e) => setExpirarEmSegundos(parseInt(e.target.value, 10))}
                className="w-full text-[11px] bg-white border border-amber-300 rounded py-0.5 px-1 focus:outline-none text-amber-900"
              >
                <option value="1800">Padrão (30 Minutos)</option>
                <option value="5">Curto (5 Segundos)</option>
                <option value="-10">Já Expirado (-10 Segundos)</option>
              </select>
            </div>
          </div>

          <button
            type="submit"
            className="w-full bg-puc-blue hover:bg-puc-accent text-white font-bold py-2 rounded shadow transition text-sm mt-6"
          >
            Entrar no Sistema
          </button>
        </form>
      </div>
    </div>
  );
}
