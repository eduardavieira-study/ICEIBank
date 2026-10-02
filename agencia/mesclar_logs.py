import os
import json


def comparar_vetores(v1, v2):
    v1_menor_ou_igual = True
    v2_menor_ou_igual = True
    for a, b in zip(v1, v2):
        if a > b:
            v1_menor_ou_igual = False
        if b > a:
            v2_menor_ou_igual = False
    if v1_menor_ou_igual and v2_menor_ou_igual:
        return "IGUAIS"
    if v1_menor_ou_igual:
        return "ANTES"
    if v2_menor_ou_igual:
        return "DEPOIS"
    return "CONCORRENTES"


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

    todos_eventos.sort(key=lambda x: x.get("horaParede") or x.get("dataHora", ""))

    print("=== Linha do tempo (ordenada por hora de parede) ===")
    for evento in todos_eventos:
        agencia = evento.get("agencia", "")
        tipo = evento.get("tipo", "")
        vetor = evento.get("timestampVetorial", [])
        hora = evento.get("horaParede") or evento.get("dataHora", "")
        detalhes = evento.get("detalhes", {})
        print(f"[{agencia}] vetor={vetor} {tipo} {json.dumps(detalhes, ensure_ascii=False)} | {hora}")

    print("\n=== Pares de eventos CONCORRENTES entre agências diferentes ===")
    encontrou_concorrente = False
    for i in range(len(todos_eventos)):
        for j in range(i + 1, len(todos_eventos)):
            e1 = todos_eventos[i]
            e2 = todos_eventos[j]
            if e1.get("agencia") == e2.get("agencia"):
                continue
            v1 = e1.get("timestampVetorial")
            v2 = e2.get("timestampVetorial")
            # Ignora eventos antigos que não tenham o vetor completo (ex.: logs
            # de antes do relógio vetorial estar ligado no main.py)
            if not isinstance(v1, list) or not isinstance(v2, list):
                continue
            relacao = comparar_vetores(v1, v2)
            if relacao == "CONCORRENTES":
                encontrou_concorrente = True
                print(
                    f"[{e1['agencia']}] {e1['tipo']} ({v1})  x  "
                    f"[{e2['agencia']}] {e2['tipo']} ({v2})"
                )
    if not encontrou_concorrente:
        print("(nenhum par concorrente encontrado nesta execução - gere mais eventos em paralelo e rode de novo)")


if __name__ == "__main__":
    main()
