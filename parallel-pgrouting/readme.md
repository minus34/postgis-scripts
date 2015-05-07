# parallel-pgrouting

## Description

These PostGIS scripts setup parallel processing using pgRouting with NSW Travel Zone data.

Basic testing on my commodity home PC shows a 3-4 fold performance improvement going parallel on 6 CPUs versus 1 (I have a slow HDD). A 32 CPU machine with a good hard drive should greatly improve performance.

## Usage

Um, I'll get round to explaining it all in due course...

## Notes

This is reasonably advanced use of PostGIS with dblink, use with caution and not on a production server.

One thing - don't apply more than 75% of your CPUs, things might freeze up...

## License

This work is licensed under the Apache License, Version 2: https://www.apache.org/licenses/LICENSE-2.0
