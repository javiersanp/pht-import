import json, math

# 111111 meters - 1 deg lat
# 111111 x cos(28) - 1 deg lon
basex = -16.925958
basey = 28.605455
radio = 0.02545
radiox = 2000.0/111111
radioy = radiox*math.cos(math.radians(28))
ancho = 20
alto = 20

cuadriculas = {
    'type': 'FeatureCollection',
    "crs": { "type": "name", "properties": { "name": "urn:ogc:def:crs:OGC:1.3:CRS84" } },
    'features': []
}
for j in range(alto):
    for i in range(ancho):
        p1x = basex + i * radiox
        p1y = basey - j * radioy
        p2x = p1x + radiox
        p2y = p1y
        p3x = p2x
        p3y = p2y - radioy
        p4x = p1x
        p4y = p3y
        cuadricula = {
            'type': 'feature',
            'properties': {'ref': str(i + alto*j)},
            'geometry': {
                'type': 'LineString',
                'coordinates': [[p1x,p1y], [p2x,p2y], [p3x,p3y], [p4x,p4y], [p1x, p1y]]
            }
        }
        cuadriculas['features'].append(cuadricula)
        print p1x, p1y
with open('cuadricula.geojson', 'w') as outfile:
    json.dump(cuadriculas, outfile)
print cuadriculas
