#!/usr/bin/python
# -*- coding: utf-8  -*-

'''
This module contains code to store Wiktionary content in Python objects.
The objects can output the content again in Wiktionary format by means of the wikiWrap methods

I'm currently working on a parser that can read the textual version in the various Wiktionary formats and store what it finds in the Python objects.

The data dictionaries will be moved to a separate file, later on. Right now it's practical to have everything together. They also still need to be expanded to contain more languages and more Wiktionary formats. Right now I like to keep everything together to keep my sanity.

The code is still very much alpha level and the scope of what it can do is still rather limited, only 3 parts of speech, only 2 different Wiktionary output formats. One of the things on the todo list is to harvest the contents of this matrix dictionary from the various Wiktionary projects.
'''

#from editarticle import EditArticle
#import wikipedia
import copy
import mwclient
import re
import iso639
import iso15924
import unicodedata, unicodescript
import htmlentitydefs
import srpCyrlLatnConversion, cmnsimplify

htmlentityRE=re.compile(ur"""(?xu)
    (?P<all>
    &
    (?P<entity>.+?)
    ;
    )
    """)

def htmlentity(entity):
    m=htmlentityRE.search(entity)
    if m:
        entity=m.group('entity')
    if entity[:1]==u'#':
        if entity[1:2]==u'x':
            return unichr(int(entity[2:],16))
        else:
            return unichr(int(entity[1:]))
    else:
        try:
            return unichr(htmlentitydefs.name2codepoint(entity))
        except keyError:
            print >>sys.stderr, "html entity &%s; can not be converted to a unicode string" % entity
            return ""

"""
Wiktionaries that use fully spelled out lang names:
eu, et (partly), sl, sv, tl, ta, te, tr (mostly iso2), sh, bg, fa, hr, da, fy (mostly iso3), kl (use: {{-en-}}, ms, ml, ang, gu, kk
iso3: vi, nl, ro,
iso2: br, gl, hu, it, ja, ku, li, lt, no, pt, sr, scn, vo, sq, hy, ast, ca, co, cs, eo, gn, hi, ia, ga, lo, oc, nds, sk, hsb, tk, sw, th, uk, an, az, be, km, fo, ka, ie, qu, sd, su,
no iso language templates: am, ta, pl, id, he, csb, zh-min-nan, tt, ur, bs, tl, ko (they use langnameinKorean(iso))
"""

print_dict = lambda dic: u"{"+u", ".join([u'"%s": "%s"' % (unicode(k),unicode(v)) for k,v in dic.items()])+u"}"

def printREresult(REdict):
    if 'templname' in REdict:
        templname='templname: ' +REdict['templname']
    else:
        templname='No template'
    print ' || ' + templname + ' || translations: ' + unicode(REdict['translations'])  + '||'
    nonegroup=[] ; keylist = u'|| '
    for key in REdict:
        if REdict[key]==None:
            nonegroup.append(key)
        elif key!='translations' and key!='templname':
            keylist += key + ': ' + unicode(REdict[key]) + ' || '
    print keylist
    for i in nonegroup:
        print i,
    print ': None'

wiktionaryformats = {
    'af': {
        'langheader': u'{{-%%ISOLangcode%%-}}',
        'translang': u':*{{%%ISOLangcode%%}}',
        'beforeexampleterm': u"'''",
        'afterexampleterm': u"'''",
        'gender': u"{{%%gender%%}}",
        'posheader': {
                'noun': u'{{-s.nw-}}',
                'adjective': u'{{-adj-}}',
                'verb': u'{{-verb-}}',
                },
        'meaningsheader': u'{{betekenisse}}',
        'translationsheader': u"{{-vert-}}",
        'transbefore': u'{{vert-bo}}',
        'transinbetween': u'{{vert-mid}}',
        'transafter': u'{{vert-onder}}',
        'transtemplate': u'vert', # vertxx, vertxx2 , vertxx3 also used
        'synonymsheader': u"{{-syn-}}",
        'relatedheader': u'{{-rel-}}',
        'pronunciation': u'{{-uitspraak-}}'
        },
    'nl': {
        'langheader': u'{{-%%ISOLangcode%%-}}',
        'translang': u':*{{%%ISOLangcode%%}}',
        'beforeexampleterm': u"'''",
        'afterexampleterm': u"'''",
        'gender': u"{{%%gender%%}}",
        'posheader': {
                'noun': u'{{-noun-}}',
                'adjective': u'{{-adj-}}',
                'verb': u'{{-verb-}}',
                },
        'translationsheader': u"{{-trans-}}",
        'transbefore': u'{{top}}',
        'transinbetween': u'{{mid}}',
        'transafter': u'{{after}}',
        'transtemplate': u'trans',
        'synonymsheader': u"{{-syn-}}",
        'relatedheader': u'{{-rel-}}',
        },
    'en': {
        'langheader': u'==%%langname%%==',
        'translang': u'* %%langname%%',
        'beforeexampleterm': u"'''",
        'afterexampleterm': u"'''",
        'gender': u"{{%%gender%%}}",
        'posheader': {
                'noun': u'=== Noun ===',
                'adjective': u'=== Adjective ===',
                'verb': u'=== Verb ===',
                },
        'translationsheader': u"==== Translations ====",
        'transbefore': u'{{trans-top}}',
        'transinbetween': u'{{trans-mid}}',
        'transafter': u'{{trans-bottom}}',
        'transtemplate': u't',
        'synonymsheader': u"==== Synonyms ====",
        'relatedheader': u'=== Related words ===',
        }
    }

pos = {
    u'noun': u'noun',
    u'adjective': u'adjective',
    u'verb': u'verb',
    }

otherheaders = {
    u'see also': u'seealso',
    u'see': u'seealso',
    u'translations': u'trans',
    u'trans': u'trans',
    u'synonyms': u'syn',
    u'syn': u'syn',
    u'antonyms': u'ant',
    u'ant': u'ant',
    u'pronunciation': u'pron',
    u'pron': u'pron',
    u'related terms': u'rel',
    u'rel': u'rel',
    u'acronym': u'acr',
    u'acr': u'acr',
    u'etymology': u'etym',
    u'etym': u'etym',
    }

def uncapitalize(term):
        return term[0:1].lower()+term[1:]


def createPOSlookupDict():
    for key in pos.keys():
        lowercasekey=key.lower()
        value=pos[key]
        for index in range(1,len(lowercasekey)):
            # So first we create all the possibilities with one letter gone
            pos.setdefault(lowercasekey[:index]+lowercasekey[index+1:], value)
            # Then we switch two consecutive letters
            pos.setdefault(lowercasekey[:index-1]+lowercasekey[index]+lowercasekey[index-1]+lowercasekey[index+1:], value)
            # There are of course other typos possible, but this caters for a lot of possibilities already
    return pos

def createOtherHeaderslookupDict():
    for key in otherheaders.keys():
        lowercasekey=key.lower()
        value=otherheaders[key]
        for index in range(1,len(lowercasekey)):
            # So first we create all the possibilities with one letter gone
            otherheaders.setdefault(lowercasekey[:index]+lowercasekey[index+1:], value)
            # Then we switch two consecutive letters
            otherheaders.setdefault(lowercasekey[:index-1]+lowercasekey[index]+lowercasekey[index-1]+lowercasekey[index+1:], value)
            # There are of course other typos possible, but this caters for a lot of possibilities already
    return otherheaders

class sortonname:
    '''
    This class sorts translations alphabetically on the name of the language,
    instead of on the iso abbreviation that is used internally.

    A big thanks to Rob Hooft for the following class
    It may not seem like much, but it magically allows the translations to be sorted on
    the names of the languages. I would never have thought of doing it like this myself.
    '''
    def __init__(self, lang):
        self.lang = lang

    def __call__(self, one, two):
        return cmp(self.lang[one], self.lang[two])

class WiktionaryPage:
    """ This class contains all that can appear on one Wiktionary page """
    def __init__(self,wikilang,term):
        """ Constructor
             Called with two parameters:
            - the language of the Wiktionary the page belongs to
            - the term that is described on this page
        """
        self.wikilang=wikilang
        self.sourcewiki=wikilang # where did this information come from
        self.term=term
        self.entries = {}         # entries is a dictionary of entry objects indexed by entrylang
        self.sortedentries = [] # keeps track of the order in which the entries were encountered
        self.interwikilinks = []
        self.categories = []

    def setWikilang(self,wikilang):
        """ This method allows to switch the language on the fly """
        self.wikilang=wikilang

    def addEntry(self,entry):
        """ Add an entry object to this page object """
#        self.entries.setdefault(entry.entrylang, []).append(entry)
        self.entries[entry.entrylang]=entry

    def listEntries(self):
        """ Returns a dictionary of entry objects for this entry """
        return self.entries

    def sortEntries(self):
        """ Sorts the sortedentries list containing the keys of the entry
             objects dictionary for this entry
        """

        if not self.entries == {}:
            self.sortedentries = self.entries.keys()
            self.sortedentries.sort(sortonname(iso639.alllangnamesforiso(self.wikilang)))

            try: # Put the entry that is in the same language as the wiki before the others
                samelangentrypos=self.sortedentries.index(self.wikilang)
            except (ValueError):
                # wikilang isn't in the list, do nothing
                pass
            else:
                samelangentry=self.sortedentries[samelangentrypos]
                self.sortedentries.remove(self.wikilang)
                self.sortedentries.insert(0,samelangentry)

            try: # Put the translingual entry all the way on top of the page
                translingualentrypos=self.sortedentries.index(u'translingual')
            except (ValueError):
                # translingual isn't in the list, do nothing
                pass
            else:
                translingualentry=self.sortedentries[translingualentrypos]
                self.sortedentries.remove(u'translingual')
                self.sortedentries.insert(0,translingualentry)

    def addLink(self,link):
        """ Add a link to another wikimedia project """
        link=link.replace('[','').replace(']','')
        pos=link.find(':')
        if pos!=1:
            link=link[:pos]
        self.interwikilinks.append(link)

    def addCategory(self,category):

        """ Add a link to another wikimedia project """
        self.categories.append(category)

    def storeDefinition(self, term, definition, label, examples):
        ameaning = Meaning(term=term,definition=definition, label=label, examples=examples)
        if not(contentblock['context']['lang'] in self.entries):
            # If no entry for this language is present yet,
            # let's create one
            anentry = Entry(contentblock['context']['lang'])
            # and add it to our page object
            self.addEntry(anentry)
            # Then we can easily add this meaning to it.
            anentry.addMeaning(ameaning)

    def wikiWrap(self):
        """ Returns a string that is ready to be submitted to Wiktionary for
            this page
        """
        page = ''
        self.sortEntries()
        # print "sorted: %s",self.sortedentries
        first = True
        print "SortedEntries:", self.sortedentries, len(self.sortedentries)
        for index in self.sortedentries:
            print "Entries:", self.entries[index]
            entry = self.entries[index]
            print entry
            if first == False:
                page = page + '\n----\n'
            else:
                first = False
            page = page + entry.wikiWrap(self.wikilang)
        # Add interwiktionary links at bottom of page
        for link in self.interwikilinks:
            page = page + '[' + link + ':' + self.term + ']\n'

        return page

    def showContents(self):
        """ Prints the contents of all the subobjects contained in this page.
            Every subobject is indented a little further on the screen.
            The primary purpose of this function is to help keep one's sanity while debugging.
        """
        indentation = 0
        print ' ' * indentation + 'wikilang = %s' % self.wikilang

        print ' ' * indentation + 'term = %s' % self.term

        entrieskeys = self.entries.keys()
        for entrieskey in entrieskeys:
            for entry in self.entries[entrieskey]:
                entry.showContents(indentation+2)

