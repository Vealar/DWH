CREATE SCHEMA IF NOT EXISTS dwh_detailed;

CREATE TABLE dwh_detailed.HUB_AIRPORT
(
    hub_airport_code_hash CHAR(32) PRIMARY KEY,
    bk_airport_code       CHAR(3)     NOT NULL,
    hub_load_dts          TIMESTAMP   NOT NULL,
    hub_rec_src           VARCHAR(50) NOT NULL
);

CREATE TABLE dwh_detailed.HUB_AIRCRAFT
(
    hub_aircraft_code_hash CHAR(32) PRIMARY KEY,
    bk_aircraft_code       CHAR(3)     NOT NULL,
    hub_load_dts           TIMESTAMP   NOT NULL,
    hub_rec_src            VARCHAR(50) NOT NULL
);

CREATE TABLE dwh_detailed.HUB_FLIGHT
(
    hub_flight_id_hash CHAR(32) PRIMARY KEY,
    bk_flight_id       INTEGER     NOT NULL,
    hub_load_dts       TIMESTAMP   NOT NULL,
    hub_rec_src        VARCHAR(50) NOT NULL
);

CREATE TABLE dwh_detailed.HUB_TICKET
(
    hub_ticket_no_hash CHAR(32) PRIMARY KEY,
    bk_ticket_no       CHAR(13)    NOT NULL,
    hub_load_dts       TIMESTAMP   NOT NULL,
    hub_rec_src        VARCHAR(50) NOT NULL
);

CREATE TABLE dwh_detailed.HUB_BOOKING
(
    hub_book_ref_hash CHAR(32) PRIMARY KEY,
    bk_book_ref       CHAR(6)     NOT NULL,
    hub_load_dts      TIMESTAMP   NOT NULL,
    hub_rec_src       VARCHAR(50) NOT NULL
);

CREATE TABLE dwh_detailed.HUB_PASSENGER
(
    hub_passenger_id_hash CHAR(32) PRIMARY KEY,
    bk_passenger_id       VARCHAR(20) NOT NULL,
    hub_load_dts          TIMESTAMP   NOT NULL,
    hub_rec_src           VARCHAR(50) NOT NULL
);



CREATE TABLE dwh_detailed.LNK_FLIGHT_AIRCRAFT
(
    lnk_flight_aircraft_hash CHAR(32) PRIMARY KEY,
    hub_flight_id_hash       CHAR(32)    NOT NULL,
    hub_aircraft_code_hash   CHAR(32)    NOT NULL,
    bk_flight_id             INTEGER     NOT NULL,
    bk_aircraft_code         CHAR(3)     NOT NULL,
    lnk_load_dts             TIMESTAMP   NOT NULL,
    lnk_rec_src              VARCHAR(50) NOT NULL,
    FOREIGN KEY (hub_flight_id_hash) REFERENCES dwh_detailed.HUB_FLIGHT (hub_flight_id_hash) ON DELETE CASCADE,
    FOREIGN KEY (hub_aircraft_code_hash) REFERENCES dwh_detailed.HUB_AIRCRAFT (hub_aircraft_code_hash) ON DELETE CASCADE
);
CREATE TABLE dwh_detailed.LNK_FLIGHT_AIRPORT_DEPARTURE
(
    lnk_flight_departure_hash CHAR(32) PRIMARY KEY,
    hub_flight_id_hash        CHAR(32)    NOT NULL,
    hub_airport_code_hash     CHAR(32)    NOT NULL,
    bk_flight_id              INTEGER     NOT NULL,
    bk_airport_code           CHAR(3)     NOT NULL,
    lnk_load_dts              TIMESTAMP   NOT NULL,
    lnk_rec_src               VARCHAR(50) NOT NULL,
    FOREIGN KEY (hub_flight_id_hash) REFERENCES dwh_detailed.HUB_FLIGHT (hub_flight_id_hash) ON DELETE CASCADE,
    FOREIGN KEY (hub_airport_code_hash) REFERENCES dwh_detailed.HUB_AIRPORT (hub_airport_code_hash) ON DELETE CASCADE
);
CREATE TABLE dwh_detailed.LNK_FLIGHT_AIRPORT_ARRIVAL
(
    lnk_flight_arrival_hash CHAR(32) PRIMARY KEY,
    hub_flight_id_hash      CHAR(32)    NOT NULL,
    hub_airport_code_hash   CHAR(32)    NOT NULL,
    bk_flight_id            INTEGER     NOT NULL,
    bk_airport_code         CHAR(3)     NOT NULL,
    lnk_load_dts            TIMESTAMP   NOT NULL,
    lnk_rec_src             VARCHAR(50) NOT NULL,
    FOREIGN KEY (hub_flight_id_hash) REFERENCES dwh_detailed.HUB_FLIGHT (hub_flight_id_hash) ON DELETE CASCADE,
    FOREIGN KEY (hub_airport_code_hash) REFERENCES dwh_detailed.HUB_AIRPORT (hub_airport_code_hash) ON DELETE CASCADE
);
CREATE TABLE dwh_detailed.LNK_FLIGHT_TICKET
(
    lnk_flight_ticket_hash CHAR(32) PRIMARY KEY,
    hub_flight_id_hash     CHAR(32)    NOT NULL,
    hub_ticket_no_hash     CHAR(32)    NOT NULL,
    bk_flight_id           INTEGER     NOT NULL,
    bk_ticket_no           CHAR(13)    NOT NULL,
    lnk_load_dts           TIMESTAMP   NOT NULL,
    lnk_rec_src            VARCHAR(50) NOT NULL
    -- FOREIGN KEY (hub_flight_id_hash) REFERENCES dwh_detailed.HUB_FLIGHT (hub_flight_id_hash) ON DELETE CASCADE,
    -- FOREIGN KEY (hub_ticket_no_hash) REFERENCES dwh_detailed.HUB_TICKET (hub_ticket_no_hash) ON DELETE CASCADE
);

