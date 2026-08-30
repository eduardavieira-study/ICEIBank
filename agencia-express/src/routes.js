import express from 'express';
import * as contasController from './controllers/contasController.js';
import * as transferenciasController from './controllers/transferenciasController.js';

const router = express.Router();

router.post('/contas', contasController.criarConta);
router.get('/contas/:id', contasController.consultarSaldo);
router.post('/contas/:id/depositar', contasController.depositar);
router.post('/contas/:id/sacar', contasController.sacar);

router.post('/transferencias', transferenciasController.transferir);
router.post('/contas/:id/creditar-remoto', transferenciasController.creditarRemoto);

export default router;
