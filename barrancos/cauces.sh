#!/bin/bash
# Generates auxiliary files for
# https://wiki.openstreetmap.org/wiki/Tenerife_streams_import

# Download and convert
if [ ! -f III-1-2-Anejo4-InventarioCauces.pdf ]; then
	wget http://www.planhidrologicodetenerife.org/pub/descargas/2015/III-DocumentoGestionGobernanza/III-1-Normativa/III-1-2-Anejos/III-1-2-Anejo4-InventarioCauces.pdf
fi
if [ ! -f cauces.txt ]; then
   pdftotext -layout III-1-2-Anejo4-InventarioCauces.pdf cauces.txt
fi 

# Generates csv list of streams
echo -e "ref:pht\tname\talt_name" > cauces.csv
sed -n 701,10173p cauces.txt |    # Cleans not necesary text
egrep -v "INVENTARIO|Página|Catalogado|Topónimo|^$" |
sed "s/, */; /g" | # Alónimos
sed ':a;N;$!ba;s/\n \{31,\}/; /g' |   # Corrects line wraps
sed "s/^ \{15\}//" |     # Delete excluded fields
sed -e "s/\b[0-9]\{1,2\} \+1[0-9A-Za-z]\+//" -e 's/\b[Cc]\b/ /' |
sed -e "s/^ *\([0-9]\{1,4\}\) */\1\t/" -e "s/   */\t/" >> cauces.csv

# Writes location maps
cat > prj << EOL
PROJCS["WGS 84 / UTM zone 28N",
    GEOGCS["WGS 84",
        DATUM["WGS_1984",
            SPHEROID["WGS 84",6378137,298.257223563,
                AUTHORITY["EPSG","7030"]],
            AUTHORITY["EPSG","6326"]],
        PRIMEM["Greenwich",0,
            AUTHORITY["EPSG","8901"]],
        UNIT["degree",0.01745329251994328,
            AUTHORITY["EPSG","9122"]],
        AUTHORITY["EPSG","4326"]],
    UNIT["metre",1,
        AUTHORITY["EPSG","9001"]],
    PROJECTION["Transverse_Mercator"],
    PARAMETER["latitude_of_origin",0],
    PARAMETER["central_meridian",-15],
    PARAMETER["scale_factor",0.9996],
    PARAMETER["false_easting",500000],
    PARAMETER["false_northing",0],
    AUTHORITY["EPSG","32628"],
    AXIS["Easting",EAST],
    AXIS["Northing",NORTH]]
EOL

mkdir -p maps

for i in {01..49}; do
	echo "Writing cauces"$i".tif"
    convert -depth 8 -compress lzw -density 150 -crop 1563x1080+28+75 III-1-2-Anejo4-InventarioCauces.pdf[$(expr 267 + $i)] "maps/cauces"$i".tif"
	cp prj "maps/cauces"$i".prj"    
done
while read -r i x y; do
	cat > "maps/cauces"$i".tifw" << EOL
5.995203837
0
0
-5.995203837
$x
$y
EOL
done < maps.txt
rm prj
