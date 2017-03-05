#!/bin/bash
# Generates auxiliary files for
# https://wiki.openstreetmap.org/wiki/Import_of_Tenerife's_hydraulic_infrastructures

# Download and convert
if [ ! -f II-3-PlanosOrd-5-ListadoInfra.pdf ]; then
	wget http://www.planhidrologicodetenerife.org/pub/descargas/2015/II-DocumentoOrdenacion/II-3-Planos/II-3-PlanosOrd-5-ListadoInfra.pdf
fi
if [ ! -f infraestructuras.txt ]; then
   pdftotext -layout II-3-PlanosOrd-5-ListadoInfra.pdf infraestructuras.txt
fi 

# Cleans not necesary text
tail -n +11 infraestructuras.txt | 
sed -e 's/^ *Total\xC2\xA0:.*$//' -e 's/^ *(1).*$//' -e "s/^ *ID .*$//" | 
sed -e "s/^ *X .*$//" -e "s/.*CATÁLOGO.*$//" -e "s/^ *Página.*//" | 
egrep -v "^$" > temp.txt

csplit -s -z -b '%03d' temp.txt /Función/ {*} # Split in pages
printf "%s\t%s\t%s\t%s\t%s\n" "LON" "LAT" "TIPO" "name" "alt_name" > infraestructuras.csv
for f in xx???; do
	# Get tipe of infraestructure
	funcion=$(head -n 1 $f | sed 's/.*: *//' | cut -c-5)
	tipo=$(sed -n 2p $f | sed 's/.*: *//')
	case $tipo in
	CENTRAL*)
		tipogen="Central hidroeléctrica";;
	*BOMBEO*|EBAR)
		tipogen="Estación de bombeo";;
	MANANTIAL*)
		tipogen="Fuente";;
	*METEO*)
		tipogen="Estación meteorológica";;
	PRESA|BALSA*|DEP*|GALERÍA*|POZO*|TOMADERO|SONDEO*)
		tipogen="$(echo "$tipo" | sed -e 's/\( \|\xC2\xA0\).*//' -e 's/.*/\L\u&/g')";;
	EDAM|EDAS|ERA|EDAR|ETAR)
		tipogen="$(echo "$tipo" | sed 's/\( \|\xC2\xA0\).*//')";;
	*)
		tipogen="";;
	esac

	# Corrects line wraps for long fields
	tail -n +3 $f |
	egrep -v "^ {100,}" |
	sed "s/ \+\([EP][XRL]\) /@\1/" |
	sed ':a;N;$!ba;s/\n \{30,\}/; /g' |
	egrep "@EX +3[0-9]{2}\.[0-9]{3} +3\.[0-9]{3}\.[0-9]{3}" > page   # Excluded records
	#grep -v "SIN.DENOMINACIÓN" > page # Excluye sin nombres
	cut -d @ -f1,3 page | cut -c32- | sed 's/@//g' |  # Extracts names
	sed -e 's/\xC2\xA0\+/ /g' -e "s/\xe2\x80\x90/-/g" -e "s/^ \+//" |  # no-break spaces 
	sed 's/"/\\"/g' | # Escape quotes
	sed 's/[^ ^(^\.\-]\+/\L\u&/g' |   # Title case
	sed -e "s/\b\(Del\?\|Las\?\|El\|Los\|En\)\b/\L\1/g" |  # Articles
	sed -e "s/- el/- El/g" -e "s/- los/- Los/g" | 
	sed -e "s/\bde el\b/de El/g" -e "s/\bla Orotava\b/La Orotava/g" |
	sed -e "s/ [AYOU] /\L&/g" -e "s/\"\w/\U&/g" | 	# Conjunctions, character in quotes
	sed -e "s/\b[IiVvXx]\+\b/\U&/g" -e "s/\([IVX]\) \([IVX]\)/\1\2/g" | # Roman
	sed -e "s/ *)/)/g" -e "s/ *( */ (/g" | # Parenthesis separation
	sed "s/(\([0-9]\+\|[IVX]\+\))/\1/g" | # Numbers in parentheses
	sed "s/\b\(\w\+\) \1\b/\1/g" | # Duplicates
	# Abbreviations
	sed "s/Mt\?ña\.\? \?\b/Montaña /g
		s/Hnos\.\? \?\b/Hermanos /g
		s/Vda\.\? \?\b/Viuda /g
		s/Bco\.\? \?\b/Barranco /g
		s/Urb\w*\.\? \?\b\b/Urbanización /g
		s/S\. L\./S.L./g
		s/S\. \?\(\w\{3,\}\)\b/San \1/g
		s/Cno\.\? \?\b/Camino /g
		s/Santa C\.\? \?Tfe\.\? \?\b/Santa Cruz de Tenerife /g
		s/S\.J\. Llanos/San José de Los Llanos/g
		s/Coop\.\? \?\b/Cooperativa /g
		s/Vigil\.\? \?\b/Vigilancia /g
		s/Ntra\.\? \?\b/Nuestra /g
		s/Sra\.\? \?\b/Señora /g
		s/Avda\.\? \?\b/Avenida /g
		s/Pto\.\? \?\b/Puerto /g
		s/Hrdos\.\? \?\b/Herederos /g
		s/Aerop\.\? \?\b/Aeropuerto /g
		s/[A-Z]*[0-9]\+[_a-z]\+/\U&/g
		s/\b\(\w\)\.\(\w\)\.\(\w\)\.\(\w\)\b/\1\2\3\4/g
		s/\(Pirs\|Eda[mrs]\|Ptrsu\|Itge\|Eba\|Eb\|Tf\)\b/\U\1/g" |
	# Ortography
	sed "s/\b\(\w\{3,\}\)an\b/\1án/g
		s/Estebán/Esteban/g
		s/Kaufmán/Kaufman/g
		s/\b\(\w\{2,\}\)den\b/\1dén/g
		s/\b\(\w\{3,\}\)in\b/\1ín/g
		s/\b\(\w\{3,\}\)on\b/\1ón/g
		s/Nelsón/Nelson/g
		s/Sheratón/Sheraton/g
		s/\(T\|R\|Ch\|Fr\)io\b/\1ío/g
		s/\b\(Gu\|Mar\|Sof\|Garc\|Beg\|Galer\)ia\b/\1ía/g
		s/\bAngel/Ángel/g
		s/\b\([^A^Á^ ]\w*\)a\([^a^e^i^o^u^á^é^í^ó^ú]*u*\)ez\b/\1á\2ez/g
		s/e\([^a^e^i^o^u^á^é^í^ó^ú]\+\)ez\b/é\1ez/g
		s/i\([^a^e^i^o^u^á^é^í^ó^ú]\+\)ez\b/í\1ez/g
		s/o\([^a^e^i^o^u^á^é^í^ó^ú]\+\)ez\b/ó\1ez/g
		s/u\([^a^e^i^o^u^á^é^í^ó^ú]\+\)ez\b/ú\1ez/g
		s/Senor\(a\?\)\b/Señor\1/g
		s/\bdona\b/doña/g
		s/Madron/Madroñ/g
		s/Vi[nñ]atigo/Viñátigo/g
		s/Monica\b/Mónica/g
		s/Guimar\b/Güímar/g
		s/Dieciseis\b/Dieciséis/g
		s/Doniz\b/Dóniz/g
		s/Tagara\b/Tágara/g
		s/Niagara\b/Niágara/g
		s/Alferez\b/Alférez/g
		s/Alvarez\b/Álvarez/g
		s/\(Bujam\|Mazap\|Fa[nñ]ab\|Bartolom\|Jos\|Caf\|Garo\)e/\1é/g
		s/\([Bb]l\|Nicol\)as/\1ás/g
		s/\(Andr\|Cordob\|Genov\|Garc\)es/\1és/g
		s/\(Sol\|[Pp]a\)is/\1ís/g
		s/\(R[au]\)iz/\1íz/g
		s/Organos/Órganos/g
		s/Ursula/Úrsula/g
		s/Baldios/Baldíos/g
		s/Concepión/Concepción/g
		s/Coneción/Conección/g
		s/Rocio/Rocío/g
		s/Tunel/Túnel/g
		s/Teleferico/Teleférico/g
		s/Hesperides/Hespérides/g
		s/Republica/República/g
		s/Jeronimo/Jerónimo/g
		s/Jaime/Jáime/g
		s/Núcleotagoro/Núcleo Tagoro/g
		s/-la Perdoma//g
		s/EDAR-la/EDAR La/g" |
	# Exceptions for articles in parentheses
	sed "s/Pajaros (los)/los Pájaros/g
		s/Ratones (los)/los Ratones/g
		s/Eras (las)/las Eras/g
		s/Peñón (el)/el Peñón/g
		s/Mollero (el)/el Mollero/g
		s/Flores (las)/las Flores/g" |
	# Exceptions for alternative names
	sed "s/(\(de Gordejuela\))/\[\1\]/g
		s/(Boca \(Norte\|Sur\|Este\|Oeste\))/\[\1\]/g
		s/(\(Baj[ao]\))/\[\1\]/g
		s/(\(Alt[ao]\))/\[\1\]/g
		s/J\.O\.P (\(.*\))/J.O.P \[\1\]/g
		s/(\(Nuev[ao]\))/\[\1\]/g
		s/^\(.*\) (\(Colegio\|Regulador\))/\2 \1/g
		s/\(.*\) (\(Auxiliar\))/\2 \1/g
		s/ (\(Cercado.*\|Estación.*Aires\|Montaña Pacho\|Pluviales\))//g
		s/ (\(Arenas Negras\))/ \1/g" |
	# Split alternative names
	sed "s/ (\([^)]\{4,\}\))/;\1/g
		s/\[/(/g
		s/\]/)/g
		s/,/;/g
		s/ [OUou] /;/g" > nombres

	# Place articles and prefix at the beginning of the name
	prefix=""
	if [ "$tipogen" != "" ]; then
		prefix="
			s/^\(.\+\)/$tipogen \u\1/
			s/$tipogen $tipogen/$tipogen/gI
            s/  / /g
			s/ \(De\|Para\) /\L&/g
			s/Galería \(El\|Las\?\|Los\)\b/Galería \L\1/
			s/\bbombeo Pretratamiento\b/pretratamiento/g"
	fi # Avoid duplicated prefixs
	if [ "$tipogen" = "Pozo" ] || [ "$tipogen" = "Fuente" ]; then
		sed -i "s/^\([^(]\+;.\+\) *(\(el\|los\|las\?\));$/\2 \1/" nombres
	fi 
	while read line; do  # Treat each alternate name separately
		echo $line | tr ";" "\n" | 
		sed "s/\(.*\) \+(\(el\|los\|las\?\))/\2 \1/g" |
		sed "s/^.*Sin Denom.*$//" | 
		sed "$prefix" |
		paste -s -d ";"
	done < nombres | sed 's/$/;/' > temp 
	cut -f1 -d \; temp > name
	cut -f2- -d \; temp | sed -e 's/ *;$\| \+$//' -e 's/;/; /g' > altname
 
	# Coordinates
	sed "s/^.*@EX *//" page | cut -c-20 | sed 's/\.//g' |
	gdaltransform -s_srs EPSG:32628 -t_srs EPSG:4326 | 
	cut -f1,2 -d " " | sed "s/ /\t/" > latlon
	# Generates csv
	for i in $(seq $(wc -l < nombres)); do
		echo "$funcion-$tipo"  # Repite tipos en cada fila
	done | paste latlon - name altname  # Une columnas
	rm -f nombres name altname latlon page temp $f temp.txt
