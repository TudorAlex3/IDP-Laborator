from flask import Flask, request
import pika
from prometheus_client import Counter, Gauge, Summary, Histogram, Info, start_http_server

app = Flask(__name__)

c = Counter('my_counter', 'This is my counter modified through /inc_counter')
g = Gauge('my_gauge',
          'This is my gauge modified through /inc_gauge, /dec_gauge, /set_gauge')
s = Summary('my_summary', 'This is my summary modified through /set_summary')
h = Histogram('my_histogram',
              'This is my histogram modified through /set_summary')
i = Info('my_info', 'This is my info')
i.info({'version': '1.0.1', 'buildhost': 'radu.ciobanu@upb.ro'})


@app.route("/inc_counter", methods=['POST'])
def inc_counter():
    c.inc()
    return "OK"


@app.route("/inc_gauge", methods=['POST'])
def inc_gauge():
    g.inc()
    return "OK"


@app.route("/dec_gauge", methods=['POST'])
def dec_gauge():
    g.dec()
    return "OK"


@app.route("/set_gauge", methods=['POST'])
def set_gauge():
    value = request.form["value"]
    g.set(float(value))
    return "OK"


@app.route("/set_summary", methods=['POST'])
def set_summary():
    value = request.form["value"]
    s.observe(float(value))
    return "OK"


@app.route("/set_histogram", methods=['POST'])
def set_histogram():
    value = request.form["value"]
    h.observe(float(value))
    return "OK"


@app.route("/generate_event", methods=['POST'])
def generate_event():
    event = request.form["event"]
    connection = pika.BlockingConnection(
        pika.ConnectionParameters(host='rabbitmq'))
    channel = connection.channel()
    channel.queue_declare(queue='task_queue', durable=True)
    channel.basic_publish(
        exchange='',
        routing_key='task_queue',
        body=event,
        properties=pika.BasicProperties(
            delivery_mode=2,
        ))
    connection.close()
    return "OK"


if __name__ == "__main__":
    start_http_server(8000)
    app.run(host="0.0.0.0")
