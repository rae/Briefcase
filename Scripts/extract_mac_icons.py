
from AppKit import *
import sys, os

NSApplication.sharedApplication()

dict_file = sys.argv[1]
dest_dir = sys.argv[2]

dict = NSDictionary.dictionaryWithContentsOfFile_(dict_file)

files = set(dict.values())

file_prefix = '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.'

for item in files:
    input_path = file_prefix + item.replace('png', 'icns')
    output_path = os.path.join(dest_dir, item)
    output_small_path = os.path.join(dest_dir, item.replace('.png', '_small.png'))
    
    image = NSImage.alloc().initWithContentsOfFile_(input_path)
        
    representations = image.representations()
    
    for rep in representations:
	if rep.size() == (32, 32):
	    print "writing: " + output_small_path
	    data = rep.representationUsingType_properties_(NSPNGFileType, None)
	    data.writeToFile_atomically_(output_small_path, False)
	elif rep.size() == (128, 128):
	    print "writing: " + output_path
	    data = rep.representationUsingType_properties_(NSPNGFileType, None)
	    data.writeToFile_atomically_(output_path, False)