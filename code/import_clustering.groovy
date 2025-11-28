/*
Script to import a CSV file with Object.ID and measurements (e.g., cluster)
and map them directly to QuPath objects, using Object.ID only.
*/

import static qupath.lib.gui.scripting.QPEx.*
import qupath.lib.gui.dialogs.Dialogs

def delim = ","
def Aproject = getProject()

// select a folder where each CSV corresponds to one image
def folder = Dialogs.promptForDirectory(null)
folder.listFiles().each { file ->

    // match image in project by name (ignoring extension)
    String imgName = file.name.indexOf('.').with { it != -1 ? file.name[0..<it] : file.name }
    def entry = Aproject.getImageList().find { it.getImageName().startsWith(imgName) }
    if (entry == null){
        println "No entries for image: $imgName"
        return
    }

    // get image hierarchy
    def imageData = entry.readImageData()
    def hierarchy = imageData.getHierarchy()

    // --- recursive function to collect all objects ---
    def getAllObjects
    getAllObjects = { obj ->
        def list = []
        list += obj.getChildObjects()
        obj.getChildObjects().each { child ->
            list += getAllObjects(child)
        }
        return list
    }

    def allObjects = getAllObjects(hierarchy.getRootObject())
    println "Found ${allObjects.size()} objects in hierarchy"

    // map Object.ID -> PathObject
    def objectsByID = allObjects.groupBy { it.getID().toString() }

    // --- read CSV ---
    def lines = new File(file.getAbsolutePath()).readLines()
    def header = lines.pop().split(delim)

    lines.each { line ->
        def cols = line.split(delim)
        def map = [:]
        header.eachWithIndex { h, i -> map[h.replace('"','').trim()] = cols[i].replace('"','').trim() }

        def objID = map["Object.ID"]
        def obj = objectsByID[objID]?.get(0)  // get first object with matching ID

        if (obj != null) {
            map.each { k, v ->
                if (k != "Object.ID") {
                    try {
                        obj.classification = v as String
                    } catch (Exception e) {
                        println(e)
                        println "WARN: Could not set $k=$v for Object.ID $objID"
                    }
                }
            }
        } else {
            println "WARN: Object ID $objID not found"
        }
    }

    entry.saveImageData(imageData)
}
println "Done with all CSV files!"