class Entry:
    """ This class contains the entries that belong together on one page.
        On Wiktionaries that are still on first character capitalization, this means both [[Kind]] and [[kind]].
        Terms in different languages can be described. Usually there is one entry for each language.
    """

    def __init__(self,entrylang,meaning=""):
        """ Constructor
             Called with one parameter:
            - the language of this entry
        and can optionally be initialized with a first meaning
        """
        self.entrylang=entrylang
        self.meanings = {} # a dictionary containing the meanings for this term grouped by part of speech
        if meaning:
            self.addMeaning(meaning)
        self.posorder = [] # we don't want to shuffle the order of the parts of speech, so we keep a list to keep the order in which they were encountered

    def addMeaning(self,meaning):
        """ Lets you add another meaning to this entry """
        term = meaning.term # fetch the term, in order to be able to determine its part of speech in the next step

        self.meanings.setdefault( term.pos, [] ).append(meaning)
        if not term.pos in self.posorder:    # we only need each part of speech once in our list where we keep track of the order
            self.posorder.append(term.pos)

    def getMeanings(self):
        """ Returns a dictionary containing all the meaning objects for this entry
        """
        return self.meanings

    def wikiWrap(self,wikilang):
        """ Returns a string for this entry in a format ready for Wiktionary
        """
        entry = wiktionaryformats[wikilang]['langheader'].replace('%%langname%%',iso639.iso2langname(wikilang,self.entrylang, askforhelp=True)).replace('%%ISOLangcode%%',self.entrylang) + '\n'

        for pos in self.posorder:
            meanings = self.meanings[pos]

            entry += wiktionaryformats[wikilang]['posheader'][pos]
            entry +='\n'
            if wikilang=='en':
                entry = entry + meanings[0].term.wikiWrapAsExample(wikilang) + '\n\n'
                for meaning in meanings:
                    entry = entry + '#' + meaning.getLabel() + ' ' + meaning.definition + '\n'
                    entry = entry + meaning.wikiWrapExamples()
                entry +='\n'

            if wikilang=='nl':
                for meaning in meanings:
                    term=meaning.term
                    entry = entry + meaning.getLabel() + term.wikiWrapAsExample(wikilang) + '; ' + meaning.definition + '\n'
                    entry = entry + meaning.wikiWrapExamples()
                entry +='\n'

            if meaning.hasSynonyms():
                entry = entry + wiktionaryformats[wikilang]['synonymsheader'] + '\n'
                for meaning in meanings:
                    entry = entry + '*' + meaning.getLabel() + "'''" + meaning.getreference2definition() + "''': " + meaning.wikiWrapSynonyms(wikilang)
                entry +='\n'

            if meaning.hasTranslations():
                entry = entry + wiktionaryformats[wikilang]['translationsheader'] + '\n'
                for meaning in meanings:
                    entry = entry + meaning.getLabel() + "'''" + meaning.getreference2definition() + "'''" + '\n' + meaning.wikiWrapTranslations(wikilang,self.entrylang) + '\n\n'
                entry +='\n'
        return entry

    def showContents(self,indentation):
        """ Prints the contents of all the subobjects contained in this entry.
            Every subobject is indented a little further on the screen.
            The primary purpose is to help keep your sanity while debugging.
        """
        print ' ' * indentation + 'entrylang = %s'% self.entrylang

        print ' ' * indentation + 'posorder:' + repr(self.posorder)

        meaningkeys = self.meanings.keys()
        for meaningkey in meaningkeys:
            for meaning in self.meanings[meaningkey]:
                meaning.showContents(indentation+2)

class Meaning:
    """ This class contains one meaning for a word or an expression.
    """
    def __init__(self,term,definition='',etymology='',synonyms=[],translations={},label='',reference2definition='',examples=[]):
        """ Constructor
            Generally called with one parameter:
            - The Term object we are describing

            - definition (string) for this term is optional
            - etymology (string) is optional
            - synonyms (list of Term objects) is optional
            - translations (dictionary of Term objects, ISO639 is the key) is optional
            - translationsources (dictionary containing  a list with sources where the translations were found)
        """
        self.term=term
        self.definition=definition
        self.reference2definition=reference2definition
        self.etymology=etymology
        self.synonyms=synonyms
        self.examples=examples
        self.label=label

        if translations: # Why this has to be done explicitly is beyond me, but it doesn't work correctly otherwise
            self.translations=translations
        else:
            self.translations={}

    def setDefinition(self,definition):
        """ Provide a definition  """
        self.definition=definition

    def getDefinition(self):
        """ Returns the definition  """
        return self.definition

    def setEtymology(self,etymology):
        """ Provide the etymology  """
        self.etymology=etymology

    def getEtymology(self):
        """ Returns the etymology  """
        return self.etymology

    def setSynonyms(self,synonyms):
        """ Provide the synonyms  """
        self.synonyms=synonyms

    def getSynonyms(self):
        """ Returns the list of synonym Term objects  """
        return self.synonyms

    def hasSynonyms(self):
        """ Returns True if there are synonyms
            Returns False if there are no synonyms
        """
        if self.synonyms == []:
            return False
        else:
            return True

    def setTranslations(self,translations):
        """ Provide the translations  """
        self.translations=translations

    def getTranslations(self):
        """ Returns the translations dictionary containing translation
            Term objects for this meaning
        """
        return self.translations

    def addTranslation(self,translation):
        """ Add a translation Term object to the dictionary for this meaning
            The lang property of the Term object will be used as the key of the dictionary
        """
        self.translations.setdefault( translation.lang, [] ).append( translation )

    def addTranslations(self,*translations):
        """ This method calls addTranslation as often as necessary to add
            all the translations it receives
        """
        for translation in translations:
            self.addTranslation(translation)

    def hasTranslations(self):
        """ Returns True if there are translations
            Returns False if there are no translations
        """
        if self.translations == {}:
            return 0
        else:
            return 1

    def setLabel(self,label):
        self.label=label.replace('<!--','').replace('-->','')

    def getLabel(self):
        if self.label:
            return u'<!--' + self.label + u'-->'

    def getreference2definition(self):
        if self.reference2definition:
            return self.reference2definition

    def getExamples(self):
        """ Returns the list of example strings for this meaning
        """
        return self.examples

    def addExample(self,example):
        """ Add a translation Term object to the dictionary for this meaning
            The lang property of the Term object will be used as the key of the dictionary
        """
        self.examples.append(example)

    def addExamples(self,*examples):
        """ This method calls addExample as often as necessary to add
            all the examples it receives
        """
        for example in examples:
            self.addExample(example)

    def hasExamples(self):
        """ Returns True if there are examples
            Returns False if there are no examples
        """
        if self.examples == []:
            return 0
        else:
            return 1

    def wikiWrapSynonyms(self,wikilang):
        """ Returns a string with all the synonyms in a format ready for Wiktionary
        """
        first = 1
        wrappedsynonyms = ''
        for synonym in self.synonyms:
            if first==0:
                wrappedsynonyms += ', '
            else:
                first = 0
            wrappedsynonyms = wrappedsynonyms + synonym.wikiWrapForList(wikilang)
        return wrappedsynonyms + '\n'

    def wikiWrapTranslations(self,wikilang,entrylang):
        """ Returns a string with all the translations in a format
            ready for Wiktionary
            The behavior changes with the circumstances.
            For an entry in the same language as the Wiktionary the full list of translations is contained in the output, excluding the local
        language itself
            - This list of translations has to end up in a table with two columns
            - The first column of this table contains languages with names from A to M, the second contains N to Z
            - If a column in this list remains empty a html comment is put in that column
            For an entry in a foreign language only the translation towards the local language is output.
        """
        if wikilang == entrylang:
            # When treating an entry of the same lang as the Wiktionary, we want to output the translations in such a way that they end up sorted alphabetically on the language name in the language of the current Wiktionary
            alllanguages=self.translations.keys()
            sortorder=iso639.alllangnamesforiso(wikilang)
            if wikilang=='en':
                """ TODO: Chinese has to be grouped under line stating Chinese
                     Serbian is written in Cyrillic and Latin scripts
                     Aramaic is written in Syriac and Aramaic scripts (example at [[pig]])
                     So all these need special treatment after the sorting took place
                     Albanian Tosk (als) is sorted beneath Albanian
                     Old Church Slavonic is written in Cyrillic and Glagolitic scripts
                     Ligurian can be subbed by Genoese
                     North Frisian can be subdivided in Mooring and Feering
                     Dutch can have Brabantish under it
                     Greek can have Ancient and modern under it
                     Kurdish can have Kurmancî and Soranî under it
                     There is also Saterland Frisian
                     Saxon has an old version

                """
                print sortorder
                sortorder['nn']='Norwegian (Nynorsk)'
                sortorder['zh-min-nan']='Chinese Min Nan'
                sortorder['zh']='Chinese Mandarin'
                sortorder['hak']='Chinese Hakka'
                sortorder['als']='Albanian Tosk'
            alllanguages.sort(sortonname(sortorder))

            wrappedtranslations = wiktionaryformats[wikilang]['transbefore'] + '\n'
            for language in alllanguages:
                if language == wikilang: continue # don't output translation for the wikilang itself
                # Indicating the language according to the wikiformats dictionary
                wrappedtranslations = wrappedtranslations + wiktionaryformats[wikilang]['translang'].replace('%%langname%%',iso639.iso2langname(wikilang,language, askforhelp=True)).replace('%%ISOLangcode%%',language) + ': '
                first = 1
                for translation in self.translations[language]:
                    term=translation.term
                    if first==0:
                        wrappedtranslations += ', '
                    else:
                        first = 0
                    wrappedtranslations = wrappedtranslations + translation.wikiWrapAsTranslation(wikilang)
                wrappedtranslations += '\n'
            if not alreadydone:
                wrappedtranslations = wrappedtranslations + wiktionaryformats[wikilang]['transinbetween'] + '\n' + wiktionaryformats[wikilang]['transnoNtoZ'] + '\n'
                alreadydone = 1
            wrappedtranslations = wrappedtranslations + wiktionaryformats[wikilang]['transafter'] + '\n'
        else:
            # For the other entries we want to output the translation in the language of the Wiktionary
        # TODO We also want the 'gloss/short definition' to be added after it or maybe the full definition for this meaning
            wrappedtranslations = wiktionaryformats[wikilang]['translang'].replace('%%langname%%',iso639.iso2langname(wikilang, wikilang)).replace('%%ISOLangcode%%',wikilang) + ': '
            first = True
            for translation in self.translations[wikilang]:
                term=translation.term
                if first==False:
                    wrappedtranslations += ', '
                else:
                    first = False
                wrappedtranslations = wrappedtranslations + translation.wikiWrapAsTranslation(wikilang)
        return wrappedtranslations

    def showContents(self,indentation):
        """ Prints the contents of this meaning.
            Every subobject is indented a little further on the screen.
            The primary purpose of this method is to help keep one's sanity while debugging.
        """
        print ' ' * indentation + 'term: '
        self.term.showContents(indentation+2)
        print ' ' * indentation + 'definition = %s'% self.definition
        print ' ' * indentation + 'etymology = %s'% self.etymology

        print ' ' * indentation + 'Synonyms:'
        for synonym in self.synonyms:
            synonym.showContents(indentation+2)

        print ' ' * indentation + 'Translations:'
        translationkeys = self.translations.keys()
        for translationkey in translationkeys:
            for translation in self.translations[translationkey]:
                translation.showContents(indentation+2)

    def wikiWrapExamples(self):
        """ Returns a string with all the examples in a format ready for Wiktionary
        """
        wrappedexamples = ''
        for example in self.examples:
            wrappedexamples = wrappedexamples + "#:'''" + example + "'''\n"
        return wrappedexamples


