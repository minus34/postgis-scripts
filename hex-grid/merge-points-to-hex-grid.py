# *********************************************************************************************************************
# PURPOSE: Copies policy data from the prod Greenplum appliance to another postgres instance
#
# AUTHOR: HS, 2015/04/08
#
# NOTES:
#  -
#
# *********************************************************************************************************************

# Import Python modules
import math
import psycopg2

from datetime import datetime

metres2degrees = (2.0 * math.pi * 6378137.0) / 360.0
tile_width = 78271.52  # Standard width of a single 256 pixel map tile at zoom level one


#######################################################################################################################
# SCRIPT PARAMETERS
#######################################################################################################################

# Postgres parameters
pg_host = "localhost"
pg_port = 5432
pg_db = "iadpdev"
pg_user = "postgres"
pg_password = "password"
pg_schema = "hex"

hex_grid_table_name = "grid"

points_table_name = "mb_random_points"
output_points_table_name = "mb_points_hex"

# Parallel processing parameters
cpus = 6

# Grid parameters
start_zoom_level = 1
start_width = 1024  # in km
multiple = 2
min_width = 0.9

# #####################################################################################################################

startTime = datetime.now()

print "--------------------------------------------------"
print datetime.now().strftime('%Y-%m-%d %H:%M:%S') + " - PROCESSING STARTED"


def main():
    # Connect to Postgres
    pg_connect_string = "host='%s' dbname='%s' user='%s' password='%s' port=%s"

    # need to use password version as trust is not set on server
    pg_conn = psycopg2.connect(pg_connect_string % (pg_host, pg_db, pg_user, pg_password, pg_port))

    pg_conn.autocommit = True
    pg_cur = pg_conn.cursor()

    # Get Hex IDs
    get_hex_ids(pg_cur)

    pg_cur.close()
    pg_conn.close()

    return True


def get_hex_ids(pg_cur):
    curr_width = start_width
    zoom_level = start_zoom_level

    while curr_width > min_width:
        # Set the number of decimal places for the output GeoJSON to reduce response size & speed up rendering
        tolerance = (tile_width / math.pow(2.0, float(zoom_level))) / metres2degrees
        places = 0
        precision = 0.1

        while precision > tolerance:
            places += 1
            precision /= 10

        places += 1

        # Get table name friendly width
        curr_width_str = str(curr_width)
        curr_width_str = curr_width_str.replace(".", "_")
        curr_width_str = curr_width_str.replace("_0", "")

        pg_cur.execute("DROP TABLE IF EXISTS {0}.grid_{1}_counts".format(pg_schema, curr_width_str))

        sql = "CREATE UNLOGGED TABLE {0}.grid_{2}_counts (count integer, geojson text, geom geometry(POINT,4283, 2)) " \
              "WITH (OIDS=FALSE); ALTER TABLE hex.grid_{2}_counts OWNER TO {3};"\
            .format(pg_schema, points_table_name, curr_width_str, pg_user)

        pg_cur.execute(sql)

        # Create spatial index
        pg_cur.execute("CREATE INDEX grid_{1}_counts_geom_idx ON {0}.grid_{1}_counts USING gist (geom)"
                       .format(pg_schema, curr_width_str))

        pg_cur.execute("ALTER TABLE {0}.grid_{1}_counts CLUSTER ON grid_{1}_counts_geom_idx"
                       .format(pg_schema, curr_width_str))

        # Get the 'what ever the attribute is' counts for each hex grid (using parallel processing)
        sql = "SELECT public.parsel('{0}.grid_{2}'," \
              "'gid'," \
              "'SELECT sqt.count, ST_AsGeoJSON(grd.geom, {4}, 0), ST_Centroid(grd.geom) " \
              "FROM {0}.grid_{2} AS grd INNER JOIN (" \
              "SELECT bdys.gid, Count(*) AS count " \
              "FROM {0}.grid_{2} AS bdys INNER JOIN public.{1} as pnts ON ST_Contains(bdys.geom, pnts.geom) " \
              "GROUP BY bdys.gid" \
              ") AS sqt ON grd.gid = sqt.gid'," \
              "'{0}.grid_{2}_counts'," \
              "'bdys'," \
              "{3})".format(pg_schema, points_table_name, curr_width_str, str(cpus), places)

        # print sql

        pg_cur.execute(sql)

        pg_cur.execute("ANALYZE {0}.grid_{1}_counts".format(pg_schema, curr_width_str))

        print datetime.now().strftime('%Y-%m-%d %H:%M:%S') + " - {0} processed".format(curr_width_str,)

        curr_width /= multiple
        zoom_level += 1

    return True


if __name__ == '__main__':
    if main():
        print datetime.now().strftime('%Y-%m-%d %H:%M:%S') + " - PROCESSING FINISHED"
    else:
        print datetime.now().strftime('%Y-%m-%d %H:%M:%S') + " - PROCESSING STOPPED UNEXPECTEDLY"

    duration = datetime.now() - startTime
    days, seconds = duration.days, duration.seconds
    hours = str(days * 24 + seconds // 3600).zfill(2)
    minutes = str((seconds % 3600) // 60).zfill(2)
    seconds = str(seconds % 60 + duration.microseconds // 1000000).zfill(2)

    print "DURATION: " + hours + ":" + minutes + ":" + seconds
