#!/usr/bin/python
# -*- coding: utf-8  -*-

import mwclient
import pw

#if len(sys.argv) == 2:
 #       if sys.argv[1] == 'clearcache':

site = mwclient.Site('de.wiktionary.org')
site.login(u'Polyglot',pw.pw)

essite=mwclient.Site('es.wiktionary.org')
cat = essite.categories['Sprachkürzel']
outpage=u''

print 'expanding templates'
for page in cat.members():
    langcode=page.name.split(':')[1]
    #if langcode in ['kl', 'pl', 'ru', 'no', 'vep',  'en', 'de',  'sv',  'uk', 'bo',  'da']: continue
    print len(langcode)
    if len(langcode)>3:continue
    print langcode
    template=site.expandtemplates(('{{%s}}' % langcode))
    print template
    langname=template.split('|')[0].replace('[', '')
    if langname[0]==':' : continue
    """
    if langname.find('title="'): # only needed for pl.wiktionary
        try:
            langname=langname.split('title="')[1]
        except(IndexError):
            continue
        print langname
        langname=langname.split('"')[0]
        print langname
    else: continue
    """
    print langname
    outpage += u'|-\n| ' + langcode + u'||' + langname.replace(']', '').strip() + u'\n'
print outpage
if outpage:
    print 'ABOUT TO SAVE'
    raw_input()
    workpage=site.Pages[u'User:PolyBot/Languages']
    pagetext=workpage.edit()

    workpage.save(text=u'{| class="prettytable"\n' + outpage + u'|}\n', summary = u'Contents of all the language templates')
else:
    print 'NOTHING TO DO'
