"""
-----------------------------------------------------------------------------------------------------------------------
Name:        create a partitioned Postgres 10 table and inserts data into it parallel

Author:      Hugh Saalmans (@minus34)

Created:     28/04/2018

Notes:
    - Currently only supports partitioning on dates or floats

-----------------------------------------------------------------------------------------------------------------------
"""

import datetime
import logging
import multiprocessing
import os
import psycopg2  # need to install psycopg2 package
import re

settings = dict()

# how many parallel processes?
settings['max_concurrent_processes'] = 12

# scripts for creating and inserting into the table
settings["create_table_sql_file"] = "create_table_statement.sql"
settings["insert_sql_file"] = "insert_statement.sql"

# start and end dates of data
settings["start_timestamp"] = "2017-02-01 00:00:00"
settings["end_timestamp"] = "2018-04-02 00:00:00"

# table and schema names - MUST BE THE SAME AS IN THE CREATE TABLE AND INSERT INTO SQL FILES
settings["table_name"] = "destinations"
settings["schema_name"] = "life360_sydney"

# field that will partition the table
settings["partition_field"] = "fix_date"

# array of other fields to be indexed - don't include the geom field or the partition field
settings["other_fields_to_index"] = ["user_gid", "cad_pid", "property_pid"]

# is the table spatial?
settings["create_spatial_index"] = False


def main():
    
    
    # create postgres connect string
    settings['pg_connect_string'] = "dbname={DB} host={HOST} port={PORT} user={USER} password={PASS}\n" \
        .format(**pg_settings)

    # fix for passwords issue
    settings['pg_connect_string'] = settings['pg_connect_string'].replace("$", "#")

    # PREP THE CREATE TABLE STATEMENTS, THE LIST OF FILES TO LOAD AND THE CREATE INDEX STATEMENTS

    create_table_sql_list = list()
    insert_sql_list = list()
    index_table_sql_list = list()

    # create master table statement
    create_table_sql_list.append(open(settings["create_table_sql_file"], "r").read())

    # get the insert statement
    insert_sql = open(settings["insert_sql_file"], "r").read()

    # convert start and end timestamp strings to timestamps
    start_timestamp = datetime.datetime.strptime(settings["start_timestamp"], '%Y-%m-%d %H:%M:%S')
    end_timestamp = datetime.datetime.strptime(settings["end_timestamp"], '%Y-%m-%d %H:%M:%S')

    current_timestamp = start_timestamp

    # for each day - add a child table to partition
    while current_timestamp <= end_timestamp:
        start_date_string = current_timestamp.strftime('%Y-%m-%d')
        end_date_string = (current_timestamp + datetime.timedelta(days=1)).strftime('%Y-%m-%d')

        # child table create statement
        table_name = "{}_{}".format(settings["table_name"], start_date_string.replace("-", "_"))
        partition_start_value = current_timestamp.strftime('%Y-%m-%d %H:%M:%S')
        partition_end_value = (current_timestamp + datetime.timedelta(days=1)).strftime('%Y-%m-%d %H:%M:%S')

        create_table_sql_list.append("CREATE TABLE {0}.{1} PARTITION OF {0}.{2} FOR VALUES FROM ('{3}') TO ('{4}');"
                                     .format(settings["schema_name"], table_name, settings["table_name"],
                                             partition_start_value, partition_end_value))

        # create insert sql statement
        insert_sql_list.append(insert_sql.format(start_date_string, end_date_string))

        # create a list of analyse and create index statements
        temp_index_list = list()

        # child table analyze & create index statements (to be run after data load)
        temp_index_list.append("ANALYZE {}.{};".format(settings["schema_name"], table_name))
        temp_index_list.append("CREATE INDEX ON {}.{} USING btree ({});"
                               .format(settings["schema_name"], table_name, settings["partition_field"]))

        for field in settings["other_fields_to_index"]:
            temp_index_list.append("CREATE INDEX ON {}.{} USING btree ({});"
                                   .format(settings["schema_name"], table_name, field))

        # spatial indexing (if required)
        if settings["create_spatial_index"]:
            temp_index_list.append("CREATE INDEX {1}_geom_idx ON {0}.{1} USING gist (geom);"
                                   .format(settings["schema_name"], table_name))
            temp_index_list.append("ALTER TABLE {0}.{1} CLUSTER ON {1}_geom_idx;"
                                   .format(settings["schema_name"], table_name))

        index_table_sql_list.append("\n".join(temp_index_list))

        current_timestamp += datetime.timedelta(days=1)

    # run the big sql statement
    create_table_sql = "\n".join(create_table_sql_list)

    # RUN EVERYTHING
    start_time = datetime.datetime.now()

    # 1 of 3 - connect to Postgres and create tables
    try:
        pg_conn = psycopg2.connect(settings['pg_connect_string'])
        pg_conn.autocommit = True
        pg_cur = pg_conn.cursor()
    except:
        message = "Unable to connect to database"
        logger.exception(message)
        return False

    pg_cur.execute(create_table_sql)
    logger.info("partitioned table created : {}".format(datetime.datetime.now() - start_time, ))
    start_time = datetime.datetime.now()

    pg_cur.close()
    pg_conn.close()

    # 2 of 3 - parallel process inserts
    multiprocess_list(insert_sql_list)
    logger.info("inserts done : {}".format(datetime.datetime.now() - start_time, ))
    start_time = datetime.datetime.now()

    # 3 of 3 - index table partitions
    multiprocess_list(index_table_sql_list)
    logger.info("indexing done : {}".format(datetime.datetime.now() - start_time, ))


# takes a list of sql queries and runs them using multiprocessing
# - taken from https://github.com/minus34/gnaf-loader
def multiprocess_list(work_list):
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
    start_time = datetime.datetime.now()

    the_sql = args[0]
    the_settings = args[1]

    # get date in SQL string to log process to screen
    try:
        date_string = get_regex_date_string(r'\d{4}-\d{2}-\d{2}', the_sql)
    except:
        try:
            date_string = get_regex_date_string(r'\d{4}_\d{2}_\d{2}', the_sql)
        except:
            date_string = ""

    # print("{} started".format(date_string, ))

    pg_conn = psycopg2.connect(the_settings['pg_connect_string'])
    pg_conn.autocommit = True
    pg_cur = pg_conn.cursor()

    try:
        pg_cur.execute(the_sql)
        result = "SUCCESS"
        print("partition {} done : {}".format(date_string, datetime.datetime.now() - start_time))
    except Exception as ex:
        result = "SQL FAILED! : {} : {}".format(the_sql, ex)
        print("SQL FAILED! : {} : {}".format(the_sql, ex))

    pg_cur.close()
    pg_conn.close()

    return result


def get_regex_date_string(sub_string, the_string):
    # get date in SQL string to log process to screen
    match = re.search(sub_string, the_string)
    return the_string[match.start():match.end()]


if __name__ == '__main__':
    full_start_time = datetime.datetime.now()

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

    task_name = "Create and insert into partitioned table"
    # system_name = "ventures"

    logger.info("Start {}".format(task_name))
    logger.info("")

    # run it
    main()

    time_taken = datetime.datetime.now() - full_start_time
    logger.info("{0} finished : {1}".format(task_name, time_taken))
