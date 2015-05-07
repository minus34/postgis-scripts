
--DROP FUNCTION tz_routes();

CREATE OR REPLACE FUNCTION tz_routes(IN sql varchar, OUT o_tz integer, OUT out_o_sa3 integer, OUT out_d_tz integer, OUT out_d_sa3 integer, OUT out_vehicles integer, OUT out_seq integer, OUT out_id2 integer, OUT out_cost double precision)
  RETURNS SETOF RECORD AS
$FUNC$
DECLARE
  tz record;

BEGIN
  FOR tz IN
      EXECUTE sql
  LOOP

    RETURN QUERY (
      SELECT tz.o_tz, tz.o_sa3, tz.d_tz, tz.d_sa3, tz.vehicles, rt.seq, rt.id2, rt.cost FROM pgr_dijkstra('SELECT id, source, target, cost, reverse_cost FROM nsw_osm_main', tz.source, tz.target, false, true) AS rt
    );

  END LOOP;

RETURN;
  
END;
$FUNC$
LANGUAGE 'plpgsql' VOLATILE STRICT;