class Term:
    """ This is a superclass for terms.  """
    def __init__(self,lang,term,relatedwords=[]): # ,label=''):
        """ Constructor
            Generally called with two parameters:
            - The language of the term
            - The term (string)

            - relatedwords (list of Term objects) is optional
        """
        self.lang=lang
        self.term=term
        self.relatedwords=relatedwords
#        self.label=label

    def __getitem__(self):
        """ Documenting as an afterthought is a bad idea
            I don't know anymore why I added this, but I'm pretty sure it was in response to an error message
        """
        return self

    def setTerm(self,term):
        self.term=term

    def getTerm(self):
        return self.term

    def setLang(self,lang):
        self.lang=lang

    def getLang(self):
        return self.lang

#    def setLabel(self,label):
#        self.label=label.replace('<!--','').replace('-->','')

#    def getLabel(self):
#        if self.label:
#            return '<!--' + self.label + '-->'

    def wikiWrapGender(self,wikilang):
        """ Returns a string with the gender in a format ready for Wiktionary, if it is applicable
        """
        if self.gender:
            return ' ' + wiktionaryformats[wikilang]['gender'].replace('%%gender%%',self.gender)
        else:
            return ''

    def wikiWrapAsExample(self,wikilang):
        """ Returns a string with the gender in a format ready for Wiktionary, if it exists
        """
        return wiktionaryformats[wikilang]['beforeexampleterm'] + self.term + wiktionaryformats[wikilang]['afterexampleterm'] + self.wikiWrapGender(wikilang)

    def wikiWrapForList(self,wikilang):
        """ Returns a string with this term as a link followed by the gender in a format ready for Wiktionary
        """
        return '[[' + self.term + ']]' + self.wikiWrapGender(wikilang)

    def wikiWrapAsTranslation(self,wikilang):
        """    Returns a string with this term as a link followed by the gender in a format ready for Wiktionary
        """
        t= '{{t|' + self.lang + '|' + self.term
        if self.wikiWrapGender(wikilang): t +=  '|' + self.gender
        t += '}}'
        return t

    def showContents(self,indentation):
        """ Prints the contents of this Term.
            Every subobject is indented a little further on the screen.
            The primary purpose is to help keep your sanity while debugging.
        """
        print ' ' * indentation + 'lang = %s'% self.lang
        print ' ' * indentation + 'pos = %s'% self.pos
        print ' ' * indentation + 'term = %s'% self.term
        print ' ' * indentation + 'relatedwords = %s'% self.relatedwords

class Noun(Term):
    """ This class inherits from Term.
        It adds properties and methods specific to nouns
    """
    def __init__(self,lang,term,gender=''):
        """ Constructor
            Generally called with two parameters:
            - The language of the term
            - The term (string)

            - gender is optional
        """
        self.pos='noun'        # part of speech
        self.gender=gender
        Term.__init__(self,lang,term)

    def setGender(self,gender):
        self.gender=gender

    def getGender(self):
        return(self.gender)

    def showContents(self,indentation):
        Term.showContents(self,indentation)
        print ' ' * indentation + 'gender = %s'% self.gender

class Adjective(Term):
    def __init__(self,lang,term,gender=''):
        self.pos='adjective'        # part of speech
        self.gender=gender
        Term.__init__(self,lang,term)

    def setGender(self,gender):
        self.gender=gender

    def getGender(self):
        return(self.gender)

    def showContents(self,indentation):
        Term.showContents(self,indentation)
        print ' ' * indentation + 'gender = %s'% self.gender

class Header:
    def __init__(self,m):
        """ Constructor
              Generally called with one parameter:
            - The match result from regex parsing the line read from a Wiktonary page
        """
        self.type=''          # The type of header, i.e. lang, pos, other
        self.contents=''    # If lang, which lang? If pos, which pos?

        self.level=None
        self.header = ''

        mdict=m.groupdict()
        if 'betweenEQ' in mdict and mdict['betweenEQ']:
            self.level = mdict('level1').count('=')
            self.header = mdict['betweenEQ']
        elif 'templated' in mdict and mdict['templated']:
            self.header = mdict['templated']

        self.header = self.header.lower()

        # Now we know the contents of the header, let's try to find out what it means:
        if pos.has_key(self.header):
            self.type=u'pos'
            self.contents=pos[self.header]

        try: # Is it an iso639 code?
            iso=iso639.MW2iso(self.header, askforhelp=False)
        except UnknownLanguage:
            pass
        else:
            self.type=u'lang'
            self.contents=iso

        try: # Is it a fully spelled out language name?
            iso=iso639.langname2iso(self.header, askforhelp=False)
        except UnknownLanguage:
            pass
        else:
            self.type=u'lang'
            self.contents=iso

        if otherheaders.has_key(self.header):
            self.type=u'other'
            self.contents=otherheaders[self.header]

    def __repr__(self):
        return self.__module__+".Header("+\
            "contents='"+self.contents+\
            "', header='"+self.header+\
            "', level="+str(self.level)+\
            ", type='"+self.type+\
            "')"

htmlcommentRE=re.compile("""(?xu)    # re.VERBOSE | re.UNICODE
    \s*
    (
    (<!--)
   .*
    (-->)
    \s*
    )
    """)

genderREpart= r'''(?xu)
    (?:
     (?:\{\{)                           # {{
     (?:\()*                            # not interested in (
     (?P<gendertmplt>[^\'\}\.\)]*)   # match everything but ' } . )
     (?:\.)*                            # not interested in .
     (?:\))*                            # not interested in )
     (?:\}\})                          # }}
    |
     (?:'')                              # ''
     #(?:\()*                            # not interested in (
     (?P<quotgender>[^\'\.\)]*)   # match everything but ' . )
     (?:\.\))*                            # not interested in )
     (?:'')                              # ''
    )*
    \s*                                     # optional whitespace
    '''

defnumbersREpart = ur"""(?xu)
    (?:
     \(
     (?P<defnumbersrndbr>[^\)]*) # sometimes there are numbers between ( ) to indicate which def this
     \)                                              # translation belongs to
    )*
    (?:
     \[
     (?P<defnumberssqrbr>[^\]]*)  # sometimes there are numbers between [ ] to indicate which def this
     \]                                               # translation belongs to
    )*
    (?:
     '''
      (?P<defnumber3quot>[^'])
     \.'''
    )*
    (?P<defnumber>\d+?)*
    \s*                                              # optional whitespace
    #(?P<comment>[^\[]*)
    """

iso23RE = re.compile(ur'''(?xu)    # re.VERBOSE | re.UNICODE
     (?:\*)*
    \{{2}
    (?P<langcode>[a-z]{2,3})       # match 2 or 3 letter iso code
    (?P<hu>1)*                              # on hu.wikt they stick a 1 here
    \|
    (?P<translations>[^\}]*)         # grab all the rest into 'translations'
    \}{2}
    \s*
    (?P<rest>.*)
    ''')
t_image_templateRE = re.compile(defnumbersREpart + ur'''
    \{{2}
    (?:t-image)                          # match t-image or it wouldn't be a t-image template
    \|
    (?P<langcode>[^\|]*)        # match anything but | and put in group 'langcode'
    \|
    (?P<translations>[^\|}]*)  # match anything but | and } and put in group 'translations'
    \|
    (?P<px>[^\|}]*)                # match anything but | and } and put in group 'px'
    \|
    (?P<linkto>[^\|}]*)           # match anything but | and } and put in group 'linkto'
    \|*                                       # optionally match |
    (?P<restoftempl>[^\}]*)  # grab all the rest into 'restoftempl' for processing it the traditional way
    (?:\}{2})
    \s*                                       # optional whitespace
    ''' + genderREpart +
    '''
    (?P<rest>.*)                       # grab all the rest into 'rest' for processing it the traditional way
    ''')
t_templateRE = re.compile(defnumbersREpart + ur'''
    \{{2}
    (?:t)                                    # match t or it wouldn't be a t template
    (?P<exists>\+|-|ø)*            # optionally match +, -, ø and put in group 'exists'
    \|
    (?P<langcode>[^\|]*)        # match anything but | and put in group 'langcode'
    \|
    (?P<translations>[^\|}]*)  # match anything but | and } and put in group 'translations'
    \|*                                       # optionally match |
    (?P<restoftempl>[^\}]*)    # grab all the rest into 'restoftempl' for processing it the traditional way
    (?:\}{2})
    \s*                                      # optional whitespace
    ''' + genderREpart +
    '''
    (?P<rest>.*)                       # grab all the rest into 'rest' for processing it the traditional way
    ''')

tradvertRE = re.compile(defnumbersREpart + ur'''
    (?:''(?P<de_comment>.+?)'')*
    \s*
    \{{2}
    (?P<templname>
    (?:trad|ξεν)(?P<exists>-|\+|xx)* # this deals with trad, tradxx, trad- and trad+ (nl,fr,oc,es,ro,yi,nah,mn,id,vo(tradxx)|el)
    |vert(?:xx(?:\d)*)*                         # this deals with vert, vertxx, vertxx2, etc (af)
    |Ü(xx)*|П|ö|ກ|ת|P|ප|versk|overs   # (de,sr,sv,lo,he,,si,lt,no)
    |çeviri|Wendung|ter|trans            # (tr,ang,tk,)
    |þýðing(?:-xx)*|to                        # (is,sk)
    |алга|xlatio|aistr|ဘာသာ)               # (ky,la,ga,my)
    \|                                                 # match |
    (?P<langcode>[^\|]*)                  # match anything but | and put in group 'langcode'
    \|
    (?P<translations>[^\}]*)             # grab all the rest into 'translations' for processing it the traditional way
    (?:\}{2})
    \s*                                                  # optional whitespace
    ''' + genderREpart +
    '''
    \s*                                                  # optional whitespace
    (?:\(''
    (?P<nahtranscript>.*)                  # grab what is between ('' '') into 'nahtranscript'
    (?:''\))
    )*
     \s*                                                 # optional whitespace
    (?P<rest>.*)                                  # grab all the rest into 'rest' for processing it the traditional way
    ''')

scriptnameRE = re.compile(defnumbersREpart + ur'''
    \{{2}
     (?P<templname>
     Arab|[Ll]ang|URchar|KOfont|zh-ts|Unicode)
     \|                                                   # match |
     (?:
      (?P<langcode>
      [a-z]{2,3}(?:-[a-z]{1})*(?:-[a-z]{2,5})*
     )
     \|
     )*
     (?:\[{2})*                                      # [[
     (?P<translations>.+?)                  # grab all the rest into 'translations' for processing it the traditional way
     (?:\]{2})*                                      # ]]
    (?:\}{2})
    \s*                                                 # optional whitespace
    ''' + genderREpart +
    '''
    (?P<rest>.*)                                 # grab all the rest into 'rest' for processing it the traditional way
    ''')
foreignlinktoREpart=ur"""(?xu)
        (?:
         \[{2}:                                # [[:
         (?P<foreignlinkto>[^:]*)
         :
         (?P<foreignlink>[^\]\|]*)
           (?:
            \|
            (?P<forgndispld>.+?)
          )*
         \]{2}
        ) # optionality taken away to make it work independently
        """
