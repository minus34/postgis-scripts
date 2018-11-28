# External Storage Testing

At the <month><year> code sprint - the PostGIS contributors did some testing on the performance of storing the geometry field externally (i.e. uncompressed).

For small datasets - there is a 


<html>
<blockquote class="twitter-tweet" data-cards="hidden" data-lang="en-gb"><p lang="en" dir="ltr">5x Faster Spatial Join with this One Weird Trick <a href="https://t.co/OPifscfErY">https://t.co/OPifscfErY</a> <a href="https://t.co/d2NI1VAd6V">pic.twitter.com/d2NI1VAd6V</a></p>&mdash; PostGIS (@postgis) <a href="https://twitter.com/postgis/status/1045698033734668289?ref_src=twsrc%5Etfw">28 September 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
</html>



## Postgres/PostGIS Settings

Postgres 11


- shared_buffers = 8GB
- temp_buffers = 2GB
- work_mem = 256MB
- maintenance_work_mem = 1GB
- wal_level = minimal
- max_wal_senders = 0

## Data

- PSMA GNAF Address Principals ( rows)
- ABS 2016 Census Meshblocks ( rows)
- Meshblock polygons split where number of coordinates > 512 (using ST_Subdivide)

## Results

### Single query

#### Standard storage

    32 m 50 s 365 ms
    32 m 03 s 945 ms
    32 m 16 s 372 ms
    32 m 08 s 194 ms
    32 m 07 s 89 ms

#### External (uncompressed) storage

    33 m 24 s 633 ms
    32 m 29 s 386 ms
    32 m 26 s 970 ms
    32 m 26 s 238 ms
    32 m 27 s 546 ms


### Parallel processing

#### Standard storage

- 8 processes = 0:14:20.671523
- 20 processes = 0:14:03.023990

#### External (uncompressed) storage

- 8 processes = 0:14:27.275182
- 20 processes = 0:14:24.489754