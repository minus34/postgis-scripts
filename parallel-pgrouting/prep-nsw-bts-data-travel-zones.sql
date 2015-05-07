
--CREATE EXTENSION postgis;
--CREATE EXTENSION pgRouting;
--CREATE EXTENSION dblink;

-- Import NSW BTS Journey to Work data
DROP TABLE IF EXISTS jtw_table2011eh07;
CREATE TABLE jtw_table2011eh07
(
  o_tz11 character varying(10),
  o_tz_name11 character varying(100),
  o_lga_code11 character varying(10),
  o_lga_name11 character varying(100),
  o_sa2_11 integer,
  o_sa2_name11 character varying(100),
  o_sa3_11 integer,
  o_sa3_name11 character varying(100),
  o_sa4_11 integer,
  o_sa4_name11 character varying(100),
  o_ste_11 smallint,
  o_ste_name11 character varying(100),
  o_study_area_11 smallint,
  o_study_area_name11 character varying(100),
  o_lga_study_area_name11 character varying(100),
  d_tz11 character varying(10),
  d_tz_name11 character varying(100),
  d_lga_code11 integer,
  d_lga_name11 character varying(100),
  d_sa2_11 integer,
  d_sa2_name11 character varying(100),
  d_sa3_11 integer,
  d_sa3_name11 character varying(100),
  d_sa4_11 integer,
  d_sa4_name11 character varying(100),
  d_ste_11 smallint,
  d_ste_name11 character varying(100),
  d_study_area_11 smallint,
  d_study_area_name11 character varying(100),
  d_lga_study_area_name11 character varying(100),
  mode10 smallint,
  mode10_name character varying(100),
  uaicp smallint,
  uaicp_name character varying(100),
  employed_persons numeric(10,2)
)
WITH (OIDS=FALSE);
ALTER TABLE jtw_table2011eh07 OWNER TO postgres;

COPY jtw_table2011eh07 FROM 'C:\\minus34\\GitHub\\WestCON\\data\\nsw-bts-travel-zones\\2011JTW_TableEH07.csv' CSV HEADER; -- 783,237
UPDATE jtw_table2011eh07 SET o_tz11 = trim(o_tz11) WHERE o_tz11 = ' '; -- 4282
UPDATE jtw_table2011eh07 SET d_tz11 = trim(d_tz11) WHERE d_tz11 = ' '; -- 0
ANALYSE jtw_table2011eh07;


-- 
-- --Create table of Sydney Travel Zones
-- DROP TABLE IF EXISTS tz_nsw_2011_sydney;
-- CREATE TABLE tz_nsw_2011_sydney
-- (
--   tz_code11 integer NOT NULL,
--   tz_name11 character varying(100),
--   sa3_code11 integer,
--   geom geometry(MultiPolygon,4326,2),
--   CONSTRAINT tz_nsw_2011_sydney_pkey PRIMARY KEY (tz_code11)
-- )
-- WITH (OIDS=FALSE);
-- ALTER TABLE tz_nsw_2011_sydney OWNER TO postgres;
-- 
-- CREATE INDEX tz_nsw_2011_sydney_geom_idx ON tz_nsw_2011_sydney USING gist (geom);
-- 
-- INSERT INTO tz_nsw_2011_sydney -- 2272
-- SELECT tz_code11,
--        tz_name11,
--        sa3_code11,
--        ST_Transform(ST_Multi(ST_Buffer(geom, 0.0)), 4326)
--   FROM tz_nsw_2011
--   WHERE sa3_code11 IN (SELECT sa3_code FROM sa3_2011_sydney_bts);


--Create table of travel zone centroids and their source and target road network ids
DROP TABLE IF EXISTS tz_nsw_2011_routing;
CREATE TABLE tz_nsw_2011_routing
(
  tz_code11 integer NOT NULL,
  tz_name11 character varying(100) NOT NULL,
  sa3_code11 integer NOT NULL,
  source integer,
  target integer,
  geom geometry(Point,4326,2) NOT NULL,
  CONSTRAINT tz_nsw_2011_routing_pkey PRIMARY KEY (tz_code11)
)
WITH (OIDS=FALSE);
ALTER TABLE tz_nsw_2011_routing OWNER TO postgres;

CREATE INDEX tz_nsw_2011_routing_geom_idx ON tz_nsw_2011_routing USING gist (geom);

INSERT INTO tz_nsw_2011_routing (tz_code11, tz_name11, sa3_code11, geom) -- 3514 
SELECT tz_code11,
       tz_name11,
       sa3_code11,
       ST_Centroid(ST_Transform(geom, 4326))
  FROM tz_nsw_2011;

ANALYSE tz_nsw_2011_routing;
CLUSTER tz_nsw_2011_routing USING tz_nsw_2011_routing_geom_idx;

