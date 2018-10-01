
-- Load into PG (via command line)
-- osm2pgsql -d geo -P 5432 -H localhost -s -l /Users/hugh.saalmans/Downloads/australia-oceania-latest.osm.pbf

-- get stats for non-spatial tables
ANALYZE public.planet_osm_rels;
ANALYZE public.planet_osm_ways;
ANALYZE public.planet_osm_nodes;

-- cluster spatial tables on spatial indexes
ALTER TABLE public.planet_osm_line CLUSTER ON planet_osm_line_index;
ALTER TABLE public.planet_osm_polygon CLUSTER ON planet_osm_polygon_index;
ALTER TABLE public.planet_osm_point CLUSTER ON planet_osm_point_index;
ALTER TABLE public.planet_osm_roads CLUSTER ON planet_osm_roads_index;

-- get stats for spatial tables
ANALYZE public.planet_osm_line;
ANALYZE public.planet_osm_polygon;
ANALYZE public.planet_osm_point;
ANALYZE public.planet_osm_roads;
