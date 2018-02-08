# -*- coding: utf-8 -*-

import io
import os

from pyexcelerate import Workbook, Style, Font
from datetime import datetime

import __main__ as m  # get the calling script


def run_query(pg_cur, sql):
    """Exports query to the chosen format"""

    start_time = datetime.now()

    # export_sql = "COPY ({0}) TO STDOUT WITH NULL AS '' HEADER CSV".format(sql, )
    # rows = io.StringIO()

    # Run query. Output result into in-memory stream formatted as CSV with the header row (NULLs are set to '')
    try:
        # pg_cur.copy_expert(export_sql, rows)
        pg_cur.execute(sql)

        # get column names & data
        column_names = tuple([desc[0] for desc in pg_cur.description])
        rows = pg_cur.fetchall()
        rows.insert(0, column_names)  # add column_names to top of list

    except Exception as ex:
        m.logger.fatal("\tunable to run query: {}\n{}".format(sql, ex))
        return None

    m.logger.info("\tquery took {}".format(datetime.now() - start_time))
    return rows


def export_to_delimited_file(data, delimiter):
    """ Export in-memory data to a delimited text file. e.g. CSV, TSV, PSV """
    start_time = datetime.now()

    try:
        # TODO: put double apostrophes around strings with commas already in them
        file_input = "\n".join(delimiter.join(map(str, row)) for row in data)
        output = io.StringIO()
        output.write(file_input)

    except Exception as ex:
        m.logger.fatal("\tunable to export to file: {}".format(ex,))
        return None

    m.logger.info("\tfile export took {}".format(datetime.now() - start_time))

    return output


def export_to_xlsx(data, temp_dir):

    start_time = datetime.now()

    # full_file_path = "{0}{1}temp.xlsx".format(file_path, os.sep)
    file_path = "/tmp/temp.xlsx"

    try:
        wb = Workbook()
        ws = wb.new_sheet("Policies", data=data)
        ws.set_row_style(1, Style(font=Font(bold=True)))  # bold the header row

        # save xlsx file and open it as a binary file
        wb.save(file_path)
        xlsx_file = open(file_path, 'rb')

        output = io.BytesIO()
        output.write(xlsx_file.read())

        # close and delete file
        xlsx_file.close()
        os.remove(file_path)

    except Exception as ex:
        m.logger.fatal("\tunable to export to file: {}".format(ex,))
        return None

    m.logger.info("\tfile export took {}".format(datetime.now() - start_time))

    return output
