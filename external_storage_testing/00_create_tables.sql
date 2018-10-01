
-- create meshblocks table
DROP TABLE if exists testing.abs_2011_mb;
CREATE TABLE testing.abs_2011_mb (
	gid int4 NOT NULL,
	mb_11code text NULL,
	mb_category text NULL,
	sa1_11main float8 NULL,
	sa1_11_7cd int4 NULL,
	sa2_11main int4 NULL,
	sa2_11_5cd int4 NULL,
	sa2_11name text NULL,
	sa3_11code int4 NULL,
	sa3_11name text NULL,
	sa4_11code int4 NULL,
	sa4_11name text NULL,
	gcc_11code text NULL,
	gcc_11name text NULL,
	state text NULL,
	area_sqm numeric NULL,
	mb11_pop int4 NULL,
	mb11_dwell int4 NULL,
	geom geometry(Multipolygon,4283) NULL
)
WITH (OIDS = FALSE);
ALTER TABLE testing.abs_2011_mb OWNER TO postgres;

-- set geom column to decompressed
ALTER TABLE testing.abs_2011_mb ALTER COLUMN geom SET STORAGE EXTERNAL;

-- insert data
insert into testing.abs_2011_mb
select * from admin_bdys_201808.abs_2011_mb;

-- add indexes and cluster on geom index
ALTER TABLE testing.abs_2011_mb ADD CONSTRAINT abs_2011_mb_pk PRIMARY KEY (gid);

CREATE INDEX abs_2011_mb_geom_idx ON testing.abs_2011_mb USING gist (geom);
ALTER TABLE testing.abs_2011_mb CLUSTER ON abs_2011_mb_geom_idx;


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
insert into testing.address_principals
select * from gnaf_201808.address_principals;

-- add indexes and cluster on geom index
ALTER TABLE testing.address_principals ADD CONSTRAINT address_principals_pk PRIMARY KEY (gnaf_pid);

CREATE INDEX address_principals_geom_idx ON testing.address_principals USING gist (geom);
ALTER TABLE testing.address_principals CLUSTER ON address_principals_geom_idx;

CREATE INDEX address_principals_gid_idx ON testing.address_principals USING btree (gid);
