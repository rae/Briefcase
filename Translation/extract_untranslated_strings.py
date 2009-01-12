#!/usr/bin/python

import glob, optparse, os, tempfile, re, codecs
from collections import defaultdict

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
	    
def extractTranslations(string_file):
    f = codecs.open(string_file, 'r', 'utf-16')
    
    result = []
    
    previous = ''
    for line in f:
	match = string_expr.match(line)
	if match:
	    result.append( (match.group('en'), match.group('trans'), previous) )
	else:
	    previous = line
	    
    f.close()
    
    return result
	    
def extractLocalizableStrings(source_dir):
    temp_dir = tempfile.mkdtemp()
    os.system('genstrings -o %s %s/*.m' % (temp_dir, source_dir))
    path = os.path.join(temp_dir, 'Localizable.strings')
    
    return extractTranslations(path)
	    
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

def findUntranslatedStrings(en_strings, languages, proj_dir, dest_file):
    languages = list(languages)
    languages.remove('en')
    
    all_strings = set([x for x,y,z in en_strings])
    untranslated = set()
    
    print "Creating Merged Localizable.strings files:"

    untranslated_langs = defaultdict(list)

    for language in languages:
	print '  - %s' % language
	lproj = os.path.join(proj_dir, '%s.lproj' % language)
	translations = extractTranslations(os.path.join(lproj, 'Localizable.strings'))
	
	translated_strings = set([x for x,y,z in translations])
	
	missing = all_strings.difference(translated_strings)
	untranslated = untranslated.union(missing)
	
	for string in missing:
	    untranslated_langs[string].append(language)
    
    f = file(dest_file, 'w+')
    
    for english, trans, comment in en_strings:
	if english in untranslated:
	    #langs = ', '.join(untranslated_langs[english])
	    #f.write('/* %s */\n' % langs)
	    f.write('%s%s = %s;\n\n' % (comment, english, trans))
    
    f.close()

def main():
    parser = optparse.OptionParser()
    parser.add_option("-p", "--project", dest="project",
		      help="Project directory", metavar="PROJECT_DIR")
    parser.add_option("-o", "--output", dest="output",
		      help="Output file for untranslated strings")
    parser.add_option("-s", "--source", dest="source",
		      help="Source directory for extracting strings")

    (options, args) = parser.parse_args()
    
    languages = getLanguageList(options.project)
    
#    makeOutputDirectories(languages, options.output)
    
#    extractXibStrings(languages, options.project, options.output)
    
    strings = extractLocalizableStrings(options.source)
        
    findUntranslatedStrings(strings, languages, options.project, options.output)    

if __name__ == '__main__':
	main()

