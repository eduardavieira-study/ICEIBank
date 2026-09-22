import React, { createContext, useContext, useState, useEffect } from 'react';

const AGENCIAS = [
  { id: 0, nome: "Agência Central (0)", porta: 4074 },
  { id: 1, nome: "Agência Leste (1)", porta: 4075 },
  { id: 2, nome: "Agência Norte (2)", porta: 4076 }
];

const AppContext = createContext(null);

export function AppProvider({ children }) {
  // Tema Claro / Escuro (Padrão: Escuro conforme preferência)
  const [theme, setTheme] = useState(() => {
    return localStorage.getItem('ICEIBANK_THEME') || 'dark';
  });

  const isDark = theme === 'dark';

  const toggleTheme = () => {
    setTheme(prev => {
      const next = prev === 'dark' ? 'light' : 'dark';
      localStorage.setItem('ICEIBANK_THEME', next);
      return next;
    });
  };

  useEffect(() => {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [theme]);

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

  // Estados dos Formulários de Login
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

  const addToast = (mensagem, tipo = 'success') => {
    const id = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
    setToasts(prev => [...prev, { id, mensagem, tipo }]);
    setTimeout(() => {
      removeToast(id);
    }, 5000);
  };

  const removeToast = (id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  };

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

      if (response.status === 401) {
        const errData = await response.json().catch(() => ({}));
        const detail = errData.detail || 'Sessão expirada ou inválida.';
        addToast(`Erro 401: ${detail}`, 'error');
        handleLogout(false);
        throw new Error('Não autenticado.');
      }

      if (response.status === 403) {
        const errData = await response.json().catch(() => ({}));
        addToast(`Erro 403: ${errData.detail || 'Você não tem permissão para esta ação.'}`, 'error');
        throw new Error('Acesso negado.');
      }

      if (response.status === 404) {
        const errData = await response.json().catch(() => ({}));
        addToast(`Erro 404: ${errData.detail || 'Conta ou recurso não encontrado.'}`, 'error');
        throw new Error('Não encontrado.');
      }

      if (response.status === 409) {
        const errData = await response.json().catch(() => ({}));
        addToast(`Erro 409: ${errData.detail || 'Esta conta já existe.'}`, 'error');
        throw new Error('Conflito.');
      }

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

      setLoginUser('');
      setLoginPass('');
      setLoginIdConta('');
      setLoginNomeAluno('');
      setExpirarEmSegundos(1800);
      return true;
    } catch (err) {
      return false;
    }
  };

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

  useEffect(() => {
    if (token && role === 'user') {
      carregarDadosConta();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token, role, portaAgencia]);

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

  const value = {
    // tema
    theme, isDark, toggleTheme,
    // agencia
    AGENCIAS, portaAgencia, setPortaAgencia,
    // auth
    token, role, idConta, nomeAluno, handleLogout,
    // conta
    dadosConta, extrato, loadingConta, carregarDadosConta,
    // login form
    isAdminMode, setIsAdminMode,
    loginUser, setLoginUser,
    loginPass, setLoginPass,
    loginIdConta, setLoginIdConta,
    loginNomeAluno, setLoginNomeAluno,
    expirarEmSegundos, setExpirarEmSegundos,
    handleLogin,
    // aluno
    valorDeposito, setValorDeposito, handleDeposito,
    valorSaque, setValorSaque, handleSaque,
    transferDestId, setTransferDestId,
    transferValor, setTransferValor,
    handleTransferencia,
    // admin
    newAccountId, setNewAccountId,
    newAccountName, setNewAccountName,
    newAccountBalance, setNewAccountBalance,
    handleCriarConta,
    // toasts
    toasts, addToast, removeToast,
  };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp deve ser usado dentro de um AppProvider');
  return ctx;
}
