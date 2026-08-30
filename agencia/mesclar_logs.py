import os
import json

def main():
    # Sobe para a pasta data na raiz da agência
    pasta_dados = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "data"))
    if not os.path.exists(pasta_dados):
        print(f"Diretório de dados '{pasta_dados}' não existe ou nenhum log foi gerado ainda.")
        return

    arquivos = [f for f in os.listdir(pasta_dados) if f.endswith(".jsonl")]
    todos_eventos = []

    for arquivo in arquivos:
        caminho = os.path.join(pasta_dados, arquivo)
        with open(caminho, "r", encoding="utf-8") as f:
            for linha in f:
                linha = linha.strip()
                if linha:
                    try:
                        todos_eventos.append(json.loads(linha))
                    except json.JSONDecodeError:
                        pass

    # Ordenar por timestampLamport
    todos_eventos.sort(key=lambda x: x.get("timestampLamport", 0))

    print("=== Linha do tempo unificada (ordenada por relogio de Lamport) ===")
    for evento in todos_eventos:
        agencia = evento.get("agencia", "")
        tipo = evento.get("tipo", "")
        ts = evento.get("timestampLamport", 0)
        hora = evento.get("horaParede") or evento.get("dataHora", "")
        detalhes = evento.get("detalhes", {})
        print(f"[Lamport {ts}] ({hora}) {agencia} - {tipo} {json.dumps(detalhes, ensure_ascii=False)}")

if __name__ == "__main__":
    main()
