import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class RegistroEventos {
  constructor(nomeAgencia) {
    this.nomeAgencia = nomeAgencia;
    this.caminhoArquivo = path.join(__dirname, '..', '..', 'data', `eventos-${nomeAgencia}.jsonl`);
    fs.mkdirSync(path.dirname(this.caminhoArquivo), { recursive: true });
  }

  registrar(tipo, timestampLamport, detalhes) {
    const evento = {
      agencia: this.nomeAgencia,
      tipo,
      timestampLamport,
      horaParede: new Date().toISOString(),
      detalhes,
    };
    fs.appendFileSync(this.caminhoArquivo, JSON.stringify(evento) + '\n');
    console.log(`[Lamport ${timestampLamport}] ${tipo}`, detalhes);
    return evento;
  }
}

export default RegistroEventos;
