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