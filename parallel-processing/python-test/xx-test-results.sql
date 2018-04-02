TRUNCATE TABLE testing.test_gnaf_meshblocks_slow;

INSERT INTO testing.test_gnaf_meshblocks_slow
  WITH polys AS (
    SELECT mb_code16,
      st_subdivide(geom, 512) AS geom
    FROM census_2016_bdys.mb_2016_aust
  )
  SELECT pnts.gnaf_pid, polys.mb_code16
  FROM testing.address_principals_part AS pnts
  INNER JOIN polys
  ON ST_Intersects(pnts.geom, polys.geom);

-- INSERT INTO testing.test_gnaf_meshblocks_slow
-- SELECT pnts.gnaf_pid, polys.mb_code16
-- FROM testing.address_principals_part AS pnts
-- INNER JOIN census_2016_bdys.mb_2016_aust AS polys
-- ON ST_Intersects(pnts.geom, polys.geom)

-- part on, parallel on, subdivide on = 2, 2 min
-- part on, parallel on, subdivide off = 8, 8, 8 min
-- part on, parallel off, subdivide on  = 3, 3 min
-- part on, parallel off, subdivide off  = 3, 3 min
-- part off, parallel off, subdivide off  = 29 min
-- part off, parallel off, subdivide on  = 30 min
-- part off, parallel on, subdivide on  = 14, 13 min
-- part off, parallel on, subdivide off  = 9, 8 min