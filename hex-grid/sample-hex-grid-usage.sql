---------------------------------------------------------------------------------------------------------------------------------
-- HEX GRID - Sample usage script
---------------------------------------------------------------------------------------------------------------------------------
--
-- Hugh Saalmans (@minus34)
-- 2015/04/10
--
-- DESCRIPTION:
-- 
-- Script creates a new table and populates it with ~18 million hexagons covering Australia, using the hex grid function.
-- Takes under 10 mins on my 8 core, 16Gb RAM commodity PC to produce the hexagons, and another 10 mins to index & cluster.
--
-- Coordinate systems (SRIDs) used:
--   input:   GDA94 lat/long - SRID 4283
--   working: Australian Albers Equal Area (GDA94) - SRID 3577
--   output:  GDA94 lat/long - SRID 4283
--
-- LICENSE
--
-- This work is licensed under the Apache License, Version 2: https://www.apache.org/licenses/LICENSE-2.0
--
---------------------------------------------------------------------------------------------------------------------------------

--Create table for results
DROP TABLE IF ExISTS my_hex_grid;
CREATE TABLE my_hex_grid (
  gid SERIAL not null primary key,
  geom GEOMETRY('POLYGON', 4283, 2) not null
)
WITH (OIDS=FALSE);

-- Create 1km2 hex grid for Australia (note: extents allow for the effects of the Albers Equal Area projection)
-- Input parameters: hex_grid(areakm2 float, xmin float, ymin float, xmax float, ymax float, inputsrid integer,
--   workingsrid integer, ouputsrid integer)
INSERT INTO my_hex_grid (geom)
select hex_grid(1.0, 108.0, -44.0, 151.0, -8.0, 4283, 3577, 4283);

-- Create spatial index
CREATE INDEX my_hex_grid_geom_idx ON my_hex_grid USING gist (geom);

-- Cluster table by spatial index (for spatial query performance)
CLUSTER my_hex_grid USING my_hex_grid_geom_idx;

-- Update stats on table
ANALYZE my_hex_grid;

--Check accuracy of results (in square km)
SELECT (SELECT Count(*) From my_hex_grid) AS hexagon_count,
       (SELECT (MIN(ST_Area(geom::geography, FALSE)) / 1000000.0)::numeric(10,3) From my_hex_grid) AS min_area,
       (SELECT (MAX(ST_Area(geom::geography, FALSE)) / 1000000.0)::numeric(10,3) From my_hex_grid) AS max_area;
