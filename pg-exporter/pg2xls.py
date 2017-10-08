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
import pandas  # module needs to be installed (IMPORTANT: need to install 'xlrd' module for Pandas to read .xlsx files)
import psycopg2  # module needs to be installed
import psycopg2.extras
import utils

from datetime import datetime


def main():
    full_start_time = datetime.now()

    # set command line arguments
    args = arguments.set_arguments()

    # get settings from arguments
    settings = arguments.get_settings(args)

    if settings is None:
        logger.fatal("Invalid Census Year\nACTION: Set value to 2011 or 2016")
        return False

    # connect to Postgres
    try:
        pg_conn = psycopg2.connect(settings['pg_connect_string'])
    except psycopg2.Error:
        logger.fatal("Unable to connect to database\nACTION: Check your Postgres parameters and/or database security")
        return False

    pg_conn.autocommit = True
    pg_cur = pg_conn.cursor(cursor_factory=psycopg2.extras.DictCursor)


def copy_table(source_target):
    """PURPOSE: copy DATA between postgres tables
    * target table must exist"""

    StartTime = datetime.datetime.now()

    # connections
    input_con, input_cur = PG_Connect(source_target['connection_source'])
    output_con, output_cur = PG_Connect(source_target['connection_target'])

    m.logger.info("copying {source} to {target}".format(**source_target))

    try:
        # Get data from input DB
        sql = "SELECT * FROM {source}".format(**source_target)
        export_sql = "COPY ({0}) TO STDOUT".format(sql, )

        input_rows = cStringIO.StringIO()
        input_cur.copy_expert(export_sql, input_rows)
        input_rows.seek(0)

        m.logger.debug("{source} table to copy loaded into memory".format(
            **source_target))  # excessive reporting > only in DEBUG mode

        # truncate destination table - always full replacement, never CRUD
        try:  # depends on the db, it is possible there are no active_locks
            output_cur.execute("WITH sub AS (SELECT pid FROM active_locks WHERE relname = '{}') "
                               "SELECT pg_terminate_backend(pid) FROM sub"
                               .format(source_target['target'].split('.')[1]))
            m.logger.debug('locks killed')
        except:
            pass
        output_cur.execute("TRUNCATE TABLE {target}".format(**source_target))
        m.logger.debug('truncated')
        output_cur.copy_expert("COPY {target} FROM STDOUT".format(**source_target), input_rows)
        m.logger.debug('copied')
        output_cur.execute("VACUUM ANALYZE {target}".format(**source_target))
        m.logger.debug('vacuumed')
        # close connection
        input_con.close();
        input_cur.close()
        output_con.close();
        output_cur.close()

    except:
        # m.logger.fatal("unable to copy {source} to {target}".format(**source_target))
        m.logger.exception("unable to copy {source} to {target}".format(**source_target))
        return False

    duration = datetime.datetime.now() - StartTime
    hours, minutes, seconds = duration.seconds / (60 * 60), duration.seconds / 60, duration.seconds % (60)
    source_target.update({'time': ':'.join([str(i) for i in [hours, minutes, seconds]])})
    m.logger.info("{source} copied in {time}".format(**source_target))
    return True


def is_error_relevant(msg):
    """skipping not important messages from pg_dump / psql"""
    k = 0
    for l in msg.splitlines():
        if l.find('ERROR') != -1:
            if l.find('role') != -1 and l.find('does not exist') != -1:
                pass
            elif l.find('relation') != -1 and l.find('already exists') != -1:
                pass
            else:
                k += 1
    return k != 0  # True with errors


