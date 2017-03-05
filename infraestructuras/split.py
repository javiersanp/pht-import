from java.io import File, FileInputStream
from org.openstreetmap.josm.data.osm import DataSet
from org.openstreetmap.josm.gui.layer import OsmDataLayer
from org.openstreetmap.josm.io import OsmReader, OsmExporter
from org.openstreetmap.josm.gui.progress import NullProgressMonitor
from org.openstreetmap.josm.plugins.utilsplugin2.selection import NodeWayUtils

fis = FileInputStream("cuadricula.osm")
cuadricula = OsmReader.parseDataSet(fis, NullProgressMonitor.INSTANCE)
fis = FileInputStream("infraestructuras.osm")
infraestructuras = OsmReader.parseDataSet(fis, NullProgressMonitor.INSTANCE)

for hoja in cuadricula.getWays():
    dentro = NodeWayUtils.selectAllInside([hoja], infraestructuras)
    print "hoja: %s (%d)" % (hoja.get('hoja'), len(dentro))
    task = DataSet()
    for v in dentro:
        infraestructuras.removePrimitive(v)
        task.addPrimitive(v)
    if len(dentro) > 0:
        name = 'task%s.osm' % hoja.get('hoja')
        layer = OsmDataLayer(task, name, File(name))
        OsmExporter().exportData(layer.getAssociatedFile(), layer)

