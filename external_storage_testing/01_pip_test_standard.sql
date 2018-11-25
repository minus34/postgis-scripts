
-- run point in polygon test with standard geom field storage
-- PG 10 Execute times 37 m 28 s
-- PG 11 Execute times
    -- 32 m 50 s 365 ms
    -- 32 m 3 s 945 ms
    -- 32 m 16 s 372 ms
    -- 32 m 8 s 194 ms
    -- 32 m 7 s 89 ms

DROP TABLE IF EXISTS testing.pip_test_standard;
CREATE TABLE testing.pip_test_standard AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM admin_bdys_201811.abs_2016_mb AS mb
         inner join gnaf_201811.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);

DROP TABLE IF EXISTS testing.pip_test_standard;
CREATE TABLE testing.pip_test_standard AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM admin_bdys_201811.abs_2016_mb AS mb
         inner join gnaf_201811.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);

DROP TABLE IF EXISTS testing.pip_test_standard;
CREATE TABLE testing.pip_test_standard AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM admin_bdys_201811.abs_2016_mb AS mb
         inner join gnaf_201811.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);

DROP TABLE IF EXISTS testing.pip_test_standard;
CREATE TABLE testing.pip_test_standard AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM admin_bdys_201811.abs_2016_mb AS mb
         inner join gnaf_201811.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);

DROP TABLE IF EXISTS testing.pip_test_standard;
CREATE TABLE testing.pip_test_standard AS
  SELECT gnaf.gnaf_pid,
         mb.mb_16code
  FROM admin_bdys_201811.abs_2016_mb AS mb
         inner join gnaf_201811.address_principals as gnaf
           on st_intersects(gnaf.geom, mb.geom);
