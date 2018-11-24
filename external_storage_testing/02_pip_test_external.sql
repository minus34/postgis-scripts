
-- run point in polygon test with standard geom field storage 
-- PG 10 Execute times 34 m 18 s
-- PG 11 Execute times
    -- 33 m 24 s 633 ms
    -- 32 m 29 s 386 ms
    -- 32 m 26 s 970 ms
    -- 32 m 26 s 238 ms
    -- 32 m 27 s 546 ms

DROP TABLE IF EXISTS testing.pip_test_external;
CREATE TABLE testing.pip_test_external AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM testing.abs_2016_mb AS mb
  inner join testing.address_principals as gnaf
  on st_intersects(gnaf.geom, mb.geom);

DROP TABLE IF EXISTS testing.pip_test_external;
CREATE TABLE testing.pip_test_external AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM testing.abs_2016_mb AS mb
         inner join testing.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);

DROP TABLE IF EXISTS testing.pip_test_external;
CREATE TABLE testing.pip_test_external AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM testing.abs_2016_mb AS mb
         inner join testing.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);

DROP TABLE IF EXISTS testing.pip_test_external;
CREATE TABLE testing.pip_test_external AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM testing.abs_2016_mb AS mb
         inner join testing.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);

DROP TABLE IF EXISTS testing.pip_test_external;
CREATE TABLE testing.pip_test_external AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM testing.abs_2016_mb AS mb
         inner join testing.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);