done >> infraestructuras.csv

# Converts to osm
count=1
echo "<?xml version='1.0' encoding='UTF-8'?>" > infraestructuras.osm
echo "<osm version='0.6' upload='false' generator='script'>" >> infraestructuras.osm
egrep -v "\bTIPO\b|MEZCLA|PUNTO|MANANTIAL|INFOR\-|VERTI\-|\-TOMA|ORDI|POZO.*MAR" infraestructuras.csv |

while IFS=$'\t' read -r lon lat tipo name altname
do 
	echo "<node id='-$count' visible='true' lat='$lat' lon='$lon'>"
	(( count++ ))
	if [ "$name" != "" ]; then
	    echo "<tag k='name' v='$name' />"
	fi
	if [ "$altname" != "" ]; then
	    echo "<tag k='alt_name' v='$altname' />"
	fi
	case $tipo in
	*-GALERÍA*)
	    echo "<tag k='man_made' v='adit' />"
	    echo "<tag k='resource' v='water' />";;
	*-POZO*)
		echo "<tag k='man_made' v='water_well' />";;
	*-EDAM*|*-EDAS*)
		echo "<tag k='landuse' v='industrial' />"
		echo "<tag k='man_made' v='water_works' />";;
	*-ERA*|*-EDAR*|*-ETAR*|*PREVIO*)
		echo "<tag k='landuse' v='industrial' />"
		echo "<tag k='man_made' v='wastewater_plant' />";;
	*BOMBEO*)
		echo "<tag k='building' v='yes' />"
		echo "<tag k='man_made' v='pumping_station' />"
		echo "<tag k='pumping_station' v='water' />";;
	*-EBAR*)
		echo "<tag k='building' v='yes' />"
		echo "<tag k='man_made' v='pumping_station' />"
		echo "<tag k='pumping_station' v='wastewater' />";;
	*-CENTRAL*)
		echo "<tag k='building' v='yes' />"
		echo "<tag k='power' v='generator' />";;
	*-DEP*)
		echo "<tag k='building' v='yes' />"
		echo "<tag k='man_made' v='reservoir_covered' />"
		echo "<tag k='content' v='water' />";;
	*-BALSA*|*-PRESA*)
		echo "<tag k='landuse' v='reservoir' />"
		echo "<tag k='reservoir_type' v='water_storage' />";;
	esac
	echo "</node>"
done >> infraestructuras.osm
echo "</osm>" >> infraestructuras.osm