--Snap travel zone centroids to edge ids
UPDATE tz_nsw_2011_routing
  SET source = (SELECT id FROM nsw_osm_main_vertices_pgr ORDER BY the_geom <-> geom LIMIT 1);

UPDATE tz_nsw_2011_routing SET target = source;


--Create table of motorist counts for each combination of origin and destination travel zone within Sydney
DROP TABLE IF EXISTS tz_nsw_2011_vehicles;
CREATE TABLE tz_nsw_2011_vehicles
(
  gid serial NOT NULL,
  o_tz integer NOT NULL,
  o_sa3 integer,
  d_tz integer NOT NULL,
  d_sa3 integer,
  vehicles integer NOT NULL,
  source integer,
  target integer,
  --geom geometry(MultiLinestring, 4326, 2),
  CONSTRAINT tz_nsw_2011_vehicles_pnt_pkey PRIMARY KEY (gid)
)
WITH (OIDS=FALSE);
ALTER TABLE tz_nsw_2011_vehicles OWNER TO postgres;

INSERT INTO tz_nsw_2011_vehicles (o_tz, d_tz, vehicles) -- 380106
SELECT o_tz11::integer,
       d_tz11::integer,
       SUM(employed_persons)::integer AS vehicles -- 1 driver = 1 vehicle
  FROM jtw_table2011eh07
  WHERE mode10 = 4
  --WHERE mode10 IN (4, 5)
  AND o_tz11 <> '' AND d_tz11 <> ''
GROUP BY o_tz11,
         d_tz11;

UPDATE tz_nsw_2011_vehicles AS mot -- 379661  
   SET source = tz.source
      ,o_sa3 = sa3_code11
  FROM tz_nsw_2011_routing AS tz
  WHERE mot.o_tz = tz.tz_code11;

UPDATE tz_nsw_2011_vehicles AS mot -- 376842  
   SET target = tz.target
      ,d_sa3 = sa3_code11
  FROM tz_nsw_2011_routing AS tz
  WHERE mot.d_tz = tz.tz_code11;

--Only keep rows that have coords and vehicles (i.e. when origin and destination are in NSW) -- 37388 
DELETE FROM tz_nsw_2011_vehicles
  WHERE source IS NULL
  OR target IS NULL
  OR vehicles = 0;

ANALYSE tz_nsw_2011_vehicles;


----------------------------------------------
-- CREATE ROUTES
----------------------------------------------

DROP TABLE IF EXISTS tz_nsw_2011_origin_routes CASCADE;
CREATE TABLE tz_nsw_2011_origin_routes
(
  o_tz integer NOT NULL,
  o_sa3 integer NOT NULL,
  d_tz integer NOT NULL,
  d_sa3 integer NOT NULL,
  vehicles integer NOT NULL,
  seq integer NOT NULL,
  id2 integer NOT NULL,
  cost double precision NOT NULL
)
WITH (OIDS=FALSE);
ALTER TABLE tz_nsw_2011_origin_routes OWNER TO postgres;
COMMIT;

-- INSERT INTO tz_nsw_2011_origin_routes
-- SELECT * FROM tz_routes('SELECT * FROM tz_nsw_2011_vehicles LIMIT 600');

-- Create routes using parallel processing (only support inserts)
SELECT parsel('tz_nsw_2011_vehicles' -- table to parallel process
      ,'gid' -- id field of table to parallel process (must be an integer)
      ,'SELECT * FROM tz_routes(''SELECT * FROM tz_nsw_2011_vehicles AS fred'')' -- the query to insert
      ,'tz_nsw_2011_origin_routes' -- table (and fields) to insert the results into
      ,'fred' -- table to parallel process aliasname
      ,6); -- number of parallel processes - recommended to be 75% of available logical CPUs (e.g. 12 processes on 16 CPU machine)
COMMIT;

CREATE INDEX tz_nsw_2011_origin_routes_id2_idx ON tz_nsw_2011_origin_routes USING btree (id2);

--SELECT Count(*) FROM tz_nsw_2011_origin_routes;


-- Create view of routes and the volume of traffic they get each day to work
DROP VIEW IF EXISTS vw_tz_nsw_2011_origin_routes;
CREATE VIEW vw_tz_nsw_2011_origin_routes AS
SELECT a.*, b.geom FROM (
  SELECT id2 AS id, SUM(vehicles) AS vehicles FROM tz_nsw_2011_origin_routes GROUP BY id2
) AS a
INNER JOIN nsw_osm AS b ON (a.id = b.id);

SELECT DISTINCT o_tz, d_tz FROM tz_nsw_2011_origin_routes;









--------------------------------------------------------------------------------
-- JUNKYARD OF TEST CODE
--------------------------------------------------------------------------------

