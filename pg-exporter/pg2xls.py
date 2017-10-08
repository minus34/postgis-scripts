# -*- coding: utf-8 -*-
# *********************************************************************************************************************
# PURPOSE: Exports the results of a Postgres query to an Excel Spreadsheet
#
# AUTHOR: Hugh Saalmans @minus34
#
# *********************************************************************************************************************

import arguments
import io
import logging.config
import os
import psycopg2  # module needs to be installed
import psycopg2.extras

from datetime import datetime


def main():
    full_start_time = datetime.now()

    # set command line arguments
    args = arguments.set_arguments()

    # get settings from arguments
    settings = arguments.get_settings(args)

    # connect to Postgres
    try:
        pg_conn = psycopg2.connect(settings['pg_connect_string'])
    except psycopg2.Error:
        logger.fatal("Unable to connect to database\nACTION: Check your Postgres parameters and/or database security")
        return False

    pg_conn.autocommit = True
    # pg_cur = pg_conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    pg_cur = pg_conn.cursor()

    result = export_query(pg_cur, settings['sql'], settings['file'])

    pg_cur.close()
    pg_conn.close()

    return result


def export_query(pg_cur, sql, file):
    """Exports query to the chosen format"""

    start_time = datetime.now()

    # Run query. Output result into in-memory stream formatted as CSV with the header row (NULLs are set to '')
    try:
        export_sql = "COPY ({0}) TO STDOUT WITH NULL AS '' HEADER CSV".format(sql, )

        rows = io.StringIO()
        pg_cur.copy_expert(export_sql, rows)

        logger.info("query took {}".format(datetime.now() - start_time))
        start_time = datetime.now()

    except Exception as ex:
        logger.fatal("unable to run query: {}\n{}".format(sql, ex))
        return False

    # Export in-memory CSV to file
    try:
        rows.seek(0)

        file = open(file, 'w')
        file.write(rows.getvalue())
        file.close()

        rows.close()

        logger.info("file export took {}".format(datetime.now() - start_time))

    except Exception as ex:
        logger.fatal("unable to export to file: {}".format(ex,))
        return False

    return True


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

    logger.info("")
    logger.info("Start pg-exporter")

    if main():
        logger.info("Finished successfully!")
    else:
        logger.fatal("Something bad happened!")

    logger.info("")
    logger.info("-------------------------------------------------------------------------------")
