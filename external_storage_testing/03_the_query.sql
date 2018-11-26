-- INSERT INTO testing.pip_test_external
-- SELECT gnaf.gnaf_pid,
--        mb.mb_16code
-- FROM testing.abs_2016_mb_analysis AS mb
--        INNER JOIN testing.address_principals AS gnaf
--                   ON st_intersects(gnaf.geom, mb.geom);


INSERT INTO testing.pip_test_standard
SELECT gnaf.gnaf_pid,
       mb.mb_16code
FROM admin_bdys_201811.abs_2016_mb_analysis AS mb
            inner join gnaf_201811.address_principals as gnaf
                       on st_intersects(gnaf.geom, mb.geom);
