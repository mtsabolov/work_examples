-- Примеры запросов с использованием базы данных "bookings"

-- База данных: https://edu.postgrespro.ru/bookings.pdf

--2.1 В каких городах больше одного аэропорта?
select city, count(city) 
from airports
group by city
having count(city) > 1;
-- группируем по городам, считаем строки в группах, выбираем те, где количество больше 1

--2.2 В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?
select aircraft_code, departure_airport, model, "range" 
from flights f 
join aircrafts a using(aircraft_code)
where "range" = (select max("range") from aircrafts a)
group by f.departure_airport, f.aircraft_code, a.model, "a.range";
/* из таблицы aircrafts получаем данные о самолете с максимальной дальностью полёта, по коду самолёта (aircraft_code)
 * объединяем с таблицей flights, где есть информация об аэропортах, из которых самолёт с таким кодом выполняет рейсы,
 * по условию максимальной дальности перелёта отфильтровываем. Затем по аэропортам группируем, чтобы видеть только уникальные значения
 */

--2.3 Вывести 10 рейсов с максимальным временем задержки вылета
select flight_no, scheduled_departure, actual_departure,
	actual_departure - scheduled_departure as delay --считаем разницу между фактическим вылетом и запланированным вылетом
from flights f 
where actual_departure is not null --убираем отображение рейсов, где не указан фактический вылет
order by delay desc --сортируем по времени задержки от наибольшего к наименьшему
limit 10 --ограничиваем показ первыми десятью

--2.4 Были ли брони, по которым не были получены посадочные талоны?
select book_ref, ticket_no, boarding_no
from tickets t 
left join boarding_passes bp using(ticket_no)
where boarding_no is null 
/*в таблице tickets есть номер брони - book_ref и номер билета - ticket_no, этой брони соответствующий
  в таблице boarding_passes есть номер билета - ticket_no и номер посадочного талона - boarding_no
  LEFT JOIN по номеру билета объединит брони и их посадочные.
  если у брони нет соответствующего посадочного - в столбце boarding_no выведен NULL,
  значит брони, по которым не были получены посадочные, есть */

-- 2.5 uncomplete	
with ts as (
	select fv.flight_id, fv.flight_no, fv.scheduled_departure_local, fv.departure_city, fv.arrival_city, fv.aircraft_code, 
		count(tf.ticket_no) as fact_passengers,
		(select count(s.seat_no)
			from seats s
			where s.aircraft_code = fv.aircraft_code) as total_seats
	from flights_v fv 
	join ticket_flights tf on fv.flight_id = tf.flight_id 
	where fv.status = 'Departed'
	group by 1, 2, 3, 4, 5, 6
)
select ts.flight_id, ts.flight_no, ts.scheduled_departure_local, ts.departure_city, ts.fact_passengers, ts.total_seats,
	(ts.total_seats::numeric - ts.fact_passengers::numeric) as free_seats,
	round((total_seats::numeric - fact_passengers::numeric) / ts.total_seats::numeric, 2) * 100 as percentage
from ts 
join aircrafts as a on ts.aircraft_code = a.aircraft_code
order by ts.scheduled_departure_local



