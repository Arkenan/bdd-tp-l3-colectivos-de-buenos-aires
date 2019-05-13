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

drop table recorridos;
create table recorridos (
	wkt text,
	id bigint primary key,
	linea int not null,
	tipo_servicio varchar, 
	ramal varchar, 
	sentido varchar);


COPY recorridos
FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/recorrido-colectivos.csv'
DELIMITER ';' 
CSV HEADER encoding 'latin1';

--modificamos la columna wkt de tipo text a tipo linestring
ALTER TABLE recorridos ALTER COLUMN wkt TYPE geometry USING ST_SetSRID((wkt::GEOMETRY), 4326);


select * from recorridos limit 5;

--Usuamos la tabla creada para el punto 1
select * 
from paradas p
inner join recorridos r
on p.linea = r.linea
limit 5




create or replace function colectivos_a_utilizar(origen geometry, destino geometry, max_distancia float)
  returns table (
    calle_origen varchar,
    altura_origen int,
    distancia_origen float,
    linea int,
    ramal varchar,
    sentido varcar,
    calle_destino varchar,
    altura_destino int,
    distancia_destino float)
  as $$
  declare
    metros_por_grado constant float := 111000;
  begin
      return query
	with o as (
		select *, ST_Distance(origen, coords)*metros_por_grado as distancia_origen
		from paradas
        ), d as(
		select *, ST_Distance(destino, coords)*metros_por_grado as distancia_destino
		from paradas
        )
        select o.calle as calle_origen , o.altura as altura_origen, o.distancia_origen, 
        o.linea, o.ramal, o.sentido
         d.calle as calle_destino, d.altura as altura_destino, d.distancia_destino
		
        from o
        inner join d
        on o.linea = d.linea
        where (o.distancia_origen + d.distancia_destino) < max_distancia
        and o.ramal = d.ramal
        and o.sentido = o.sentido;
  end; $$
language 'plpgsql';


--colectivos que me llevan a mi casa desde la facu
select *
from colectivos_a_utilizar(ST_MakePoint(-34.617454, -58.368293), ST_MakePoint(-34.581750, -58.407540),500);
