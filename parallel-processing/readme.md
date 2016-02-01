# parallel-processing


NOTE: THIS DOCUMENTATION IS INCOMPLETE


## Description

A Postgres 9.3 function to enable simple parallel processing.

Basic testing on my commodity home PC shows a 3-4 fold performance improvement going parallel on 6 CPUs versus 1.

A mid-level Windows 32 CPU server with an SSD hard drive has seen improvements of up to 50x (test case was 13 million points intersecting ~20k polygons)

## How does it work 

Using an integer ID (mandatory!) on the table to parallise the query on - the script converts a single insert query into several queries that process a range of IDs.  e.g it converts this:

INSERT INTO theOutputTable
SELECT pnts.gid, polys.gid FROM pointsTable AS pnts, polygonTable AS polys WHERE ST_Contains(polys.geom, pnts.geom)

..into this, run in parallel:

INSERT INTO theOutputTable
SELECT pnts.gid, polys.gid FROM pointsTable AS pnts, (SELECT * FROM polygonTable WHERE gid < 1000) AS polys
  WHERE ST_Contains(polys.geom, pnts.geom)

INSERT INTO theOutputTable
SELECT pnts.gid, polys.gid FROM pointsTable AS pnts, (SELECT * FROM polygonTable WHERE gid >= 1000 AND gid < 2000) AS polys
  WHERE ST_Contains(polys.geom, pnts.geom)

INSERT INTO theOutputTable
SELECT pnts.gid, polys.gid FROM pointsTable AS pnts, (SELECT * FROM polygonTable WHERE gid >= 2000 AND gid < 3000) AS polys
  WHERE ST_Contains(polys.geom, pnts.geom)


## Usage

### Environment

Testing was done using Postgres 9.4.2 & PostGIS 2.1.7 on Windows 8.1 Pro

Hardware is a commodity Dell desktop with 16Gb RAM and Intel i7 CPU with 4 physical cores hyperthreaded to make 8 'CPUs'.  The hard drive is a 7200 RPM SATA drive which can barely handle Microsoft Search indexing

### Process

1 - Install Postgres and PostGIS
2 - Add the Postgres bin folder to your system path (e.g. C:\Program Files\PostgreSQL\9.4\bin)
3 - Tune Postgres according to the Boundless guide: http://workshops.boundlessgeo.com/postgis-intro/tuning.html.

  My settings are (noting I'm not a tuning expert):
  
    random_page_cost: 2.0
    seq_page_cost: 1.0
    maintenance_work_mem: 512MB
    shared_buffers: 4GB
    temp_buffers: 1GB
    work_mem: 512MB
    wal_buffers: -1 (-1 = based on shared_buffers)
    checkpoint_segments: 6
    
4 - Restart the Postgres service for the new settings to take effect

2 - Create new database, if you don't have a spare test DB





You'll need to beef up several settings



Postgres 9.4.2

PostGIS 2.1.7




## Limitations

The function only supports insert statements, however as you can potentially get a huge performance boost - refactoring your code to support this is worthwhile.

The function requires you have an sequential integer ID on the table to be broken up into chunks - just add a SERIAL field to your table to make one.


## Notes

If doing a 'point in polygon' query - choose the polygon table to chunk the query to get the max performance improvement.

This is reasonably advanced use of PostGIS with dblink, use with caution and not on a production server.

Also, don't run parallel processing with more than 75% of your CPUs, things might freeze up...

## Acknowledgements

Parallel processing code was derived from Mike Gleeson's post:

http://geeohspatial.blogspot.com.au/2013/12/a-simple-function-for-parallel-queries_18.html

## License

Data is copyright Australian Bureau of Statistics and is licensed CC-BY

This work is licensed under the Apache License, Version 2: https://www.apache.org/licenses/LICENSE-2.0
