-- Importamos las librerías de postgis.
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;

-- El CSV limpio del mapa de la ciudad tiene coordenadas X, Y (longitud, latitud).
create table paradas_raw (
	longitud float,
	latitud float
);

COPY paradas_raw
FROM '/home/tomas/Desktop/BDD/TP/datasets/paradas-de-colectivo-clean.csv'
DELIMITER ',' 
CSV HEADER;

-- Observamos el contenido de las primeras filas.
select * from paradas_raw limit 5;

-- Creamos una tabla con las los puntos correspondientes a cada parada.
-- Google maps representa las coordenadas como (Latitud, Longitud), orden inverso al
-- de la ciudad. Representaremos nuestras paradas con esa convención.
create table paradas as
select ST_MakePoint(latitud, longitud) as coords from paradas_raw

-- Distancia en metros de todos los puntos a la facultad de ingeniería.
select ST_Distance(ST_MakePoint(-34.617454, -58.368293), coords)*111000 as distancia
from paradas
order by distancia asc;

-- Devuelve las paradas a menos de max_distancia respecto de la parada_objetivo.
create or replace function paradas_cercanas(parada_objetivo geometry, max_distancia float)
  returns table
    (distance float)
  as $$
  declare
    metros_por_grado constant float := 111000;
  begin
      return query
	with c as (
          select ST_Distance(parada_objetivo, coords)*metros_por_grado as distancia
	  from paradas
        )
        select *
        from c
        where distancia < max_distancia;
  end; $$
language 'plpgsql';

-- Las paradas a menos de 200 metros de FIUBA (PC).
-- Las coordenadas de FIUBA fueron obtenidas de Google Maps.
select paradas_cercanas(ST_MakePoint(-34.617454, -58.368293), 200);
