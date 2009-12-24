#!/usr/bin/python
# -*- coding: utf-8  -*-

import codecs
import wiktionary

myfile = codecs.open('./Spanish.txt','r','utf-8')
translang = None

while 1:
    lines = myfile.readlines(1000)
    if not lines:
        break
    i=-1
    for line in lines:
        print line
        a=wiktionary.Parser()
        translang=a.singleTranslationLine(line,  context={'header': 'trans', 'wikilang': 'en', 'translang':  translang})
