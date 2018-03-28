CREATE TABLE gnaf_201802.address_principals_part
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
WITH (OIDS = FALSE)
TABLESPACE geo;

ALTER TABLE gnaf_201802.address_principals_part OWNER to postgres;
