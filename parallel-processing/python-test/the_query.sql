INSERT INTO testing.test_gnaf_meshblocks
  WITH polys AS (
    SELECT mb_code16,
      st_subdivide(geom, 16384) AS geom
    FROM census_2016_bdys.mb_2016_aust
  )
  SELECT pnts.gnaf_pid, polys.mb_code16
  FROM gnaf_201802.address_principals_part AS pnts
  INNER JOIN polys
  ON ST_Intersects(pnts.geom, polys.geom)
  WHERE longitude >= %s AND longitude < %s
