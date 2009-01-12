#!/usr/bin/python

import glob, optparse, os, tempfile, re, codecs

string_expr = re.compile(r'(?P<en>".*") = (?P<trans>".*")')

def getLanguageList(source_dir):
    lprojs = glob.glob(os.path.join(source_dir, '*.lproj'))
    lprojs = [os.path.splitext(os.path.basename(item)) for item in lprojs]
    return [base for base, ext in lprojs]

def makeOutputDirectories(languages, dest_dir):
    for language in languages:
	path = os.path.join(dest_dir, language)
	if not os.path.isdir(path):
	    os.makedirs(path)

def extractXibStrings(languages, proj_dir, dest_dir):
    print "Extracting XIB Strings:"
    for language in languages:
	print '  %s:' % language
	lproj = os.path.join(proj_dir, '%s.lproj' % language)
	lang_dir = os.path.join(dest_dir, language)
	xibs = glob.glob(os.path.join(lproj, '*.xib'))
	for xib in xibs:
	    base, ext = os.path.splitext(os.path.basename(xib))
	    string_name = '%s.strings' % base
	    print '    - %s' % string_name
	    output = os.path.join(lang_dir, string_name)
	    cmd = 'ibtool --generate-strings-file %s %s' % (output, xib)
	    os.system(cmd)

def extractLocalizableStrings(source_dir, dest_dir):
    dest_path = os.path.join(dest_dir, 'en')
    os.system('genstrings -o %s %s/*.m' % (dest_path, source_dir))
    path = os.path.join(dest_path, 'Localizable.strings')
    f = codecs.open(path, 'r', 'utf-16')
    strings = f.readlines()
    f.close()
    return strings

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

def mergeLocalizableStrings(en_strings, languages, proj_dir, dest_dir):
    languages = list(languages)
    languages.remove('en')
    
    print "Creating Merged Localizable.strings files:"

    for language in languages:
	print '  - %s' % language
	lproj = os.path.join(proj_dir, '%s.lproj' % language)
	lang_dir = os.path.join(dest_dir, language)
	translations = extractTranslations(os.path.join(lproj, 'Localizable.strings'))
	
	merged = mergeStrings(en_strings, translations)
	
	merged_file = codecs.open(os.path.join(lang_dir, 'Localizable.strings'), 'w+', 'utf-16')
	merged_file.writelines(merged)
	merged_file.close()

def main():
    parser = optparse.OptionParser()
    parser.add_option("-p", "--project", dest="project",
		      help="Project directory", metavar="PROJECT_DIR")
    parser.add_option("-o", "--output", dest="output",
		      help="Output directory for extracted translations")
    parser.add_option("-s", "--source", dest="source",
		      help="Source directory for extracting strings")

    (options, args) = parser.parse_args()
    
    languages = getLanguageList(options.project)
    
    makeOutputDirectories(languages, options.output)
    
    extractXibStrings(languages, options.project, options.output)
    
    strings = extractLocalizableStrings(options.source, options.output)
        
    mergeLocalizableStrings(strings, languages, options.project, options.output)    

if __name__ == '__main__':
	main()

