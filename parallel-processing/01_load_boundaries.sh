#!/bin/bash

# Creates a new database and imports Australian Bureau of Statistics 2011 Census meshblock boundaries from Shapefiles

# You'll need to have stored your login password in pgAdmin prior to run this without interruption

# shp2pgsql basics: http://suite.opengeo.org/opengeo-docs/dataadmin/pgGettingStarted/shp2pgsql.html
# psql basics:      http://www.postgresql.org/docs/9.3/static/app-psql.html

# ------------------------------------------------------------------------------------------------------------------------------------
# -- Set your input parameters here
# ------------------------------------------------------------------------------------------------------------------------------------

SERVER="localhost"
PORT="5432"
DBNAME="perftest"
USER="postgres"
THEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ------------------------------------------------------------------------------------------------------------------------------------

# Add extensions to database
psql -U $USER -d $DBNAME -h $SERVER -p $PORT -c "CREATE EXTENSION postgis"
psql -U $USER -d $DBNAME -h $SERVER -p $PORT -c "CREATE EXTENSION dblink"

# Create Parallel Processing and Random Point Functions
psql -U $USER -d $DBNAME -h $SERVER -p $PORT -f "$THEDIR/functions/create_parallel_processing_function.sql"
psql -U $USER -d $DBNAME -h $SERVER -p $PORT -f "$THEDIR/functions/create_random_points_in_polygon_function.sql"

# Import Meshblocks and optimise table
shp2pgsql -d -D -s 4283 -i -I $THEDIR/data/MB_2011_AUST.shp mb_2011_aust | psql -U $USER -d $DBNAME -h $SERVER -p $PORT
psql -U $USER -d $DBNAME -h $SERVER -p $PORT -c "ALTER TABLE mb_2011_aust CLUSTER ON mb_2011_aust_geom_idx"
psql -U $USER -d $DBNAME -h $SERVER -p $PORT -c "CREATE INDEX idx_mb_2011_aust_mb_code11 ON mb_2011_aust USING btree (mb_code11)"
psql -U $USER -d $DBNAME -h $SERVER -p $PORT -c "ANALYZE mb_2011_aust"

# Confim record count = 347,519
psql -U $USER -d $DBNAME -h $SERVER -p $PORT -c "SELECT Count(*) FROM mb_2011_aust"
