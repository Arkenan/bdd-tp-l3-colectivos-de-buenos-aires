
-------------------------------------------probando----------------------------------------------

--Probamos la funcion ST_ClosesPoint que devuelve un punto en la primer geometria que este mas cerca de la segunda geometria
select ST_AsText(
	ST_ClosestPoint(
		ST_MakeLine(ST_MakePoint(0,0), ST_MakePoint(2,2)),
		ST_MakePoint(0, 1)
	)
);

--Probamos la funcion ST_LineLocatePoint que devuelve el porcentaje de la linea en la que se encuentra un punto
select	ST_LineLocatePoint(
		ST_MakeLine(ST_MakePoint(4,4), ST_MakePoint(0,0)),
		ST_MakePoint(1, 1)
		);

select	ST_LineLocatePoint(
		ST_MakeLine(ST_MakePoint(-34.617454, -58.368293), ST_MakePoint(-34.581750, -58.407540)),
		ST_MakePoint(-34.601750, -58.387540)
		);

-- 1,1 esta mas lejos que 2,2 segun el sentido de la linea que empieza en 4,4 y termina en 0,0.
select	ST_LineLocatePoint( linea, punto_3_3) <  ST_LineLocatePoint( linea, punto_1_1)
from (
	select 	ST_MakeLine(ST_MakePoint(4,4), ST_MakePoint(0,0)) as linea ,
		ST_MakePoint(3, 3) as punto_3_3,
		ST_MakePoint(1, 1) as punto_1_1
) as tabla;

--------------------------------------------------------------------------------------------------
-------------------------probando----------------------------------------------

with a as (
	select *, ST_Distance(Geography(ST_Transform(ST_SetSrid(ST_MakePoint(-58.368293, -34.617454),4326),4326)), coords) as distancia
	from paradas_por_recorrido)
select calle,altura, ST_AsText(point), ST_AsText(parada),*
from a
where distancia < 200
order by porcentaje_parada_en_recorrido

-------------------------------------------------------------------------------
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
