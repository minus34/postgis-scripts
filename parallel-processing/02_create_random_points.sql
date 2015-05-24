
-- Create points distributed by neighbourhood population density - single CPU
-- Windows 8.1
--   Postgres 9.3.7: ~1m = 50 seconds, ~21m = 710 seconds
--   Postgres 9.4.2" ~1m = 50 seconds, ~21m = s
DROP TABLE IF EXISTS mb_1m_random_points;
CREATE UNLOGGED TABLE mb_1m_random_points
(
  mb_code11 character varying(11) NOT NULL,
  geom geometry(POINT, 4283, 2)
) WITH (OIDS=FALSE);
ALTER TABLE mb_1m_random_points OWNER TO postgres;
CREATE INDEX mb_1m_random_points_geom_gist ON mb_1m_random_points USING gist (geom);

INSERT INTO mb_1m_random_points (mb_code11, geom)
--SELECT mb_code11, ST_RandomPointsInPolygon((ST_Dump(geom)).geom, (population::float/21.0)::integer) FROM mb_2011_aust WHERE (population::float/21.0)::integer > 0;
SELECT mb_code11, ST_RandomPointsInPolygon((ST_Dump(geom)).geom, population) FROM mb_2011_aust WHERE population > 0;

ALTER TABLE mb_1m_random_points CLUSTER ON mb_1m_random_points_geom_gist;
ANALYZE mb_1m_random_points;
 
select Count(*) from mb_1m_random_points; -- ~1m = 1,019,910 records, ~21m = 21,458,707 records


-- Create points distributed by neighbourhood population density - parallel processing
-- Windows 8.1
--   Postgres 9.3.7: ~1m = 50 seconds, ~21m = 262 seconds
--   Postgres 9.4.2: ~1m =  seconds, ~21m =  seconds
DROP TABLE IF EXISTS mb_1m_random_points;
CREATE UNLOGGED TABLE mb_1m_random_points
(
  mb_code11 character varying(11) NOT NULL,
  geom geometry(POINT, 4283, 2)
) WITH (OIDS=FALSE);
ALTER TABLE mb_1m_random_points OWNER TO postgres;
CREATE INDEX mb_1m_random_points_geom_gist ON mb_1m_random_points USING gist (geom);
COMMIT;

SELECT parsel('mb_2011_aust'
      ,'gid'
      ,'SELECT mb.mb_code11, ST_RandomPointsInPolygon((ST_Dump(mb.geom)).geom, population) FROM mb_2011_aust AS mb WHERE mb.population > 0'
      ,'mb_1m_random_points'
      ,'mb'
      ,6);

--      ,'SELECT mb.mb_code11, ST_RandomPointsInPolygon((ST_Dump(mb.geom)).geom, (mb.population::float/21.0)::integer) FROM mb_2011_aust AS mb WHERE (mb.population::float/21.0)::integer > 0'

ALTER TABLE mb_1m_random_points CLUSTER ON mb_1m_random_points_geom_gist;
ANALYZE mb_1m_random_points;

--SET AUTOCOMMIT TO OFF;

select Count(*) from mb_1m_random_points; -- ~1m = 1,019,910 records, ~21m = 21,458,707 records


-- Select Meshblock ID on points using ST_Contains - single CPU
-- Windows 8.1
--   Postgres 9.3.7: ~1m = 42 seconds, ~21m = 139 seconds
--   Postgres 9.4.2: ~1m =  seconds, ~21m =  seconds
DROP TABLE IF EXISTS points_mb;
CREATE UNLOGGED TABLE points_mb
(
  orig_mb_code11 character varying(11) NOT NULL,
  mb_code11 character varying(11) NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE points_mb OWNER TO postgres;

INSERT INTO points_mb
SELECT pnts.mb_code11, bdys.mb_code11 FROM mb_1m_random_points AS pnts JOIN mb_2011_aust AS bdys ON ST_Contains(bdys.geom, pnts.geom);

select Count(*) from points_mb; -- ~1m = 1,019,910 records, ~21m = 21,458,707 records


-- Select Meshblock ID on points using ST_Contains - parallel processing
-- Windows 8.1
--   Postgres 9.3.7: ~1m = 12 seconds, ~21m = 55 seconds
--   Postgres 9.4.2: ~1m =  seconds, ~21m =  seconds
DROP TABLE IF EXISTS points_mb;
CREATE UNLOGGED TABLE points_mb
(
  orig_mb_code11 character varying(11) NOT NULL,
  mb_code11 character varying(11) NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE points_mb OWNER TO postgres;
COMMIT;

SELECT parsel('mb_2011_aust'
      ,'gid'
      ,'SELECT pnts.mb_code11, bdys.mb_code11 FROM mb_1m_random_points AS pnts JOIN mb_2011_aust AS bdys ON ST_Contains(bdys.geom, pnts.geom)'
      ,'points_mb'
      ,'bdys'
      ,16);

select Count(*) from points_mb; -- ~1m = 1,019,910 records, ~21m = 21,458,707 records


