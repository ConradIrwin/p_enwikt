from __future__ import with_statement
import wiktionary
import codecs
import sys

def detab(string):
	return string.replace(u"\t", u"        ")

if len(sys.argv) == 3:
    with codecs.open(sys.argv[2], 'w', 'utf8') as output:
        for entry in wiktionary.dump_entries(main_only=True, dump=sys.argv[1]):
            for lang in wiktionary.language_sections(entry.text):
                if lang.heading:
                    for sect in wiktionary.all_subsections(lang.text):
                        for defn in wiktionary.definition_lines(sect.text):
                            print >>output,\
				"\t".join(detab(field) for field in (lang.heading, entry.name, sect.heading, defn))
else:
    print "Usage: %s <dump> <output> " % sys.argv[0]
    print "Creates a tab-separated-output-file from an English Wiktionary XML dump:"
    print "Language\tWord\tPart-of-speech\tDefinition"
