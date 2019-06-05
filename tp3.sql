-- Punto 3. Ramales de Parada.

-- En base a una línea de colectivo (dada como número de colectivo), analizar qué paradas del
-- mismo no son recorridas por todos los ramales del colectivo. Devolver calle, número de la
-- parada y nombre del ramal que pasa por la parada, únicamente para aquellas paradas que no
-- sean recorridas por todos los ramales de la línea.

create or replace function paradas_incompletas(linea_objetivo int)
  returns table (
    id_parada bigint,
    calle varchar,
    ramal varchar)
  as $$
  begin
    return query
	with paradas_incompletas as (
		select distinct(ppr.id_parada) from paradas_por_recorrido as ppr
		where ppr.linea = linea_objetivo
		group by ppr.id_parada, sentido
		having count(ppr.ramal) < (
			select count(distinct(ppr.ramal)) 
			from paradas_por_recorrido as ppr
			where ppr.linea = linea_objetivo
		)
	)
	select distinct(ppr.id_parada), ppr.calle, ppr.ramal
    from paradas_por_recorrido as ppr
    where exists(
   		select 1
   		from paradas_incompletas as pi
   		where pi.id_parada = ppr.id_parada
  	) and ppr.linea = linea_objetivo;
  end; $$
language 'plpgsql';

-- Ejemplo: paradas del 60 por las cuales no pasan todos los ramales.
select * from paradas_incompletas(60);

-- Ejemplo: paradas del 130 por las cuales no pasan todos los ramales.
select * from paradas_incompletas(130) order by id_parada;

select distinct(ramal) from
paradas_por_recorrido where linea = 130

select * from 
paradas_por_recorrido
where id_parada = 1002111 and linea = 130