-- SELECT
--     SUM(count)::integer count,
--     JSON_Agg(JSON_Build_Object(cat, count)) cat,
--     ST_AsGeoJson(ST_PointOnSurface(ST_Union(geom))) geomj
--   FROM (
--     SELECT
--       COUNT(cat) count,
--       ST_Union(geom) geom,
--       cat,
--       kmeans_cid,
--       dbscan_cid
--     FROM (
--       SELECT
--         cat,
--         kmeans_cid,
--         geom AS geom,
--         ST_ClusterDBSCAN(geom, 0.1, 1) OVER (PARTITION BY kmeans_cid) dbscan_cid
--       FROM (
--         SELECT
--           reliability AS cat,
--           ST_ClusterKMeans(geom, 10) OVER () kmeans_cid,
--           geom
--         FROM gnaf_201802.address_principals
-- 		LIMIT 1000
--       ) kmeans
--     ) dbscan GROUP BY kmeans_cid, dbscan_cid, cat
--   ) cluster GROUP BY kmeans_cid, dbscan_cid;

WITH kmeans AS (
	SELECT
	  reliability AS cat,
	  ST_ClusterKMeans(geom, 10) OVER () kmeans_cid,
	  geom
	FROM gnaf_201802.address_principals
	LIMIT 1000
), dbscan AS (
	SELECT
        cat,
        kmeans_cid,
        geom AS geom,
        ST_ClusterDBSCAN(geom, 0.1, 1) OVER (PARTITION BY kmeans_cid) dbscan_cid
      FROM kmeans
), cluster AS (
    SELECT
      COUNT(cat) count,
      ST_Union(geom) geom,
      cat,
      kmeans_cid,
      dbscan_cid
	FROM dbscan
	GROUP BY
	  kmeans_cid,
	  dbscan_cid,
	  cat
)
SELECT
    SUM(count)::integer count,
    JSON_Agg(JSON_Build_Object(cat, count)) cat,
    ST_AsGeoJson(ST_PointOnSurface(ST_Union(geom))) geomj
  FROM cluster
  GROUP BY
    kmeans_cid,
	dbscan_cid;