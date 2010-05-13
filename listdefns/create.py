from __future__ import with_statement
import wiktionary
import codecs
import sys

if len(sys.argv) == 2:
    with codecs.open(sys.argv[1], 'w', 'utf8') as output:
        for entry in wiktionary.dump_entries(main_only=True):
            for lang in wiktionary.language_sections(entry.text):
                if lang.heading:
                    for sect in wiktionary.all_subsections(lang.text):
                        for defn in wiktionary.definition_lines(sect.text):
                            print >>output,\
                                ("%s\t%s\t%s\t%s" % (lang.heading, entry.name, sect.heading, defn))
else:
    print "Usage: %s <output> " % sys.argv[0]
    print "Creates a tab-separated-file:"
    print "Language\tWord\tPart-of-speech\tDefinition"
