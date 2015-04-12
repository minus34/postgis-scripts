# hex-grid

## Description

This PostGIS function returns a grid of mathematically correct hexagonal polygons. Useful for hexbinning (the art of mapping clusters of information unbiased by political/historical/statistical boundaries).

## Input

| Parameter    | Description
| ------------ | :-------------
| areakm2      | Area of each hexagon in square km. Hexagon size can be off slightly due to coordinate rounding in the calcs.
| xmin, ymin   | Minimum coordinates of the grid extents (i.e. bottom, left).
| xmax, ymax   | Maximum coordinates of the grid extents (i.e. top, right).
| inputrid     | The SRID of the min/max coordinates.
| workingsrid  | The SRID used to process the hexagons.
|              | - SRID must be a projected coord sys (i.e. in metres) as the calcs require ints. Degrees are out.
|              | - should be an equal area SRID such as Albers or Lambert Azimuthal (e.g. Australia = 3577, US = 2163).
|              | - using Mercator will NOT return hexagons of equal area due to its distortions (don't try it in Greenland).
| ouputsrid    | The SRID of the output hexagons.

## Notes

- **Hexagon height & width** are rounded up & down to the nearest metre, hence the area may be off slightly.  This is due to the Postgres generate_series function which doesn't support floats.
- **Why are my areas wrong in QGIS, MapInfo, etc...?** Let's assume you created WGS84 lat/long hexagons, you may have noticed the areas differ by almost half in a desktop GIS like QGIS or MapInfo Pro. This is due to the way those tools display geographic coordinate systems like WGS84 lat/long. Running the following query in PostGIS will confirm the min & max sizes of your hexagons (in km2):
```sql
  SELECT (SELECT (MIN(ST_Area(geom::geography, FALSE)) / 1000000.0)::numeric(10,3) From my_hex_grid) AS minarea,
        (SELECT (MAX(ST_Area(geom::geography, FALSE)) / 1000000.0)::numeric(10,3) From my_hex_grid) AS maxarea;
```
- **Hey, why doesn't the grid cover the area I defined using my min/max extents?** Assuming you used lat/long extents and processed the grid with an equal area projection, the projection caused your min/max coords to describe a conical shape, not a rectangular one - and the conical area didn't cover everything you wanted to include.  See us-hex-grid.png in the sample images as an example of this. If you're bored - learn why projections distort maps here: http://www.icsm.gov.au/mapping/about_projections.html
- This code is based on this PostGIS Wiki article: https://trac.osgeo.org/postgis/wiki/UsersWikiGenerateHexagonalGrid
- Dimension calcs are based on formulae from: http://hexnet.org/content/hexagonal-geometry

## License

This work is licensed under the Apache License, Version 2: https://www.apache.org/licenses/LICENSE-2.0
