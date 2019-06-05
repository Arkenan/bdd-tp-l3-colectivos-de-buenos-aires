-- Punto 3. Ramales de Parada.

-- En base a una línea de colectivo (dada como número de colectivo), analizar qué paradas del
-- mismo no son recorridas por todos los ramales del colectivo. Devolver calle, número de la
-- parada y nombre del ramal que pasa por la parada, únicamente para aquellas paradas que no
-- sean recorridas por todos los ramales de la línea.

-- Primero hago una tabla con la cuenta de, para cada parada, cuántos recorridos 
-- (línea + sentido)de un colectivo pasan por allí. 


-- pruebas -------------------------------------------------------------------------------------

select * 
from paradas 
where calle like '%URIBURU%' and linea = 93;

-- Vemos que la parada 1001045 es la única parda del 93 sobre uriburu, que solo va en un sentido.

select *
from recorridos
where linea = 93;

-- Vemos que el 93 tiene tres ramales, 6 recorridos (ida y vuelta c/u).

select * from paradas_por_recorrido
where linea = 93 and id_parada = 1001045;

select * 
from paradas 
where upper(calle) like '%LAS HERAS%' and linea = 93 
and altura < 4000 and altura > 3400;

select id_parada, count(distinct(ramal)) from paradas_por_recorrido
where linea = 60
group by id_parada
having count(distinct(ramal)) < (select count(distinct(ramal)) from recorridos where linea = 60);


-- fin pruebas ----------------------------------------------------------------------------------


--- Pruebas del problema que parecería venir del ej2.

-- Paradas del 60 en Luis maria campos y 11 de septiembre
select * 
from paradas 
where linea = 60 
	and upper(calle) like '%CAMPOS%'
	and altura > 1300
	
-- La parada 1001996 está en LMC al 1395 (Esquina zabala). Solo los ramales que pasan por LMC deberían pasar por esa.

select  * 
from paradas_por_recorrido
where linea = 60 and ramal = 'RAMAL C';

select * from paradas where linea = 60;

-- El 60 tiene 15 ramales.

select count(distinct(ramal))
from paradas_por_recorrido
where linea = 60;

-- 12 de esos ramales pasan por Luis María Campos.
select id_parada, count(distinct(ramal)) 
from paradas_por_recorrido
where 
	linea = 60 
	and calle like '%CAMPOS%' 
group by id_parada

select id_parada, count(distinct(ramal)) 
from paradas_por_recorrido
where 
	linea = 60 
	and upper(calle) like '%CABILDO%' 
group by id_parada


select id_parada, count(distinct(ramal)) 
from paradas_por_recorrido
where 
	linea = 60
group by id_parada


select * from paradas where linea = 60 and upper(calle) like '%CABILDO%'
-- Esto nos muestra que los 15 ramales del 60 pasan por las paradas de Luis María Campos. 
-- Eso significa indefectiblemente que tenemos un problema en el armado de paradas_por_recorrido.


select * from paradas where linea = 60 
and (upper(calle) ilike '%CABILDO%' OR upper(dire) ilike '%CABILDO%')

select* from paradas where id_parada=20427

--------------------------------------------------------------------------------------------
---la idea es hacer una division donde el requisito sean los ramales de la linea

drop table lineas_por_parada;
--- El CSV limpio del mapa de la ciudad tiene coordenadas X, Y (longitud, latitud).
create table lineas_por_parada (
	dire varchar,
	linea integer,
	stop_id bigint,
	primary key(stop_id,linea)
);

COPY lineas_por_parada
FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/lineas_por_parada.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM lineas_por_parada limit 5

SELECT * FROM paradas_por_recorrido limit 5

create table ramal_por_parada as
SELECT l.linea, stop_id, dire, ramal FROM
lineas_por_parada l
inner join paradas_por_recorrido r
on r.id_parada = l.stop_id

SELECT * FROM ramal_por_parada limit 5

--tomo todas las paradas de la lina 60
SELECT stop_id
from ramal_por_parada 
where linea = 60

--tomo todos los ramales de la linea 60
SELECT distinct ramal
from ramal_por_parada 
where linea = 60

--aquellas paradas que son recorridas por todos los ramales
--todas las paradas para las cuales no existe un ramal de la linea 60 para el cual no exista una parada de la linea 60
SELECT stop_id
FROM ramal_por_parada 
WHERE linea = 60
AND not exists (
		SELECT 1
		FROM ramal_por_parada r
		WHERE linea =  60
		AND NOT EXISTS (
				SELECT 1 
				FROM ramal_por_parada p
				WHERE linea = 60
				AND r.stop_id = p.stop_id				
		      		)
		)




		SELECT stop_id
FROM ramal_por_parada
WHERE linea = 60 EXCEPT
		(SELECT stop_id
FROM ramal_por_parada 
WHERE linea = 60
AND not exists (
		SELECT 1
		FROM ramal_por_parada r
		WHERE linea =  60
		AND NOT EXISTS (
				SELECT 1 
				FROM ramal_por_parada p
				WHERE linea = 60
				AND r.stop_id = p.stop_id				
		      		)
		))










