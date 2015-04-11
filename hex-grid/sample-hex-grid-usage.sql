---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- HEX GRID - Sample usage script
---------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Hugh Saalmans (@minus34)
-- 2015/04/10
--
-- DESCRIPTION:
-- 
-- Script creates a new table and populates it with a grid of hexagons covering Australia using hex grid function.
-- Takes under 10 mins on my 8 core, 16Gb RAM commodity PC to produce the hexagons, and another 10-15 mins to index & cluster
--
-- Coordinate systems used:
--   input:   GDA94 lat/long - SRID 4283
--   working: Australian Albers Equal Area (GDA94) - SRID 3577
--   output:  GDA94 lat/long
--
-- LICENSE
--
-- This work is licensed under the Apache License, Version 2: https://www.apache.org/licenses/LICENSE-2.0
--
---------------------------------------------------------------------------------------------------------------------------------------------------------------

--Create table for results
DROP TABLE IF ExISTS my_hex_grid;
CREATE TABLE my_hex_grid (
  gid SERIAL not null primary key,
  geom GEOMETRY('POLYGON', 4283, 2) not null
)
WITH (OIDS=FALSE);

-- Create 1km2 hex grid for Australia (extents are oversized to counter the effects of using the Albers Equal Area projection)
INSERT INTO my_hex_grid (geom)
select hex_grid(1.0, 108.0, -44.0, 151.0, -8.0, 4283, 3577, 4283);

-- Update stats on table
ANALYZE my_hex_grid;

-- Create spatial index
CREATE INDEX my_hex_grid_geom_idx ON my_hex_grid USING gist (geom);

-- Cluster table by spatial index for performance
CLUSTER my_hex_grid USING my_hex_grid_geom_idx;


--Check accuracy of results (in square km)
SELECT (SELECT Count(*) From my_hex_grid) AS hexagon_count,
       (SELECT (MIN(ST_Area(geom::geography, FALSE)) / 1000000.0)::numeric(10,3) From my_hex_grid) AS min_area,
       (SELECT (MAX(ST_Area(geom::geography, FALSE)) / 1000000.0)::numeric(10,3) From my_hex_grid) AS max_area;
