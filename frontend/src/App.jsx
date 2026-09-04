import React, { useState, useEffect } from 'react';

// Importando componentes modulares
import Header from './components/Header';
import LoginForm from './components/LoginForm';
import AdminPanel from './components/AdminPanel';
import StudentPanel from './components/StudentPanel';
import Footer from './components/Footer';
import ToastContainer from './components/ToastContainer';

const AGENCIAS = [
  { id: 0, nome: "Agência Central (0)", porta: 4074 },
  { id: 1, nome: "Agência Leste (1)", porta: 4075 },
  { id: 2, nome: "Agência Norte (2)", porta: 4076 }
];

export default function App() {
  // Configurações Globais (Porta Ativa)
  const [portaAgencia, setPortaAgencia] = useState(() => {
    return parseInt(localStorage.getItem('ICEIBANK_PORTA') || '4074', 10);
  });

  // Autenticação
  const [token, setToken] = useState(() => localStorage.getItem('ICEIBANK_TOKEN') || '');
  const [role, setRole] = useState(() => localStorage.getItem('ICEIBANK_ROLE') || '');
  const [idConta, setIdConta] = useState(() => parseInt(localStorage.getItem('ICEIBANK_ID_CONTA') || '0', 10));
  const [nomeAluno, setNomeAluno] = useState(() => localStorage.getItem('ICEIBANK_NOME_ALUNO') || '');

  // Dados da Conta (Modo Usuário)
  const [dadosConta, setDadosConta] = useState(null);
  const [extrato, setExtrato] = useState([]);
  const [loadingConta, setLoadingConta] = useState(false);

  // Estados dos Formulários
  const [isAdminMode, setIsAdminMode] = useState(false);
  const [loginUser, setLoginUser] = useState('');
  const [loginPass, setLoginPass] = useState('');
  const [loginIdConta, setLoginIdConta] = useState('');
  const [loginNomeAluno, setLoginNomeAluno] = useState('');
  const [expirarEmSegundos, setExpirarEmSegundos] = useState(1800);

  // Operações Aluno
  const [valorDeposito, setValorDeposito] = useState('');
  const [valorSaque, setValorSaque] = useState('');
  const [transferDestId, setTransferDestId] = useState('');
  const [transferValor, setTransferValor] = useState('');

  // Operações Admin
  const [newAccountId, setNewAccountId] = useState('');
  const [newAccountName, setNewAccountName] = useState('');
  const [newAccountBalance, setNewAccountBalance] = useState('');

  // Sistema de Toasts
  const [toasts, setToasts] = useState([]);

  // URL Base da API da agência atualmente selecionada
  const apiBaseUrl = `http://localhost:${portaAgencia}`;

  // Persistir porta selecionada
  useEffect(() => {
    localStorage.setItem('ICEIBANK_PORTA', portaAgencia.toString());
  }, [portaAgencia]);

  // Função para adicionar Toast (pop-up)
  const addToast = (mensagem, tipo = 'success') => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, mensagem, tipo }]);
    setTimeout(() => {
      removeToast(id);
    }, 5000);
  };

  const removeToast = (id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  };

  // Logout
  const handleLogout = (exibirMensagem = false) => {
    setToken('');
    setRole('');
    setIdConta(0);
    setNomeAluno('');
    setDadosConta(null);
    setExtrato([]);
    localStorage.removeItem('ICEIBANK_TOKEN');
    localStorage.removeItem('ICEIBANK_ROLE');
    localStorage.removeItem('ICEIBANK_ID_CONTA');
    localStorage.removeItem('ICEIBANK_NOME_ALUNO');
    if (exibirMensagem === true) {
      addToast('Sessão encerrada com sucesso.', 'info');
    }
  };

  // Helper para requisições com tratamento de erro global
  const fetchWithAuth = async (endpoint, options = {}) => {
    const headers = {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    try {
      const response = await fetch(`${apiBaseUrl}${endpoint}`, {
        ...options,
        headers
      });

      // Se for 401 (Não Autorizado / Expirado)
      if (response.status === 401) {
        const errData = await response.json().catch(() => ({}));
        const detail = errData.detail || 'Sessão expirada ou inválida.';
        addToast(`Erro 401: ${detail}`, 'error');
        handleLogout(false);
        throw new Error('Não autenticado.');
      }

      // Se for 403 (Proibido / Permissão Negada)
      if (response.status === 403) {
        const errData = await response.json().catch(() => ({}));
        addToast(`Erro 403: ${errData.detail || 'Você não tem permissão para esta ação.'}`, 'error');
        throw new Error('Acesso negado.');
      }

      // Se for 404 (Não Encontrado)
      if (response.status === 404) {
        const errData = await response.json().catch(() => ({}));
        addToast(`Erro 404: ${errData.detail || 'Conta ou recurso não encontrado.'}`, 'error');
        throw new Error('Não encontrado.');
      }

      // Se for 409 (Conflito - ex: conta já existe)
      if (response.status === 409) {
        const errData = await response.json().catch(() => ({}));
        addToast(`Erro 409: ${errData.detail || 'Esta conta já existe.'}`, 'error');
        throw new Error('Conflito.');
      }

      // Se for 502 (Bad Gateway - erro de conexão entre agências)
      if (response.status === 502) {
        const errData = await response.json().catch(() => ({}));
        addToast(`Erro 502: ${errData.detail || 'Erro ao contatar agência de destino.'}`, 'error');
        throw new Error('Falha na conexão externa.');
      }

      if (!response.ok) {
        const errData = await response.json().catch(() => ({}));
        const msg = errData.detail || 'Ocorreu um erro na requisição.';
        addToast(`Erro: ${msg}`, 'error');
        throw new Error(msg);
      }

      return await response.json();
    } catch (error) {
      if (error.message.includes('Failed to fetch')) {
        addToast(`Erro de conexão: A Agência selecionada na porta ${portaAgencia} está online?`, 'error');
      }
      throw error;
    }
  };

  // Login
  const handleLogin = async (e) => {
    try {
      let bodyData = {};
      if (isAdminMode) {
        bodyData = {
          usuario: loginUser,
          senha: loginPass,
          expirar_em_segundos: parseInt(expirarEmSegundos, 10)
        };
      } else {
        const idNum = parseInt(loginIdConta, 10);
        if (isNaN(idNum) || idNum < 0) {
          addToast('O número da conta deve ser um valor válido e não negativo.', 'error');
          return;
        }
        bodyData = {
          idConta: idNum,
          nomeAluno: loginNomeAluno,
          expirar_em_segundos: parseInt(expirarEmSegundos, 10)
        };
      }

      const data = await fetchWithAuth('/auth/login', {
        method: 'POST',
        body: JSON.stringify(bodyData)
      });

      // Salva no estado e localStorage
      setToken(data.token);
      setRole(data.role);
      localStorage.setItem('ICEIBANK_TOKEN', data.token);
      localStorage.setItem('ICEIBANK_ROLE', data.role);

      if (data.role === 'admin') {
        setNomeAluno('Administrador');
        localStorage.setItem('ICEIBANK_NOME_ALUNO', 'Administrador');
        addToast('Login de administrador efetuado!', 'success');
      } else {
        setIdConta(data.idConta);
        setNomeAluno(data.nomeAluno);
        localStorage.setItem('ICEIBANK_ID_CONTA', data.idConta.toString());
        localStorage.setItem('ICEIBANK_NOME_ALUNO', data.nomeAluno);
        addToast(`Bem-vindo, ${data.nomeAluno}!`, 'success');
      }

      // Reseta form
      setLoginUser('');
      setLoginPass('');
      setLoginIdConta('');
      setLoginNomeAluno('');
      setExpirarEmSegundos(1800);
    } catch (err) {}
  };

  // Buscar saldo e histórico da conta
  const carregarDadosConta = async () => {
    if (role !== 'user' || !token) return;
    setLoadingConta(true);
    try {
      const data = await fetchWithAuth(`/contas/${idConta}`);
      setDadosConta(data);
      
      const histData = await fetchWithAuth(`/contas/${idConta}/historico`);
      setExtrato(histData);
    } catch (err) {} finally {
      setLoadingConta(false);
    }
  };

  // Recarrega os dados ao logar ou mudar de agência
  useEffect(() => {
    if (token && role === 'user') {
      carregarDadosConta();
    }
  }, [token, role, portaAgencia]);

  // Depósito
  const handleDeposito = async (e) => {
    e.preventDefault();
    const valor = parseFloat(valorDeposito);
    if (isNaN(valor) || valor <= 0) {
      addToast('Informe um valor de depósito maior que zero.', 'error');
      return;
    }
    try {
      await fetchWithAuth(`/contas/${idConta}/depositar`, {
        method: 'POST',
        body: JSON.stringify({ valor: valor })
      });
      addToast(`Depósito de R$ ${valor.toFixed(2)} realizado!`, 'success');
      setValorDeposito('');
      carregarDadosConta();
    } catch (err) {}
  };

  // Saque
  const handleSaque = async (e) => {
    e.preventDefault();
    const valor = parseFloat(valorSaque);
    if (isNaN(valor) || valor <= 0) {
      addToast('Informe um valor de saque maior que zero.', 'error');
      return;
    }
    try {
      await fetchWithAuth(`/contas/${idConta}/sacar`, {
        method: 'POST',
        body: JSON.stringify({ valor: valor })
      });
      addToast(`Saque de R$ ${valor.toFixed(2)} realizado!`, 'success');
      setValorSaque('');
      carregarDadosConta();
    } catch (err) {}
  };

  // Transferência
  const handleTransferencia = async (e) => {
    e.preventDefault();
    const destId = parseInt(transferDestId, 10);
    const valor = parseFloat(transferValor);

    if (isNaN(destId) || destId < 0) {
      addToast('Informe um ID de destino válido e não negativo.', 'error');
      return;
    }
    if (isNaN(valor) || valor <= 0) {
      addToast('Informe um valor de transferência maior que zero.', 'error');
      return;
    }

    try {
      const data = await fetchWithAuth('/transferencias', {
        method: 'POST',
        body: JSON.stringify({
          idOrigem: idConta,
          idDestino: destId,
          valor: valor
        })
      });
      addToast(data.mensagem || 'Transferência efetuada com sucesso!', 'success');
      setTransferDestId('');
      setTransferValor('');
      carregarDadosConta();
    } catch (err) {}
  };

  // Criar Conta (Admin)
  const handleCriarConta = async (e) => {
    e.preventDefault();
    const accountId = parseInt(newAccountId, 10);
    const saldoInit = parseFloat(newAccountBalance || '0');

    if (isNaN(accountId) || accountId < 0) {
      addToast('Informe um ID numérico não negativo para a conta.', 'error');
      return;
    }
    if (isNaN(saldoInit) || saldoInit < 0) {
      addToast('O saldo inicial não pode ser negativo.', 'error');
      return;
    }
    if (!newAccountName.trim()) {
      addToast('Informe o nome do titular.', 'error');
      return;
    }

    try {
      await fetchWithAuth('/contas', {
        method: 'POST',
        body: JSON.stringify({
          id: accountId,
          nomeAluno: newAccountName,
          saldoInicial: saldoInit
        })
      });
      addToast(`Conta ${accountId} (titular ${newAccountName}) criada com sucesso!`, 'success');
      setNewAccountId('');
      setNewAccountName('');
      setNewAccountBalance('');
    } catch (err) {}
  };

  return (
    <div className="min-h-screen bg-black flex flex-col justify-between">
      
      {/* HEADER COMPONENTE */}
      <Header 
        portaAgencia={portaAgencia}
        setPortaAgencia={setPortaAgencia}
        agencias={AGENCIAS}
        token={token}
        handleLogout={handleLogout}
      />

      {/* ÁREA DE CONTEÚDO */}
      <main className="max-w-6xl w-full mx-auto px-4 py-8 flex-grow">
        
        {/* TELA DE LOGIN */}
        {!token && (
          <LoginForm 
            isAdminMode={isAdminMode}
            setIsAdminMode={setIsAdminMode}
            loginUser={loginUser}
            setLoginUser={setLoginUser}
            loginPass={loginPass}
            setLoginPass={setLoginPass}
            loginIdConta={loginIdConta}
            setLoginIdConta={setLoginIdConta}
            loginNomeAluno={loginNomeAluno}
            setLoginNomeAluno={setLoginNomeAluno}
            expirarEmSegundos={expirarEmSegundos}
            setExpirarEmSegundos={setExpirarEmSegundos}
            handleLogin={handleLogin}
            addToast={addToast}
          />
        )}

        {/* PAINEL DE CONTROLE - ADMINISTRADOR */}
        {token && role === 'admin' && (
          <AdminPanel 
            portaAgencia={portaAgencia}
            newAccountId={newAccountId}
            setNewAccountId={setNewAccountId}
            newAccountName={newAccountName}
            setNewAccountName={setNewAccountName}
            newAccountBalance={newAccountBalance}
            setNewAccountBalance={setNewAccountBalance}
            handleCriarConta={handleCriarConta}
          />
        )}

        {/* PAINEL DE CONTROLE - ALUNO (USER) */}
        {token && role === 'user' && (
          <StudentPanel 
            nomeAluno={nomeAluno}
            idConta={idConta}
            dadosConta={dadosConta}
            loadingConta={loadingConta}
            carregarDadosConta={carregarDadosConta}
            valorDeposito={valorDeposito}
            setValorDeposito={setValorDeposito}
            handleDeposito={handleDeposito}
            valorSaque={valorSaque}
            setValorSaque={setValorSaque}
            handleSaque={handleSaque}
            transferDestId={transferDestId}
            setTransferDestId={setTransferDestId}
            transferValor={transferValor}
            setTransferValor={setTransferValor}
            handleTransferencia={handleTransferencia}
            extrato={extrato}
          />
        )}

      </main>

      {/* FOOTER COMPONENTE */}
      <Footer />

      {/* POP-UPS / TOASTS */}
      <ToastContainer toasts={toasts} removeToast={removeToast} />

    </div>
  );
}
