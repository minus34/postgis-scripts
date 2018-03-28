


-- SELECT Count(*) FROM gnaf_201802.address_principals; -- 13750039


-- Get partitions of equal record counts - SMALLINT
WITH cte AS (
  SELECT (longitude * 100)::SMALLINT AS partition_id FROM gnaf_201802.address_principals
)
SELECT
  MIN(partition_id) AS part_01,
  percentile_cont(0.05) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_02,
  percentile_cont(0.10) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_03,
  percentile_cont(0.15) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_04,
  percentile_cont(0.20) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_05,
  percentile_cont(0.25) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_06,
  percentile_cont(0.30) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_07,
  percentile_cont(0.35) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_08,
  percentile_cont(0.40) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_09,
  percentile_cont(0.45) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_10,
  percentile_cont(0.50) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_11,
  percentile_cont(0.55) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_12,
  percentile_cont(0.60) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_13,
  percentile_cont(0.65) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_14,
  percentile_cont(0.70) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_15,
  percentile_cont(0.75) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_16,
  percentile_cont(0.80) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_17,
  percentile_cont(0.85) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_18,
  percentile_cont(0.90) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_19,
  percentile_cont(0.95) WITHIN GROUP (ORDER BY partition_id)::SMALLINT AS part_20,
  MAX(partition_id) + 1 AS part_21 -- add 1 to account for trimming max value to an integer
FROM cte;


-- 9682,11585,12058,13860,14249,14475,14497,14508,14525,14607,14745,14954,15081,15100,15113,15124,15167,15284,15303,15315,16800


-- Get partitions of equal record counts - numeric(8,4)
WITH cte AS (
    SELECT longitude::numeric(8,4) AS partition_id FROM gnaf_201802.address_principals
)
SELECT
  MIN(partition_id) - 0.0001 AS part_01,
  percentile_cont(0.05) WITHIN GROUP (ORDER BY partition_id) AS part_02,
  percentile_cont(0.10) WITHIN GROUP (ORDER BY partition_id) AS part_03,
  percentile_cont(0.15) WITHIN GROUP (ORDER BY partition_id) AS part_04,
  percentile_cont(0.20) WITHIN GROUP (ORDER BY partition_id) AS part_05,
  percentile_cont(0.25) WITHIN GROUP (ORDER BY partition_id) AS part_06,
  percentile_cont(0.30) WITHIN GROUP (ORDER BY partition_id) AS part_07,
  percentile_cont(0.35) WITHIN GROUP (ORDER BY partition_id) AS part_08,
  percentile_cont(0.40) WITHIN GROUP (ORDER BY partition_id) AS part_09,
  percentile_cont(0.45) WITHIN GROUP (ORDER BY partition_id) AS part_10,
  percentile_cont(0.50) WITHIN GROUP (ORDER BY partition_id) AS part_11,
  percentile_cont(0.55) WITHIN GROUP (ORDER BY partition_id) AS part_12,
  percentile_cont(0.60) WITHIN GROUP (ORDER BY partition_id) AS part_13,
  percentile_cont(0.65) WITHIN GROUP (ORDER BY partition_id) AS part_14,
  percentile_cont(0.70) WITHIN GROUP (ORDER BY partition_id) AS part_15,
  percentile_cont(0.75) WITHIN GROUP (ORDER BY partition_id) AS part_16,
  percentile_cont(0.80) WITHIN GROUP (ORDER BY partition_id) AS part_17,
  percentile_cont(0.85) WITHIN GROUP (ORDER BY partition_id) AS part_18,
  percentile_cont(0.90) WITHIN GROUP (ORDER BY partition_id) AS part_19,
  percentile_cont(0.95) WITHIN GROUP (ORDER BY partition_id) AS part_20,
  MAX(partition_id) + 0.0001 AS part_21 -- add 1 to account for trimming max value to an integer
FROM cte;

-- 96.8215,115.8473,120.5748,138.6046,142.4924,144.7469,144.9711,145.0797,145.2545,146.0666,147.4484,149.5449,150.8143,150.9992,151.129,151.2382,151.6735,152.8368,153.0298,153.1523,167.9931


-- -- check row counts are roughly even - yes!
-- SELECT
--   SUM(CASE WHEN longitude >= 9682.0/100.0 AND longitude < 12058.0/100.0 THEN 1 ELSE 0 END)  AS part_01_count,
--   SUM(CASE WHEN longitude >= 12058.0/100.0 AND longitude < 14249.0/100.0 THEN 1 ELSE 0 END) AS part_02_count,
--   SUM(CASE WHEN longitude >= 14249.0/100.0 AND longitude < 14497.0/100.0 THEN 1 ELSE 0 END) AS part_03_count,
--   SUM(CASE WHEN longitude >= 14497.0/100.0 AND longitude < 14525.0/100.0 THEN 1 ELSE 0 END) AS part_04_count,
--   SUM(CASE WHEN longitude >= 14525.0/100.0 AND longitude < 14745.0/100.0 THEN 1 ELSE 0 END) AS part_05_count,
--   SUM(CASE WHEN longitude >= 14745.0/100.0 AND longitude < 15081.0/100.0 THEN 1 ELSE 0 END) AS part_06_count,
--   SUM(CASE WHEN longitude >= 15081.0/100.0 AND longitude < 15113.0/100.0 THEN 1 ELSE 0 END) AS part_07_count,
--   SUM(CASE WHEN longitude >= 15113.0/100.0 AND longitude < 15167.0/100.0 THEN 1 ELSE 0 END) AS part_08_count,
--   SUM(CASE WHEN longitude >= 15167.0/100.0 AND longitude < 15303.0/100.0 THEN 1 ELSE 0 END) AS part_09_count,
--   SUM(CASE WHEN longitude >= 15303.0/100.0 AND longitude < 16800.0/100.0 THEN 1 ELSE 0 END) AS part_10_count
-- FROM gnaf_201802.address_principals;