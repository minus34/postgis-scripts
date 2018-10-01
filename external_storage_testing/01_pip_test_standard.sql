
-- run point in polygon test with standard geom field storage --  mins
DROP TABLE IF EXISTS testing.pip_test_standard;
CREATE TABLE testing.pip_test_standard AS
  SELECT gnaf.gnaf_pid,
         mb.mb_11code
  FROM admin_bdys_201808.abs_2011_mb AS mb
  inner join gnaf_201808.address_principals as gnaf
  on st_intersects(gnaf.geom, mb.geom);
