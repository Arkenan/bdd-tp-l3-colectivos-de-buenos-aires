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
	id bigint not null,
	linea int not null,
	ramal varchar, 
	sentido varchar,
	primary key(id, linea));


COPY recorridos
FROM '/home/jazminferreiro/jaz/fiuba/baseDeDatos/tp/bdd-tp/datasets/recorridos-clean.csv'
DELIMITER ',' 
CSV HEADER encoding 'latin1';

--modificamos la columna wkt de tipo text a tipo linestring
--ALTER TABLE recorridos ALTER COLUMN wkt TYPE geometry USING ST_SetSRID((wkt::GEOMETRY), 4326);

select * from recorridos limit 5;

--ALTER TABLE paradas ALTER COLUMN coords TYPE geometry USING ST_SetSRID((coords::GEOMETRY), 4326);

create table paradas2 as
select p.id_parada, latitud, longitud, calle, altura, linea 
from paradas_raw p
inner join lineas_raw l
on p.id_parada = l.id_parada

select * from paradas2 limit 5;


select p.linea,ST_Intersects(p.coords, r.wkt) as point_inside_line, ST_GeometryType(p.coords), ST_GeometryType(r.wkt)
from paradas p
inner join recorridos r
on ( p.linea = r.linea )
limit 5

--probamos la funcion intersects
SELECT ST_Intersects(
		ST_GeographyFromText('SRID=4326;LINESTRING(-43.23456 72.4567,-43.23456 72.4568)'),
		ST_GeographyFromText('SRID=4326;POINT(-43.23456 72.4567772)')
		);

drop table paradas_por_recorrido;
create table paradas_por_recorrido as
select id_parada, latitud, longitud, calle, altura, p.linea, wkt, ramal, sentido
from paradas2 p
inner join recorridos r
on ST_Intersects(
		ST_GeographyFromText(concat('SRID=4326;',wkt)),
		ST_GeographyFromText(concat('SRID=4326;POINT(',latitud,' ',longitud,')'))
		)
--on (p.linea = r.linea)

select * from paradas_por_recorrido limit 5


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
  declare
    metros_por_grado constant float := 111000;
  begin
      return query
	with o as (
		select *, ST_Distance(origen, coords)*metros_por_grado as distancia_origen
		from paradas_por_recorrido
        ), d as(
		select *, ST_Distance(destino, coords)*metros_por_grado as distancia_destino
		from paradas_por_recorrido
        )
        select o.calle as calle_origen , o.altura as altura_origen,
        o.linea, o.ramal, o.sentido,
        d.calle as calle_destino, d.altura as altura_destino
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
from colectivos_a_utilizar(
ST_SetSRID(ST_MakePoint(-34.617454, -58.368293),4326), 
ST_SetSRID(ST_MakePoint(-34.581750, -58.407540),4326),
500);
