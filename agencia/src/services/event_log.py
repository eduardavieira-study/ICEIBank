import json
import os
from datetime import datetime, timezone


def get_data_hora() -> str:
    return datetime.now(timezone.utc).isoformat()


class RegistroEventos:
    def __init__(self, nome_agencia: str):
        self.nome_agencia = nome_agencia
        # Sobe dois níveis (de src/services para a raiz de agencia) para colocar data/ na raiz da agencia
        pasta_dados = os.path.abspath(
            os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "data")
        )
        os.makedirs(pasta_dados, exist_ok=True)
        self.caminho_arquivo = os.path.join(
            pasta_dados, f"eventos-{nome_agencia}.jsonl"
        )

    def registrar(self, tipo: str, timestamp_lamport: int, detalhes: dict) -> dict:
        data_hora = get_data_hora()
        evento = {
            "agencia": self.nome_agencia,
            "tipo": tipo,
            "timestampLamport": timestamp_lamport,
            "horaParede": data_hora,
            "dataHora": data_hora,
            "detalhes": detalhes,
        }
        with open(self.caminho_arquivo, "a", encoding="utf-8") as arquivo:
            arquivo.write(json.dumps(evento, ensure_ascii=False) + "\n")
        print(f"[Lamport {timestamp_lamport}] {tipo} {detalhes} | {data_hora}")
        return evento
