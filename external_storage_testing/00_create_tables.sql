
-- CREATE SCHEMA testing;

-- create meshblocks table
DROP TABLE if exists testing.abs_2016_mb;
CREATE TABLE testing.abs_2016_mb (
    --     gid serial NOT NULL,
    gid integer NOT NULL,
    mb_16code text NOT NULL,
    mb_category text,
    sa1_16main double precision,
    sa1_16_7cd integer,
    sa2_16main integer,
    sa2_16_5cd integer,
    sa2_16name text,
    sa3_16code integer,
    sa3_16name text,
    sa4_16code integer,
    sa4_16name text,
    gcc_16code text,
    gcc_16name text,
    state text,
    area_sqm numeric,
    mb16_pop integer,
    mb16_dwell integer,
    geom geometry(MultiPolygon,4283) NULL
)
WITH (OIDS = FALSE);
ALTER TABLE testing.abs_2016_mb OWNER TO postgres;

-- set geom column to decompressed
ALTER TABLE testing.abs_2016_mb ALTER COLUMN geom SET STORAGE EXTERNAL;

-- insert data -- 358,011 rows
INSERT INTO testing.abs_2016_mb
SELECT * FROM admin_bdys_201811.abs_2016_mb;

ANALYZE testing.abs_2016_mb;

-- add indexes and cluster on geom index
ALTER TABLE testing.abs_2016_mb ADD CONSTRAINT abs_2016_mb_pk PRIMARY KEY (gid);

CREATE INDEX abs_2016_mb_geom_idx ON testing.abs_2016_mb USING gist (geom);
ALTER TABLE testing.abs_2016_mb CLUSTER ON abs_2016_mb_geom_idx;

ANALYZE testing.abs_2016_mb;


-- create subdivided meshblocks table
DROP TABLE if exists testing.abs_2016_mb_subd;
CREATE TABLE testing.abs_2016_mb_subd (
    gid serial NOT NULL,
    mb_16code text NOT NULL,
    mb_category text,
    sa1_16main double precision,
    sa1_16_7cd integer,
    sa2_16main integer,
    sa2_16_5cd integer,
    sa2_16name text,
    sa3_16code integer,
    sa3_16name text,
    sa4_16code integer,
    sa4_16name text,
    gcc_16code text,
    gcc_16name text,
    state text,
    area_sqm numeric,
    mb16_pop integer,
    mb16_dwell integer,
    geom geometry(Polygon,4283) NULL
)
WITH (OIDS = FALSE);
ALTER TABLE testing.abs_2016_mb_subd OWNER TO postgres;

-- set geom column to decompressed
ALTER TABLE testing.abs_2016_mb_subd ALTER COLUMN geom SET STORAGE EXTERNAL;

-- insert data -- 385,263 rows
INSERT INTO testing.abs_2016_mb_subd (
    mb_16code,
    mb_category,
    sa1_16main,
    sa1_16_7cd,
    sa2_16main,
    sa2_16_5cd,
    sa2_16name,
    sa3_16code,
    sa3_16name,
    sa4_16code,
    sa4_16name,
    gcc_16code,
    gcc_16name,
    state,
    area_sqm,
    mb16_pop,
    mb16_dwell,
    geom)
SELECT mb_16code,
       mb_category,
       sa1_16main,
       sa1_16_7cd,
       sa2_16main,
       sa2_16_5cd,
       sa2_16name,
       sa3_16code,
       sa3_16name,
       sa4_16code,
       sa4_16name,
       gcc_16code,
       gcc_16name,
       state,
       area_sqm,
       mb16_pop,
       mb16_dwell,
       ST_Subdivide(geom, 512)
FROM admin_bdys_201811.abs_2016_mb;

ANALYZE testing.abs_2016_mb_subd;

-- add indexes and cluster on geom index
ALTER TABLE testing.abs_2016_mb_subd ADD CONSTRAINT abs_2016_mb_subd_pk PRIMARY KEY (gid);

CREATE INDEX abs_2016_mb_subd_geom_idx ON testing.abs_2016_mb_subd USING gist (geom);
ALTER TABLE testing.abs_2016_mb_subd CLUSTER ON abs_2016_mb_subd_geom_idx;

ANALYZE testing.abs_2016_mb_subd;


-- create GNAF table -- 13,810,270
DROP TABLE IF EXISTS testing.address_principals;
CREATE TABLE testing.address_principals
(
    gid integer NOT NULL,
    gnaf_pid text NOT NULL,
    street_locality_pid text NOT NULL,
    locality_pid text NOT NULL,
    alias_principal character(1) NOT NULL,
    primary_secondary text,
    building_name text,
    lot_number text,
    flat_number text,
    level_number text,
    number_first text,
    number_last text,
    street_name text NOT NULL,
    street_type text,
    street_suffix text,
    address text NOT NULL,
    locality_name text NOT NULL,
    postcode text,
    state text NOT NULL,
    locality_postcode text,
    confidence smallint NOT NULL,
    legal_parcel_id text,
    mb_2011_code bigint,
    mb_2016_code bigint,
    latitude numeric(10,8) NOT NULL,
    longitude numeric(11,8) NOT NULL,
    geocode_type text NOT NULL,
    reliability smallint NOT NULL,
    geom geometry(Point,4283) NOT NULL
)
WITH (OIDS = FALSE);
ALTER TABLE testing.address_principals OWNER to postgres;

-- set geom column to decompressed
ALTER TABLE testing.address_principals ALTER COLUMN geom SET STORAGE EXTERNAL;

-- insert data
INSERT INTO testing.address_principals
SELECT * FROM gnaf_201811.address_principals;

ANALYZE testing.address_principals;

-- add indexes and cluster on geom index
ALTER TABLE testing.address_principals ADD CONSTRAINT address_principals_pk PRIMARY KEY (gnaf_pid);

CREATE INDEX address_principals_geom_idx ON testing.address_principals USING gist (geom);
ALTER TABLE testing.address_principals CLUSTER ON address_principals_geom_idx;

CREATE INDEX address_principals_gid_idx ON testing.address_principals USING btree (gid);

ANALYZE testing.address_principals;
