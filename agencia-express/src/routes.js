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

export default router;
