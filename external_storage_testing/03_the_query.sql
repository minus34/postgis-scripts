INSERT INTO testing.pip_test_external
SELECT gnaf.gnaf_pid,
       mb.mb_16code
FROM testing.abs_2016_mb_analysis AS mb
       INNER JOIN testing.address_principals AS gnaf
                  ON st_intersects(gnaf.geom, mb.geom);