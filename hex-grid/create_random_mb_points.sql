

--ALTER TABLE mb_2011_aust CLUSTER ON mb_2011_aust_geom_idx;


-- Create points distributed by neighbourhood population density - parallel processing
-- Windows 8.1
--   Postgres 9.3.7: ~1m = 50 seconds, ~21m = 350 seconds
--   Postgres 9.4.2: ~1m =  seconds, ~21m =  seconds
DROP TABLE IF EXISTS public.mb_random_points;
CREATE UNLOGGED TABLE public.mb_random_points
(
  gid serial NOT NULL PRIMARY KEY,
  mb_main character varying(11) NOT NULL,
  geom geometry(POINT, 4283, 2)
) WITH (OIDS=FALSE);
ALTER TABLE public.mb_random_points OWNER TO postgres;
CREATE INDEX mb_random_points_geom_gist ON public.mb_random_points USING gist (geom);
COMMIT;

SELECT parsel('public.mb_2011_aust'
      ,'gid'
      ,'SELECT mb.mb_code11, st_randompointsinpolygon((ST_Dump(mb.geom)).geom, population::integer) FROM public.mb_2011_aust AS mb WHERE mb.population > 0'
      ,'public.mb_random_points (mb_main, geom)'
      ,'mb'
      ,6);

--      ,'SELECT mb.mb_main, ST_RandomPointsInPolygon((ST_Dump(mb.geom)).geom, (mb.population::float/21.0)::integer) FROM mb_2011_aust AS mb WHERE (mb.population::float/21.0)::integer > 0'

ALTER TABLE public.mb_random_points CLUSTER ON mb_random_points_geom_gist;
ANALYZE public.mb_random_points;

select Count(*) from public.mb_random_points; -- ~1m = 1,019,910 records, ~21m = 21,458,707 records



