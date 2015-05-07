# parallel-pgrouting

## Description

These PostGIS scripts setup parallel processing using pgRouting with NSW Travel Zone data.

Basic testing on my commodity home PC shows a 3-4 fold performance improvement going parallel on 6 CPUs versus 1 (I have a slow HDD). A 32 CPU machine with a good hard drive should greatly improve performance.

## Usage

Um, I'll get round to explaining it all in due course...

## Network Data

To load some test data, have a look at Anita Graser's good intro to loading OpenStreetMap data into pgRouting:

http://anitagraser.com/2011/12/15/an-osm2po-quickstart/

## Notes

This is reasonably advanced use of PostGIS with dblink, use with caution and not on a production server.

One thing - don't apply more than 75% of your CPUs, things might freeze up...

Also, if you want pgRouting to really sing - you should be applying bounding boxes on the network data:

e.g. http://gis.stackexchange.com/questions/144115/speeding-up-pgr-dijkstra-using-bounding-box-in-postgis2-0

## Acknowledgements

Parallel processing code was derived from Mike Gleeson's post:

http://geeohspatial.blogspot.com.au/2013/12/a-simple-function-for-parallel-queries_18.html

## License

This work is licensed under the Apache License, Version 2: https://www.apache.org/licenses/LICENSE-2.0
