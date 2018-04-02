CREATE SCHEMA IF NOT EXISTS testing AUTHORIZATION postgres;

CREATE TABLE﻿testing.address_principals_part
(
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
) PARTITION BY RANGE (longitude)
WITH (OIDS = FALSE);

ALTER TABLE testing.address_principals_part OWNER to postgres;

CREATE TABLE testing.address_principals_part_1 PARTITION OF testing.address_principals_part FOR VALUES FROM ('96.8215') TO ('115.8473');
CREATE TABLE testing.address_principals_part_2 PARTITION OF testing.address_principals_part FOR VALUES FROM ('115.8473') TO ('120.5748');
CREATE TABLE testing.address_principals_part_3 PARTITION OF testing.address_principals_part FOR VALUES FROM ('120.5748') TO ('138.6046');
CREATE TABLE testing.address_principals_part_4 PARTITION OF testing.address_principals_part FOR VALUES FROM ('138.6046') TO ('142.4924');
CREATE TABLE testing.address_principals_part_5 PARTITION OF testing.address_principals_part FOR VALUES FROM ('142.4924') TO ('144.7469');
CREATE TABLE testing.address_principals_part_6 PARTITION OF testing.address_principals_part FOR VALUES FROM ('144.7469') TO ('144.9711');
CREATE TABLE testing.address_principals_part_7 PARTITION OF testing.address_principals_part FOR VALUES FROM ('144.9711') TO ('145.0797');
CREATE TABLE testing.address_principals_part_8 PARTITION OF testing.address_principals_part FOR VALUES FROM ('145.0797') TO ('145.2545');
CREATE TABLE testing.address_principals_part_9 PARTITION OF testing.address_principals_part FOR VALUES FROM ('145.2545') TO ('146.0666');
CREATE TABLE testing.address_principals_part_10 PARTITION OF testing.address_principals_part FOR VALUES FROM ('146.0666') TO ('147.4484');
CREATE TABLE testing.address_principals_part_11 PARTITION OF testing.address_principals_part FOR VALUES FROM ('147.4484') TO ('149.5449');
CREATE TABLE testing.address_principals_part_12 PARTITION OF testing.address_principals_part FOR VALUES FROM ('149.5449') TO ('150.8143');
CREATE TABLE testing.address_principals_part_13 PARTITION OF testing.address_principals_part FOR VALUES FROM ('150.8143') TO ('150.9992');
CREATE TABLE testing.address_principals_part_14 PARTITION OF testing.address_principals_part FOR VALUES FROM ('150.9992') TO ('151.129');
CREATE TABLE testing.address_principals_part_15 PARTITION OF testing.address_principals_part FOR VALUES FROM ('151.129') TO ('151.2382');
CREATE TABLE testing.address_principals_part_16 PARTITION OF testing.address_principals_part FOR VALUES FROM ('151.2382') TO ('151.6735');
CREATE TABLE testing.address_principals_part_17 PARTITION OF testing.address_principals_part FOR VALUES FROM ('151.6735') TO ('152.8368');
CREATE TABLE testing.address_principals_part_18 PARTITION OF testing.address_principals_part FOR VALUES FROM ('152.8368') TO ('153.0298');
CREATE TABLE testing.address_principals_part_19 PARTITION OF testing.address_principals_part FOR VALUES FROM ('153.0298') TO ('153.1523');
CREATE TABLE testing.address_principals_part_20 PARTITION OF testing.address_principals_part FOR VALUES FROM ('153.1523') TO ('167.9931');

INSERT INTO testing.address_principals_part
SELECT gnaf_pid, street_locality_pid, locality_pid, alias_principal, primary_secondary, building_name,
  lot_number, flat_number, level_number, number_first, number_last, street_name, street_type, street_suffix, address,
  locality_name, postcode, state, locality_postcode, confidence, legal_parcel_id, mb_2011_code, mb_2016_code,
  latitude, longitude, geocode_type, reliability, geom
FROM gnaf_201802.address_principals;

ANALYZE testing.address_principals_part_1;
CREATE INDEX ON testing.address_principals_part_1 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_1 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_1_geom_idx ON testing.address_principals_part_1 USING gist (geom);
ALTER TABLE testing.address_principals_part_1 CLUSTER ON address_principals_part_1_geom_idx;

ANALYZE testing.address_principals_part_2;
CREATE INDEX ON testing.address_principals_part_2 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_2 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_2_geom_idx ON testing.address_principals_part_2 USING gist (geom);
ALTER TABLE testing.address_principals_part_2 CLUSTER ON address_principals_part_2_geom_idx;

ANALYZE testing.address_principals_part_3;
CREATE INDEX ON testing.address_principals_part_3 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_3 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_3_geom_idx ON testing.address_principals_part_3 USING gist (geom);
ALTER TABLE testing.address_principals_part_3 CLUSTER ON address_principals_part_3_geom_idx;

ANALYZE testing.address_principals_part_4;
CREATE INDEX ON testing.address_principals_part_4 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_4 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_4_geom_idx ON testing.address_principals_part_4 USING gist (geom);
ALTER TABLE testing.address_principals_part_4 CLUSTER ON address_principals_part_4_geom_idx;

