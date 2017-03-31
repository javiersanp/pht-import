#!/bin/bash
for f in mapa/*.tif; do
    bn=${f%\.tif}
    composite \
    <(convert $f -dither None -colors 64 -fuzz 20% -fill white +opaque 'rgb(0,200,255)' -threshold 80% png:-) \
    <(convert $f -dither None -colors 64 -fuzz 20% -fill white +opaque 'rgb(0,115,76)' -threshold 50% png:- ) \
    -compose Darken temp.tif
    autotrace -centerline -color-count 2 -corner-threshold 170 -output-file "$bn".svg temp.tif
    rm temp.tif
    python vectorize.py "$bn"
    rm "$bn".svg
    ogr2ogr -f "KML" -t_srs WGS84 "$bn".kml "$bn".geojson
    rm "$bn".geojson
done
