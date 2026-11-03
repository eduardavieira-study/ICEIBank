import os
import json

TIPOS_BULLY = [
    "ELEICAO_INICIADA",
    "ELEICAO_RECEBIDA",
    "TORNOU_LIDER",
    "LIDER_ANUNCIADO",
    "LIDER_NAO_RESPONDEU",
]


def main():
    pasta_dados = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "data"))
    if not os.path.exists(pasta_dados):
        print(f"Diretório de dados '{pasta_dados}' não existe ou nenhum log foi gerado ainda.")
        return

    arquivos = [f for f in os.listdir(pasta_dados) if f.endswith(".jsonl")]
    eventos = []

    for arquivo in arquivos:
        with open(os.path.join(pasta_dados, arquivo), "r", encoding="utf-8") as f:
            for linha in f:
                linha = linha.strip()
                if linha:
                    try:
                        eventos.append(json.loads(linha))
                    except json.JSONDecodeError:
                        pass

    eventos_bully = [e for e in eventos if e.get("tipo") in TIPOS_BULLY]
    eventos_bully.sort(key=lambda x: x.get("horaParede") or x.get("dataHora", ""))

    print("=== Histórico de eventos de eleição ===")
    for evento in eventos_bully:
        hora = evento.get("horaParede") or evento.get("dataHora", "")
        print(f"({hora}) [{evento.get('agencia')}] {evento.get('tipo')}", json.dumps(evento.get("detalhes", {}), ensure_ascii=False))

    tornou_lider = [e for e in eventos_bully if e["tipo"] == "TORNOU_LIDER"]
    print("\n=== Linha do tempo de líderes ===")
    for evento in tornou_lider:
        hora = evento.get("horaParede") or evento.get("dataHora", "")
        print(f"A partir de {hora}: Agência {evento['detalhes']['idAgencia']} é a líder")


if __name__ == "__main__":
    main()
