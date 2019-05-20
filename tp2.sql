---ENUNCAIDO
---2 – Colectivo a utilizar
---En base a dos posiciones (dadas como geometrías de tipo POINT), una de origen y otra de
---destino, indicar qué colectivos llevan de una ubicación a otra. Se deberá devolver el número
---de línea de colectivo, el ramal y el sentido, los datos de la parada de origen y destino (calle y
---número para ambas).
---Un parámetro de la consulta será cuánto está dispuesto a caminar como máximo la persona,
---incluyendo una primer caminata entre el punto de origen y la parada de origen y una segunda
---caminata entre la parada de destino y el punto de destino. Es decisión del grupo si este límite
---será total (la suma de ambas caminatas no puede superar el límite) o particular (ninguna
---caminata puede superar el límite).

drop table recorridos_raw;
create table recorridos_raw (
	wkt text,
	id bigint not null,
	linea int not null,
	ramal varchar, 
	sentido varchar,
	primary key(id, linea));


COPY recorridos_raw
FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/recorridos-clean.csv'
DELIMITER ',' 
CSV HEADER encoding 'latin1';

select * from recorridos_raw limit 5;

--modificamos la columna wkt de tipo text a tipo linestring
--ALTER TABLE recorridos ALTER COLUMN wkt TYPE geometry USING ST_SetSRID((wkt::GEOMETRY), 4326);

drop table recorridos;
create table recorridos as
select id,linea,ramal,sentido, ST_GeomFromText(wkt) as recorrido from recorridos_raw

select * from recorridos limit 5;

--usamos la tabla anterior de paradas
select * from paradas limit 5;

-------------------------------------------probando----------------------------------------------
	
--Probamos la funcion ST_ClosesPoint que devuelve un punto en la primer geometria que este mas cerca de la segunda geometria
select ST_AsText(
	ST_ClosestPoint(
		ST_MakeLine(ST_MakePoint(0,0), ST_MakePoint(2,2)),
		ST_MakePoint(0, 1)
		)
	)

	
--Probamos la funcion ST_LineLocatePoint que devuelve el porcentaje de la linea en la que se encuentra un punto
select	ST_LineLocatePoint(
		ST_MakeLine(ST_MakePoint(4,4), ST_MakePoint(0,0)),
		ST_MakePoint(1, 1)
		)

select	ST_LineLocatePoint(
		ST_MakeLine(ST_MakePoint(-34.617454, -58.368293), ST_MakePoint(-34.581750, -58.407540)),
		ST_MakePoint(-34.601750, -58.387540)
		)
		
-- 1,1 esta mas lejos que 2,2 segun el sentido de la linea que empieza en 4,4 y termina en 0,0.
select	ST_LineLocatePoint( linea, punto_3_3) <  ST_LineLocatePoint( linea, punto_1_1) 
from (
	select 	ST_MakeLine(ST_MakePoint(4,4), ST_MakePoint(0,0)) as linea ,
		ST_MakePoint(3, 3) as punto_3_3,
		ST_MakePoint(1, 1) as punto_1_1


) as tabla

--------------------------------------------------------------------------------------------------

--drop table paradas_por_recorrido;
create table paradas_por_recorrido as
select *, ST_LineLocatePoint(recorrido,parada)*100 as porcentaje_parada_en_recorrido
from (select p.linea, recorrido, ramal, sentido, id_parada, point, latitud, longitud, coords, calle, altura,  
	ST_ClosestPoint(r.recorrido,p.point) as parada
from paradas p
inner join recorridos r
on (p.linea = r.linea)) as tabla 

select ST_AsText(point) as point, 
	ST_AsText(parada) as parada,
	ST_AsText(recorrido) as recorrido,
	ST_AsText(coords) as coords,
*  from paradas_por_recorrido limit 5

--probamos buscar las paradas de la linea 93 en orden
select calle, altura, latitud, longitud, porcentaje_parada_en_recorrido
from paradas_por_recorrido
where (linea = 93 and sentido = 'IDA')
order by porcentaje_parada_en_recorrido

			

-------------------------probando--------------------------------------


with a as ( 
	select *, ST_Distance(Geography(ST_Transform(ST_SetSrid(ST_MakePoint(-58.368293, -34.617454),4326),4326)), coords) as distancia
	from paradas_por_recorrido)
select calle,altura, ST_AsText(point), ST_AsText(parada),*
from a
where distancia < 200
order by porcentaje_parada_en_recorrido 

with o as (
	select *, ST_Distance(Geography(ST_Transform(ST_SetSrid(ST_MakePoint(-58.368293, -34.617454),4326),4326)), coords) as distancia_origen
	from paradas_por_recorrido
), d as(
	select *, ST_Distance(Geography(ST_Transform(ST_SetSrid(ST_MakePoint(-58.407540, -34.581750),4326),4326)), coords) as distancia_destino
	from paradas_por_recorrido
)
        select 
        o.calle as calle_origen, o.altura as altura_origen,
        d.calle as calle_detino, d.altura as altura_destino,
	ST_AsText(o.parada) as coord_origen, ST_AsText(d.parada) as coord_destino, 
	d.distancia_destino, o.distancia_origen,
        o.porcentaje_parada_en_recorrido as porcentaje_origen,  
        d.porcentaje_parada_en_recorrido as porcentaje_destino
        from o
        inner join d
	on (o.linea = d.linea and o.sentido = o.sentido and o.ramal = d.ramal 
		and o.recorrido = d.recorrido and ST_Equals(o.parada, d.parada) is not true)
        where o.distancia_origen < 200
        and d.distancia_destino < 200
        and o.porcentaje_parada_en_recorrido  < d.porcentaje_parada_en_recorrido;
        
-------------------------------------------------------------------------------------------

--DROP FUNCTION colectivos_a_utilizar

create or replace function colectivos_a_utilizar(origen geometry, destino geometry, max_distancia float)
  returns table (
    calle_origen varchar,
    altura_origen int,
    linea int,
    ramal varchar,
    sentido varchar,
    calle_destino varchar,
    altura_destino int)
  as $$
  begin
      return query
	with o as (
		select *, ST_Distance(Geography(ST_Transform(ST_SetSrid(origen,4326),4326)), coords) as distancia_origen
		from paradas_por_recorrido
        ), d as(
		select *, ST_Distance(Geography(ST_Transform(ST_SetSrid(destino,4326),4326)), coords) as distancia_destino
		from paradas_por_recorrido
        )
        select o.calle as calle_origen , o.altura as altura_origen,
        o.linea, o.ramal, o.sentido,
        d.calle as calle_destino, d.altura as altura_destino
        from o
        inner join d
        on (o.linea = d.linea and o.sentido = o.sentido and o.ramal = d.ramal 
		and o.recorrido = d.recorrido and ST_Equals(o.parada, d.parada) is not true)
        where (o.porcentaje_parada_en_recorrido  < d.porcentaje_parada_en_recorrido)
        and o.distancia_origen < max_distancia
        and d.distancia_destino < max_distancia;
     
  end; $$
language 'plpgsql';


--colectivos que me llevan a mi casa desde la facu
select *
from colectivos_a_utilizar(
ST_MakePoint( -58.368293, -34.617454),
ST_MakePoint(-58.407540,-34.581750),
400.0);





		
      
