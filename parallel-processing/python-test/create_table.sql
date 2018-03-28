CREATE TABLE testing.test_gnaf_meshblocks (
    gnaf_pid text COLLATE pg_catalog."default",
    mb_code16 character varying(11) COLLATE pg_catalog."default"
)
WITH (OIDS = FALSE);

ALTER TABLE testing.test_gnaf_meshblocks OWNER to postgres;







truncate table testing.test_gnaf_meshblocks;