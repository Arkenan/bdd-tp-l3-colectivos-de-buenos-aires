---ENUNCIADO
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
-- FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/recorridos-clean.csv'
FROM '/home/tomas/FIUBA/BDD/tp/datasets/recorridos-clean.csv'
DELIMITER ','
CSV HEADER encoding 'latin1';

--modificamos la columna wkt de tipo text a tipo linestring
--ALTER TABLE recorridos ALTER COLUMN wkt TYPE geometry USING ST_SetSRID((wkt::GEOMETRY), 4326);

drop table recorridos;
create table recorridos as
	select id, linea, ramal, sentido, ST_GeomFromText(wkt) as recorrido,
	Geography(ST_Transform(ST_SetSrid(ST_GeomFromText(wkt),4326),4326)) as recorrido_geo
	from recorridos_raw

--drop table paradas_por_recorrido;

-- Creación de tabla que asocia los recorridos de cada línea y ramal con sus correspondientes paradas.
-- TODO: debería solo seleccionar para cada parada un sentido. Para esto podría seleccionarse el que más cerca quede.
-- TODO: los ramales que no pasan por un lugar determinado no deberían aparecer en esa parada.
drop table paradas_por_recorrido;
create table paradas_por_recorrido as
select *, ST_LineLocatePoint(recorrido,parada)*100 as porcentaje_parada_en_recorrido
from (
	select p.linea, recorrido, ramal, sentido, id_parada, point, 
		latitud, longitud, coords, calle, altura,
		ST_ClosestPoint(r.recorrido,p.point) as parada,
		ST_Distance(r.recorrido_geo, p.coords) as distancia_a_recorrido
	from paradas p
	inner join recorridos r
	on (p.linea = r.linea)
	where ST_Distance(r.recorrido_geo, p.coords) < 100
) as tabla;

select ST_AsText(point) as point,
	ST_AsText(parada) as parada,
	ST_AsText(recorrido) as recorrido,
	ST_AsText(coords) as coords,
  *
from paradas_por_recorrido limit 5

-- Probamos buscar las paradas de la linea 93 en orden
select calle, altura, latitud, longitud, porcentaje_parada_en_recorrido
from paradas_por_recorrido
where (linea = 93 and sentido = 'IDA')
order by porcentaje_parada_en_recorrido

-- Colectivos a utilizar para viajar de origen adestino, caminando a lo sumo "max_distancia" metros.
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

-- Ejemplo: colectivos que me llevan a mi casa desde la facu.
select *
from colectivos_a_utilizar(
ST_MakePoint( -58.368293, -34.617454),
ST_MakePoint(-58.407540,-34.581750),
400.0);
