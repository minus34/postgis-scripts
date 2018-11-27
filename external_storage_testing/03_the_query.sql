
-- TRUNCATE TABLE testing.pip_test_external;
-- TRUNCATE TABLE testing.pip_test_standard;

INSERT INTO testing.pip_test_external
WITH gnaf AS (
  SELECT gnaf_pid, geom FROM testing.address_principals
)
SELECT gnaf.gnaf_pid,
       mb.mb_16code
FROM gnaf
  INNER JOIN testing.abs_2016_mb_analysis AS mb
  ON st_intersects(gnaf.geom, mb.geom);

-- INSERT INTO testing.pip_test_standard
-- WITH gnaf AS (
--        SELECT gnaf_pid, geom FROM gnaf_201811.address_principals
-- )
-- SELECT gnaf.gnaf_pid,
--        mb.mb_16code
-- FROM gnaf
--   INNER JOIN admin_bdys_201811.abs_2016_mb_analysis AS mb
--     ON st_intersects(gnaf.geom, mb.geom);
