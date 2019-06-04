-- Importamos las librerías de postgis.
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;

--- El CSV limpio del mapa de la ciudad tiene coordenadas X, Y (longitud, latitud).
create table paradas_raw (
	id_parada bigint primary key,
	longitud float,
	latitud float,
	calle varchar,
	altura int
);

COPY paradas_raw
-- FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/paradas-de-colectivo-clean.csv'
FROM '/home/tomas/FIUBA/BDD/tp/datasets/paradas-de-colectivo-clean.csv'
NULL 'S/N'
DELIMITER ','
CSV HEADER;

drop table lineas_raw;
create table lineas_raw (
	linea int not null,
	id_parada int references paradas_raw(id_parada),
	primary key(linea, id_parada));

COPY lineas_raw
-- FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/lineas-por-paradas-clean.csv'
FROM '/home/tomas/FIUBA/BDD/tp/datasets/lineas-por-paradas-clean.csv'
DELIMITER ','
CSV HEADER;

-- Observamos el contenido de las primeras filas de lineas.
select * from lineas_raw limit 5;


drop table paradas;
-- Creamos una tabla con las los puntos correspondientes a cada parada.
-- Google maps representa las coordenadas como (Latitud, Longitud) ~(-58,-34)
-- Nosotros usaremos el orden inverso porque es el que esta en los linestring

create table paradas as
select p.id_parada, calle, altura, linea, latitud, longitud, ST_MakePoint(longitud, latitud) as point,
	Geography(
		ST_Transform(
			ST_SetSrid(ST_MakePoint(longitud, latitud),4326),
			4326)
		) as coords
from paradas_raw p
inner join lineas_raw l
on p.id_parada = l.id_parada;

DROP FUNCTION IF EXISTS  paradas_cercanas;
-- Devuelve las paradas a menos de max_distancia respecto de la parada_objetivo.
create or replace function paradas_cercanas(parada_objetivo geometry, max_distancia float)
  returns table (
    calle varchar,
    altura int,
    distancia float,
    linea int)
  as $$
  begin
      return query
	with c as (
          select *, ST_Distance(Geography(ST_Transform(ST_SetSrid(parada_objetivo,4326),4326)), coords) as distancia
	  from paradas
        )
        select c.calle, c.altura, c.distancia, c.linea
        from c
        where c.distancia < max_distancia;
  end; $$
language 'plpgsql';

-- Las paradas a menos de 200 metros de FIUBA (PC).
-- Las coordenadas de FIUBA fueron obtenidas de Google Maps.
select calle, altura, linea from paradas_cercanas(ST_MakePoint(-58.368293,-34.617454), 200.0);

--drop function viajar_con_2_colectivos;
create or replace function viajar_con_2_colectivos(origen geometry, destino geometry, max_distancia float)
  returns table (
    calle_origen varchar,
    altura_origen int,
    linea1 int,
    ramal1 varchar,
    sentido1 varchar,
    calle_destino varchar,
    altura_destino int,
    linea2 int,
    ramal2 varchar,
    sentido2 varchar)
  as $$
  begin
    return query
	with p1 as (
		select linea, ramal, sentido, coords, porcentaje_parada_en_recorrido
		from paradas_por_recorrido
		where linea in (
			select distinct linea from paradas where ST_Distance(Geography(origen), coords) < max_distancia
		) group by linea, ramal, sentido, coords, porcentaje_parada_en_recorrido
	), p2 as (
		select linea, ramal, sentido, coords, porcentaje_parada_en_recorrido
		from paradas_por_recorrido
		where linea in (
			select distinct linea from paradas where ST_Distance(Geography(destino), coords) < max_distancia
		) group by linea, ramal, sentido, coords, porcentaje_parada_en_recorrido
	), o as (
		select distinct calle as calle_origen, altura as altura_origen, linea, ramal, sentido, porcentaje_parada_en_recorrido
		from paradas_por_recorrido
		where ST_Distance(Geography(origen), coords) < max_distancia
	), d as (
		select distinct calle as calle_destino, altura as altura_destino, linea, ramal, sentido, porcentaje_parada_en_recorrido
		from paradas_por_recorrido
		where ST_Distance(Geography(destino), coords) < max_distancia
	)
	select distinct o.calle_origen, o.altura_origen, p1.linea as linea1, p1.ramal as ramal1, p1.sentido as sentido1,
		d.calle_destino, d.altura_destino, p2.linea as linea2, p2.ramal as ramal2, p2.sentido as sentido2
	from p1
	inner join p2
	on (p1.linea != p2.linea)
	inner join o
	on (o.linea = p1.linea and o.ramal = p1.ramal and o.sentido = p1.sentido)
	inner join d
	on (d.linea = p2.linea and d.ramal = p2.ramal and d.sentido = p2.sentido)
	where ST_Distance(p1.coords, p2.coords) < max_distancia
	and o.porcentaje_parada_en_recorrido < p1.porcentaje_parada_en_recorrido
	and p2.porcentaje_parada_en_recorrido < d.porcentaje_parada_en_recorrido
	and (p1.linea, p1.ramal, p1.sentido) not in (
		select distinct linea, ramal, sentido
		from colectivos_a_utilizar(origen, destino, max_distancia))
	and (p2.linea, p2.ramal, p2.sentido) not in (
		select distinct linea, ramal, sentido
		from colectivos_a_utilizar(origen, destino, max_distancia));
     --esto ultimo para que no elija el colectivo que me lleva directo
  end; $$
language 'plpgsql';


--Ejemplo: de segurola y beiro a cabildo y congreso
select * from viajar_con_2_colectivos(ST_MakePoint(-58.512955, -34.606336), ST_MakePoint(-58.461966, -34.555347), 200);
