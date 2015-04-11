---------------------------------------------------------------------------------------------------------------------------------------------------------------
-- HEX GRID - Create function
---------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Hugh Saalmans (@minus34)
-- 2015/04/10
--
-- DESCRIPTION:
-- 
-- Function returns a grid of mathmatically correct hexagonal polyons.
-- Useful for hexbinning (aka the art of mapping clusters of information with unbiased boundaries).
--
-- INPUT
--
--   areakm2     : area of each hexagon in square km.
--               - note, hexagon size could be off slightly due to some coordinate rounding required in the calcs.
--
--   xmin, ymin  : min coords of the grid.
--
--   xmax, ymax  : max coords of the grid.
--
--   inputsrid   : the coordinate system (SRID) of the input min/max coords.
--
--   workingsrid : the SRID used to process the polygons.
--               - SRID must be a projected coordinate system (i.e in metres) as the calcs require integers, so degrees are out.
--               - should be an equal area SRID such as Albers or Lambert Azimuthal (e.g. 3577 for Australia, 2163 for the US).
--               - using a Mercator projection will NOT return hexagons of equal area (don't try it in Greenland).
--
--   ouputsrid   : the SRID of the output polygons.
--
-- NOTES
--
--   This code is based on this PostGIS Wiki article: https://trac.osgeo.org/postgis/wiki/UsersWikiGenerateHexagonalGrid
--
--   Dimension calcs are based on formulae from: http://hexnet.org/content/hexagonal-geometry
--
--   Hexagon height & width are rounded up & down to the nearest metre, hence the area may be off slightly.
--   This is due the use of the Postgres generate_series function which doesn't support floats.
--
--   Why are my areas wrong in QGIS, MapInfo, etc...?
--      Let's assume you created WGS84 lat/long hexagons, you may have noticted the areas differ by up to 50% in a desktop GIS tool like QGIS or MapInfo Pro.
--      This is due to the way they 'project' geographic coord systems like WGS84 lat/long.
--      Running the following query in PostGIS will confirm the difference in area within your hex grid:
--
--         SELECT (SELECT (MIN(ST_Area(geom::geography, FALSE)) / 1000000.0)::numeric(10,3) From my_hex_grid) AS minarea,
--               (SELECT (MAX(ST_Area(geom::geography, FALSE)) / 1000000.0)::numeric(10,3) From my_hex_grid) AS maxarea;
--
--   Hey, why doesn't the grid cover the area I defined using my min/max coords?
--      Assuming you used an equal area projection, the projection caused your extents to describe a conical shape, not a rectangular one
--      - and the conical area didn't cover everything you wanted to include.
--      If you're feeling a bit bored - learn more about projections and distortions here: http://www.icsm.gov.au/mapping/about_projections.html
--
--
-- LICENSE
--
-- This work is licensed under the Apache License, Version 2: https://www.apache.org/licenses/LICENSE-2.0
--
---------------------------------------------------------------------------------------------------------------------------------------------------------------

--DROP FUNCTION IF EXISTS hex_grid(areakm2 float, xmin float, ymin float, xmax float, ymax float, inputsrid integer, workingsrid integer, ouputsrid integer);
CREATE OR REPLACE FUNCTION hex_grid(areakm2 float, xmin float, ymin float, xmax float, ymax float, inputsrid integer, workingsrid integer, ouputsrid integer)
  RETURNS SETOF geometry AS
$BODY$

DECLARE
  minpnt GEOMETRY;
  maxpnt GEOMETRY;
  x1 integer;
  y1 integer;
  x2 integer;
  y2 integer;
  aream2 float;
  qtrwidthfloat FLOAT;
  qtrwidth INTEGER;
  halfheight INTEGER;

BEGIN

  -- Convert input coords to points in the working SRID
  minpnt = ST_Transform(ST_SetSRID(ST_MakePoint(xmin, ymin), inputsrid), workingsrid);
  maxpnt = ST_Transform(ST_SetSRID(ST_MakePoint(xmax, ymax), inputsrid), workingsrid);

  -- Get bounds in working SRID coords
  x1 = ST_X(minpnt)::integer;
  y1 = ST_Y(minpnt)::integer;
  x2 = ST_X(maxpnt)::integer;
  y2 = ST_Y(maxpnt)::integer;

  -- Get height and width of hexagon - FLOOR and CEILING is used to get the hexagon size closer to the input area
  aream2 = areakm2 * 1000000.0;
  qtrwidthfloat := sqrt(aream2/(sqrt(3.0) * (3.0/2.0))) / 2.0;
  
  qtrwidth := FLOOR(qtrwidthfloat);
  halfheight := CEILING(qtrwidthfloat * sqrt(3.0));

  -- Return the hexagons - done in pairs with one offset
  RETURN QUERY (SELECT ST_Transform(ST_SetSRID(ST_Translate(geom, x_series::float, y_series::float), workingsrid), ouputsrid) AS geom
    from generate_series(x1, x2, (qtrwidth * 6)) as x_series,
         generate_series(y1, y2, (halfheight * 2)) as y_series,
         (
           SELECT ST_GeomFromText(
             format('POLYGON((0 0, %s %s, %s %s, %s %s, %s %s, %s %s, 0 0))',
               qtrwidth, halfheight,
               qtrwidth * 3, halfheight,
               qtrwidth * 4, 0,
               qtrwidth * 3, halfheight * -1,
               qtrwidth, halfheight * -1
             )
           ) as geom
           UNION
           SELECT ST_Translate(
             ST_GeomFromText(
               format('POLYGON((0 0, %s %s, %s %s, %s %s, %s %s, %s %s, 0 0))',
                 qtrwidth, halfheight,
                 qtrwidth * 3, halfheight,
                 qtrwidth * 4, 0,
                 qtrwidth * 3, halfheight * -1,
                 qtrwidth, halfheight * -1
               )
             )
           , qtrwidth * 3, halfheight) as geom
         ) as two_hex);

END$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;