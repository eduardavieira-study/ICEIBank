// TODO: substitua pelo seu OFFSET pessoal (dois últimos dígitos da matrícula/RA),
// necessário apenas se for rodar em uma máquina compartilhada do laboratório.
const OFFSET = 74;
const NUMERO_AGENCIAS = 3;
const PORTA_BASE = 4000 + OFFSET;
const AGENCIAS = [
  { id: 0, url: `http://localhost:${PORTA_BASE}` },
  { id: 1, url: `http://localhost:${PORTA_BASE + 1}` },
  { id: 2, url: `http://localhost:${PORTA_BASE + 2}` },
];

function agenciaResponsavel(idConta) {
  return idConta % NUMERO_AGENCIAS;
}

export { NUMERO_AGENCIAS, AGENCIAS, agenciaResponsavel, OFFSET };
