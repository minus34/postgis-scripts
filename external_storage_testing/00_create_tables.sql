
-- CREATE SCHEMA testing;
-- ALTER SCHEMA SET owner to postgres;


-- create meshblocks table
DROP TABLE if exists testing.abs_2016_mb;
CREATE TABLE testing.abs_2016_mb (
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

-- insert data
insert into testing.abs_2016_mb
select * from admin_bdys_201811.abs_2016_mb;

-- add indexes and cluster on geom index
ALTER TABLE testing.abs_2016_mb ADD CONSTRAINT abs_2016_mb_pk PRIMARY KEY (gid);

CREATE INDEX abs_2016_mb_geom_idx ON testing.abs_2016_mb USING gist (geom);
ALTER TABLE testing.abs_2016_mb CLUSTER ON abs_2016_mb_geom_idx;


-- create GNAF table
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
    mb_2016_code bigint,
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
insert into testing.address_principals
select * from gnaf_201811.address_principals;

-- add indexes and cluster on geom index
ALTER TABLE testing.address_principals ADD CONSTRAINT address_principals_pk PRIMARY KEY (gnaf_pid);

CREATE INDEX address_principals_geom_idx ON testing.address_principals USING gist (geom);
ALTER TABLE testing.address_principals CLUSTER ON address_principals_geom_idx;

CREATE INDEX address_principals_gid_idx ON testing.address_principals USING btree (gid);