linkedTerm = defnumbersREpart + ur'''
       (?P<prefix>\w+)*
        \[{2}                                 # [[
          (?:
            :                                # [[:
            (?P<linkto>[^:]*)
            :
          )*
        (?P<translations>.+?)      # match up to #
          (?:
            \#                                     # it's important to escape the # or it will be treated as a comment
            (?P<section>.+?)             # and up to |
            )*
           (?:
            \|
            (?P<displayed>.+?)          # match everything up to ]], not greedily
          )*
          \]{2}
         (?P<suffix>\w+)*
          \s*                                     # optional whitespace
          (?:
            (?P<hi_gu_gender>પુ|સ્ત્રી|पु |स्त्री| न)
          \.?
          )*
          \s*                                     # optional whitespace
      ''' + foreignlinktoREpart + ur'*\s*' + genderREpart + ''' # the * makes the foreignlinktoREpart optional
        (?:
         \[
         (?P<defnumbersOromo>[^\[\]]+)  # om.wikt puts the defnumbers in this position
         \]
        )*
        (?P<rest>.*)                     # grab all the rest into 'rest' for processing it the traditional way
        '''
linkedTermRE = re.compile(linkedTerm)

partOfTemplateRE = re.compile('''(?ixu)
    \|
    (?P<langcode>[a-z]{2,4}(?:-[a-z]{2,6})*)
    \s*
    =
    \s*
    (?P<translations>
    (?:\[|\{){2}
    .*
    (?:\]|\}){2}
    )
    ''')

#two accolades without a | inbetween, mean an iso code abbreviation
templatewithoutparamsRE=re.compile(ur'''(?xu)    # re.VERBOSE | re.UNICODE
    \{{2}              # match {{
    (?:(?P<ttbc>ttbc)\|)*
    (?P<langname>
    [^\|\}]*)             # grab if no | is inbetween the {{ }},
                              # the \} is there so it doesn't put the } into the capturing group
    \}{2}              # match }}
    (?:\]\])*
    (?:<!--
    (?P<KoreanLangname>.*)
    -->)*
    ''')
striplangnamepartRE=re.compile(ur'''(?xu)    # re.VERBOSE | re.UNICODE
    [\*|:|\[|\]|\(|\)] # match * : [ ]  ( )
    ''')

""" Commas and colons between ( , ), {{, }}, [[, ]] should be treated differently.
     So we'll replace these first to get them out of the way."""

comma_function = lambda x: x.group(0).replace(",","&comma&")
colon_function = lambda x: x.group(0).replace(":","&colon&")
semicolon_function = lambda x: x.group(0).replace(";","&semicolon&")
htmlcomment_function = lambda x: x.group(0).replace(x.group(1),"")
htmlentity_function = lambda x: htmlentity(x.group('all'))
searchEmbeddedRE = re.compile(ur'''(?xu)    # re.VERBOSE | re.UNICODE
     \([^\)]*\) # match everything inside ( and )
    |\[[^\]]*\] # or match everything inside [ and ]
    |\{[^\}]*\} # or match everything inside { and }
    ''')

sqwiktRE=re.compile(ur'''(?xu)
    (?:<br>)*
    \s*
    (\{{2}.+?\}{2})      # match all that is between {{ }} and put in group 1
    \s*                            # optional whitespace
    -                               # This is what we were looking for
    \s*
    (\[{2}.*)                   # grab till the end of the string for 2nd group
    $
    ''')
commasepdnumbersRE = re.compile(ur'''(?xu)    # re.VERBOSE | re.UNICODE
    (?P<digits>\s*\d\s*
    (?:,\s*\d\s*)*
    )
    ''')

colonPresentREs=(
        ('t_templateRE', t_templateRE),
        ('scriptnameRE', scriptnameRE),
        ('tradvertRE', tradvertRE),
        ('iso23RE', iso23RE),
        ('linkedTermRE', linkedTermRE),
        ('t_image_templateRE', t_image_templateRE),
    )

noColonPresentREs=(
        ('partOfTemplateRE', partOfTemplateRE),
        ('tradvertRE', tradvertRE),
        ('iso23RE', iso23RE),
        ('templatewithoutparamsRE', templatewithoutparamsRE),
        ('linkedTermRE', linkedTermRE),
    )

def applyREs(translation, REs):
    for REname, regex in REs:
        m=regex.search(translation)
        if m:
            print REname, "matched"
            return REname, m.groupdict()
    # when the list is exhausted, return an empty result
    return '', {}

"""r e s u mf Hungarian (s might be conflicting with singular, mf is masculine/feminine)
    kk kvk hk are Icelandic
    पु   स्त्री  न  are Hindi
    પુ સ્ત્રી are Gujarati
    α, θ, ο are Greek
    dgs is Lithuanian (lt)
"""
gndrcommon={
    u'm': ('m', None),
    u'f': ('f', None),
    u'n': ('n', None),
    u'c': ('c', None),

    u'p': (None, '2'),
    }
gndrtemplates={
    u'r': ('m', None), u'kk'  : ('m', None),
    u'e': ('f', None), u'kvk': ('f', None),
    u's': ('n', None), u'hk'  : ('n', None),
    u'u': ('c', None),

    u'dgs': (None, '2'),

    u'n|d': ('n','2'),
    }
gndrtemplates.update(gndrcommon)
gndrquoted={
    u'α': ('m', None), u'पु':      ('m', None), u'પુ' :    ('m', None),
    u'θ': ('f', None), u'स्त्री': ('f', None), u'સ્ત્રી': ('f', None),
    u'ο': ('n', None), u'न':      ('n', None),
    u'πλ': (None, '2'),

    u'pl': (None, '2'),
    u'sg': (None, '1'),
    }
gndrquoted.update(gndrcommon)

def wikitemplate(fromtmpl, resultdic):
    splitcontent=fromtmpl.split('|')
    if splitcontent[0] in ['italbrac']:
        resultdic['italbrac']=splitcontent[1]

def gendernumber(fromtmpl, fromquoted, resultdic):
    # TODO: what if what was found between {{ }} or '' '' was not a gender or a number?
    # That should be in the main code. Maybe that's the only return that should be made
    # return None if all is fine, return what couldn't be processed otherwise
    if fromtmpl in gndrtemplates:
        gender, number=gndrtemplates[fromtmpl]
        if gender: resultdic['gender']=gender
        if number: resultdic['number']=number
        return None
    elif fromquoted in gndrquoted:
        gender, number=gndrquoted[fromquoted]
        if gender: resultdic['gender']=gender
        if number: resultdic['number']=number
        return None
    elif fromtmpl[:2]=='kl':
        # So it's a noun class
        resultdic['nounclass']=fromtmpl
    else:
        return fromtmpl + '&sep&' + fromquoted

jpn_scriptRE = re.compile(ur'''(?xu)
    ^\s*
    (?:（)*
    \s*
    ピンイン
    \s*
    (?::)
    \s*
    (?:'')*
     (?P<jpn_tr>.+?)
    (?:'')*
    (?:）)
    \s*
    (?P<rest>.+)*
    ''')

languageRE = re.compile(ur'''(?xu)
    ^\s*
    (?P<wordforlanguage>language|dil|keel|kieli)
    \s*
    (?P<rest>.+)*
    ''')

rndbrackRE=re.compile(ur'''(?xu)
    ^\s*
    (?P<quotbfr1>'')*
    (?:\()
    \s*
    (?P<lnkopen>\[{2})*
    (?P<quotbfr2>'')*
    \s*
    (?P<betweenrndbrack>[^\)\]]*)          # grab all between ( )
    \s*
    (?P<lnkclose>\]{2})*
    (?P<quotaftr2>'')*
    \s*
    (?:\))
    (?P<quotaftr1>'')*
    \s*
    (?P<rest>.+)*
    ''')

otherlookupsREs=(
        ('rndbrackRE', rndbrackRE),
        ('languageRE', languageRE),
        ('jpn_scriptRE', jpn_scriptRE),
    )

def processRest(rest, context, termdict, endresult,askforhelp):
    if rest.strip() == ';' or rest.strip() == ',':
       return
    if context['wikilang']=='el':
        r=True ; m=re.match(ur'''(?xu)\[(?P<Han>.+?)\]''',rest)
        if m:
            for char in m.group('Han'):
                if unicodescript.script(char)!='Han': r=False
            if r:
                termdict['hanspelling']=m.group('Han')
    resultofREL2={}
    print 'rest:|'+rest+'|'
    if rest in [u'a',u'à'] and context['translang'] in ['spa','por','fra','cat']:
        termdict['term'] += ' ' + rest
        return
    splitrest=rest.split()
    if 'wikilang' in context and context['wikilang']=='tr' and len(splitrest[0])<3:
        splitrest = [u"{{"] + splitrest[0].split() + [u"}}"] + splitrest[1:]
        restToBeTestedForGender = u''.join(splitrest)
    else:
        restToBeTestedForGender=rest
    m=re.match(genderREpart, restToBeTestedForGender)
    if m:
        # apparently this could be a gender, so let's test it further
        res=m.groupdict()
        if not('gendertmplt' in res) or not(res['gendertmplt']):
            res['gendertmplt']=''
        if not('quotgender' in res) or not(res['quotgender']):
            res['quotgender']=''
        newrest=gendernumber(res['gendertmplt'], res['quotgender'],termdict)
        if not newrest:
            print 'Processed as gender:', termdict['gender']
            rest = u''.join(splitrest[1:])
        else:
            wikitemplate(newrest.split('&sep&')[1], termdict)
    m=re.match(foreignlinktoREpart + "(?P<rest>.*)",rest)
    if m:
        gd=m.groupdict() ; print 'foreignlink:', gd
        if 'foreignlink' in gd and gd['foreignlink']==termdict['term']:
            termdict['langcode']=gd['foreignlinkto']
        if 'rest' in gd and gd['rest']:
            processRest(gd['rest'], context, termdict, endresult,askforhelp)
        return
    if rest.find(u'simplificado')!=-1:
        if termdict['reference2definition'] in endresult:
            for er in endresult[termdict['reference2definition']]:
                if cmnsimplify.simplify(er['term']['Hant'])==termdict['term']:
                    er['term']['Hans']=termdict['term']
                    termdict.clear()
                    return
    elif rest.find(u'tradicional')!=-1:
        if termdict['term']:
            if type(termdict['term'])==type(u''):
                termdict['term']={'Hant': termdict['term']}
    elif rest.find(u'H:')!=-1:
        smpl=re.search(ur'\[\[(.+)\]\]',rest).group(1)
        if cmnsimplify.simplify(smpl)==termdict['term']:
            termdict['term']={'Hant': smpl, 'Hans': termdict['term']}
            return
    else:
        REnameOther, resultofREOther = applyREs(rest, otherlookupsREs)
        print 'REnameOther, resultofREOther:' , REnameOther, resultofREOther
        if resultofREOther:
            if 'betweenrndbrack' in resultofREOther and resultofREOther['betweenrndbrack']:
                m=commasepdnumbersRE.search(resultofREOther['betweenrndbrack'])
                if m:
                    # a group of comma separated numbers
                    termdict['reference2definition'] = context['reference2definition'] = resultofREOther['betweenrndbrack']
                    context['ref2deffromtransline'] = True
                else:
                    if askforhelp:
                        print u"(%s) was found on the line. Do you have an idea what it could be? (tr for transcription)" % resultofREOther['betweenrndbrack']
                        if 'userinput' in context and context['userinput']:
                            userinput=context['userinput']
                        else:
                            userinput=mwclient.editor.editline('tr')
                        print 'userinput:',userinput
                        if userinput == 'tr':
                            termdict['tr']=resultofREOther['betweenrndbrack']
                    else:
                        if 'betweenrndbrackets' in termdict and termdict['betweenrndbrackets']:
                            termdict['betweenrndbrackets']+=', '+resultofREOther['betweenrndbrack']
                        else:
                            termdict['betweenrndbrackets']=resultofREOther['betweenrndbrack']
                        if 'lnkopen' in resultofREOther and resultofREOther['lnkopen']:
                            termdict['betweenrndbrackets'] = resultofREOther['lnkopen'] + termdict['betweenrndbrackets']
                        if 'lnkclose' in resultofREOther and resultofREOther['lnkclose']:
                            termdict['betweenrndbrackets'] += resultofREOther['lnkclose']
                        quotbfr=''
                        if 'quotbfr1' in resultofREOther and resultofREOther['quotbfr1']:
                            quotbfr=resultofREOther['quotbfr1']
                        if 'quotbfr2' in resultofREOther and resultofREOther['quotbfr2']:
                            quotbfr=resultofREOther['quotbfr2']
                        if quotbfr:
                            termdict['betweenrndbrackets'] = quotbfr + termdict['betweenrndbrackets']
                        quotaftr=''
                        if 'quotaftr1' in resultofREOther and resultofREOther['quotaftr1']:
                            quotaftr=resultofREOther['quotaftr1']
                        if 'quotaftr2' in resultofREOther and resultofREOther['quotaftr2']:
                            quotaftr=resultofREOther['quotaftr2']
                        if quotaftr:
                            termdict['betweenrndbrackets'] += quotaftr
            elif 'jpn_tr' in resultofREOther and resultofREOther['jpn_tr']:
                termdict['tr']=resultofREOther['jpn_tr']
            elif REnameOther=='languageRE':
                termdict.pop('exists', None)
                termdict['term'] += ' ' + resultofREOther['wordforlanguage']
                #if 'newrest' in resultofREOther and resultofREOther['newrest']:
                #    rest = resultofREOther['newrest']
            # keep going as long as necessary
            if 'rest' in resultofREOther and resultofREOther['rest']:
                processRest(resultofREOther['rest'], context, termdict, endresult,askforhelp)
        else:
            REnameL2, resultofREL2 = applyREs(rest, colonPresentREs)
            print 'REnameL2, resultofREL2:',REnameL2, resultofREL2
            if 'translations' in resultofREL2 and resultofREL2['translations']:
                print termdict['term'], srpCyrlLatnConversion.srCyrillicToLatin(termdict['term']), resultofREL2['translations']
                if srpCyrlLatnConversion.srCyrillicToLatin(termdict['term']) == resultofREL2['translations']:
                    termdict['term']={'Cyrl': termdict['term'], 'Latn': resultofREL2['translations']}
                else:
                    termdict['term'] = termdict['term'] + ' ' + resultofREL2['translations']
    # keep going as long as necessary
    if 'rest' in resultofREL2 and resultofREL2['rest']:
        processRest(resultofREL2['rest'], context, termdict, endresult,askforhelp)