def tables_in_schema(source_target, schema_table):
    """returns [schema.table, ...] which exist in source db, using % notation for tables"""
    schema, table = schema_table.split('.')
    input_con, input_cur = PG_Connect(source_target['connection_source'])

    sql_ = """with sub as (
            with all_tables as (
                SELECT * FROM INFORMATION_SCHEMA.tables
                where table_name not like 'pg_%' and table_schema not in ('information_schema', 'topology', 'tiger', 'tiger_data') order by table_name
                ), 
              all_mv as (
                SELECT oid::regclass::text
                FROM   pg_class
                WHERE  relkind = 'm'
                ) 
            select  table_schema :: text , replace (lower(table_type), 'base ','') as type,  table_name ::text   from all_tables 
            union 
            select split_part(oid, '.',1) as tabale_schema, 'mv' :: text as type, split_part(oid, '.',2) as table from all_mv 
            ) 
            select * from sub where type <> 'foreign table' 
            and table_schema = '{}' and table_name like '{}'
            order by table_schema, type, table_name""".format(schema, table)

    input_cur.execute(sql_)
    tabs = input_cur.fetchall()

    input_cur.close()
    input_con.close()

    return [i[0] + '.' + i[2] for i in tabs]


def create_table_structure(source_target):
    """building table structure, indexes , sequences etc.
    to trigger: use parameter in INI file
        DROP_CREATE := TRY_TO_CREATE_TABLE|YES,DROP_TABLE_IF_EXISTS|YES_NO
    """
    global message
    try:
        tmp_file = os.path.join(tempfile.gettempdir(), 'new_tab.sql')
        remove_if_exists(tmp_file)

        params_dict = {'FROM_' + k: v for k, v in source_target['connection_source'].items()}
        params_dict.update({'TO_' + k: v for k, v in source_target['connection_target'].items()})
        params_dict.update({'FROM_TABLE': source_target['source']})
        params_dict.update({'TO_TABLE': source_target['target']})
        params_dict.update({'TMP_FILE': tmp_file})
        source_schema, source_table = source_target['source'].split('.')
        target_schema, target_table = source_target['target'].split('.')

        m.logger.info('creating table {}.{}'.format(target_schema, target_table))

        if m.p.DROP_CREATE['DROP_TABLE_IF_EXISTS']:
            params_dict.update({'-C': '-c --if-exists '})
        else:
            params_dict.update({'-C': ''})

        syntax1 = r'pg_dump -h {FROM_HOST} -p {FROM_PORT} -U {FROM_USER} -O -s {-C}-t {FROM_TABLE} -d {FROM_DB} -f {TMP_FILE}'.format(
            **params_dict)
        syntax2 = r'psql -h {TO_HOST} -p {TO_PORT} -U {TO_USER} -d {TO_DB} --file={TMP_FILE}'.format(**params_dict)

        m.logger.debug(syntax1)

        si = subprocess.STARTUPINFO()  # hiding the CMD window
        si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        message = subprocess.Popen(syntax1.split(' '), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   startupinfo=si).communicate()
        if is_error_relevant(message[0]): m.logger.warn('CHECK message from CMD:\n' + str(message[0]))

        # parsing schema / table names in target DB
        print(open(tmp_file, 'r').read().replace(source_schema, target_schema).replace(source_table, target_table),
              file=open(tmp_file, 'w'))

        m.logger.debug(syntax2)
        message = subprocess.Popen(syntax2.split(' '), stdout=subprocess.PIPE, stderr=subprocess.STDOUT).communicate()

        if is_error_relevant(message[0]):
            m.logger.warn('CHECK message from CMD:\n' + str(message[0]))
        remove_if_exists(tmp_file)
    except:
        m.logger.exception('can\'t create table {target} on the target DB'.format(**source_target))


def parser_parameters(source_target):
    params_dict = {'FROM_' + k: v for k, v in source_target['connection_source'].items()}
    params_dict.update({'TO_' + k: v for k, v in source_target['connection_target'].items()})
    params_dict.update({'FROM_TABLE': source_target['source']})
    params_dict.update({'TO_TABLE': source_target['target']})
    source_schema, source_table = source_target['source'].split('.')
    target_schema, target_table = source_target['target'].split('.')
    params_dict.update({'FROM_SCHEMA': source_schema})
    params_dict.update({'FROM_TABLE': source_table})
    params_dict.update({'TO_SCHEMA': target_schema})
    params_dict.update({'TO_TABLE': target_table})
    params_dict.update({'ID': RandomStamp()})
    params_dict.update({'source': source_target['source']})
    params_dict.update({'target': source_target['target']})

    return params_dict


