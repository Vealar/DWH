with flight_info as (
select f.flight_id,departure_airport,arrival_airport,COUNT(ticket_no) as pass_num
from flights f
left join ticket_flights as tf on tf.flight_id = f.flight_id
group by f.flight_id, departure_airport, arrival_airport
),
dep_info as (
select airports.airport_code,
       COALESCE(COUNT(fid.flight_id), 0) AS departure_flights_num,
       COALESCE(SUM(fid.pass_num), 0) AS departure_psngr_num
from airports
left join flight_info as fid on airports.airport_code = fid.departure_airport
group by airports.airport_code
),
arr_info as (
    select airports.airport_code,
    COALESCE(COUNT(fia.flight_id), 0) AS arrival_flights_num,
    COALESCE(SUM(fia.pass_num), 0) AS arrival_psngr_num
from airports
left join flight_info as fia on airports.airport_code = fia.arrival_airport
group by airports.airport_code
)
select dep_info.airport_code, departure_flights_num, departure_psngr_num, arrival_flights_num, arrival_psngr_num
from dep_info join arr_info on dep_info.airport_code = arr_info.airport_code