exceptionlangs={
        'zho': 'cmn',
        'zh-tc': 'zh-tw',
        'zh-sc': 'zh-cn',
        }

def addSynonym(endresult, reference2definition, termdict):
    if 'term' in termdict and (type(termdict['term']) == type ({}) or type(termdict['term']) == type (u'') and termdict['term'].strip()) or 'betweenrndbrackets' in termdict and termdict['betweenrndbrackets']:
        # if term is in termdict and its type is a non empty string or if term is a dict
        if reference2definition in endresult:
            intermediate=endresult[reference2definition]
        else:
            intermediate=[]
        intermediate.append(termdict.copy())
        endresult[reference2definition]=intermediate

interwikilinkRE=re.compile(ur'''(xu)
\[\[
(?P<lang>\w+(-\w+)*)
:
(?p<linkto>.+)
''')

headerRE=re.compile(ur'''(?xu)
(?:
(?P<level1>=+)
\s*
(?P<betweenEQ>.+?)
\s*
(?P<level2>=+)
)
|
(?:
(?:\{\{-)
(?P<templated>.+)
(?:-\}\})
)
''')

throwawaytransRE=ur'''(?xui)
(?:
\{\{
(?:
(?P<check>check)*
trans-
)*
(?:top|mid|bottom)
(?:\|(?P<concisedef>.+?))*
\}\}
|
\|-
|
\{\|
|
\|\}
|
(?:<!--)
\s*
(?:
(?:lef|righ)t\scolumn.*
|
jezici\sod\s\w\sdo\s\w
)
\s*
(?:-->)*
)
'''
enwikipediaRE=re.compile(ur'''(?xu)
\{\{wikipedia
(\|dab=(?P<dab>.*?))*
(\|.*?)*
\}\}
''')

class Parser:
    """Class for parsing Wiktionary entries"""
    def wiktionaryPage(self,pagecontent,context):
        '''This function will parse the contents of a Wiktionary page
           and read it into our object structure.
           It returns a list of dictionaries. Each dictionary contains a header object
           and the textual content found under that header. Only relevant content is stored.
           Empty lines and lines to create tables for presentation to the user are taken out.'''

        currentpage=WiktionaryPage(context['wikilang'], context['term'])

        templist = []

        splitcontent=[]
        for line in pagecontent.split('\n'):
            print line
            # Let's get rid of line breaks and extraneous white space
            line=line.strip()
            # Let's start by looking for general stuff, that provides information
            # which needs to be stored at the page level
            m = enwikipediaRE.match(line)
            if m:
                currentpage.addLink('wikipedia')
                continue
            if line.lower().find('[[category:')!=-1:
                category=line.split(':')[1].replace(']','')
                currentpage.addCategory(category)
#                print 'category: ', category
                continue
            m=interwikilinkRE.match(line)
            if m:
                    # This seems to be an interwikilink
                    # If there is a pipe in it, it's not a simple interwikilink
                iwldict=m.groupdict()
                currentpage.addLink(iwldict['lang']+':'+iwldict['linkto'])
                continue
            # store empty lines literally, this is necessary for the blocks we don't parse
            # and will return literally when writing the entry back
            if len(line) <2:
                templist.append(line)
                continue
            m=headerRE.match(line)
            if m:
                # When a new header is encountered, it is necessary to store the information
                # encountered under the previous header.
                if templist:
                    tempdictstructure={'text': templist,
                                       'header': header,
                                       'context': copy.copy(context),
                                      }
                    templist=[] # served its purpose, clear for the next section
                    splitcontent.append(tempdictstructure)
#                print "splitcontent: ",splitcontent,"\n\n"
                header=Header(m)
#                print "Header parsed:",header.level, header.header, header.type, header.contents
                if header.type==u'lang':
                    context['lang']=header.contents
                if header.type==u'pos':
                    if not(context.has_key('lang')):
                        # This entry lacks a language indicator,
                        # so we assume it is the same language as the Wiktionary we're working on
                        context['lang']=currentpage.wikilang
                    context['pos']=header.contents

            else:
                # It's not a header line, so we add it to a temporary list
                # containing content lines
                if header.contents==u'trans':
                    # Under the translations header there is quite a bit of stuff
                    # that's only needed for formatting, we can just skip that* {{ttbc|West Frisian}}: {{t-|fy|Flaanderen}}

                    # and go on processing the next line
                    m=throwawaytransRE.search(line)
                    if m:
                        mdict=m.groupdict()
                        if 'check' in mdict and mdict['check']:
                            # TODO context[''] needs to be adapted
                            pass
                        if 'concisedef' in mdict and mdict['concisedef']:
                            context['concisedef'] = mdict['concisedef']
                        continue
                    else:
                        templist.append(line)

            # Let's not forget the last block that was encountered
            if templist:
                tempdictstructure={'text': templist,
                                   'header': header,
                                   'context': copy.copy(context),
                                  }
                splitcontent.append(tempdictstructure)

        """
        At this point we have a collection of contentblock objects that represent the page split
        on the headers. Now it's time to pass these blocks to functions that are
        dedicated to parsing them.
        """

    def definitionssection(self):

        # make sure variables are initialized
        gender = sample = plural = diminutive = label = definition = ''
        examples = []
        for contentblock in splitcontent:
            # print "contentblock:",contentblock
            # print contentblock['header']
            # Now we parse the text blocks.
            # Let's start by describing what to do with content found under the POS header
            if contentblock['header'].type==u'pos':
                flag=False
                for line in contentblock['text']:
                # print line
                    if line[:3] == "'''":
                        # This seems to be an ''inflection line''
                        # It can be built up like this: '''sample'''
                        # Or more elaborately like this: '''staal''' ''n'' (Plural: [[stalen]],    diminutive: [[staaltje]])
                        # Or like this: '''staal''' {{n}} (Plural: [[stalen]], diminutive: [[staaltje]])
                        # Or like this: {{en-infl-reg-other-e|ic|e}} (but then we won't recognize it here TODO)
                        # Or even like this: {{en-noun|ice}}  and a lot of parameters,
                        #       all dependent on the language it's for

                        # Let's first get rid of parentheses and brackets:
                        line=line.replace('(','').replace(')','').replace('[','').replace(']','')
                        # Then we can split it on the spaces
                        for part in line.split(' '):
#                            print part[:3], "Flag:", flag
                            if flag==False and part[:3] == "'''":
                                sample=part.replace("'",'').strip()
#                                print 'Sample:', sample
                                # OK, so this should be an example of the term we are describing
                                # maybe it is necessary to compare it to the title of the page
                            if sample:
                                maybegender=part.replace("'",'').replace("}",'').replace("{",'').lower()
                                if maybegender=='m':
                                   gender='m'
                                if maybegender=='f':
                                   gender='f'
                                if maybegender=='n':
                                    gender='n'
                                if maybegender=='c':
                                    gender='c'
