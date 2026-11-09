// Mesma lógica de comparação do mesclar-logs.js (Sprint 2), agora usada em tempo
// real pela rota de sincronização. Devolve IGUAIS, ANTES (v1 aconteceu antes de
// v2), DEPOIS ou CONCORRENTES.
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

export default compararVetores;