def create_table_structure_using_fdw(source_target):
    """used to create table structure based on view / mat. view"""

    params_dict = parser_parameters(source_target)

    # !!!!!!!! need to handle IF EXISTS
    SQL = """DROP SERVER IF EXISTS fdw_postgis_{ID} CASCADE;
            CREATE SERVER fdw_postgis_{ID} FOREIGN DATA WRAPPER postgres_fdw 
            OPTIONS (host '{FROM_HOST}', port '{FROM_PORT}', dbname '{FROM_DB}');
            CREATE USER MAPPING FOR postgres SERVER fdw_postgis_{ID} OPTIONS (user '{FROM_USER}', password '{FROM_PASS}');
            DROP SCHEMA IF EXISTS fdw_postgis_{ID} CASCADE;
            CREATE SCHEMA fdw_postgis_{ID};
            IMPORT FOREIGN SCHEMA {FROM_SCHEMA}  FROM SERVER fdw_postgis_{ID} INTO fdw_postgis_{ID};
            DROP TABLE IF EXISTS {TO_SCHEMA}.{TO_TABLE};
            CREATE TABLE {TO_SCHEMA}.{TO_TABLE} AS SELECT * from fdw_postgis_{ID}.{FROM_TABLE} LIMIT 0; 
            DROP SCHEMA IF EXISTS fdw_postgis_{ID} CASCADE;
            DROP SERVER IF EXISTS fdw_postgis_{ID} CASCADE;""".format(**params_dict)

    m.logger.info('creating table structure using FDW')
    m.logger.debug('executing \n' + SQL)
    output_con, output_cur = PG_Connect(source_target['connection_target'])
    output_cur.execute(SQL)
    output_con.close();
    output_cur.close()
    return True


def copy_using_fdw(source_target):
    """run copy_using_fdw on the target db"""

    params_dict = parser_parameters(source_target)
    sql = "SELECT copy_using_fdw( connect := '{FROM_USER}:{FROM_PASS}@{FROM_HOST}:{FROM_PORT}/{FROM_DB}', " \
          "source :='{source}',  target :='{target}')".format(**params_dict)

    output_con, output_cur = PG_Connect(source_target['connection_target'])

    m.logger.debug(sql)
    output_cur.execute(sql)

    output_cur.close()
    output_con.close()


@timing_one_func_print
def Copy_One(task):
    """process 1 table: craete (if needed) and copy data"""
    if m.p.DROP_CREATE['TRY_TO_CREATE_TABLE']:
        if m.p.DROP_CREATE['FLAVOUR'] == 'PG_DUMP':
            create_table_structure(task)
        elif m.p.DROP_CREATE['FLAVOUR'] == 'FDW_PYTHON':
            create_table_structure_using_fdw(task)
        elif m.p.DROP_CREATE['FLAVOUR'] == 'FDW_POSTGRES':
            result = copy_using_fdw(task)
            return result  # here need to break

    if not copy_table(task):
        m.logger.fatal('something bad happened! we all gonna die!')


if __name__ == '__main__':

    ps, logger, hb, p = Interface_Suite(suit=['ps', 'lg', 'hb', 'p'], log_file=None)
    tasks = [p.__dict__[k] for k, v in sorted(p.__dict__.items()) if k.startswith('TASK')]

    print(tasks)

    for task in tasks:
        try:
            task['connection_source'] = getattr(ps, task[
                'connection_source'])  # replacing pointer to the connection with connection details
            task['connection_target'] = getattr(ps, task['connection_target'])

            if task['source'].find('%') == -1:
                Copy_One(task)

            else:  # multiple tables
                tables_to_copy = tables_in_schema(task, task['source'])
                logger.info(
                    'table pattern: {}. \nfound tables to copy :\n'.format(task['source']) + '\n'.join(tables_to_copy))
                for tab in tables_to_copy:
                    t1 = copy.copy(task)
                    t1['source'] = tab
                    t1['target'] = t1['target'].split('.')[0] + '.' + tab.split('.')[1]  # target schema + table name
                    Copy_One(t1)
        except Exception as e:
            logger.exception(e.message)



