class RelogioLamport {
  constructor() {
    this.contador = 0;
  }

  eventoLocal() {
    this.contador += 1;
    return this.contador;
  }

  aoEnviar() {
    this.contador += 1;
    return this.contador;
  }

  aoReceber(timestampRecebido) {
    this.contador = Math.max(this.contador, timestampRecebido) + 1;
    return this.contador;
  }
}

export default RelogioLamport;