CREATE TABLE dwh_detailed.LNK_TICKET_BOOKING
(
    lnk_ticket_booking_hash CHAR(32) PRIMARY KEY,
    hub_ticket_no_hash      CHAR(32)    NOT NULL,
    hub_book_ref_hash       CHAR(32)    NOT NULL,
    bk_ticket_no            CHAR(13)    NOT NULL,
    bk_book_ref             CHAR(6)     NOT NULL,
    lnk_load_dts            TIMESTAMP   NOT NULL,
    lnk_rec_src             VARCHAR(50) NOT NULL,
    FOREIGN KEY (hub_ticket_no_hash) REFERENCES dwh_detailed.HUB_TICKET (hub_ticket_no_hash) ON DELETE CASCADE,
    FOREIGN KEY (hub_book_ref_hash) REFERENCES dwh_detailed.HUB_BOOKING (hub_book_ref_hash) ON DELETE CASCADE
);

CREATE TABLE dwh_detailed.LNK_TICKET_PASSENGER
(
    lnk_ticket_passenger_hash CHAR(32) PRIMARY KEY,
    hub_ticket_no_hash        CHAR(32)    NOT NULL,
    hub_passenger_id_hash     CHAR(32)    NOT NULL,
    bk_ticket_no              CHAR(13)    NOT NULL,
    bk_passenger_id           VARCHAR(20) NOT NULL,
    lnk_load_dts              TIMESTAMP   NOT NULL,
    lnk_rec_src               VARCHAR(50) NOT NULL,
    FOREIGN KEY (hub_ticket_no_hash) REFERENCES dwh_detailed.HUB_TICKET (hub_ticket_no_hash) ON DELETE CASCADE,
    FOREIGN KEY (hub_passenger_id_hash) REFERENCES dwh_detailed.HUB_PASSENGER (hub_passenger_id_hash) ON DELETE CASCADE
);



CREATE TABLE dwh_detailed.SAT_AIRPORT
(
    hub_airport_code_hash CHAR(32)         NOT NULL,
    airport_name          TEXT             NOT NULL,
    city                  TEXT             NOT NULL,
    coordinates_lon       DOUBLE PRECISION NOT NULL,
    coordinates_lat       DOUBLE PRECISION NOT NULL,
    timezone              TEXT             NOT NULL,
    sat_load_dts          TIMESTAMP        NOT NULL,
    sat_rec_src           VARCHAR(50)      NOT NULL,
    PRIMARY KEY (hub_airport_code_hash, sat_load_dts),
    FOREIGN KEY (hub_airport_code_hash) REFERENCES dwh_detailed.HUB_AIRPORT (hub_airport_code_hash) ON DELETE CASCADE
);

