-- DROP FUNCTION public.parsel(table_to_chunk text, pkey text, query text, output_table text, table_to_chunk_alias text, num_chunks integer);
CREATE OR REPLACE FUNCTION public.parsel(table_to_chunk text, pkey text, query text, output_table text, table_to_chunk_alias text, num_chunks integer)
  RETURNS text AS
$BODY$
DECLARE
  db text;
  username text;
  pword text;
  connectstring text;
  sql text;
  min_id integer;
  max_id integer;
  step_size integer;
  lbnd integer;
  ubnd integer;
  subquery text;
  insert_query text;
  i integer;
  conn text;
  n integer;
  num_done integer;
  status integer;
  dispatch_result integer;
  dispatch_error text;
  part text;
  rand text;

BEGIN

  --get calling database name
  sql := 'SELECT current_database();';
  EXECUTE sql INTO db;

  ------------------------------------------------------------------
  -- TO DO: edit your user name, password and connect string here --
  ------------------------------------------------------------------

  username := 'postgres';
--  pword :=  '<your password>';
  
--  connectstring := QUOTE_LITERAL('dbname=' || db || ' user=' || username || ' password=' || pword);
  connectstring := QUOTE_LITERAL('dbname=' || db || ' user=' || username);
--  connectstring := QUOTE_LITERAL('dbname=' || db);

  ------------------------------------------------------------------
  ------------------------------------------------------------------

  --find minimum pkey id
  sql := 'SELECT min(' || pkey || ') from ' || table_to_chunk || ';';
  EXECUTE sql INTO min_id;

  --find maximum pkey id
  sql := 'SELECT max(' || pkey || ') from ' || table_to_chunk || ';';
  EXECUTE sql INTO max_id;

  -- determine size of chunks based on min id, max id, and number of chunks
  sql := 'SELECT ( ' || max_id || '-' || min_id || ')/' || num_chunks - 1 || ';';
  EXECUTE sql INTO step_size;

  -- loop through chunks
  FOR lbnd,ubnd,i IN 
	SELECT  generate_series(min_id, max_id, step_size) as lbnd, 
		generate_series(min_id + step_size, max_id + step_size, step_size) as ubnd,
		generate_series(1, num_chunks) as i
  LOOP
    --for debugging
    --RAISE NOTICE 'Chunk %: % >= % and % < %', i, pkey, lbnd, pkey, ubnd;

    --make a new db connection
    conn := 'conn_' || i;  
    sql := 'SELECT dblink_connect(' || QUOTE_LITERAL(conn) || ',' || connectstring || ');';




    --RAISE NOTICE '%', sql;





    EXECUTE sql;

    --create a subquery string that will replace the table name in the original query
    part := '(SELECT * FROM ' || table_to_chunk || ' WHERE ' || pkey || ' >= ' || lbnd || ' AND ' || pkey || ' < ' || ubnd || ') ';
  
    --edit the input query using the subsquery string
    sql := 'SELECT REPLACE(' || QUOTE_LITERAL(query) || ',' || QUOTE_LITERAL(table_to_chunk) || ',' || QUOTE_LITERAL(part) || ');';
    EXECUTE sql INTO subquery;
    
    insert_query := 'INSERT INTO ' || output_table || ' ' || subquery || ';';
    RAISE NOTICE 'Connection % : %', i, insert_query;
    
    --send the query asynchronously using the dblink connection
    sql := 'SELECT dblink_send_query(' || QUOTE_LITERAL(conn) || ',' || QUOTE_LITERAL(insert_query) || ');';
    EXECUTE sql INTO dispatch_result;

    -- check for errors dispatching the query
    IF dispatch_result = 0 THEN
	sql := 'SELECT dblink_error_message(' || QUOTE_LITERAL(conn)  || ');';
	EXECUTE sql INTO dispatch_error;
        RAISE '%', dispatch_error;
    END IF;
    
  END LOOP;

  -- wait until all queries are finished
  LOOP
    num_done := 0;
  
    FOR i IN 1..num_chunks
    LOOP
      conn := 'conn_' || i;
      sql := 'SELECT dblink_is_busy(' || QUOTE_LITERAL(conn) || ');';
      EXECUTE sql INTO status;

      IF status = 0 THEN	
        -- check for error messages
        sql := 'SELECT dblink_error_message(' || QUOTE_LITERAL(conn)  || ');';
        EXECUTE sql INTO dispatch_error;
        IF dispatch_error <> 'OK' THEN
          RAISE '%', dispatch_error;
        END IF;

        num_done := num_done + 1;
      END if;
    END LOOP;
  
    IF num_done >= num_chunks THEN
      EXIT;
    END IF;
    
  END LOOP;

  -- disconnect the dblinks
  FOR i IN 1..num_chunks
  LOOP
    conn := 'conn_' || i;
    sql := 'SELECT dblink_disconnect(' || QUOTE_LITERAL(conn) || ');';
    EXECUTE sql;
  END LOOP;

RETURN 'Success';

-- error catching to disconnect dblink connections, if error occurs
EXCEPTION WHEN others THEN
  BEGIN
  RAISE NOTICE '% %', SQLERRM, SQLSTATE;
  FOR n IN 
	SELECT generate_series(1,i) as n
  LOOP
    conn := 'conn_' || n;
    sql := 'SELECT dblink_disconnect(' || QUOTE_LITERAL(conn) || ');';
    EXECUTE sql;
  END LOOP;
  
  EXCEPTION WHEN others THEN
    RAISE NOTICE '% %', SQLERRM, SQLSTATE;
  END;
  
END
$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;