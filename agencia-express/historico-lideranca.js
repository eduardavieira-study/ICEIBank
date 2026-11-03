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

let eventos = [];
for (const arquivo of arquivos) {
  const linhas = fs
    .readFileSync(path.join(pastaDados, arquivo), 'utf-8')
    .trim()
    .split('\n')
    .filter(Boolean);
  eventos.push(...linhas.map((l) => JSON.parse(l)));
}

const tiposBully = ['ELEICAO_INICIADA', 'ELEICAO_RECEBIDA', 'TORNOU_LIDER', 'LIDER_ANUNCIADO', 'LIDER_NAO_RESPONDEU'];
const eventosBully = eventos.filter((e) => tiposBully.includes(e.tipo));
eventosBully.sort((a, b) => new Date(a.horaParede) - new Date(b.horaParede));

console.log('=== Histórico de eventos de eleição ===');
for (const evento of eventosBully) {
  console.log(`(${evento.horaParede}) [${evento.agencia}] ${evento.tipo}`, JSON.stringify(evento.detalhes));
}

const tornouLider = eventosBully.filter((e) => e.tipo === 'TORNOU_LIDER');
console.log('\n=== Linha do tempo de líderes ===');
for (const evento of tornouLider) {
  console.log(`A partir de ${evento.horaParede}: Agência ${evento.detalhes.idAgencia} é a líder`);
}
