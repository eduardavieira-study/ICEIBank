import express from 'express';
import * as contasController from './controllers/contasController.js';
import * as transferenciasController from './controllers/transferenciasController.js';

const router = express.Router();

router.post('/contas', contasController.criarConta);
router.get('/contas/:id', contasController.consultarSaldo);
router.post('/contas/:id/depositar', contasController.depositar);
router.post('/contas/:id/sacar', contasController.sacar);

// A rota /contas/:id/creditar-remoto do Sprint 1 deixou de existir - o crédito
// remoto agora chega via mensageria (RabbitMQ), não mais por chamada REST.
router.post('/transferencias', transferenciasController.transferir);

// Rotas do algoritmo de Bully (eleição de líder entre as agências)
router.post('/bully/eleicao', (req, res) => {
  const { origemId, vetorEnvio } = req.body;
  req.app.locals.bully.receberEleicao(origemId, vetorEnvio);
  res.sendStatus(200);
});

router.post('/bully/coordenador', (req, res) => {
  const { liderId, vetorEnvio } = req.body;
  req.app.locals.bully.receberCoordenador(liderId, vetorEnvio);
  res.sendStatus(200);
});

router.get('/bully/lider', (req, res) => {
  const liderAtual = req.app.locals.bully.obterLiderAtual();
  res.json({ idAgencia: req.app.locals.idAgencia, liderAtual });
});

export default router;
