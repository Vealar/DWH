-- Аэропорты
--1
SELECT COUNT(DISTINCT airport_code) AS active_airports
FROM (
    SELECT departure_airport AS airport_code
    FROM flights
    WHERE scheduled_departure >= NOW() - INTERVAL '180 days'

    UNION

    SELECT arrival_airport AS airport_code
    FROM flights
    WHERE scheduled_arrival >= NOW() - INTERVAL '180 days'
) AS unique_airports;
-- 2
SELECT flight_date, COUNT(DISTINCT airport_code) AS active_airports
FROM (
    SELECT DATE(scheduled_departure) AS flight_date, departure_airport AS airport_code
    FROM flights
    WHERE scheduled_departure >= NOW() - INTERVAL '180 days'

    UNION

    SELECT DATE(scheduled_arrival) AS flight_date, arrival_airport AS airport_code
    FROM flights
    WHERE scheduled_arrival >= NOW() - INTERVAL '180 days'
) AS unique_airports_per_day
GROUP BY flight_date
ORDER BY flight_date;
-- 3/4
WITH airport_traffic AS (
    SELECT airport_code, COUNT(*) AS total_flights
    FROM (
        SELECT departure_airport AS airport_code FROM flights
        UNION ALL
        SELECT arrival_airport AS airport_code FROM flights
    ) AS all_flights
    GROUP BY airport_code
)
SELECT
    airport_code AS "airport",
    total_flights AS "value"
FROM airport_traffic
ORDER BY total_flights DESC;
--
-- Пассажиры
-- 1
SELECT COUNT(DISTINCT passenger_id) AS unique_passengers
FROM tickets
JOIN ticket_flights USING (ticket_no)
JOIN flights USING (flight_id)
WHERE scheduled_departure >= NOW() - INTERVAL '180 days';
-- 2
SELECT AVG(total_amount) AS avg_ticket_price
FROM bookings
WHERE book_date >= NOW() - INTERVAL '180 days';
-- 3
WITH passenger_flight_counts AS (
    SELECT t.passenger_id, COUNT(*) AS flights_per_passenger
    FROM tickets t
    JOIN bookings b ON t.book_ref = b.book_ref
    WHERE b.book_date >= NOW() - INTERVAL '180 days'
    GROUP BY t.passenger_id
)
SELECT AVG(flights_per_passenger) AS avg_flights_per_passenger
FROM passenger_flight_counts;
-- 4
SELECT DATE(book_date) AS day, SUM(total_amount) AS total_revenue
FROM bookings
WHERE book_date >= NOW() - INTERVAL '180 days'
GROUP BY day
ORDER BY day;
-- 5
SELECT count(distinct(passenger_id)), book_date
FROM  tickets
Join  bookings on bookings.book_ref = tickets.book_ref
Group by book_date
--