import sys
import re
import json

filename = sys.argv[1]
with open(filename + '.tifw', 'r') as file:
    dx = float(file.readline())
    file.readline()
    file.readline()
    dy = float(file.readline())
    ox = float(file.readline())
    oy = float(file.readline())
with open(filename + '.svg', 'r') as file:
    file.readline()
    text = file.readline()
    width = float(re.search('width="([0-9]+)"', text).group(1))
    height = float(re.search('height="([0-9]+)"', text).group(1))
    text = file.readline()
    fc = {
        "type": "FeatureCollection",
        "crs": { "type": "name", "properties": { "name": "urn:ogc:def:crs:EPSG::32628" } },
        "features": []
    }
    for way in re.findall('M[0-9L ]+', text): 
        ls = []
        for point in re.findall('[ML][0-9]+ [0-9]+', way):
            (x, y) = [int(i) for i in point[1:].split(' ')]
            ls.append([round(ox + x * dx, 2), round(oy + y * dy, 2)])
        feat = {
            "type": "Feature",
            "geometry": {
                "type": "LineString",
                "coordinates": ls
            }
        }
        fc['features'].append(feat)
with open(filename + '.geojson', 'w') as file:
    json.dump(fc, file)
