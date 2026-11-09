from typing import List


def comparar_vetores(v1: List[int], v2: List[int]) -> str:
    """Mesma lógica de comparação do mesclar_logs.py (Sprint 2), agora usada em
    tempo real pela rota de sincronização. Devolve IGUAIS, ANTES (v1 aconteceu
    antes de v2), DEPOIS ou CONCORRENTES."""
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
