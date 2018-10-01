
-- run point in polygon test with standard geom field storage -- Execute times 1,719.268, 1,688.382
DROP TABLE IF EXISTS testing.pip_test_external;
CREATE TABLE testing.pip_test_external AS
  SELECT gnaf.gnaf_pid,
         mb.mb_11code
  FROM testing.abs_2011_mb AS mb
  inner join testing.address_principals as gnaf
  on st_intersects(gnaf.geom, mb.geom);
  