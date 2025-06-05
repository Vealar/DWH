import json
from kafka import *

KAFKA_HOST = "localhost"
KAFKA_CONSUMER_GROUP = "backend"


def read_single_message(topic=None):
    assert topic is not None, 'You must specify topic name'

    consumer = KafkaConsumer(
        bootstrap_servers=f"{KAFKA_HOST}:9092",
        value_deserializer=lambda v: v if v is None else json.loads(v.decode("utf-8")),
        auto_offset_reset="earliest",
        group_id=KAFKA_CONSUMER_GROUP
    )
    consumer.subscribe(topics=topic)

    try:
        for message in consumer:
            value = message.value
            return value
    except Exception as e:
        print("Closing consumer due to error\n")
        consumer.close()
        raise e
    finally:
        print("Closing consumer due to finish\n")
        consumer.close()

value = read_single_message('postgres.public.aircrafts')
print(value)