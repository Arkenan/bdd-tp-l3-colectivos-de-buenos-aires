CREATE TABLE paradas (
	INDEX	      INT,
	X             FLOAT,
	Y             FLOAT,
	STOP_ID       INT,
	TIPO          VARCHAR,
	CALLE         VARCHAR,
	NUMERO        INT,
	ENTRE1        VARCHAR,
	ENTRE2        VARCHAR,
	LINEAS        VARCHAR, -- Esto va a tener que ser preprocesado.
	DIR_NORM      VARCHAR,
	CALLE_NORM    VARCHAR,
	ALTURA_NOR    VARCHAR, 
	COORDX        VARCHAR, -- Esto tal vez tenga que ser un float, pero tiene formato raro.
	COORDY        VARCHAR, -- Esto tal vez tenga que ser un float, pero tiene formato raro.
	METROBUS      BOOLEAN,
	STOP_NAME     VARCHAR,
	STOP_DESC     VARCHAR,
	FUENTE        VARCHAR, -- Categorías 'RELEVAMIENTO2015', 'USIG'
	VERIFICADA    BOOLEAN,
	FECHA_ULTI    DATE
)

COPY paradas
FROM '/home/tomas/Desktop/BDD/TP/datasets/csv/paradas-de-colectivo-clean.csv'
DELIMITER ',' 
CSV HEADER;

SELECT * FROM paradas