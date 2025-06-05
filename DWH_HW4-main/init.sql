COPY public.airports(
    "airport_code",
    "airport_name",
    "city",
    "coordinates_lon",
    "coordinates_lat",
    "timezone"
) FROM '/data_init/airports_data.csv' DELIMITER ';' CSV HEADER;
COPY public.aircrafts(
    "aircraft_code",
    "model",
    "range"
) FROM '/data_init/aircrafts_data.csv' DELIMITER ';' CSV HEADER;
COPY public.seats(
    "aircraft_code",
    "seat_no",
    "fare_conditions"
) FROM '/data_init/seats_data.csv' DELIMITER ';' CSV HEADER;
COPY public.flights(
    "flight_no",
    "scheduled_departure",
    "scheduled_arrival",
    "departure_airport",
    "arrival_airport",
    "status",
    "aircraft_code",
    "actual_departure",
    "actual_arrival"
) FROM '/data_init/flights_data.csv' DELIMITER ';' CSV HEADER;
COPY public.bookings(
    "book_ref",
    "book_date",
    "total_amount"
) FROM '/data_init/bookings_data.csv' DELIMITER ';' CSV HEADER;
COPY public.tickets(
    "ticket_no",
    "book_ref",
    "passenger_id",
    "passenger_name",
    "contact_data"
) FROM '/data_init/tickets_data.csv' DELIMITER ';' CSV HEADER;
COPY public.ticket_flights(
    "ticket_no",
    "flight_id",
    "fare_conditions",
    "amount"
) FROM '/data_init/ticket_flights_data.csv' DELIMITER ';' CSV HEADER;
COPY public.boarding_passes(
    "ticket_no",
    "flight_id",
    "boarding_no",
    "seat_no"
) FROM '/data_init/boarding_passes_data.csv' DELIMITER ';' CSV HEADER;
