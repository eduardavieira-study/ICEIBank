import amqp from 'amqplib';

const EXCHANGE = 'iceibank.eventos';

let canalCache = null;

// Lida com a URL dentro da função (não no topo do módulo): em ESM, todos os
// imports de um arquivo são avaliados antes do corpo do módulo que os importa
// rodar - então ler process.env.RABBITMQ_URL aqui em cima rodaria ANTES do
// app.js carregar o .env. Lendo dentro da função, isso só acontece quando
// publicar()/assinar() são de fato chamados (depois do .env já carregado).
function obterUrlRabbitMQ() {
  const url = process.env.RABBITMQ_URL;
  if (!url) {
    console.error(
      'Defina a variável de ambiente RABBITMQ_URL (ou o arquivo .env na raiz do repo) ' +
        'com a URL AMQP da sua instância CloudAMQP antes de iniciar.'
    );
    process.exit(1);
  }
  return url;
}

async function obterCanal() {
  if (canalCache) return canalCache;
  const conexao = await amqp.connect(obterUrlRabbitMQ());
  const canal = await conexao.createChannel();
  await canal.assertExchange(EXCHANGE, 'topic', { durable: true });
  canalCache = canal;
  return canal;
}

async function publicar(routingKey, mensagem) {
  const canal = await obterCanal();
  canal.publish(EXCHANGE, routingKey, Buffer.from(JSON.stringify(mensagem)), { persistent: true });
}

async function assinar(idAgencia, aoReceberMensagem) {
  const canal = await obterCanal();
  const nomeFila = `fila-agencia-${idAgencia}`;
  await canal.assertQueue(nomeFila, { durable: true });
  await canal.bindQueue(nomeFila, EXCHANGE, `agencia.${idAgencia}.creditar`);
  canal.consume(nomeFila, (msg) => {
    if (msg) {
      const conteudo = JSON.parse(msg.content.toString());
      aoReceberMensagem(conteudo);
      canal.ack(msg);
    }
  });
  console.log(`[Agência ${idAgencia}] aguardando mensagens na fila '${nomeFila}'...`);
}

export { publicar, assinar };
