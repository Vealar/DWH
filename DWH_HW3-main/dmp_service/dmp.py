import time

import psycopg2
from kafka import KafkaConsumer
import json
import threading
from datetime import datetime
import hashlib


class DmpService:
    def __init__(self):
        self.kafka_config = {
            "bootstrap_servers": ["broker:29092"],
            "group_id": "dmp-group",
            "auto_offset_reset": 'earliest',
            "enable_auto_commit": True,
            "value_deserializer": lambda x: x.decode('utf-8')
        }

        self.pg_config = {
            "host": "data_vault",
            "port": 5432,
            "database": "postgres",
            "user": "postgres",
            "password": "postgres"
        }

        self.topics_mapping = {
            "postgres.public.airports": self.process_airport,
            "postgres.public.aircrafts": self.process_aircraft,
            "postgres.public.bookings": self.process_booking,
            "postgres.public.tickets": self.process_ticket,
            "postgres.public.flights": self.process_flight,
            "postgres.public.ticket_flights": self.process_ticket_flights,
            "postgres.public.seats": self.process_seat,
            "postgres.public.boarding_passes": self.process_boarding
        }

        # Порядок обработки топиков (от независимых к зависимым)
        self.topics_processing_order = [
            "postgres.public.airports",
            "postgres.public.aircrafts",
            "postgres.public.bookings",
            "postgres.public.tickets",
            "postgres.public.flights",
            "postgres.public.ticket_flights",
            "postgres.public.seats",
            "postgres.public.boarding_passes"
        ]


    def get_current_timestamp(self):
        return datetime.now()

    def generate_md5_hash(self, *args):
        hash_input = ''.join(str(arg) for arg in args)
        return hashlib.md5(hash_input.encode()).hexdigest()

    def create_consumer(self, topic):
        return KafkaConsumer(topic, **self.kafka_config)

    def create_db_connection(self):
        return psycopg2.connect(**self.pg_config)

    def execute_query(self, cursor, query, params):
        try:
            cursor.execute(query, params)
            return True
        except Exception as e:
            print(f"Query execution failed: {e}")
            return False

    def process_airport(self, row, cursor):
        current_ts = self.get_current_timestamp()
        hub_key = self.generate_md5_hash(row["airport_code"])

        # Insert into HUB_AIRPORT
        hub_query = """
            INSERT INTO dwh_detailed.HUB_AIRPORT 
            (hub_airport_code_hash, bk_airport_code, hub_load_dts, hub_rec_src)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (hub_airport_code_hash) DO NOTHING
        """
        self.execute_query(cursor, hub_query,
                           (hub_key, row["airport_code"], current_ts, "kafka"))

        # Insert into SAT_AIRPORT
        sat_query = """
            INSERT INTO dwh_detailed.SAT_AIRPORT 
            (hub_airport_code_hash, airport_name, city, coordinates_lon, 
             coordinates_lat, timezone, sat_load_dts, sat_rec_src)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        self.execute_query(cursor, sat_query, (
            hub_key, row["airport_name"], row["city"],
            row["coordinates_lon"], row["coordinates_lat"],
            row["timezone"], current_ts, "kafka"
        ))

    def process_aircraft(self, row, cursor):
        current_ts = self.get_current_timestamp()
        hub_key = self.generate_md5_hash(row["aircraft_code"])

        # Insert into HUB_AIRCRAFT
        hub_query = """
            INSERT INTO dwh_detailed.HUB_AIRCRAFT 
            (hub_aircraft_code_hash, bk_aircraft_code, hub_load_dts, hub_rec_src)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (hub_aircraft_code_hash) DO NOTHING
        """
        self.execute_query(cursor, hub_query,
                           (hub_key, row["aircraft_code"], current_ts, "kafka"))

        # Insert into SAT_AIRCRAFT
        sat_query = """
            INSERT INTO dwh_detailed.SAT_AIRCRAFT 
            (hub_aircraft_code_hash, model, range, sat_load_dts, sat_rec_src)
            VALUES (%s, %s, %s, %s, %s)
        """
        self.execute_query(cursor, sat_query, (
            hub_key, json.dumps(row["model"]), row["range"],
            current_ts, "kafka"
        ))

    def process_seat(self, row, cursor):
        current_ts = self.get_current_timestamp()
        hub_key = self.generate_md5_hash(row["aircraft_code"])

        # Insert into SAT_AIRCRAFT_SEATS
        sat_query = """
            INSERT INTO dwh_detailed.SAT_AIRCRAFT_SEATS 
            (hub_aircraft_code_hash, seat_no, fare_conditions, sat_load_dts, sat_rec_src)
            VALUES (%s, %s, %s, %s, %s)
            ON CONFLICT (hub_aircraft_code_hash, seat_no, sat_load_dts) DO NOTHING
        """
        self.execute_query(cursor, sat_query, (
            hub_key, row["seat_no"], row["fare_conditions"],
            current_ts, "kafka"
        ))

    def process_flight(self, row, cursor):
        current_ts = self.get_current_timestamp()
        hub_key = self.generate_md5_hash(row["flight_id"])

        # Insert into HUB_FLIGHT
        hub_query = """
            INSERT INTO dwh_detailed.HUB_FLIGHT 
            (hub_flight_id_hash, bk_flight_id, hub_load_dts, hub_rec_src)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (hub_flight_id_hash) DO NOTHING
        """
        self.execute_query(cursor, hub_query,
                           (hub_key, row["flight_id"], current_ts, "kafka"))

        # Insert into SAT_FLIGHT
        sat_query = """
            INSERT INTO dwh_detailed.SAT_FLIGHT 
            (hub_flight_id_hash, flight_no, scheduled_departure, scheduled_arrival, 
             status, actual_departure, actual_arrival, sat_load_dts, sat_rec_src)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        self.execute_query(cursor, sat_query, (
            hub_key, row["flight_no"], row["scheduled_departure"],
            row["scheduled_arrival"], row["status"],
            row.get("actual_departure"), row.get("actual_arrival"),
            current_ts, "kafka"
        ))

        # Process links
        if "aircraft_code" in row:
            aircraft_key = self.generate_md5_hash(row["aircraft_code"])
            lnk_key = self.generate_md5_hash(hub_key, aircraft_key)
            lnk_query = """
                INSERT INTO dwh_detailed.LNK_FLIGHT_AIRCRAFT 
                (lnk_flight_aircraft_hash, hub_flight_id_hash, hub_aircraft_code_hash, 
                 bk_flight_id, bk_aircraft_code, lnk_load_dts, lnk_rec_src)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (lnk_flight_aircraft_hash) DO NOTHING
            """
            self.execute_query(cursor, lnk_query, (
                lnk_key, hub_key, aircraft_key,
                row["flight_id"], row["aircraft_code"],
                current_ts, "kafka"
            ))

        if "departure_airport" in row:
            dep_airport_key = self.generate_md5_hash(row["departure_airport"])
            lnk_dep_key = self.generate_md5_hash(hub_key, dep_airport_key)
            lnk_dep_query = """
                INSERT INTO dwh_detailed.LNK_FLIGHT_AIRPORT_DEPARTURE 
                (lnk_flight_departure_hash, hub_flight_id_hash, hub_airport_code_hash, 
                 bk_flight_id, bk_airport_code, lnk_load_dts, lnk_rec_src)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (lnk_flight_departure_hash) DO NOTHING
            """
            self.execute_query(cursor, lnk_dep_query, (
                lnk_dep_key, hub_key, dep_airport_key,
                row["flight_id"], row["departure_airport"],
                current_ts, "kafka"
            ))

        if "arrival_airport" in row:
            arr_airport_key = self.generate_md5_hash(row["arrival_airport"])
            lnk_arr_key = self.generate_md5_hash(hub_key, arr_airport_key)
            lnk_arr_query = """
                INSERT INTO dwh_detailed.LNK_FLIGHT_AIRPORT_ARRIVAL 
                (lnk_flight_arrival_hash, hub_flight_id_hash, hub_airport_code_hash, 
                 bk_flight_id, bk_airport_code, lnk_load_dts, lnk_rec_src)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (lnk_flight_arrival_hash) DO NOTHING
            """
            self.execute_query(cursor, lnk_arr_query, (
                lnk_arr_key, hub_key, arr_airport_key,
                row["flight_id"], row["arrival_airport"],
                current_ts, "kafka"
            ))

    def process_ticket(self, row, cursor):
        current_ts = self.get_current_timestamp()
        hub_key = self.generate_md5_hash(row["ticket_no"])

        # Insert into HUB_TICKET
        hub_query = """
            INSERT INTO dwh_detailed.HUB_TICKET 
            (hub_ticket_no_hash, bk_ticket_no, hub_load_dts, hub_rec_src)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (hub_ticket_no_hash) DO NOTHING
        """
        self.execute_query(cursor, hub_query,
                           (hub_key, row["ticket_no"], current_ts, "kafka"))

        # Process passenger
        passenger_key = self.generate_md5_hash(row["passenger_id"])
        passenger_query = """
            INSERT INTO dwh_detailed.HUB_PASSENGER 
            (hub_passenger_id_hash, bk_passenger_id, hub_load_dts, hub_rec_src)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (hub_passenger_id_hash) DO NOTHING
        """
        self.execute_query(cursor, passenger_query,
                           (passenger_key, row["passenger_id"], current_ts, "kafka"))

        # Insert into SAT_PASSENGER
        sat_passenger_query = """
            INSERT INTO dwh_detailed.SAT_PASSENGER 
            (hub_passenger_id_hash, passenger_name, contact_data, sat_load_dts, sat_rec_src)
            VALUES (%s, %s, %s, %s, %s)
        """
        self.execute_query(cursor, sat_passenger_query, (
            passenger_key, row["passenger_name"],
            json.dumps(row["contact_data"]), current_ts, "kafka"
        ))

        # Link ticket to passenger
        lnk_passenger_key = self.generate_md5_hash(hub_key, passenger_key)
        lnk_passenger_query = """
            INSERT INTO dwh_detailed.LNK_TICKET_PASSENGER 
            (lnk_ticket_passenger_hash, hub_ticket_no_hash, hub_passenger_id_hash, 
             bk_ticket_no, bk_passenger_id, lnk_load_dts, lnk_rec_src)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (lnk_ticket_passenger_hash) DO NOTHING
        """
        self.execute_query(cursor, lnk_passenger_query, (
            lnk_passenger_key, hub_key, passenger_key,
            row["ticket_no"], row["passenger_id"],
            current_ts, "kafka"
        ))

        # Link ticket to booking if exists
        if "book_ref" in row:
            booking_key = self.generate_md5_hash(row["book_ref"])
            lnk_booking_key = self.generate_md5_hash(hub_key, booking_key)
            lnk_booking_query = """
                INSERT INTO dwh_detailed.LNK_TICKET_BOOKING 
                (lnk_ticket_booking_hash, hub_ticket_no_hash, hub_book_ref_hash, 
                 bk_ticket_no, bk_book_ref, lnk_load_dts, lnk_rec_src)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                ON CONFLICT (lnk_ticket_booking_hash) DO NOTHING
            """
            self.execute_query(cursor, lnk_booking_query, (
                lnk_booking_key, hub_key, booking_key,
                row["ticket_no"], row["book_ref"],
                current_ts, "kafka"
            ))

    def process_booking(self, row, cursor):
        current_ts = self.get_current_timestamp()
        hub_key = self.generate_md5_hash(row["book_ref"])

        # Insert into HUB_BOOKING
        hub_query = """
            INSERT INTO dwh_detailed.HUB_BOOKING 
            (hub_book_ref_hash, bk_book_ref, hub_load_dts, hub_rec_src)
            VALUES (%s, %s, %s, %s)
            ON CONFLICT (hub_book_ref_hash) DO NOTHING
        """
        self.execute_query(cursor, hub_query,
                           (hub_key, row["book_ref"], current_ts, "kafka"))

        # Insert into SAT_BOOKING
        sat_query = """
            INSERT INTO dwh_detailed.SAT_BOOKING 
            (hub_book_ref_hash, book_date, total_amount, sat_load_dts, sat_rec_src)
            VALUES (%s, %s, %s, %s, %s)
        """
        self.execute_query(cursor, sat_query, (
            hub_key, row["book_date"], row["total_amount"],
            current_ts, "kafka"
        ))

    def process_ticket_flights(self, row, cursor):
        current_ts = self.get_current_timestamp()
        ticket_key = self.generate_md5_hash(row["ticket_no"])
        flight_key = self.generate_md5_hash(row["flight_id"])
        lnk_flight_ticket_key = self.generate_md5_hash(flight_key, ticket_key)


        # Insert into LNK_FLIGHT_TICKET
        lnk_flight_ticket_query = """
            INSERT INTO dwh_detailed.LNK_FLIGHT_TICKET 
            (lnk_flight_ticket_hash, hub_flight_id_hash, hub_ticket_no_hash, bk_flight_id,
            bk_ticket_no, lnk_load_dts, lnk_rec_src)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            -- ON CONFLICT (lnk_flight_ticket_hash) DO NOTHING
        """
        self.execute_query(cursor, lnk_flight_ticket_query,
                           (lnk_flight_ticket_key,flight_key,ticket_key,row["flight_id"],
                            row["ticket_no"], current_ts, "kafka"))

        sat_flight_ticket_query = """
            INSERT INTO dwh_detailed.SAT_FLIGHT_TICKET 
            (lnk_flight_ticket_hash, fare_conditions, amount,sat_load_dts, sat_rec_src)
            VALUES (%s, %s, %s, %s, %s)
            -- ON CONFLICT (lnk_flight_ticket_hash) DO NOTHING
        """
        self.execute_query(cursor, sat_flight_ticket_query,
                           (lnk_flight_ticket_key, row["fare_conditions"], row["amount"]
                            , current_ts, "kafka"))



    def process_boarding(self, row, cursor):
        current_ts = self.get_current_timestamp()

        # Link ticket to flight (SAT_BOARDING_PASSES)
        if "ticket_no" in row and "flight_id" in row:
            ticket_key = self.generate_md5_hash(row["ticket_no"])
            flight_key = self.generate_md5_hash(row["flight_id"])
            lnk_flight_ticket_key = self.generate_md5_hash(flight_key, ticket_key)

            sat_boarding_passes_query = """
                INSERT INTO dwh_detailed.SAT_BOARDING_PASSES 
                (lnk_flight_ticket_hash, boarding_no, 
                 seat_no, sat_load_dts, sat_rec_src)
                VALUES (%s, %s, %s, %s, %s)
            """
            self.execute_query(cursor, sat_boarding_passes_query, (
                lnk_flight_ticket_key, row["boarding_no"],
                row["seat_no"], current_ts, "kafka"
            ))

    def process_topic(self, topic):
        consumer = self.create_consumer(topic)
        pg_connector = self.create_db_connection()
        cursor = pg_connector.cursor()

        print(f"Consumer and Postgres connector created for topic: {topic}")

        try:
            for message in consumer:
                message_value = message.value

                try:
                    payload = json.loads(message_value)["payload"]
                    row = payload.get("after")

                    operation = payload.get("op")

                    print(f"Processing {operation} operation with values: {row}")

                    processor = self.topics_mapping.get(topic)
                    if processor:
                        processor(row, cursor)
                        pg_connector.commit()
                    else:
                        print(f"No processor found for topic: {topic}")
                except Exception as e:
                    print(f"Error processing message: {e}")
                    pg_connector.rollback()
        except Exception as e:
            print(f"Closing consumer due to error for topic {topic}: {e}")
        finally:
            consumer.close()
            cursor.close()
            pg_connector.close()

    def run(self):

        # Запуск потоков с задержкой между ними
        delay_between_topics = 5  # секунды
        threads = []

        for topic in self.topics_processing_order:
            if topic in self.topics_mapping:
                thread = threading.Thread(
                    target=self.process_topic,
                    args=(topic,),
                    daemon=True
                )
                thread.start()
                threads.append(thread)
                time.sleep(delay_between_topics)


if __name__ == "__main__":
    dmp_service = DmpService()
    dmp_service.run()