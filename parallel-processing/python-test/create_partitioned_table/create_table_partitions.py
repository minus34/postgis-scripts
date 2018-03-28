"""
-----------------------------------------------------------------------------------------------------------------------
Name:        create partitions for your table
Purpose:     creates a SQL script for creating a higher performance version of a large table (e.g. GNAF, CADLite)

Author:      Hugh Saalmans (@minus34)

Created:     28/03/2018

-----------------------------------------------------------------------------------------------------------------------
"""

import os


def main():

    # #################################################################################################################
    # Your settings
    # #################################################################################################################

    settings = dict()

    settings["output_sql_file"] = os.path.abspath(__file__).replace(".py", ".sql")

    # scripts for creating and inserting into the table
    settings["create_table_sql_file"] = "create_table.sql"
    settings["insert_into_sql_file"] = "insert_into_table.sql"

    # # start and end dates of data
    # settings["start_date"] = "2017-02-01"
    # settings["end_date"] = "2018-02-02"  # NEEDS TO BE ONE DAY MORE AS THE CODE MOVE THE TIMES FROM UTC TO SYDNEY TIME

    # array of partition range values
    settings["partition_ranges"] = [96.8215, 115.8473, 120.5748, 138.6046, 142.4924, 144.7469, 144.9711, 145.0797,
                                    145.2545, 146.0666, 147.4484, 149.5449, 150.8143, 150.9992, 151.129, 151.2382,
                                    151.6735, 152.8368, 153.0298, 153.1523, 167.9931]

    # table and schema names - MUST BE THE SAME AS IN THE CREATE TABLE AND INSERT INTO SQL FILES
    settings["table_name"] = "address_principals_part"
    settings["schema_name"] = "gnaf_201802"

    # field that will partition the table
    settings["partition_field_name"] = "longitude"

    # array of other fields to be indexed - don't include the geom field or the partition field
    settings["other_indexes"] = ["gnaf_pid"]

    # is the table spatial?
    settings["is_spatial"] = True

    # #################################################################################################################

    # open sql file for writing
    output_sql_file = open(settings["output_sql_file"], "w")

    # open sql files
    create_table_sql = open(settings["create_table_sql_file"], "r").read()
    insert_into_sql = open(settings["insert_into_sql_file"], "r").read()

    # write create table statement to output sql file
    output_sql_file.write(create_table_sql)
    output_sql_file.write("\n")

    # create child tables
    num_partitions = len(settings["partition_ranges"])
    current_child_table_num = 1

    while current_child_table_num < num_partitions:
        table_name = "{}_{}".format(settings["table_name"], current_child_table_num)
        partition_start_value = settings["partition_ranges"][current_child_table_num - 1]
        partition_end_value = settings["partition_ranges"][current_child_table_num]

        sql = "CREATE TABLE {0}.{1} PARTITION OF {0}.{2} FOR VALUES FROM ('{3}') TO ('{4}');\n"\
            .format(settings["schema_name"], table_name, settings["table_name"],
                    partition_start_value, partition_end_value)

        output_sql_file.write(sql)

        current_child_table_num += 1

    output_sql_file.write("\n")

    # the big insert
    output_sql_file.write(insert_into_sql)
    output_sql_file.write("\n")

    # index child tables
    current_child_table_num = 1

    while current_child_table_num < num_partitions:
        table_name = "{}_{}".format(settings["table_name"], current_child_table_num)

        # update stats first
        output_sql_file.write("ANALYZE {}.{};\n".format(settings["schema_name"], table_name))

        # index on partition field
        output_sql_file.write("CREATE INDEX ON {}.{} USING btree ({});\n"
                              .format(settings["schema_name"], table_name, settings["partition_field_name"]))

        # index other fields that need it
        for field in settings["other_indexes"]:
            output_sql_file.write("CREATE INDEX ON {}.{} USING btree ({});\n"
                                  .format(settings["schema_name"], table_name, field))

        # spatial indexing if required
        if settings["is_spatial"]:
            output_sql_file.write("CREATE INDEX {1}_geom_idx ON {0}.{1} USING gist (geom);\n"
                       .format(settings["schema_name"], table_name))
            output_sql_file.write("ALTER TABLE {0}.{1} CLUSTER ON {1}_geom_idx;\n"
                                  .format(settings["schema_name"], table_name))

        output_sql_file.write("\n")

        current_child_table_num += 1

    # update stats of master table (not sure if this does anything)
    output_sql_file.write("ANALYZE {}.{};\n".format(settings["schema_name"], settings["table_name"]))

    output_sql_file.close()


if __name__ == '__main__':
    main()