#                            print 'Gender: ',gender
                            if part.replace("'",'')[:2].lower()=='pl':
                                flag='plural'
                            if part.replace("'",'')[:3].lower()=='dim':
                                flag='diminutive'
                            if flag=='plural':
                                plural=part.replace(',','').replace("'",'').strip()
                            # print 'Plural: ',plural
                            if flag=='diminutive':
                                diminutive=part.replace(',','').replace("'",'').strip()
                            # print 'Diminutive: ',diminutive
                    if line[:2] == "{{": # TODO: there is more than one kind of template nowadays
                        # Let's get rid of accolades:
                        line=line.replace('{','').replace('}','')
                        # Then we can split it on the dashes
                        parts=line.split('-')
                        lang=parts[0]
                        what=parts[1]
                        mode=parts[2]
                        other=parts[3]
                        infl=parts[4].split('|')
                    if sample:
                        # We can create a Term object
                        # TODO which term object depends on the POS
                        # print "contentblock['context'].['lang']", contentblock['context']['lang']
                        if contentblock['header'].contents=='noun':
                            theterm=Noun(lang=contentblock['context']['lang'], term=sample, gender=gender)
                        if contentblock['header'].contents=='verb':
                            theterm=Verb(lang=contentblock['context']['lang'], term=sample)
                        sample=''
                        # raw_input("")
                    if line[:1].isdigit():
                        # Somebody didn't like automatic numbering and added static numbers
                        # of their own. Let's get rid of them
                        while line[:1].isdigit():
                            line=line[1:]
                        # and replace them with a hash, so the following if block picks it up
                        line = '#' + line
                    if line[:1] == "#":
                        """This probably is a definition
                            If we already had a definition we need to store that one's data
                            in a Meaning object and make that Meaning object part of the Page object"""
                        if definition:
                            self.storeDefinition(term=theterm,definition=definition, label=label, examples=examples)
                            # sample
                            # plural and diminutive belong with the Noun object
                            # comparative and superlative belong with the Adjective object
                            # conjugations belong with the Verb object

                            # Reset everything for the next round
                            sample = plural = diminutive = label = definition = ''
                            examples = []
                        '''
                        pos=line.find('<!--')
                        if pos < 4:
                            # A html comment at the beginning of the line means this entry already has disambiguation labels, great
                            pos2=line.find('-->')
                            label=line[pos+4:pos2]
                            definition=line[pos2+1:]
                            # print 'label:',label
                        else:
                            definition=line[1:]
                            # print "Definition: ", definition
                        '''
                    if line[:2] == "#:":
                        # This is an example for the preceding definition
                        example=line[2:]
                        # print "Example:", example
                        examples.add(example)
            # Make sure we store the last definition
            if definition:
                self.storeDefinition(term=theterm,definition=definition, label=label, examples=examples)

    def translationsSection(self, contentblock):
        ''' a contentblock is built up as follows:
        {'text': templist,
          'header': header,
          'context': context),
        }
        where text is a list containing all the literal lines of the translations section
        header should always be 'trans'
        and context is a dictionary containing:

        {'lang': code,
          'pos': 'noun', 'verb', 'adj'
        }

        Technically these are the translations for several meanings,
        so I'm not entirely sure this method belongs here.
        '''

    def translationForOneMeaning(self):
        pass

    def singleTranslationLine(self, line, context=None, askforhelp=False):
        """
        Output: context adapted with the code for the language

        endresult: A list with dict objects for several meanings, that occur together on the same line on some wiktionaries
        synonyms: The endresult list contains dictionary objects that are nearly synonyms, they're all translations for the same definition, at least, keyed on either reference2definition or defnumber
        termdict: a dictionary containing all that can be said about the term described in it

        Input: one line of Unicode text:
        * Languagename: [[Translation1]] {{g}}, [[Translation2]] ''g'', ...
        * [[Languagename]]: {{t|iso|Translation1}},{{t+|Translation2,|g}}, {{t-|Translation3|sc=Grek|tr=Translation3|cs=Translation3}} (translation comment)
        *: {{iso}}:  {{trad|Translation1}}

        context is a dictionary that contains the following keys:
        header; normally this will always be trans
        wikilang
        translang; (optional) language code of the previous line
        reference2definition; (optional) on en.wikt there is a concise definition that applies to the block this translations line belongs to
                            for entries that don't have defnumbers, this will be used in the dictionary containing the results
        """

        print 'line:', line
        if not(context):
            context = {}
        line=htmlcommentRE.sub(htmlcomment_function, line)
        if not(line.strip()):
            # nothing left after replacing the html comments?
            # Can't do more than returning the context
            print
            return context, None

        line=htmlentityRE.sub(htmlentity_function, line)

        if not('header' in context):
            context['header']='trans'
        if 'reference2definition' in context:
            # later on we want to make different decisions based on whether the reference2definition was passed through
            # from the outside, or whether it was found on the translations line
            context['ref2deffromtransline']=False

        line=line.replace(u'：',u':')
        if line.strip()[-1:]==':':
            # lines ending with : are generally followed by indented lines that contain the actual information.
            # In order to avoid having them being split, leaving us with an empty translations part,
            # it's better to remove the :
            line = line.strip()[:-1]

        # Prepare our data a bit, to make it easier to work with

        # We are going to split on : ; and ,
        # we have to 'protect' the : ; and , that are inbetween ( ), [ ] and { } though
        line=searchEmbeddedRE.sub(comma_function, searchEmbeddedRE.sub(colon_function, searchEmbeddedRE.sub(semicolon_function, line)))

        if line.find("v1}} {{")!=-1:
            # some languages use flags (lt.wikt) instead of language names, let's normalise that
            line=line.replace("v1}} {{", "}}: {{")
        elif line.find("v1}}")!=-1:
            line=line.replace("v1}}", "}}")
        elif line.find("1|")!=-1:
            # for hu.wikt
            m=re.search('\{\{\w+?1\|',line)
            if m:
                line=line.replace("1|", "|")
        # normalize sq.wikt format where - is used between the langname and the translations
        m=sqwiktRE.match(line)
        if m:
            print 'preprocessing, replacing - by :'
            line=sqwiktRE.sub(r'\1:\2',line)
            print line

        #on de.wikt: *{{hy}}: [1,2,3,6] {{Ü|hy|ջուր}} (ostarm.: dschur), (westarm.: tschur)
        # needs to become: *{{hy}}: [1,2,3,6] {{Ü|hy|ջուր}} (ostarm.: dschur) (westarm.: tschur)
        line=re.sub(ur'(?xu)(.*\(.+?\))\s*,\s*(\(.+?\))',r'\1 \2',line)

        # Now it should be possible to split on the ':'
        colonpos=line[2:].find(':') # this skips the first two positions, it's not the : in those positions that we're interested in

        code=languagepart=''
        if colonpos==-1:
            # no colon, this means we have a line with only one template containing both the language and the translation(s)
            # we escaped the embedded colons, time to restore them
            line=line.replace('&colon&', ':')

            # A series of regexes is applied, until one matches
            REname, resultofRE=applyREs(line, noColonPresentREs)
            if resultofRE:
                if REname=='iso23RE':
                    langcode=resultofRE['langcode']
                    context['translang']=iso639.MW2iso(langcode)
                    endresult={} ; intermediate=[]
                    if context['wikilang']=='hu' and context['translang']=='cmn':
                        # *{{zh1|西班牙语|Xībānyá-yǔ}}
                        tr=resultofRE['translations'].split('|')[1]
                        resultofRE['translations']=resultofRE['translations'].split('|')[0]
                    else:
                        tr=''
                    for translation in resultofRE['translations'].split('|'):
                        if tr:
                            termdict={'langcode': langcode, 'term': translation, 'tr': tr}
                        else:
                            termdict={'langcode': langcode, 'term': translation}
                        if 'rest' in resultofRE and resultofRE['rest']:
                            processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                        intermediate.append(termdict)
                    if not('reference2definition' in context):
                        context['reference2definition']='unknown'
                        context['ref2deffromtransline']=True
                    endresult[context['reference2definition']]=intermediate
                    print
                    return context, endresult
                elif REname=='tradvertRE':
                    code=iso639.MW2iso(resultofRE['langcode'])
                    if resultofRE['templname']==u'П':
                        context['reference2definition']=resultofRE['translations'][0]
                        context['ref2deffromtransline']=True
                        translations=resultofRE['translations']
                        pos=translations.find('|')
                        resultofRE['translations']=translations=translations[pos+1:]
                        #termdict={'reference2definition':  context['reference2definition']}
                    if resultofRE['templname']==u'aistr' or resultofRE['templname']==u'overs':
                        translations=line.replace('&colon&', ':')
                        resultofRE=None
                    else:
                        translations=resultofRE['translations']
                elif REname=='templatewithoutparamsRE':
                    if resultofRE['langname'] in exceptionlangs:
                        context['translang']=exceptionlangs[resultofRE['langname']]
                    else:
                        context['translang']=iso639.MW2iso(resultofRE['langname'])
                    print
                    return context, None
                elif REname=='partOfTemplateRE':
                    print 'partOfTemplateRE matched, preprocessing'
                    code=iso639.MW2iso(resultofRE['langcode'].lower())
                    translations=resultofRE['translations']
                    resultofRE=None
                else:
                    languagepart=line ; translations = '' ; resultofRE=None
            else:
                languagepart=line ; translations = ''
        else:
            # line with a colon in it, the normal case
            languagepart=line[:colonpos+2].strip()
            translations=line[colonpos+3:].strip().replace('&colon&', ':')
            resultofRE=None

        # *** Processing of the language part. ***

        if not(languagepart.strip()) and not code:
            print
            return context, None
        scriptname=False
        langname=u'' ; ttbc = False
        if not(code):
            # It could be that tradvertRE matched higher up, in which case we would already know the ISO language code
            langpartREs=(
                    ('templatewithoutparamsRE', templatewithoutparamsRE),
                    ('linkedTermRE', linkedTermRE),
                )
            if context['wikilang']=='ko':
                m=re.search(ur'''(?xu)(?:\*)*(?:\s)*(?P<KoreanLangname>\w+)\((?P<langcode>\w+)\)''', languagepart)
                if m:
                    code=iso639.MW2iso(m.group('langcode'))
                langname=None
            else:
                REnameLP, resultofRElp=applyREs(languagepart, langpartREs)
                if REnameLP=='templatewithoutparamsRE':
                    if resultofRElp['langname'] in exceptionlangs:
                        # some Wiktionaries started using some odd codes for Chinese
                        code=exceptionlangs[resultofRElp['langname']]
                    elif context['wikilang'] in ("vi", "nl", "ro"):
                        # case for Wiktionaries that use iso639-3
                        code=resultofRElp['langname']
                    elif 'ttbc' in resultofRElp and resultofRElp['ttbc']:
                        langname=resultofRElp['langname']
                        ttbc=True
                    else:
                        # normal case, conversion to iso639-3 still required
                        code=iso639.MW2iso(resultofRElp['langname'])
                elif REnameLP=='linkedTermRE':
                    langname=resultofRElp['translations']
                else:
                    langname=striplangnamepartRE.sub(u'', languagepart).strip()
                    while langname[-2:]=='--':
                        langname=langname[:-1]
            if langname:
                try:
                    code=iso639.langname2iso(langname)
                except iso639.UnknownLanguage:
                    try:
                        code=iso15924.scriptname2iso(langname)
                        scriptname=code
                    except iso15924.UnknownScript:
                        pass
        print 'code:', code,

        if 'translang' in context and context['translang'] in ['arc','kas','kur','srp']:
            if code == 'heb':
            # Hebrew is a special case in that it can be both a language name and the name for a script
                scriptname='Hebr' ; code = context['translang']
            if code == 'syr':
            # Syriac is a special case in that it can be both a language name and the name for a script
                scriptname='Syrc' ; code = context['translang']
            if code == 'ara':
            # Arabic is a special case in that it can be both a language name and the name for a script
                scriptname='Arab' ; code = context['translang']
            if code in ['Deva', 'Latn', 'Ku-arab', 'Cyrl']:
            # For Devanagari version of Kashmiri, Kurmancî makes the code become Latin, Soranî makes it become Ku-arab
                code = context['translang']
        if scriptname:
            print 'scriptname:', iso15924.iso2scriptname(scriptname, u'en')
        else:
            if type(code)==type([]):
                # There are several possibilities for this language name
                # How to determine the most likely one?
                # What is done here is too specific, needs improvement
                print
                if 'translang' in context and context['translang']:
                    if context['translang'] == 'ara':
                        poss=['arz']
                        for p in poss:
                            if p in code: code = p ; break
                    elif context['translang'] == 'ell':
                        poss=['grc']
                        for p in poss:
                            if p in code: code = p ; break
                    elif context['translang'] == 'nde':
                        poss=['nde','nbl']
                        for p in poss:
                            if p in code: code = p ; break
                elif 'egy' in code:
                    code='egy'

            print 'langname:', iso639.iso2langname(code, u'en')
        context['translang']=code

        # *** Processing of the translations part. ***

        endresult={} ; reference2definition=''
        translations=translations.replace(';', ',')
        translations=translations.replace('&semicolon&', ';')
        splittranslations=translations.split(',')
        # hi.wikt puts the defnumbers after the terms and they apply to all the terms up to the one that has them
        if context['wikilang']=='hi': splittranslations.reverse()
        for translation in splittranslations:
            # we escaped the embedded commas, time to restore them
            translation=translation.replace('&comma&', ',')

            if not(resultofRE):
                # There might already be a resultofRE from looking at a line without a : in it
                REname, resultofRE=applyREs(translation, colonPresentREs)

            if resultofRE:
                if 'comment' in resultofRE and not 'translations' in resultofRE:
                    resultofRE['translations']=''
                print REname, 'matched', printREresult(resultofRE)
                if ttbc:
                    termdict={'confidence': 'ttbc'}
                else:
                    termdict={}
                if scriptname and scriptname!='Latn':
                    termdict['sc']=scriptname
                if 'translations' in resultofRE:
                    if 'de_comment' in resultofRE and resultofRE['de_comment']:
                        termdict['comment']=resultofRE['de_comment']
                    if 'restoftempl' in resultofRE and resultofRE['restoftempl']:
                        print "resultofRE['restoftempl']:", resultofRE['restoftempl']
                        for r in resultofRE['restoftempl'].split('|'):
                            print 'r:', r
                            r4=r[:4] ; r3=r4[:3] ; r2=r3[:2]
                            if r4 in [u'alt=']:
                                termdict[r3]=r[4:]
                            if r3 in [u'sc=', u'tr=', u'xs=']:
                                termdict[r2]=r[3:]
                            else:
                                if r2==u'g=':
                                    r=r[2:]
                                rc=gendernumber(r, '', termdict)
                                if rc:
                                    # This function only returns something when it couldn't process the input as a gender or a number
                                    # otherwise it simply updates termdict appropriately
                                    print 'This is not a gender or a number:'
                                    for i in rc.split('&sep&'):
                                        print i
                    if REname=='t_image_templateRE':
                        termdict['image']=resultofRE['translations']
                        if 'px' in resultofRE and resultofRE['px']:
                            termdict['px']=resultofRE['px']
                        if 'linkto' in resultofRE and resultofRE['linkto']:
                            termdict['linkto']=resultofRE['linkto']
                    if 'langcode' in resultofRE and resultofRE['langcode'] and not(context['wikilang']=='he'):
                        # he.wikt uses full language names in templates. We don't need those
                        termdict['langcode']=resultofRE['langcode']
                    elif 'foreignlinkto' in resultofRE and resultofRE['foreignlinkto']:
                        termdict['langcode']=resultofRE['foreignlinkto']
                    if 'comment' in resultofRE and resultofRE['comment']:
                        termdict['comment']=resultofRE['comment']
                    if 'nahtranscript' in resultofRE and resultofRE['nahtranscript']:
                        termdict['tr']=resultofRE['nahtranscript']
                    if 'gendertmplt' in resultofRE and resultofRE['gendertmplt'] or 'quotgender' in resultofRE and resultofRE['quotgender']:
                        if not('gendertmplt' in resultofRE) or not(resultofRE['gendertmplt']):
                            resultofRE['gendertmplt']=''
                        if not('quotgender' in resultofRE) or not(resultofRE['quotgender']):
                            resultofRE['quotgender']=''
                        resultofRE['quotgender'] = resultofRE['quotgender'].replace('(','')
                        rc=gendernumber(resultofRE['gendertmplt'], resultofRE['quotgender'], termdict)
                        if rc:
                            # If this function has a result other than updating termdict appropriately
                            # This means we are getting something back that couldn't be processed as a gender or a number
                            print 'This is not a gender or a number:'
                            for i in rc.split('&sep&'):
                                print i
                            wikitemplate(rc.split('&sep&')[0], termdict)
                    if resultofRE['translations'].find('|')!=-1:
                        # found | in 'translations
                        if not('reference2definition' in context):
                            if 'defnumber' in resultofRE and resultofRE['defnumber'] :
                                context['reference2definition'] = resultofRE['defnumber']
                                context['ref2deffromtransline']=True
                            else:
                                context['reference2definition']='unknown'
                        if 'templname' in resultofRE:
                            if resultofRE['templname'] == u'Üxx':
                                termdict['tr'], termdict['term'] = resultofRE['translations'].split('|')
                            if resultofRE['templname'] in ['vertxx','tradxx']:
                                termdict['tr'], termdict['term'] = resultofRE['translations'].split('|')
                                if 'rest' in resultofRE and resultofRE['rest']:
                                    processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                                addSynonym(endresult, context['reference2definition'], termdict)
                            elif resultofRE['templname']=='vertxx3':
                                termdict['term'], termdict['tr'] = resultofRE['translations'].split('|')
                                if 'rest' in resultofRE and resultofRE['rest']:
                                    processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                                addSynonym(endresult, context['reference2definition'], termdict)
                            elif resultofRE['templname']=='xlatio':
                                termdict['term'], latingender = resultofRE['translations'].split('|')
                                rc=gendernumber('', latingender.replace("'",''), termdict)
                                if rc:
                                    # If this function has a result other than updating termdict appropriately
                                    # This means we are getting something back that couldn't be processed as a gender or a number
                                    print 'This is not a gender or a number:'
                                    for i in rc.split('&sep&'):
                                        print i
                                if 'rest' in resultofRE and resultofRE['rest']:
                                    processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                                addSynonym(endresult, context['reference2definition'], termdict)
                            elif resultofRE['templname']=='trad' and 'wikilang' in context and context['wikilang']=='yi':
                                termdict['term'], yigender = resultofRE['translations'].split('|')
                                rc=gendernumber( yigender.replace("{",'').replace("}",''), '', termdict)
                                if rc:
                                    # If this function has a result other than updating termdict appropriately
                                    # This means we are getting something back that couldn't be processed as a gender or a number
                                    print 'This is not a gender or a number:'
                                    for i in rc.split('&sep&'):
                                        print i
                                    wikitemplate(rc.split('&sep&')[1], termdict)
                                if 'rest' in resultofRE and resultofRE['rest']:
                                    processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                                addSynonym(endresult, context['reference2definition'], termdict)
                            elif resultofRE['templname']==u'þýðing-xx':
                                termdict['tr'], termdict['term'], termdict['reference2definition'] = resultofRE['translations'].split('|')
                                context['reference2definition'] = termdict['reference2definition']
                                if 'rest' in resultofRE and resultofRE['rest']:
                                    processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                                addSynonym(endresult, context['reference2definition'], termdict)
                            elif REname=='scriptnameRE':
                                parts=resultofRE['translations'].split('|')
                                if 'rest' in resultofRE and resultofRE['rest']:
                                    processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                                if cmnsimplify.simplify(parts[0])==parts[1]:
                                    termdict['term']={'Hant': parts[0], 'Hans': parts[1]}
                                    addSynonym(endresult, context['reference2definition'], termdict)
                            else:
                                # not vertxx nor vertxx3 nor tradxx nor xlatio nor þýðing-xx
                                termdicts=[]
                                if resultofRE['templname'] != u'Üxx':
                                    translationslist=resultofRE['translations'].split('|')
                                    m=commasepdnumbersRE.search(translationslist[-1])
                                    if m:
                                        # does the last item contain comma separated numbers?
                                        defnumbers=translationslist.pop() # take it off
                                        context['reference2definition']=u''
                                        for dn in defnumbers.split(','):
                                            if context['reference2definition']: context['reference2definition']+= ',' +  dn.strip()
                                            else: context['reference2definition']=dn.strip()
                                        context['ref2deffromtransline']=True
                                        termdict['reference2definition'] = context['reference2definition']
                                else:
                                    translationslist=[termdict['term']]
                                    if 'ref2deffromtransline' in context and context['ref2deffromtransline']:
                                        if 'defnumberssqrbr' in resultofRE and resultofRE['defnumberssqrbr'] and resultofRE['defnumberssqrbr']!=context['reference2definition']:
                                            context['reference2definition']=resultofRE['defnumberssqrbr']
                                        termdict['reference2definition'] = context['reference2definition']
                                    else:
                                        termdict['reference2definition'] = resultofRE['defnumberssqrbr']
                                for translation in translationslist:
                                    termdict['term'] = translation
                                    if 'rest' in resultofRE and resultofRE['rest']:
                                        processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                                    if 'defnumbersrndbr' in resultofRE and resultofRE['defnumbersrndbr']:
                                        context['reference2definition']=resultofRE['defnumbersrndbr']
                                        context['ref2deffromtransline']=True
                                    elif 'defnumberssqrbr' in resultofRE and resultofRE['defnumberssqrbr']:
                                        resultofRE['defnumberssqrbr']=resultofRE['defnumberssqrbr'].replace('&comma&',',')
                                        context['reference2definition']=resultofRE['defnumberssqrbr']
                                        context['ref2deffromtransline']=True
                                    for ref2def in context['reference2definition'].split(','):
                                        addSynonym(endresult, ref2def, termdict.copy())
                    else:
                        # didn't find | in resultofRE['translations']
                        termdict['term']= resultofRE['translations']
                        if 'prefix' in resultofRE and resultofRE['prefix']: termdict['term']=resultofRE['prefix'] + termdict['term']
                        if 'suffix' in resultofRE and resultofRE['suffix']: termdict['term'] += resultofRE['suffix']
                        if 'exists' in resultofRE and resultofRE['exists'] in [u'+', u'-', u'ø']:
                            termdict['exists']=resultofRE['exists']
                        if 'hi_gu_gender' in resultofRE and resultofRE['hi_gu_gender']:
                            rc=gendernumber('', resultofRE['hi_gu_gender'].strip(), termdict)
                            if rc:
                                # If this function has a result other than updating termdict appropriately
                                # This means we are getting something back that couldn't be processed as a gender or a number
                                print 'This Hindi/Gujarati gender is not recognised as a gender or a number:',
                                for i in rc.split('&sep&'):
                                    print i,
                                print
                        if 'displayed' in resultofRE and resultofRE['displayed']:
                            if 'linkto' in resultofRE and resultofRE['linkto']:
                                termdict['langcode']=resultofRE['linkto']
                            else:
                                termdict['displayed']=resultofRE['displayed']
                        if 'section' in resultofRE and resultofRE['section']:
                            termdict['section']=resultofRE['section']
                        m=re.search(ur'(?u)(?P<traditional>.+?)\]{2},\s\[{2}(?P<simplified>.+)$', termdict['term'])
                        if m:
                            rc=m.groupdict()
                            if cmnsimplify.simplify(rc['traditional'])==rc['simplified']:
                                termdict['term']={'Hant': rc['traditional'], 'Hans': rc['simplified']}
                        if 'rest' in resultofRE and resultofRE['rest']:
                            processRest(resultofRE['rest'], context, termdict, endresult,askforhelp)
                        print 'context:', context
                        defnumberslist=[]
                        if 'defnumber' in resultofRE and resultofRE['defnumber'] :
                            termdict['reference2definition'] = resultofRE['defnumber']
                            defnumberslist.append(resultofRE['defnumber'])
                        elif 'defnumbersrndbr' in resultofRE and resultofRE['defnumbersrndbr'] :
                            for i in resultofRE['defnumbersrndbr'] .split('-'):
                                m=re.search(ur'(?u)(?P<number>\d+(\.\d+)*)', i)
                                if m:
                                    termdict['reference2definition'] = resultofRE['defnumbersrndbr']
                                    defnumberslist.append(m.group('number'))
                                else:
                                    defnumberslist.append(context['reference2definition'])
                        elif 'defnumberssqrbr' in resultofRE and resultofRE['defnumberssqrbr'] :
                            resultofRE['defnumberssqrbr']=resultofRE['defnumberssqrbr'].replace('&comma&',',')
                            termdict['reference2definition'] = resultofRE['defnumberssqrbr']
                            # now the 1-3 references need to be unpacked to 1,2,3
                            for i in resultofRE['defnumberssqrbr'] .split(','):
                                m=re.search('''(?P<bottom>\d)-(?P<top>\d)*''',i)
                                if m:
                                    topbottomdict=m.groupdict()
                                    if 'top' in topbottomdict and topbottomdict['top']:
                                        for j in range(int(topbottomdict['bottom']),int(topbottomdict['top'])+1):
                                            # this indicates a range on de.wikt
                                            defnumberslist.append(unicode(j))
                                    else:
                                        defnumberslist.append(unicode(topbottomdict['bottom']))
                                elif i.strip()=='?':
                                    defnumberslist.append('?')
                                elif i.strip()=='...':
                                    pass # defnumberslist.append('...')
                                else:
                                    defnumberslist.append(unicode(int(i)))
                        elif 'defnumber3quot' in resultofRE and resultofRE['defnumber3quot'] :
                            termdict['reference2definition'] = resultofRE['defnumber3quot']
                            for i in resultofRE['defnumber3quot'] .split(','):
                                m=re.search(ur'(?u)(?P<number>\d+)', i)
                                defnumberslist.append(m.group('number'))
                        elif 'defnumbersOromo' in resultofRE and resultofRE['defnumbersOromo'] :
                            termdict['reference2definition'] = resultofRE['defnumbersOromo']
                            for i in resultofRE['defnumbersOromo'] .split(','):
                                m=re.search(ur'(?u)(?P<number>\d+(\.\d+)*)', i)
                                defnumberslist.append(m.group('number'))
                        elif 'reference2definition' in context:
                            if context['ref2deffromtransline']:
                                termdict['reference2definition'] = context['reference2definition']
                            for dn in context['reference2definition'].split(','):
                                newstring=u''
                                for char in unicode(dn):
                                    try:
                                        # try to convert numeric digits in foreign scripts to their value
                                        char=unicodedata.decimal(char)
                                    except ValueError:
                                        # if it can't be converted, it was not a decimal in any script
                                        # so nothing needs to happen to it
                                        pass
                                    newstring+=unicode(char)
                                defnumberslist.append(newstring)
                        elif 'reference2definition' in termdict:
                            for dn in termdict['reference2definition'].split(','):
                                defnumberslist.append(unicode(unicodedata.decimal(dn)))
                        else:
                            # no reference2definition in context and no defnumber(s(rndbr|sqrbr)) in resultofRE
                            defnumberslist.append('unknown')
                        if 'reference2definition' in termdict:
                            context['reference2definition'] = termdict['reference2definition'] = termdict['reference2definition'].replace('&comma&', ',')
                            context['ref2deffromtransline']=True

                        for defnumber in defnumberslist:
                            addSynonym(endresult, defnumber, termdict)
                else:
                    # no 'translations' group? Major trouble, all REs should return 'translations'
                    return context, None
            else:
                print 'None of the REs matched!', REname
                termdict={}
                processRest(translation, context, termdict, endresult, askforhelp)
                if 'reference2definition' in context and context['reference2definition']:
                    reference2definition=context['reference2definition']
                else:
                    reference2definition='unknown'
                addSynonym(endresult, reference2definition, termdict)
            resultofRE=None

        print
        if context['wikilang']=='hi':
            # we processed the line backwards, so the resulting lists are also in reverse order
            for ref2def in endresult:
                endresult[ref2def].reverse()

        if endresult:
            return context, endresult
        else:
            return context, None

