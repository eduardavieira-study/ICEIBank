import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const pastaDados = path.join(__dirname, 'data');

if (!fs.existsSync(pastaDados)) {
  console.log(`Diretório de dados '${pastaDados}' não existe ou nenhum log foi gerado.`);
  process.exit(0);
}

const arquivos = fs.readdirSync(pastaDados).filter((f) => f.endsWith('.jsonl'));
let todosEventos = [];

for (const arquivo of arquivos) {
  const linhas = fs
    .readFileSync(path.join(pastaDados, arquivo), 'utf-8')
    .trim()
    .split('\n')
    .filter(Boolean);
  todosEventos.push(...linhas.map((l) => JSON.parse(l)));
}

todosEventos.sort((a, b) => a.timestampLamport - b.timestampLamport);

console.log('=== Linha do tempo unificada (ordenada por relogio de Lamport) ===');
for (const evento of todosEventos) {
  console.log(
    `[Lamport ${evento.timestampLamport}] (${evento.horaParede}) ${evento.agencia} - ${evento.tipo}`,
    JSON.stringify(evento.detalhes)
  );
}
