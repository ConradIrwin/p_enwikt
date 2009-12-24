#!/usr/bin/python
# -*- coding: utf-8  -*-

import pdb

import mwclient
import re
import sys
import iso639

"""This module harvests WP interwiki links and formats them properly for an en.wikt Translations section
"""
type='noun' # default
if len(sys.argv) > 2:
    t=sys.argv[2].lower()
    if t=='proper':
        type='propernoun'
    elif t in ['propernoun', 'proper', 'weekday', 'month', 'lang', 'demonym', 'deity', 'prondeity', 'formal', 'title', 'properadj', 'nationadj', 'holiday']:
        type=t
if len(sys.argv) > 0:
    workterm=sys.argv[1].decode('utf-8')
    if workterm.find(':')!=-1:
        lang=workterm.split(':')[0]
        workterm=workterm.split(':')[1]
    else:
        lang='en'
else:
    print 'please give the term you want to lookup on Wikipedia'

translations={}
langnames=[]
firstfewlines={}
def uncapitalize(term):
    return term[0:1].lower()+term[1:]

print >>sys.stderr, 'type:', type

for wikilang, term in mwclient.Site(lang + '.wikipedia.org').pages[workterm].langlinks ():
    if wikilang not in [u'simple',u'zh-yue',u'gan',u'wuu',u'sh',u'be-x-old']:
        """ We are not interested in Simple English, Cantonese, Gan, Wu, Serbo-Croatian, or Old Byelarussian """
        print >>sys.stderr, wikilang,  
        term = term.split(u'(')[0].strip() # We only want the first part of the term before the parenthesis
        cap=iso639.cap(wikilang,  type)
        terms=[]
        if cap==-1:
            terms.append(term)
            u=uncapitalize(term)
            if u!=term:
                terms.append(u)
        elif not(cap):
            terms.append(uncapitalize(term)) 
        else:
            terms.append(term)
            #if wikilang == 'fr':
            '''TODO If the French word gender is not known yet and it's not possible to obtain it from fr.wikt
           it's possible to load the wikipedia page and go hunting for articles
           la chose
           le truc
           toutes les choses
           tous les trucs
               
           in case of words that start with a 'h' or a vowel, like

           l'hélium

           this doesn't help,
           tout l'hélium does indicate the gender (f would have been with toute)

           If that doesn't work either, we have to use something like qui est, qui sont and look at the adjective/past participle that follows it:

           l'hélium qui est produit

           Those are desperate matters already, but it can be done with this re:


               frpage=mwclient.Site('fr.wikipedia.org').pages[term].edit()
           rewordsaround=re.compile(r"(\w+\W+\w+\W+\w+\W+" + uterm + r"\W+qui est \w+\W+\w+\W+\w+\W+\w+)")
               frwords=rewordsaround.findall(frpage)

               for items in frwords:
        #for tuple in items:
                print items # tuple # + ' '
               '''
    else: continue
    wppage=  '' # mwclient.Site('%s.wikipedia.org' % wikilang).pages[term].edit().split(u'\n')
    i=1
    firstfewlines[wikilang]=[]
#    for line in wppage:
#            if not(term in line): continue
#        if i > 5: break
#        if not(line): continue
#        if line[:1] in ['[','|','{','!','<','=','}']:
#            continue
#        if line[:2] in ['<!','|']:
#            continue
#        # print line 
#        firstfewlines[wikilang].append(line + u'\n')
#            #print firstfewlines
    print >>sys.stderr, terms
    ln,  langname =iso639.iso2langname(iso639.MW2iso(wikilang), 'en',  wikify=True)

    #print langname.encode('utf-8'), ln.encode('utf-8'), uterm.encode('utf-8')
    langnames.append(ln)
    for uterm in terms:
        script=iso639.scripts(iso639.MW2iso(wikilang),  unknownIsBlank=True)
        if script:
            script = '|sc=' + script
        try:
            site=mwclient.Site('%s.wiktionary.org' % (wikilang))
        except:
            pageexists=u'ø'
        else:
            if site.pages[uterm].edit():
                pageexists=u'+'
            else:
                pageexists=u'-'

       #langname=mwclient.Site('en.wiktionary.org').expandtemplates('{{%s}}' % wikilang)
        #ln=langname.replace('[','').replace(']','')
        # print langnames
        if not(ln in translations):
            translations[ln]=(u"* %s: {{t%s|%s|%s%s}}" % (langname, pageexists, wikilang, uterm, script)).encode('utf-8')
        else:
            temp=translations[ln]
            temp+= (u", {{t%s|%s|%s%s}}" % (pageexists, wikilang, uterm, script)).encode('utf-8')
            translations[ln]=temp
        print >>sys.stderr, translations[ln]

langnames.sort()

print """
==English==

===Proper noun===
{{infl|en|proper noun}}

# language spoken in 

====Synonyms====
*[[]]

====Translations====
{{trans-top|language}}"""
i=0
mid=False
for lang in langnames:
    i+=1
    print translations[lang]
    if i > len(langname) and mid==False:
        print '{{trans-mid}}'
        mid=True
    #if firstfewlines.has_key(lang):
    #   for line in firstfewlines[lang]:
    #        print line
print """{{trans-bottom}}

===See also===
{{interwiktionary|code=}}

* {{langcat}}
* {{wikipedia| language}}
* [[::| edition of Wiktionary]]
* {{ethnologue|code=}}

[[Category:Abkhaz language]]
[[Category:Languages]]
"""























""" An attempt to harvest the language names from the templates in the Wiktionaries
       and to store it on a subpage of the PolyBot user 

import iso639

print iso639.iso2langname(u'en',u'en') # ask for one, so the dictionaries get populated
#print iso639._r_isocodes.keys()

iso=u'eng'
print mwclient.Site('nl.wiktionary.org').expandtemplates(('{{%s}}' % iso ),'hydrogen') 
langname=mwclient.Site('nl.wiktionary.org').pages[u':Sjabloon:eng'].edit()
print langname


for iso in iso639._r_isocodes.keys():
    # read the template from another Wiktionary
    print mwclient.Site('en.wiktionary.org').exandtemplates(('{{%s}}' % iso ),'') + '\n'

Some testing to sort

alllanguages = 'eu,zh-min-nan,ca,zh,zh-yue,nl,zh-classic,pl'

zh=alllanguages.find('zh')
zh-min-nan=alllanguages.find('zh-min-nan')
if zh-min-nan:
    if !(zh):
        for lang in alllanguages:
            if langnames['en'][lang] > u'Chinese':
                break
            zh=zh+1
    alllanguages.insert(zh-1,'zh-min-nan')

"""
