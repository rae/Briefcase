#!/usr/bin/python

from Foundation import *
import urllib2, re, sys, string

from CoreGraphics import *

url = 'http://developer.apple.com/documentation/Carbon/Conceptual/understanding_utis/utilist/chapter_4_section_1.html'
url_handle = urllib2.urlopen(url)
data = url_handle.read().decode('ascii', 'ignore')

lines = data.split('\n')

expr = re.compile(r'((public|com)(\.[a-z0-9-]+)+)')

uti_list = [item[0] for item in expr.findall(data)]

# Filter duplicates
uti_list = list(set(uti_list))
uti_list.sort()

array = NSArray.arrayWithArray_(uti_list)
array.writeToFile_atomically_(sys.argv[1], False)

