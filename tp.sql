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
FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/paradas-de-colectivo-clean.csv'
--FROM '/home/tomas/Desktop/BDD/TP/datasets/paradas-de-colectivo-clean.csv'
DELIMITER ',' 
CSV HEADER;


-- Observamos el contenido de las primeras filas de paradas.
select * from paradas_raw limit 5;



create table lineas_raw (
	linea int not null,
	id_parada int references paradas_raw(id_parada),
	primary key(linea, id_parada));


COPY lineas_raw
FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/lineas-por-paradas-clean.csv'
DELIMITER ',' 
CSV HEADER;

-- Observamos el contenido de las primeras filas de lineas.
select * from lineas_raw limit 5;


drop table paradas
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
on p.id_parada = l.id_parada

select * from paradas limit 5;
		


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

