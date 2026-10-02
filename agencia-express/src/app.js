import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Carrega o .env da raiz do repositório (RABBITMQ_URL) antes de qualquer
// coisa tentar se conectar ao RabbitMQ.
try {
  process.loadEnvFile(path.join(__dirname, '..', '..', '.env'));
} catch {
  // Sem .env encontrado - RABBITMQ_URL deve já estar definida no ambiente
}

import express from 'express';
import * as config from './config.js';
import RelogioVetorial from './services/vectorClock.js';
import RegistroEventos from './services/eventLog.js';
import { assinar } from './services/mensageria.js';
import routes from './routes.js';
import { processarCreditoRemoto } from './controllers/transferenciasController.js';

const idAgencia = parseInt(process.env.AGENCIA_ID || '0', 10);
const agenciaConfig = config.AGENCIAS.find((a) => a.id === idAgencia);

if (!agenciaConfig) {
  console.error(`Agência ${idAgencia} não configurada em config.js`);
  process.exit(1);
}

const app = express();
app.use(express.json());

app.locals.idAgencia = idAgencia;
app.locals.relogio = new RelogioVetorial(idAgencia, config.NUMERO_AGENCIAS);
app.locals.registro = new RegistroEventos(`agencia-${idAgencia}`);
app.locals.contas = new Map();

app.use('/', routes);

// Consumidor: processa créditos vindos de outras agências via RabbitMQ
assinar(idAgencia, (mensagem) => {
  processarCreditoRemoto(app.locals, mensagem);
});

const porta = new URL(agenciaConfig.url).port;
app.listen(porta, () => {
  console.log(`[Agência ${idAgencia}] ouvindo na porta ${porta}`);
});
