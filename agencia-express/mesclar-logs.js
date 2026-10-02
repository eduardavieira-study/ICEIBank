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

todosEventos.sort((a, b) => new Date(a.horaParede) - new Date(b.horaParede));

console.log('=== Linha do tempo (ordenada por hora de parede) ===');
for (const evento of todosEventos) {
  console.log(
    `[${evento.agencia}] vetor=${JSON.stringify(evento.timestampVetorial)} ${evento.tipo}`,
    JSON.stringify(evento.detalhes)
  );
}

function compararVetores(v1, v2) {
  let v1MenorOuIgual = true;
  let v2MenorOuIgual = true;
  for (let i = 0; i < v1.length; i++) {
    if (v1[i] > v2[i]) v1MenorOuIgual = false;
    if (v2[i] > v1[i]) v2MenorOuIgual = false;
  }
  if (v1MenorOuIgual && v2MenorOuIgual) return 'IGUAIS';
  if (v1MenorOuIgual) return 'ANTES';
  if (v2MenorOuIgual) return 'DEPOIS';
  return 'CONCORRENTES';
}

console.log('\n=== Pares de eventos CONCORRENTES entre agências diferentes ===');
let encontrouConcorrente = false;
for (let i = 0; i < todosEventos.length; i++) {
  for (let j = i + 1; j < todosEventos.length; j++) {
    const e1 = todosEventos[i];
    const e2 = todosEventos[j];
    if (e1.agencia === e2.agencia) continue;
    // Ignora eventos antigos que não tenham o vetor completo
    if (!Array.isArray(e1.timestampVetorial) || !Array.isArray(e2.timestampVetorial)) continue;
    const relacao = compararVetores(e1.timestampVetorial, e2.timestampVetorial);
    if (relacao === 'CONCORRENTES') {
      encontrouConcorrente = true;
      console.log(
        `[${e1.agencia}] ${e1.tipo} (${JSON.stringify(e1.timestampVetorial)})  x  [${e2.agencia}] ${e2.tipo} (${JSON.stringify(e2.timestampVetorial)})`
      );
    }
  }
}
if (!encontrouConcorrente) {
  console.log('(nenhum par concorrente encontrado nesta execução - gere mais eventos em paralelo e rode de novo)');
}
