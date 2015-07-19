


CREATE TABLE hex.grid_1_counts AS SELECT sqt.count::integer, grd.geom FROM hex.grid_1 AS grd INNER JOIN (SELECT bdys.gid, Count(*) AS count FROM hex.grid_1 AS bdys INNER JOIN public.mb_random_points as pnts ON ST_Contains(bdys.geom, pnts.geom) GROUP BY bdys.gid) AS sqt ON grd.gid = sqt.gid;
