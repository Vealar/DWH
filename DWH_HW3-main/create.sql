create table IF NOT EXISTS airports(
    airport_code    CHAR(3)                 PRIMARY KEY ,
    airport_name    TEXT                    NOT NULL ,
    city            TEXT                    NOT NULL ,
    coordinates_lon DOUBLE PRECISION        NOT NULL ,
    coordinates_lat DOUBLE PRECISION        NOT NULL ,
    timezone        TEXT                    NOT NULL
);

create table IF NOT EXISTS aircrafts(
    aircraft_code   CHAR(3)                 PRIMARY KEY ,
    model           JSONB                   NOT NULL ,
    range           INTEGER                 NOT NULL
);

create table IF NOT EXISTS seats(
    aircraft_code   CHAR(3)                 NOT NULL ,
    seat_no         VARCHAR(4)              NOT NULL ,
    fare_conditions VARCHAR(10)             NOT NULL ,

    PRIMARY KEY (aircraft_code, seat_no),
    FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE
);

create table IF NOT EXISTS flights(
    flight_id               SERIAL                  PRIMARY KEY ,
    flight_no               CHAR(6)                 NOT NULL ,
    scheduled_departure     timestamptz             NOT NULL ,
    scheduled_arrival       timestamptz             NOT NULL ,
    departure_airport       CHAR(3)                 NOT NULL ,
    arrival_airport         CHAR(3)                 NOT NULL ,
    status                  VARCHAR(20)             NOT NULL ,
    aircraft_code           CHAR(3)                 NOT NULL ,
    actual_departure        timestamptz             NULL ,
    actual_arrival          timestamptz             NULL ,
    FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code) ON DELETE CASCADE ,
    FOREIGN KEY (departure_airport) REFERENCES airports(airport_code) ON DELETE CASCADE ,
    FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code) ON DELETE CASCADE
);

create table IF NOT EXISTS bookings(
    book_ref                CHAR(6)                  PRIMARY KEY ,
    book_date               timestamptz              NOT NULL ,
    total_amount            DOUBLE PRECISION            NOT NULL
);

create table IF NOT EXISTS tickets(
    ticket_no               CHAR(13)                 PRIMARY KEY ,
    book_ref                CHAR(6)                  NOT NULL ,
    passenger_id            VARCHAR(20)              NOT NULL ,
    passenger_name          TEXT                     NOT NULL ,
    contact_data            jsonb                    NULL ,
    FOREIGN KEY (book_ref) REFERENCES bookings(book_ref) ON DELETE CASCADE
);

create table IF NOT EXISTS ticket_flights(
    ticket_no               CHAR(13)                 NOT NULL ,
    flight_id               INTEGER                  NOT NULL ,
    fare_conditions         DOUBLE PRECISION            NOT NULL ,
    amount                  DOUBLE PRECISION            NOT NULL ,

    PRIMARY KEY (ticket_no,flight_id),

    FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no) ON DELETE CASCADE ,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id) ON DELETE CASCADE
);

create table IF NOT EXISTS boarding_passes(
    ticket_no               CHAR(13)                  NOT NULL ,
    flight_id               INTEGER                   NOT NULL ,
    boarding_no             INTEGER                   NOT NULL ,
    seat_no                 VARCHAR(4)                NOT NULL ,

    PRIMARY KEY (ticket_no,flight_id),

    FOREIGN KEY (ticket_no,flight_id) REFERENCES ticket_flights(ticket_no,flight_id) ON DELETE CASCADE
);