CREATE TABLE dwh_detailed.SAT_AIRCRAFT
(
    hub_aircraft_code_hash CHAR(32)    NOT NULL,
    model                  JSONB       NOT NULL,
    range                  INTEGER     NOT NULL,
    sat_load_dts           TIMESTAMP   NOT NULL,
    sat_rec_src            VARCHAR(50) NOT NULL,
    PRIMARY KEY (hub_aircraft_code_hash, sat_load_dts),
    FOREIGN KEY (hub_aircraft_code_hash) REFERENCES dwh_detailed.HUB_AIRCRAFT (hub_aircraft_code_hash) ON DELETE CASCADE
);
CREATE TABLE dwh_detailed.SAT_AIRCRAFT_SEATS
(
    hub_aircraft_code_hash CHAR(32)    NOT NULL,
    seat_no                VARCHAR(4)  NOT NULL,
    fare_conditions        VARCHAR(10) NOT NULL,
    sat_load_dts           TIMESTAMP   NOT NULL,
    sat_rec_src            VARCHAR(50) NOT NULL,
    PRIMARY KEY (hub_aircraft_code_hash, seat_no, sat_load_dts),
    FOREIGN KEY (hub_aircraft_code_hash) REFERENCES dwh_detailed.HUB_AIRCRAFT (hub_aircraft_code_hash) ON DELETE CASCADE
);

CREATE TABLE dwh_detailed.SAT_FLIGHT
(
    hub_flight_id_hash  CHAR(32)    NOT NULL,
    flight_no           CHAR(6)     NOT NULL,
    scheduled_departure TIMESTAMPTZ NOT NULL,
    scheduled_arrival   TIMESTAMPTZ NOT NULL,
    status              VARCHAR(20) NOT NULL,
    actual_departure    TIMESTAMPTZ NULL,
    actual_arrival      TIMESTAMPTZ NULL,
    sat_load_dts        TIMESTAMP   NOT NULL,
    sat_rec_src         VARCHAR(50) NOT NULL,
    PRIMARY KEY (hub_flight_id_hash, sat_load_dts),
    FOREIGN KEY (hub_flight_id_hash) REFERENCES dwh_detailed.HUB_FLIGHT (hub_flight_id_hash) ON DELETE CASCADE
);

CREATE TABLE dwh_detailed.SAT_FLIGHT_TICKET
(
    lnk_flight_ticket_hash CHAR(32)         NOT NULL,
    fare_conditions        DOUBLE PRECISION NOT NULL,
    amount                 DOUBLE PRECISION NOT NULL,
    sat_load_dts           TIMESTAMP        NOT NULL,
    sat_rec_src            VARCHAR(50)      NOT NULL,
    PRIMARY KEY (lnk_flight_ticket_hash, sat_load_dts)
    -- FOREIGN KEY (lnk_flight_ticket_hash) REFERENCES dwh_detailed.LNK_FLIGHT_TICKET (lnk_flight_ticket_hash) ON DELETE CASCADE
);
CREATE TABLE dwh_detailed.SAT_BOARDING_PASSES
(
    lnk_flight_ticket_hash CHAR(32)    NOT NULL,
    boarding_no            INTEGER     NOT NULL,
    seat_no                VARCHAR(4)  NOT NULL,
    sat_load_dts           TIMESTAMP   NOT NULL,
    sat_rec_src            VARCHAR(50) NOT NULL,
    PRIMARY KEY (lnk_flight_ticket_hash, sat_load_dts)
    -- FOREIGN KEY (lnk_flight_ticket_hash) REFERENCES dwh_detailed.LNK_FLIGHT_TICKET (lnk_flight_ticket_hash) ON DELETE CASCADE
);

CREATE TABLE dwh_detailed.SAT_BOOKING
(
    hub_book_ref_hash CHAR(32)         NOT NULL,
    book_date         TIMESTAMPTZ      NOT NULL,
    total_amount      DOUBLE PRECISION NOT NULL,
    sat_load_dts      TIMESTAMP        NOT NULL,
    sat_rec_src       VARCHAR(50)      NOT NULL,
    PRIMARY KEY (hub_book_ref_hash, sat_load_dts),
    FOREIGN KEY (hub_book_ref_hash) REFERENCES dwh_detailed.HUB_BOOKING (hub_book_ref_hash) ON DELETE CASCADE
);

CREATE TABLE dwh_detailed.SAT_PASSENGER
(
    hub_passenger_id_hash CHAR(32)    NOT NULL,
    passenger_name        TEXT        NOT NULL,
    contact_data          JSONB       NOT NULL,
    sat_load_dts          TIMESTAMP   NOT NULL,
    sat_rec_src           VARCHAR(50) NOT NULL,
    PRIMARY KEY (hub_passenger_id_hash, sat_load_dts),
    FOREIGN KEY (hub_passenger_id_hash) REFERENCES dwh_detailed.HUB_PASSENGER (hub_passenger_id_hash) ON DELETE CASCADE
);
