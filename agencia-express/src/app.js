import express from 'express';
import * as config from './config.js';
import RelogioLamport from './services/lamportClock.js';
import RegistroEventos from './services/eventLog.js';
import routes from './routes.js';

const idAgencia = parseInt(process.env.AGENCIA_ID || '0', 10);
const agenciaConfig = config.AGENCIAS.find((a) => a.id === idAgencia);

if (!agenciaConfig) {
  console.error(`Agência ${idAgencia} não configurada em config.js`);
  process.exit(1);
}

const app = express();
app.use(express.json());

app.locals.idAgencia = idAgencia;
app.locals.relogio = new RelogioLamport();
app.locals.registro = new RegistroEventos(`agencia-${idAgencia}`);
app.locals.contas = new Map();

app.use('/', routes);

const porta = new URL(agenciaConfig.url).port;
app.listen(porta, () => {
  console.log(`[Agência ${idAgencia}] ouvindo na porta ${porta}`);
});