from __future__ import with_statement
import wiktionary
import codecs
import sys

i=1
if len(sys.argv) > 2:
    with codecs.open(sys.argv[1], 'w', 'utf8') as fgood:
        with codecs.open(sys.argv[2], 'w', 'utf8') as fbad:
            for entry in wiktionary.dump_entries(main_only=True):
                for lang in wiktionary.language_sections(entry.text):
                    for sect in wiktionary.all_subsections(lang.text):
                        for defn in wiktionary.definition_lines(sect.text):
                            print >>(fgood if wiktionary.is_part_of_speech(sect.heading) else fbad),\
                                "%s\t%s\t%s\t%s" % (lang.heading, sect.heading, entry.name, defn)

                            if not i % 10000:
                                print >>sys.stderr, ".",
                            i += 1

else:
    print "Usage: %s <output> <errors>" % sys.argv[0]
    print "Creates a tab-separated-file:"
    print "Language\tPart-of-speech\tWord\tDefinition"
    print "Valid parts of speech can be tweaked in wiktionary.py"
