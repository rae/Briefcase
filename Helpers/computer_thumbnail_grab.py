
from AppKit import *

NSApplication.sharedApplication()

image = NSImage.imageNamed_('NSComputer')
data = image.TIFFRepresentation()
data.writeToFile_atomically_("/tmp/out.tif", False)