-- 
-- SELECT * FROM tz_nsw_2011_vehicles WHERE o_tz IN (SELECT tz_code11::integer FROM tz_nsw_2011 WHERE sa3_code11 = 12403); -- 149, 252, 300, ... , 10206
-- 
-- --Create routes
-- UPDATE tz_nsw_2011_vehicles
--   SET geom = (SELECT sqt.geom FROM (SELECT ST_Multi(ST_Union(b.geom)) AS geom FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM nsw_osm_main', source, target, false, true) AS a LEFT JOIN nsw_osm_main AS b ON (a.id2 = b.id)) AS sqt)
--   WHERE o_tz IN (SELECT tz_code11::integer FROM tz_nsw_2011 WHERE sa3_code11 = 12403 LIMIT 1); 
-- 
-- select Count(*) from tz_nsw_2011_vehicles where geom IS NOT NULL; -- 147, , 297, ... , 10018 (~3 hours)
-- 
-- 
-- 
-- SELECT SUM(a.cost) as cost, ST_Union(b.geom) AS geom
-- SELECT * 
--   FROM pgr_dijkstra('SELECT id, source, target, cost FROM nsw_osm_main', 53171, 18339, false, false) AS a
--   LEFT JOIN nsw_osm AS b ON (a.id2 = b.id);
-- 
-- 
-- SELECT id2, cost FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM nsw_osm_main', 53171, 18339, false, true);



-- 9787 records = 1700s
-- 380106 records = s

-- DROP TABLE IF EXISTS public.test_route;
-- CREATE TABLE public.test_route AS
--   SELECT a.seq, a.id1 AS node, a.id2 AS edge, a.cost, b.geom AS geom
--     FROM pgr_dijkstra('SELECT id, source, target, cost FROM nsw_osm', 1635, 17850, true, false) AS a
--     LEFT JOIN nsw_osm AS b ON (a.id2 = b.id);
-- 
-- 
-- DROP TABLE IF EXISTS public.test_route;
-- CREATE TABLE public.test_route AS
--   SELECT SUM(a.cost) as cost, ST_Union(b.geom) AS geom
--     FROM pgr_dijkstra('SELECT id, source, target, cost FROM nsw_osm', 1635, 17850, true, false) AS a
--     LEFT JOIN nsw_osm AS b ON (a.id2 = b.id);




-- --Western Sydney vehicles driving to the CDB
-- select o_11601 + 
--        o_11602 + 
--        o_11603 + 
--        o_12404 + 
--        o_12405 + 
--        o_12503 + 
--        o_12504 + 
--        o_12701 + 
--        o_12702 as w_sydney_vehicles,
--        *
--  from sa3_2011_sydney_bts 
-- where sa3_code = 11703







-- 
-- 
-- -- Create web friendly NSW Travel Zone table
-- DROP TABLE IF EXISTS sa3_2011_sydney_bts;
-- CREATE TABLE sa3_2011_sydney_bts
-- (
--   centroid_x numeric(6,3) NOT NULL,
--   centroid_y numeric(5,3) NOT NULL,
--   geom geometry(MultiPolygon,4326, 2) NOT NULL,
--   sa3_code integer NOT NULL,
--   sa3_name character varying(50) NOT NULL,
--   o_motorists integer NOT NULL,
--   d_motorists integer NOT NULL,
--   CONSTRAINT sa3_2011_sydney_bts_pkey PRIMARY KEY (sa3_code)
-- )
-- WITH (OIDS=FALSE);
-- ALTER TABLE sa3_2011_sydney_bts OWNER TO postgres;
-- 
-- CREATE INDEX sidx_sa3_2011_sydney_bts_geom ON sa3_2011_sydney_bts USING gist (geom);
-- 
-- INSERT INTO sa3_2011_sydney_bts -- 3514
-- SELECT ST_X(ST_Centroid(ST_Transform(ST_Buffer(geom, 0.0), 4326))),
--        ST_Y(ST_Centroid(ST_Transform(ST_Buffer(geom, 0.0), 4326))),
--        ST_Transform(ST_Multi(ST_Buffer(geom, 0.0)), 4326),
--        sa3_code::integer,
--        sa3_name,
--        0,
--        0
--   FROM sa3_2011_sydney;
-- 
-- CLUSTER sa3_2011_sydney_bts USING sidx_sa3_2011_sydney_bts_geom;
-- ANALYSE sa3_2011_sydney_bts;
-- 
-- 
-- -- Update motorist counts for origin travel zones -- 41
-- UPDATE sa3_2011_sydney_bts AS sa3
--   SET o_motorists = jtw.motorists
--   FROM (
--     SELECT o_sa3_11,
--            SUM(employed_persons)::integer AS motorists
--     FROM jtw_table2011eh07
--     WHERE mode10 IN (4, 5)
--     --AND o_sa3_11 IS NOT NULL AND d_sa3_11 IS NOT NULL
--     AND d_sa3_11 IN (SELECT sa3_code FROM sa3_2011_sydney_bts)
--     --AND o_study_area_name11 =  'GMA' AND d_study_area_name11 =  'GMA'
--     GROUP BY o_sa3_11
--   ) AS jtw
--   WHERE jtw.o_sa3_11 = sa3.sa3_code;
-- 
-- 
-- -- Update motorist counts for destination travel zones -- 41 
-- UPDATE sa3_2011_sydney_bts AS sa3
--   SET d_motorists = jtw.motorists
--   FROM (
--     SELECT d_sa3_11,
--            SUM(employed_persons)::integer AS motorists
--     FROM jtw_table2011eh07
--     WHERE mode10 IN (4, 5)
--     --AND o_sa3_11 IS NOT NULL AND d_sa3_11 IS NOT NULL
--     AND o_sa3_11 IN (SELECT sa3_code FROM sa3_2011_sydney_bts)
--     --AND o_study_area_name11 =  'GMA' AND d_study_area_name11 =  'GMA'
--     GROUP BY d_sa3_11
--   ) AS jtw
--   WHERE jtw.d_sa3_11 = sa3.sa3_code;
-- 
-- 
-- -- SELECT * FROM sa3_2011_sydney_bts; -- 41
-- -- SELECT SUM(o_motorists), SUM(d_motorists) FROM sa3_2011_sydney_bts; -- 1,102,028; 1,099,290
-- 
-- --Create table of motorist counts for each combination of origin and destination SA3 -- 6966
-- DROP TABLE IF EXISTS sa3_2011_sydney_motorists;
-- CREATE TABLE sa3_2011_sydney_motorists
-- (
--   o_sa3_code integer NOT NULL,
--   d_sa3_code integer NOT NULL,
--   motorists integer NOT NULL,
--   o_x numeric(6,3),
--   o_y numeric(5,3),
--   d_x numeric(6,3),
--   d_y numeric(5,3),
--   CONSTRAINT sa3_2011_sydney_motorists_pnt_pkey PRIMARY KEY (o_sa3_code, d_sa3_code)
-- )
-- WITH (OIDS=FALSE);
-- ALTER TABLE sa3_2011_sydney_motorists OWNER TO postgres;
-- 
-- INSERT INTO sa3_2011_sydney_motorists (o_sa3_code, d_sa3_code, motorists)
-- SELECT o_sa3_11,
--        d_sa3_11,
--        SUM(employed_persons)::integer AS motorists
--   FROM jtw_table2011eh07
--   WHERE mode10 IN (4, 5)
--   AND o_sa3_11 IS NOT NULL AND d_sa3_11 IS NOT NULL
-- GROUP BY o_sa3_11,
--          d_sa3_11;
-- 
-- UPDATE sa3_2011_sydney_motorists AS mot
--   SET o_x = ST_X(ST_Centroid(bdys.geom))
--      ,o_y = ST_Y(ST_Centroid(bdys.geom))
--   FROM sa3_2011_sydney_bts AS bdys
--   WHERE mot.o_sa3_code = bdys.sa3_code;
-- 
-- UPDATE sa3_2011_sydney_motorists AS mot
--   SET d_x = ST_X(ST_Centroid(bdys.geom))
--      ,d_y = ST_Y(ST_Centroid(bdys.geom))
--   FROM sa3_2011_sydney_bts AS bdys
--   WHERE mot.d_sa3_code = bdys.sa3_code;
-- 
-- --Only keep rows that have coords (i.e. Sydney sa3's with geoms)
-- DELETE FROM sa3_2011_sydney_motorists
--   WHERE o_x IS NULL OR d_x IS NULL;


--COPY sa3_2011_sydney_motorists TO 'C:\\minus34\\GitHub\\WestCON\\sa3_2011_sydney_motorists.csv' CSV;

--select * from sa3_2011_sydney_motorists where d_sa3_code = 11501 order by o_sa3_code;



--------------------------------------
-- testing
--------------------------------------

-- 
-- SELECT * FROM sa3_2011_sydney_bts
--   WHERE sa3_code = 11703
--  ;
-- 
-- 
-- 
-- SELECT o_sa3_11,
--        d_sa3_11,
--        SUM(employed_persons)::integer AS motorists
--   FROM jtw_table2011eh07
--   WHERE mode10 IN (4, 5)
--   and o_sa3_11 = 11703
--   and d_sa3_11 = 12403
--   group by o_sa3_11,
--            d_sa3_11;
-- 





