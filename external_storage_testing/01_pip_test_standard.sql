
-- run point in polygon test with standard geom field storage -- Execute times 37 m 28 s
DROP TABLE IF EXISTS testing.pip_test_standard;
CREATE TABLE testing.pip_test_standard AS
SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM admin_bdys_201811.abs_2016_mb AS mb
  inner join gnaf_201811.address_principals as gnaf
  on st_intersects(gnaf.geom, mb.geom);


-- in-memory -- 42 m 5 s
DROP TABLE IF EXISTS pip_test_standard;
CREATE TEMPORARY TABLE pip_test_standard AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM admin_bdys_201811.abs_2016_mb AS mb
  inner join gnaf_201811.address_principals as gnaf
  on st_intersects(gnaf.geom, mb.geom);
