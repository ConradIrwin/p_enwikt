#!/usr/bin/python
# -*- coding: utf-8  -*-

import pickle
import mwclient
import re
import sys
import unicodedata
import os,  types

_r_code2ENtemplate = {}
_r_ENtemplate2code = {}
_r_scripts = {}
_r_scriptnames = {}
_r_isocodes = {}
_r_syns={}
_l_scriptnames = {}
_l_isocodes = {}
loaded = False

cache_file = os.path.dirname (os.path.abspath (__file__))+"/.iso15924_cache"

class UnknownScript(Exception):
    """
        Raised when we can't provide an answer.
    """
    pass

def normalize (string):

    """
        Returns unicode normalized, lowercase.
        Keys in all dictionaries and iso codes as values
        in dictionaries are passed through this.

        If you edit this function, delete the cache_file.
    """
    if not type(string) == unicode:
        string=unicode(string)
    string = unicodedata.normalize ('NFKD', string)
    if len(string)>0:
        return string[0].upper() + string[1:].lower()

    return string


def add_scriptname(key,  code):
    if not key in _r_scriptnames:
        # if we don't have it yet, simply put the code in as a string
        _r_scriptnames[key]=code

def tf(value):
    if value.strip()==u'1':
        return True
    else:
        return False

def clear_cache ():
    """
        Reload the remote data stuff, which will otherwise remain
        in cache indefinitely
    """
    print >>sys.stderr, "! Reloading ISO script names cache"

    _r_scriptnames.clear ()
    _r_isocodes.clear ()
    _r_code2ENtemplate.clear ()
    _r_ENtemplate2code.clear ()
    _r_scripts .clear ()
    _r_syns.clear ()

    reENlang = re.compile(ur'''
            \|
            \s*                             # optional whitespace
            (?P<code>.*)
            \|{2}                          # || table cell separator
            (?P<name>.*)
            \|{2}
            (?P<synonyms>.*)
            \|{2}
            (?P<template>.*)
            $
            ''', re.VERBOSE | re.UNICODE)

    for wiktsite in ['en', 'uk']:
    #for wiktsite in ['en', 'ang', 'bg', 'da', 'et', 'eu', 'fa', 'fy', 'gu', 'he', 'hr', 'kk', 'ms', 'ml', 'nl', 'sh', 'sl','sv', 'te', 'tr', 'pl']:
        print >>sys.stderr, wiktsite, 'Wiktionary'
        page = mwclient.Site(wiktsite + '.wiktionary.org').pages['User:PolyBot/Scripts'].edit ()
        if not(page):
            print 'empty page'
            continue

        for line in page.split ('\n'):
            m = reENlang.match (line)
            if m:
                code = normalize(m.group('code').strip())
                name = m.group('name').strip()
                template = m.group('template').strip()
                synonyms = m.group('synonyms')

                if template:
                     _r_ENtemplate2code[normalize(template)]=code
                     _r_code2ENtemplate[code]=template
                add_scriptname(normalize(name), code)

                if synonyms.strip():
                    print code, name, '     Synonyms:',
                    for synonym in synonyms.split(','):
                        print synonym,
                        add_scriptname(normalize(synonym.strip()), code)
                    print
                else:
                    print code, name

                if not normalize(wiktsite) in _r_isocodes:
                    _r_isocodes[normalize(wiktsite)] = {}

                _r_isocodes[normalize(wiktsite)][code] = name
        print

    _save_dictionaries ()

def _load_dictionaries (clear=True):
    """
        @private Loads the pickled data from the cache.
        Will be called automatically, don't call it manually.
    """
    global loaded
    loaded = True
    try:
        file = open(cache_file,'r')
        #Can't assign directly thanks to silly scoping rules
        tup = pickle.load (file)
        _r_scriptnames.update(tup[0])
        _r_isocodes.update(tup[1])
        _l_scriptnames.update (tup[2])
        _l_isocodes.update (tup[3])
        _r_code2ENtemplate.update (tup[4])
        _r_syns.update(tup[5])
        file.close ()
    except:
        if clear:
            clear_cache ()

def _save_dictionaries ():
    """
        @private Saves the pickled data to the cache.
    """

    if not loaded: _load_dictionaries ()

    file = open(cache_file, 'w')
    pickle.dump ((_r_scriptnames, _r_isocodes, _l_scriptnames, _l_isocodes, _r_code2ENtemplate, _r_ENtemplate2code,  _r_syns), file)
    file.close ()

#def add_scriptname_for_iso (iso, scriptname):
#    """
#        Add this scriptname in the list of things that will
#        return the given iso code.
#    """
#
#    (iso, scriptname) = (normalize (iso), normalize (scriptname))
#    if not loaded: _load_dictionaries ()
#
#    if _l_scriptnames == None:
#        _load_dictionaries ()
#    _l_scriptnames[scriptname]= iso
#    _save_dictionaries ()
#    return iso
#
#def add_iso_in_language (iso, outputlang, scriptname):
#    """
#        Add a translation of an iso code into an outputlanguage
#        to our local datastore.
#    """
#
#    (iso, outputlang) = (normalize(iso), normalize(outputlang))
#    if not loaded: _load_dictionaries ()
#
#    _l_scriptnames[normalize(scriptname)] = iso
#    if not iso in  _l_isocodes:
#        _l_isocodes[iso] = {}
#    _l_isocodes[iso][outputlang] = scriptname
#    _save_dictionaries ()
#    return scriptname

