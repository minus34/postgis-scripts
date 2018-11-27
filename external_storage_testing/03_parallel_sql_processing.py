"""
-----------------------------------------------------------------------------------------------------------------------
Name:        parallel processing test
Purpose:     uses parallel processing in Postgres to run a point in polygon query against GNAF,

Author:      Hugh Saalmans (@minus34)

Created:     28/03/2018

-----------------------------------------------------------------------------------------------------------------------
"""

import argparse
import logging
import os
import psycopg2  # need to install psycopg2 package
import psycopg2.extras
import multiprocessing

from datetime import datetime


# set command line arguments for the script
def set_arguments():

    parser = argparse.ArgumentParser(
        description='blah blah blah')

    parser.add_argument(
        '--max-processes', type=int, default=20,
        help='Maximum number of parallel processes to use. (Set it to the number of cores on the '
             'Postgres server minus 2. Defaults to 6.')

    # PG Options
    parser.add_argument(
        '--pghost',
        help='Host name for Postgres server. Defaults to PGHOST environment variable if set, otherwise localhost.')
    parser.add_argument(
        '--pgport', type=int,
        help='Port number for Postgres server. Defaults to PGPORT environment variable if set, otherwise 5433.')
    parser.add_argument(
        '--pgdb',
        help='Database name for Postgres server. Defaults to PGDATABASE environment variable if set, '
             'otherwise geo.')
    parser.add_argument(
        '--pguser',
        help='Username for Postgres server. Defaults to PGUSER environment variable if set, otherwise postgres.')
    parser.add_argument(
        '--pgpassword',
        help='Password for Postgres server. Defaults to PGPASSWORD environment variable if set, '
             'otherwise \'password\'.')

    return parser.parse_args()


# create the dictionary of settings
def get_settings(args):
    settings = dict()

    # options are "coordinates" (AU only) or "gid" for an integer sequential ID
    settings["partition_type"] = "coordinates"

    # longitudes that break the AUS population into 20 roughly equal counts
    settings['partition_ranges'] = [96.8215, 115.8473, 120.5748, 138.6046, 142.4924, 144.7469, 144.9711, 145.0797,
                                    145.2545, 146.0666, 147.4484, 149.5449, 150.8143, 150.9992, 151.129, 151.2382,
                                    151.6735, 152.8368, 153.0298, 153.1523, 167.9931]

    # script for inserting into
    settings["the_sql_file"] = "03_the_query.sql"

    # get the sql string
    settings["sql"] = open(settings["the_sql_file"], "r").read()

    # how many parallel processes?
    settings['max_concurrent_processes'] = args.max_processes

    # create postgres connect string
    settings['pg_host'] = args.pghost or os.getenv("PGHOST", "localhost")
    settings['pg_port'] = args.pgport or os.getenv("PGPORT", 5433)
    settings['pg_db'] = args.pgdb or os.getenv("PGDATABASE", "geo")
    settings['pg_user'] = args.pguser or os.getenv("PGUSER", "postgres")
    settings['pg_password'] = args.pgpassword or os.getenv("PGPASSWORD", "password")

    settings['pg_connect_string'] = "dbname='{}' host='{}' port='{}' user='{}' password='{}'".format(
        settings['pg_db'], settings['pg_host'], settings['pg_port'], settings['pg_user'], settings['pg_password'])

    return settings


def main():
    full_start_time = datetime.now()

    logger.info("START")

    # set command line arguments
    args = set_arguments()

    # get settings from arguments
    settings = get_settings(args)

    # create list of sql statements to process in parallel
    sql_list = list()

    num_partitions = len(settings["partition_ranges"])
    current_child_table_num = 1

    while current_child_table_num < num_partitions:
        partition_start_value = settings["partition_ranges"][current_child_table_num - 1]
        partition_end_value = settings["partition_ranges"][current_child_table_num]

        where_clause = " WHERE longitude > {} AND longitude <= {};".format(partition_start_value, partition_end_value)
        sql = settings['sql'].replace(";", where_clause)
        # print(sql)

        sql_list.append(sql)

        current_child_table_num += 1

    # parallel process the lot
    multiprocess_list(sql_list, settings)

    logger.info("FINISHED : {}".format(datetime.now() - full_start_time, ))


# takes a list of sql queries or command lines and runs them using multiprocessing
# - taken from https://github.com/minus34/gnaf-loader
def multiprocess_list(work_list, settings):
    pool = multiprocessing.Pool(processes=settings['max_concurrent_processes'])

    num_jobs = len(work_list)

    results = pool.imap_unordered(run_sql_multiprocessing, [[w, settings] for w in work_list])

    pool.close()
    pool.join()

    result_list = list(results)
    num_results = len(result_list)

    if num_jobs > num_results:
        logger.warning("\t- A MULTIPROCESSING PROCESS FAILED WITHOUT AN ERROR\nACTION: Check the record counts")

    for result in result_list:
        if result != "SUCCESS":
            logger.info(result)


def run_sql_multiprocessing(args):
    the_sql = args[0]
    settings = args[1]
    pg_conn = psycopg2.connect(settings['pg_connect_string'])
    pg_conn.autocommit = True
    pg_cur = pg_conn.cursor()

    try:
        pg_cur.execute(the_sql)
        result = "SUCCESS"
    except Exception as ex:
        result = "SQL FAILED! : {0} : {1}".format(the_sql, ex)

    pg_cur.close()
    pg_conn.close()

    return result


if __name__ == '__main__':
    logger = logging.getLogger()

    # set logger
    log_file = os.path.abspath(__file__).replace(".py", ".log")
    logging.basicConfig(filename=log_file, level=logging.DEBUG, format="%(asctime)s %(message)s",
                        datefmt="%m/%d/%Y %I:%M:%S %p")

    # setup logger to write to screen as well as writing to log file
    # define a Handler which writes INFO messages or higher to the sys.stderr
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    # set a format which is simpler for console use
    formatter = logging.Formatter('%(name)-12s: %(levelname)-8s %(message)s')
    # tell the handler to use this format
    console.setFormatter(formatter)
    # add the handler to the root logger
    logging.getLogger('').addHandler(console)

    main()
