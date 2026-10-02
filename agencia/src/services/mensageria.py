import json
import os
import sys
import threading
from typing import Callable

import pika

EXCHANGE = "iceibank.eventos"

URL_RABBITMQ = os.environ.get("RABBITMQ_URL")

if not URL_RABBITMQ:
    print(
        "Defina a variável de ambiente RABBITMQ_URL com a URL AMQP da sua instância "
        "CloudAMQP antes de iniciar.",
        file=sys.stderr,
    )
    sys.exit(1)


def _conectar():
    parametros = pika.URLParameters(URL_RABBITMQ)
    conexao = pika.BlockingConnection(parametros)
    canal = conexao.channel()
    canal.exchange_declare(exchange=EXCHANGE, exchange_type="topic", durable=True)
    return conexao, canal


def publicar(routing_key: str, mensagem: dict) -> None:
    # Conexão nova a cada publicação: pika não é thread-safe, e as rotas do
    # FastAPI (funções síncronas) podem rodar em threads diferentes do
    # threadpool - abrir/fechar aqui evita compartilhar canal entre threads.
    conexao, canal = _conectar()
    try:
        canal.basic_publish(
            exchange=EXCHANGE,
            routing_key=routing_key,
            body=json.dumps(mensagem).encode("utf-8"),
            properties=pika.BasicProperties(delivery_mode=2),  # persistent
        )
    finally:
        conexao.close()


def _assinar(id_agencia: int, ao_receber_mensagem: Callable[[dict], None]) -> None:
    conexao, canal = _conectar()
    nome_fila = f"fila-agencia-{id_agencia}"
    canal.queue_declare(queue=nome_fila, durable=True)
    canal.queue_bind(
        exchange=EXCHANGE, queue=nome_fila, routing_key=f"agencia.{id_agencia}.creditar"
    )

    def _callback(ch, method, properties, body):
        conteudo = json.loads(body.decode("utf-8"))
        ao_receber_mensagem(conteudo)
        ch.basic_ack(delivery_tag=method.delivery_tag)

    canal.basic_consume(queue=nome_fila, on_message_callback=_callback)
    print(f"[Agência {id_agencia}] aguardando mensagens na fila '{nome_fila}'...")
    canal.start_consuming()


def iniciar_consumidor_em_thread(
    id_agencia: int, ao_receber_mensagem: Callable[[dict], None]
) -> threading.Thread:
    # start_consuming() bloqueia o loop da thread para sempre - roda em uma
    # thread em segundo plano para não travar o servidor HTTP do FastAPI.
    thread = threading.Thread(
        target=_assinar, args=(id_agencia, ao_receber_mensagem), daemon=True
    )
    thread.start()
    return thread