def scriptname2iso (scriptname, askforhelp=False):
    """
    Gets an iso-639 code from a language name. It first checks
    the remote data store (cached) and then any local amendments.

    If given an iso-639 code it will return it unchanged.

    If it still can't find the answer, it will ask the user.
    The user should give a "scriptname" response, that given scriptname
    will be looked up to find the relevant code. (This doesn't allow
    the addition of new codes yet...)

    >>> scriptname2iso("Cyrillic")
    u'Cyrl'
    >>> scriptname2iso("Roman")
    u'Latn'
    >>> scriptname2iso("Latin")
    u'Latn'
    """

    scriptname = normalize(scriptname)
    if not loaded: _load_dictionaries ()

    if scriptname in _r_scriptnames:
        return _r_scriptnames[scriptname]

    if scriptname in _r_isocodes:
        return scriptname

    if scriptname in _l_scriptnames:
        return _l_scriptnames[scriptname]

    if askforhelp:
        print >>sys.stderr,u"Couldn't recognise: '%s' as a language do you have any idea?" % scriptname
        return add_scriptname_for_iso (scriptname2iso(mwclient.editor.editline(scriptname), False), scriptname)

    raise UnknownScript(scriptname)

def iso2scriptname (iso, outputlang, askforhelp=False,  unknownIsBlank=False,  wikify=False):
    """
        Converts an iso code into a standard representation in the given outputlanguage.

        Looks for values that we have obtained from a dedicated Wiktionary page,
        then for values that we have given manually locally.

        If it can't find a suitable representation and askforhelp is True, it will
        query the user for the answer. If the user leaves the field blank, or askforhelp
        is False, then it will raise an UnknownScript exception.

        The user should enter the value with correct capitalisation, as would be found
        in standard writing.
    >>> iso2scriptname("Cyrl","en", askforhelp=False)
    u'Cyrillic'
    >>> iso2scriptname("Hebr","en", askforhelp=False)
    u'Hebrew'

    """

    (outputlang,  iso) = (normalize (outputlang),  normalize (iso))
    if not loaded: _load_dictionaries ()

    if outputlang in _r_isocodes and iso in _r_isocodes[outputlang]:
        result=_r_isocodes[outputlang][iso]

    elif outputlang in _l_isocodes and iso in _l_isocodes[outputlang]:
        result=_l_isocodes[outputlang][iso]

    elif unknownIsBlank:
        result=u''

    elif askforhelp:
        print >>sys.stderr, u"Couldn't translate: '%s' into '%s', do you have any ideas?" % (iso, outputlang)
        value = mwclient.editor.editline(u'', False)
        if value != '':
            result=add_iso_in_language (outputlang, iso, value)
        else: raise UnknownScript((outputlang,  iso))
    else:
        raise UnknownScript((outputlang,  iso))

    if wikify:
        if iso in _r_wikifyscriptname:
            return result, result
        else:
            return result, u'[[' + result + u']]'
    else:
        return result


def iso2ENtemplate(iso,  unknownIsBlank=False):
    iso = normalize(iso)
    if not loaded: _load_dictionaries ()
    try:
        return _r_code2ENtemplate [iso]
    except KeyError:
        if unknownIsBlank:
            return u''
        else:
            raise UnknownScript(iso)

def ENtemplate2iso(code,  unknownIsBlank=False):
    code = normalize(code)
    if not loaded: _load_dictionaries ()
    try:
        return _r_ENtemplate2code[code]
    except KeyError:
        if code in _r_isocodes['en']:
           return code
        else:
            if unknownIsBlank:
                return u''
            else:
                raise UnknownScript(code)

def _test():
    import doctest
    doctest.testmod()

if __name__ == "__main__":

  def main ():
    import sys
    if len(sys.argv) == 2:
        if sys.argv[1] == 'clearcache':
            _load_dictionaries (False)
            clear_cache ()
            return
        elif sys.argv[1] == 'showlocal':
            _load_dictionaries (False)
            printed = set ()
            print "Language names:"
            for key in _l_isocodes:
                print u"== %s ==" % key
                for lang in _l_isocodes[key]:
                    print u" %s : %s" % (lang, _l_isocodes[key][lang])
                    printed.add (_l_isocodes[key][lang])

            print "Aliases:"
            for key in _l_scriptnames:
                if not key in printed:
                    print u"%s -> %s" % (key, iso2scriptname(_l_scriptnames[key],u'en'))
            return
        elif sys.argv[1]=='doctest':
            _test()
    print """
        By directly running this module with the argument 'clearcache' you can purge the cache of remote data.
        By running it with the argument 'showlocal' you can see any local additions to the database.
        By running it with the argument 'doctest' a series of tests are executed to check whether it works as it should. No messages means all is well.
    """
  main ()




