INSERT INTO gnaf_201802.address_principals_part
SELECT gnaf_pid, street_locality_pid, locality_pid, alias_principal, primary_secondary, building_name,
  lot_number, flat_number, level_number, number_first, number_last, street_name, street_type, street_suffix, address,
  locality_name, postcode, state, locality_postcode, confidence, legal_parcel_id, mb_2011_code, mb_2016_code,
  latitude, longitude, geocode_type, reliability, geom
FROM gnaf_201802.address_principals;
