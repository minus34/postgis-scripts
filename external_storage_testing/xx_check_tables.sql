

-- check storage type of geom columns
select tbl.relname,
       att.attname, 
       case att.attstorage
          when 'p' then 'plain'
          when 'm' then 'main'
          when 'e' then 'external'
          when 'x' then 'extended'
       end as attstorage
from pg_attribute att  
  join pg_class tbl on tbl.oid = att.attrelid   
  join pg_namespace ns on tbl.relnamespace = ns.oid   
where ns.nspname = 'testing'
  and att.attname = 'geom'
  and not att.attisdropped;


-- check table sizes
select table_schema,
       table_name,
       pg_relation_size(table_schema||'.'||table_name),
       pg_total_relation_size(table_schema||'.'||table_name)
from information_schema.tables
where (table_schema = 'admin_bdys_201808' and table_name = 'abs_2011_mb')
  or (table_schema = 'gnaf_201808' and table_name = 'address_principals')
  OR table_schema = 'testing'
 order by table_name,
          table_schema;

--admin_bdys_201808		abs_2011_mb			270098432	424329216
--testing				abs_2011_mb			203399168	432021504
--gnaf_201808			address_principals	3510861824	5039718400
--testing				address_principals	3510812672	5037875200
