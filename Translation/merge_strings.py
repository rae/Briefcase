#!/usr/bin/python

import glob, optparse, os, tempfile, re, codecs, sys

string_expr = re.compile(r'(?P<en>".*") = (?P<trans>".*")')

def extractTranslations(string_file):
    f = codecs.open(string_file, 'r', 'utf-16')
    
    result = {}
    
    for line in f.readlines():
	match = string_expr.match(line)
	if match:
	    result[match.group('en')] = match.group('trans')
	    
    return result
	    
def mergeStrings(en_strings, mapping):
    result = []

    for line in en_strings:
	match = string_expr.match(line)
	if match:
	    en = match.group('en')
	    if en in mapping:
		new_line = '%s = %s\n' % (en, mapping[en])
		result.append(new_line)
		continue
		
	result.append(line)
	
    return result

def main():
    main_file = sys.argv[1]
    extra_file = sys.argv[2]
    outfile = sys.argv[3]
   
    # Existing strings
    f = codecs.open(main_file, 'r', 'utf-16')
    strings = f.readlines()
    f.close()
    
    extras = extractTranslations(extra_file)
    
    merged = mergeStrings(strings, extras)

    merged_file = codecs.open(outfile, 'w+', 'utf-16')
    merged_file.writelines(merged)
    merged_file.close()   
    
   

if __name__ == '__main__':
	main()

