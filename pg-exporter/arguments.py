#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import os
import tempfile

TEST_QUERY = "SELECT gid, gnaf_pid, street_locality_pid, locality_pid, alias_principal, primary_secondary, " \
             "building_name, lot_number, flat_number, level_number, number_first, number_last, street_name, " \
             "street_type, street_suffix, address, locality_name, postcode, state, locality_postcode, confidence, " \
             "legal_parcel_id, mb_2011_code, mb_2016_code, latitude, longitude, geocode_type, reliability " \
             "FROM gnaf_201708.address_principals"

TEST_LOCPID = "NSW401"

TEST_FILE_PATH = "/Users/hugh.saalmans/tmp"
TEST_FILE_NAME = "test"  # do not include extension

TEST_FORMAT = "xlsx"  # supported formats are: csv, tsv, psv, xlsx


# set the command line arguments for the script
def set_arguments():
    parser = argparse.ArgumentParser(
        description='Exports a Postgres query to various formats')

    # PG Options
    parser.add_argument(
        '--pghost',
        help='Host name for Postgres server. Defaults to PGHOST environment variable if set, otherwise localhost.')
    parser.add_argument(
        '--pgport', type=int,
        help='Port number for Postgres server. Defaults to PGPORT environment variable if set, otherwise 5432.')
    parser.add_argument(
        '--pgdb',
        help='Database name for Postgres server. Defaults to PGDATABASE environment variable if set, '
             'otherwise \'geo\'.')
    parser.add_argument(
        '--pguser',
        help='Username for Postgres server. Defaults to PGUSER environment variable if set, otherwise \'postgres\'.')
    parser.add_argument(
        '--pgpassword',
        help='Password for Postgres server. Defaults to PGPASSWORD environment variable if set, '
             'otherwise \'password\'.')

    # export arguments
    parser.add_argument('--format', help='The target format. Defaults to TEST_FORMAT parameter')
    parser.add_argument('--sql', help='SQL statement for the source query. Defaults to the TEST_QUERY parameter.')
    parser.add_argument('--locpid', help='Locality PID to extract PIF with. Defaults to the TEST_LOCPID parameter.')
    parser.add_argument('--filepath', help='Full path of the output file. Defaults to the TEST_FILE_PATH parameter')
    parser.add_argument('--filename', help='Full name of the output file. Defaults to the TEST_FILE_NAME parameter')

    return parser.parse_args()


# create the dictionary of settings
def get_settings(args):
    settings = dict()

    # file parameters
    settings['format'] = args.format or TEST_FORMAT
    settings['filepath'] = args.filepath or TEST_FILE_PATH
    settings['filename'] = args.filename or TEST_FILE_NAME

    # set delimiter if a text file format
    if settings['format'] == "csv":
        settings['delimiter'] = ","
    elif settings['format'] == "tsv":
        settings['delimiter'] = "\t"
    elif settings['format'] == "psv":
        settings['delimiter'] = "|"

    # sql parameters
    settings['sql'] = args.sql or TEST_QUERY
    settings['locpid'] = args.locpid or TEST_LOCPID

    # add where clause
    settings['sql'] += " WHERE locality_pid = '{}'".format(settings['locpid'])

    # create postgres connect string
    settings['pg_host'] = args.pghost or os.getenv("PGHOST", "localhost")
    settings['pg_port'] = args.pgport or os.getenv("PGPORT", 5432)
    settings['pg_db'] = args.pgdb or os.getenv("POSTGRES_USER", "geo")
    settings['pg_user'] = args.pguser or os.getenv("POSTGRES_USER", "postgres")
    settings['pg_password'] = args.pgpassword or os.getenv("POSTGRES_PASSWORD", "password")

    settings['pg_connect_string'] = "dbname='{0}' host='{1}' port='{2}' user='{3}' password='{4}'".format(
        settings['pg_db'], settings['pg_host'], settings['pg_port'], settings['pg_user'], settings['pg_password'])

    # create temporary output directory for local storage of downloaded ZIP files (dir will die when script finishes
    settings['temp_dir'] = tempfile.TemporaryDirectory()

    return settings