def temp():
    """
    apage = WiktionaryPage('nl',u'iemand')
#    print 'Wiktionary language: %s'%apage.wikilang
#    print 'Wiktionary apage: %s'%apage.term
#    print
    aword = Noun('nl',u'iemand')
#    print 'Noun: %s'%aword.term
    aword.setGender('m')
#    print 'Gender: %s'%aword.gender
    frtrans = Noun('fr',u"quelqu'un")
    frtrans.setGender('m')
    entrans1 = Noun('en',u'somebody')
    entrans2 = Noun('en',u'someone')
#    print 'frtrans: %s'%frtrans

    ameaning = Meaning(aword, definition=u'een persoon')
    ameaning.addTranslation(frtrans)
#    print ameaning.translations
    ameaning.addTranslation(entrans1)
#    print ameaning.translations
    ameaning.addTranslation(entrans2)
#    print ameaning.translations
    ameaning.addTranslation(aword) # This is for testing whether the order of the translations is correct

    anentry = Entry('en')
    anentry.addMeaning(ameaning)

    apage.addEntry(anentry)

    print
    t=apage.wikiWrap()
    print t
    apage.wikilang = 'en'
    print
    t=apage.wikiWrap()
    print t
    """
    apage = WiktionaryPage('nl',u'Italiaanse')
    aword = Noun('nl',u'Italiaanse','f')
    FemalePersonFromItalymeaning = Meaning(aword,definition = u'vrouwelijke persoon die uit [[Italië]] komt', label=u'NFemalePersonFromItaly', reference2definition=u'vrouwelijke persoon uit Italië',examples=['Die vrouw is een Italiaanse'])

