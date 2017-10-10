# -*- coding: utf-8 -*-
# *********************************************************************************************************************
# PURPOSE: Exports the results of a Postgres query to an Excel Spreadsheet
#
# AUTHOR: Hugh Saalmans @minus34
#
# *********************************************************************************************************************

import arguments
import pg_export

import io
import logging.config
import os
import psycopg2  # module needs to be installed
import tempfile
import zipfile

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
    pg_cur = pg_conn.cursor()

    # get in-memory stream of data from query
    data_stream = pg_export.run_query(pg_cur, settings['sql'])

    # export data stream to flat file
    if settings['format'] in ["csv", "tsv", "psv"]:
        file_stream = pg_export.export_to_delimited_file(data_stream, settings['delimiter'])
    elif settings['format'] == "xlsx":
        file_stream = pg_export.export_to_xlsx(data_stream, settings['temp_dir'].name)
    else:
        logger.fatal("Invalid export file format - only csv, tsv, psv and xlsx are supported! - "
                     "check your settings")
        return False

    # set file name in ZIP file
    file_name = "{0}.{1}".format(settings['filename'], settings['format'])

    # add result to in-memory ZIP file
    zip_stream = io.BytesIO()
    zip_file = zipfile.ZipFile(zip_stream, mode='w', compression=zipfile.ZIP_DEFLATED)
    zip_file.writestr(file_name, file_stream.getvalue())

    # write ZIP file to disk
    zip_file_path = "{0}{1}{2}.zip".format(settings['filepath'], os.sep, settings['locpid'])
    f = open(zip_file_path, "wb")  # use `wb` mode
    f.write(zip_stream.getvalue())
    f.close()

    pg_cur.close()
    pg_conn.close()

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
