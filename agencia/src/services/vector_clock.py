import threading
from typing import List


class RelogioVetorial:
    def __init__(self, id_agencia: int, numero_agencias: int):
        self.id_agencia = id_agencia
        self.vetor = [0] * numero_agencias
        # RLock: a rota de sincronização segura a trava enquanto compara o vetor
        # e aplica a operação, e evento_local() pede a mesma trava de novo.
        self._lock = threading.RLock()

    def obter_vetor_atual(self) -> List[int]:
        # Só lê: ao contrário dos outros métodos, não conta como evento.
        with self._lock:
            return list(self.vetor)

    def bloquear(self):
        # Uso: `with relogio.bloquear(): ...` - nenhum outro evento altera o
        # vetor enquanto o bloco roda.
        return self._lock

    def evento_local(self) -> List[int]:
        with self._lock:
            self.vetor[self.id_agencia] += 1
            return list(self.vetor)

    def ao_enviar(self) -> List[int]:
        with self._lock:
            self.vetor[self.id_agencia] += 1
            return list(self.vetor)

    def ao_receber(self, vetor_recebido: List[int]) -> List[int]:
        with self._lock:
            for i in range(len(self.vetor)):
                self.vetor[i] = max(self.vetor[i], vetor_recebido[i])
            self.vetor[self.id_agencia] += 1
            return list(self.vetor)
