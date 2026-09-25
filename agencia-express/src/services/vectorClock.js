class RelogioVetorial {
  constructor(idAgencia, numeroAgencias) {
    this.idAgencia = idAgencia;
    this.vetor = new Array(numeroAgencias).fill(0);
  }

  eventoLocal() {
    this.vetor[this.idAgencia] += 1;
    return [...this.vetor];
  }

  aoEnviar() {
    this.vetor[this.idAgencia] += 1;
    return [...this.vetor];
  }

  aoReceber(vetorRecebido) {
    for (let i = 0; i < this.vetor.length; i++) {
      this.vetor[i] = Math.max(this.vetor[i], vetorRecebido[i]);
    }
    this.vetor[this.idAgencia] += 1;
    return [...this.vetor];
  }
}

export default RelogioVetorial;
