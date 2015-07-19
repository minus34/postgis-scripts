# Import Python modules
import psycopg2

from datetime import datetime

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

# Grid parameters
start_width = 0.5  # in km
multiple = 2
min_width = 0.3

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

    # Get Hex Grids
    get_hex_grids(pg_cur)

    pg_cur.close()
    pg_conn.close()

    return True


def get_hex_grids(pg_cur):
    curr_width = start_width

    while curr_width > min_width:
        # Get table name friendly width
        curr_width_str = str(curr_width)
        curr_width_str = curr_width_str.replace(".", "_")
        curr_width_str = curr_width_str.replace("_0", "")

        # Create hex grid table
        pg_cur.execute("DROP TABLE IF EXISTS %s.%s_%s" % (pg_schema, hex_grid_table_name, curr_width_str))

        sql = "CREATE UNLOGGED TABLE {0}.{1}_{2} (" \
              "gid SERIAL, " \
              "pid varchar(20), " \
              "geom GEOMETRY('POLYGON', 4283, 2)" \
              ") WITH (OIDS=FALSE)".format(pg_schema, hex_grid_table_name, curr_width_str)

        pg_cur.execute(sql)

        # Index the geom and cluster table on the index
        sql = "CREATE INDEX %s_%s_geom_idx ON %s.%s_%s USING gist (geom)"
        pg_cur.execute(sql % (hex_grid_table_name, curr_width_str, pg_schema, hex_grid_table_name, curr_width_str))

        sql = "ALTER TABLE %s.%s_%s CLUSTER ON %s_%s_geom_idx"
        pg_cur.execute(sql % (pg_schema, hex_grid_table_name, curr_width_str, hex_grid_table_name, curr_width_str))

        # Generate hex grids
        sql = "INSERT INTO {0}.{1}_{2} (pid, geom) " \
              "SELECT * FROM hex_grid_width({3}, 84.0, -44.0, 161.5, -5.0, 4283, 3577, 4283)"\
            .format(pg_schema, hex_grid_table_name, curr_width_str, curr_width)

        pg_cur.execute(sql)

        pg_cur.execute("ANALYZE %s.%s_%s" % (pg_schema, hex_grid_table_name, curr_width_str))

        print datetime.now().strftime('%Y-%m-%d %H:%M:%S') + " - Grid %s processed" % curr_width_str

        curr_width /= multiple

    return True


if __name__ == '__main__':
    if main():
        print("PROCESSING FINISHED")
    else:
        print(datetime.now().strftime('%Y-%m-%d %H:%M:%S') + " - FATAL - PROCESSING STOPPED UNEXPECTEDLY")

    duration = datetime.now() - startTime
    days, seconds = duration.days, duration.seconds
    hours = str(days * 24 + seconds // 3600).zfill(2)
    minutes = str((seconds % 3600) // 60).zfill(2)
    seconds = str(seconds % 60 + duration.microseconds // 1000000).zfill(2)

    print("DURATION: " + hours + ":" + minutes + ":" + seconds)