#    {{-rel-}}
#    * [[Italiaan]]
    detrans = Noun('de',u'Italienerin','f')
    entrans = Noun('en',u'Italian')
    frtrans = Noun('fr',u'Italienne','f')
    ittrans = Noun('it',u'italiana','f')

    FemalePersonFromItalymeaning.addTranslations(detrans, entrans, frtrans, ittrans)

    Italiaanseentry = Entry('nl')
    Italiaanseentry.addMeaning(FemalePersonFromItalymeaning)

    apage.addEntry(Italiaanseentry)


    aword = Adjective('nl',u'Italiaanse')
    asynonym = Adjective('nl',u'Italiaans')
    FromItalymeaning = Meaning(aword, definition = u'uit Italië afkomstig', synonyms=[asynonym], label=u'AdjFromItaly', reference2definition=u'uit/van Italië',examples=['De Italiaanse mode'])
    RelatedToItalianLanguagemeaning = Meaning(aword, definition = u'gerelateerd aan de Italiaanse taal', synonyms=[asynonym], label=u'AdjRelatedToItalianLanguage', reference2definition=u'm.b.t. de Italiaanse taal',examples=['De Italiaanse werkwoorden','De Italiaanse vervoeging'])

    detrans = Adjective('de',u'italienisches','n')
    detrans2 = Adjective('de',u'italienischer','m')
    detrans3 = Adjective('de',u'italienische','f')
    entrans = Adjective('en',u'Italian')
    frtrans = Adjective('fr',u'italien','m')
    frtrans2 = Adjective('fr',u'italienne','f')
    ittrans = Adjective('it',u'italiano','m')
    ittrans2 = Adjective('it',u'italiana','f')

    FromItalymeaning.addTranslations(detrans, detrans2, detrans3, entrans)
    FromItalymeaning.addTranslations(frtrans2, frtrans, ittrans, ittrans2)

    RelatedToItalianLanguagemeaning.addTranslations(detrans, detrans2, detrans3, entrans)
    RelatedToItalianLanguagemeaning.addTranslations(frtrans2, frtrans, ittrans, ittrans2)

    Italiaanseentry.addMeaning(FromItalymeaning)
    Italiaanseentry.addMeaning(RelatedToItalianLanguagemeaning)

    apage.addEntry(Italiaanseentry)

    print
    u=apage.wikiWrap()
    print repr(u)
    raw_input()

    apage.setWikilang('en')
    print repr(apage.wikiWrap())
    raw_input()

    """{{-nl-}}
    {{-noun-}}
    '''Italiaanse''' {{f}}; vrouwelijke persoon die uit [[Italië]] komt

    {{-rel-}}
    * [[Italiaan]]

    {{-trans-}}
    *{{de}}: [[Italienierin]] {{f}}
    *{{en}}: [[Italian]]
    *{{fr}}: [[Italienne]] {{f}}
    *{{it}}: [[italiana]] {{f}}

    {{-adj-}}
    #'''Italiaanse'''; uit Italië afkomstig
    #'''Italiaanse'''; gerelateerd aan de Italiaanse taal

    {{-syn-}}
    * [[Italiaans]]"""

def run():
    ea = EditArticle(['-p', 'Andorra', '-e', 'bluefish'])
    ea.initialise_data()
    try:
        ofn, old = ea.fetchpage()

        parseWikiPage(ofn)
        new = ea.edit(ofn)
    except wikipedia.LockedPage:
        sys.exit("You do not have permission to edit %s" % self.pagelink.sectionFreeTitle())
    if old != new:
        new = ea.repair(new)
        ea.showdiff(old, new)
        comment = ea.getcomment()
        try:
            ea.pagelink.put(new, comment=comment, minorEdit=False, watchArticle=ea.options.watch, anon=ea.options.anonymous)
        except wikipedia.EditConflict:
            ea.handle_edit_conflict()
    else:
        wikipedia.output(u"Nothing changed")


def harvestEnWikipediaInterwikiLinks(wiktpage, workterm=u'Iron'):
    for wikilang, term in mwclient.Site('en.wikipedia.org').pages[workterm].langlinks ():
        if wikilang not in [u'simple',u'zh-yue',u'sh',u'be-x-old']:
            """ We are not interested in Simple English, Cantonese, Serbo-Croatian, or Old Byelarussian """
            uterm = uncapitalize(term).split(u'(')[0].strip() # We only want the first part of the term before the parenthesis
            if wikilang == 'fr':
                """TODO If the French word gender is not known yet and it's not possible to obtain it from fr.wikt
                   it's possible to load the wikipedia page and go hunting for articles
                   la chose, le truc, du fromage, toutes les choses, tous les trucs

                   in case of words that start with a 'h' or a vowel, like l'hélium this doesn't help,
                   tout l'hélium does indicate the gender (f would have been with toute)

                   If that doesn't work either, we have to use something like qui est, qui sont and look at the adjective/past participle that follows it:

                                  l'hélium qui est produit

                   Those are desperate matters already, but it can be done with this re:


                    frpage=mwclient.Site('fr.wikipedia.org').pages[term].edit()
                   rewordsaround=re.compile(r"(\w+\W+\w+\W+\w+\W+" + uterm + r"\W+qui est \w+\W+\w+\W+\w+\W+\w+)")
                   frwords=rewordsaround.findall(frpage)

                    for items in frwords:
                        print items # tuple # + ' '
                """
            print (u"{{t|%s|%s}}" % (wikilang, uterm)).encode('utf-8')

# this is setup
createPOSlookupDict()
createOtherHeaderslookupDict()

if __name__ == '__main__':

    wikilang = u'en'
    pagetopic = u'water'

    ofn = 'wiktionaryentry.txt'
    content = open(ofn).readlines()
    apage = WiktionaryPage(wikilang,pagetopic)
    p = Parser
    p.parseWikiPage(content)

