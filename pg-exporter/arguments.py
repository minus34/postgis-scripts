#!/usr/bin/env python
# -*- coding: utf-8 -*-

import argparse
import os

TEST_QUERY = "SELECT * FROM "
TEST_TARGET_FILE = "/Users/hugh.saalmans/tmp/test.xlsx"


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

    parser.add_argument('--format', default='xls', help='The target format. Defaults to xls')

    parser.add_argument(
        '--sql',
        help='SQl statement for the source query. Defaults to the TEST_QUERY parameter in this module.')
    parser.add_argument(
        '--file',
        help='Full path and name of output file. Defaults to the TEST_TARGET_FILE parameter in this module')

    return parser.parse_args()


# create the dictionary of settings
def get_settings(args):
    settings = dict()

    settings['format'] = args.sql
    settings['sql'] = args.sql or TEST_QUERY
    settings['file'] = args.file or TEST_TARGET_FILE

    # create postgres connect string
    settings['pg_host'] = args.pghost or os.getenv("PGHOST", "localhost")
    settings['pg_port'] = args.pgport or os.getenv("PGPORT", 5432)
    settings['pg_db'] = args.pgdb or os.getenv("POSTGRES_USER", "geo")
    settings['pg_user'] = args.pguser or os.getenv("POSTGRES_USER", "postgres")
    settings['pg_password'] = args.pgpassword or os.getenv("POSTGRES_PASSWORD", "password")

    settings['pg_connect_string'] = "dbname='{0}' host='{1}' port='{2}' user='{3}' password='{4}'".format(
        settings['pg_db'], settings['pg_host'], settings['pg_port'], settings['pg_user'], settings['pg_password'])

    return settings