ANALYZE testing.address_principals_part_5;
CREATE INDEX ON testing.address_principals_part_5 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_5 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_5_geom_idx ON testing.address_principals_part_5 USING gist (geom);
ALTER TABLE testing.address_principals_part_5 CLUSTER ON address_principals_part_5_geom_idx;

ANALYZE testing.address_principals_part_6;
CREATE INDEX ON testing.address_principals_part_6 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_6 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_6_geom_idx ON testing.address_principals_part_6 USING gist (geom);
ALTER TABLE testing.address_principals_part_6 CLUSTER ON address_principals_part_6_geom_idx;

ANALYZE testing.address_principals_part_7;
CREATE INDEX ON testing.address_principals_part_7 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_7 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_7_geom_idx ON testing.address_principals_part_7 USING gist (geom);
ALTER TABLE testing.address_principals_part_7 CLUSTER ON address_principals_part_7_geom_idx;

ANALYZE testing.address_principals_part_8;
CREATE INDEX ON testing.address_principals_part_8 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_8 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_8_geom_idx ON testing.address_principals_part_8 USING gist (geom);
ALTER TABLE testing.address_principals_part_8 CLUSTER ON address_principals_part_8_geom_idx;

ANALYZE testing.address_principals_part_9;
CREATE INDEX ON testing.address_principals_part_9 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_9 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_9_geom_idx ON testing.address_principals_part_9 USING gist (geom);
ALTER TABLE testing.address_principals_part_9 CLUSTER ON address_principals_part_9_geom_idx;

ANALYZE testing.address_principals_part_10;
CREATE INDEX ON testing.address_principals_part_10 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_10 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_10_geom_idx ON testing.address_principals_part_10 USING gist (geom);
ALTER TABLE testing.address_principals_part_10 CLUSTER ON address_principals_part_10_geom_idx;

ANALYZE testing.address_principals_part_11;
CREATE INDEX ON testing.address_principals_part_11 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_11 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_11_geom_idx ON testing.address_principals_part_11 USING gist (geom);
ALTER TABLE testing.address_principals_part_11 CLUSTER ON address_principals_part_11_geom_idx;

ANALYZE testing.address_principals_part_12;
CREATE INDEX ON testing.address_principals_part_12 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_12 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_12_geom_idx ON testing.address_principals_part_12 USING gist (geom);
ALTER TABLE testing.address_principals_part_12 CLUSTER ON address_principals_part_12_geom_idx;

ANALYZE testing.address_principals_part_13;
CREATE INDEX ON testing.address_principals_part_13 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_13 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_13_geom_idx ON testing.address_principals_part_13 USING gist (geom);
ALTER TABLE testing.address_principals_part_13 CLUSTER ON address_principals_part_13_geom_idx;

ANALYZE testing.address_principals_part_14;
CREATE INDEX ON testing.address_principals_part_14 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_14 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_14_geom_idx ON testing.address_principals_part_14 USING gist (geom);
ALTER TABLE testing.address_principals_part_14 CLUSTER ON address_principals_part_14_geom_idx;

ANALYZE testing.address_principals_part_15;
CREATE INDEX ON testing.address_principals_part_15 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_15 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_15_geom_idx ON testing.address_principals_part_15 USING gist (geom);
ALTER TABLE testing.address_principals_part_15 CLUSTER ON address_principals_part_15_geom_idx;

ANALYZE testing.address_principals_part_16;
CREATE INDEX ON testing.address_principals_part_16 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_16 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_16_geom_idx ON testing.address_principals_part_16 USING gist (geom);
ALTER TABLE testing.address_principals_part_16 CLUSTER ON address_principals_part_16_geom_idx;

ANALYZE testing.address_principals_part_17;
CREATE INDEX ON testing.address_principals_part_17 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_17 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_17_geom_idx ON testing.address_principals_part_17 USING gist (geom);
ALTER TABLE testing.address_principals_part_17 CLUSTER ON address_principals_part_17_geom_idx;

ANALYZE testing.address_principals_part_18;
CREATE INDEX ON testing.address_principals_part_18 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_18 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_18_geom_idx ON testing.address_principals_part_18 USING gist (geom);
ALTER TABLE testing.address_principals_part_18 CLUSTER ON address_principals_part_18_geom_idx;

ANALYZE testing.address_principals_part_19;
CREATE INDEX ON testing.address_principals_part_19 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_19 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_19_geom_idx ON testing.address_principals_part_19 USING gist (geom);
ALTER TABLE testing.address_principals_part_19 CLUSTER ON address_principals_part_19_geom_idx;

ANALYZE testing.address_principals_part_20;
CREATE INDEX ON testing.address_principals_part_20 USING btree (longitude);
CREATE INDEX ON testing.address_principals_part_20 USING btree (gnaf_pid);
CREATE INDEX address_principals_part_20_geom_idx ON testing.address_principals_part_20 USING gist (geom);
ALTER TABLE testing.address_principals_part_20 CLUSTER ON address_principals_part_20_geom_idx;

ANALYZE testing.address_principals_part;
