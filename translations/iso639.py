#!/usr/bin/python
# -*- coding: utf-8  -*-

"""
Needed functionality:
conversion between iso3+MW (code used internally) and what MW (iso2 when available, iso3 otherwise, own invention otherwise) uses in two directions

ability to lookup language name based on internally used code or MW/enwikt's code. (depending on parameter)

ability to convert language name (using synonyms as well) to internally used code, or MW, depending on parameter.
For efficiency the dictionaries used to do this can be split according to script.

possibility to query which script is used by this language.

"""
import pickle
import mwclient
import re
import sys
import unicodedata
import os,  types

_r_code2MW = {}
_r_MW2code = {}
_r_scripts = {}
_r_langnames = {}
_r_isocodes = {}
_r_syns={}
_r_wikifylangname={}
_r_cap={}
_l_langnames = {}
_l_isocodes = {}
loaded = False

cache_file = os.path.dirname (os.path.abspath (__file__))+"/.iso_cache"

class UnknownLanguage(Exception):
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
    return unicodedata.normalize ('NFKD', string).lower ()

def add_langname(key,  code, name=''):
    l=len(key)
    if not l in _r_langnames:
        _r_langnames[l]={}
    if not key in _r_langnames[l]:
        # if we don't have it yet, simply put the code in as a string
        _r_langnames[l][key]=code
    else:
        if type(_r_langnames[l][key]) is type([]): langnameIsListAlready=True
        else: langnameIsListAlready=False
        if not(langnameIsListAlready) and not(_r_langnames[l][key]==code) or langnameIsListAlready and not(code in _r_langnames[l][key]):
            if not(langnameIsListAlready):
                # if it's there, but it's still the only one put the existing one in a new list
                same=[_r_langnames[l][key]]
            else:
                # if there is already a list present, get its contents
                same=_r_langnames[l][key]
            # add the new one to the list and save it
            same.append(code)
            _r_langnames[l][key]=same
            print 'Added', code,'to',_r_langnames[l][key],'for',name

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
    print >>sys.stderr, "! Reloading ISO translation cache"

    _r_langnames.clear ()
    _r_isocodes.clear ()
    _r_code2MW.clear ()
    _r_MW2code.clear ()
    _r_scripts .clear ()
    _r_syns.clear ()
    _r_wikifylangname.clear ()
    _r_cap.clear()

    reENlang = re.compile(ur'''
            \|
            \s*                             # optional whitespace
            (?P<code>.*)
            \|{2}                          # || table cell separator
            (?P<ENwiktcode>.*)
            \|{2}
            (?P<ENwiktname>.*)
            \|{2}
            (?P<ENsyns>.*)
            \|{2}
            (?P<scripts>.*)
            $
            ''', re.VERBOSE | re.UNICODE)
    reOTHERlang = re.compile (ur'''
            \|
            \s*                             # optional whitespace
            (?P<code>.*)
            \|{2}                          # || table cell separator
            (?P<deviantcode>.*)
            \|{2}
            (?P<langname>.*)
            \|{2}
            (?P<syns>.*)
            $
            ''', re.VERBOSE | re.UNICODE)
    reLangnamesToWikify = re.compile (ur'\*\s*(?P<langname>.*?)$')
    reCAP = re.compile(ur'''
            \|
            (?P<MWcode>.*)
            \|{2}                          # || table cell separator
            (.*)                             # column with langname, we don't need that
            \|{2}
            (?P<noun>.*)
            \|{2}
            (?P<proper>.*)
            \|{2}
            (?P<weekday>.*)
            \|{2}
            (?P<month>.*)
            \|{2}
            (?P<lang>.*)
            \|{2}
            (?P<demonym>.*)
            \|{2}
            (?P<deity>.*)
            \|{2}
            (?P<prondeity>.*)
            \|{2}
            (?P<formal>.*)
            \|{2}
            (?P<title>.*)
            \|{2}
            (?P<properadj>.*)
            \|{2}
            (?P<nationadj>.*)
            \|{2}
            (?P<firstword>.*)
            \|{2}
            (?P<holiday>.*)
            $
            ''', re.VERBOSE | re.UNICODE)
    #for wiktsite in ['en']:
    for wiktsite in ['en', 'ang', 'bg', 'da', 'de', 'el', 'eo', 'et', 'eu', 'fa', 'fy', 'gu', 'he', 'hr', 'ja', 'kk', 'kw', 'ms', 'ml', 'nl', 'pl', 'sh', 'sl','sv', 'te', 'tl', 'tr', 'uk', 'zh']:
        print >>sys.stderr, wiktsite, "Wiktionary"
        page = mwclient.Site(wiktsite + '.wiktionary.org').pages['User:PolyBot/Languages'].edit ()
        if not(page):
            print 'empty page'
            continue

        redirectedRE=re.compile(ur' *# *REDIRECT *\[\[(?P<redirectedto>[^\]|]+)')
        m = redirectedRE.search(page)
        if m:
            page = mwclient.Site(wiktsite + '.wiktionary.org').pages[m.group('redirectedto')].edit ()

        for line in page.split ('\n'):
            if wiktsite=='en':
                m = reENlang.match (line)
                if m:
                    code = normalize(m.group('code').strip())
                    ENwiktcode = normalize(m.group('ENwiktcode').strip())
                    ENwiktname = normalize(m.group('ENwiktname').strip())

                    if ENwiktcode:
                         _r_MW2code[ENwiktcode]=code
                         _r_code2MW[code]=ENwiktcode
                    if ENwiktname.find(':')==-1:
                        add_langname(ENwiktname.lower(), code)
                    else:
                        if ENwiktname.lower().find(u'sign language')==-1:
                            add_langname(ENwiktname.split(':')[1].lower(), code,ENwiktname)

                    if m.group('scripts'): _r_scripts [code]=m.group('scripts')

                    if not wiktsite in _r_isocodes:
                        _r_isocodes[wiktsite] = {}
                    _r_isocodes[wiktsite][code] = m.group('ENwiktname').strip()

                    if m.group('ENsyns'):
                        for name in m.group('ENsyns').split(";"):
                            add_langname(normalize(name.strip()).lower(), code)
                        if not wiktsite in _r_syns:
                            _r_syns[wiktsite] = {}
                        _r_syns[wiktsite][code] = m.group('ENsyns')

            else:
                m = reOTHERlang.match (line)
                if m:
                    code = normalize(m.group('code').strip())
                    deviantcode= normalize(m.group('deviantcode').strip())
                    langname = normalize(m.group('langname').strip())
                    syns = normalize(m.group('syns'))

                    if deviantcode:
                         _r_MW2code[deviantcode]=code
                         _r_code2MW[code]=deviantcode

                    add_langname(langname.lower(), code)

                    if not wiktsite in _r_isocodes:
                        _r_isocodes[wiktsite] = {}
                    if code: _r_isocodes[wiktsite][code] = m.group('langname')

                    if m.group('syns'):
                        for name in m.group('syns').split(";"):
                            add_langname(normalize(name.strip()).lower(), code, langname)
                        if not wiktsite in _r_syns:
                            _r_syns[wiktsite] = {}
                        _r_syns[wiktsite][code] = m.group('syns')

    print ; print 'Loading wikification'
    page = mwclient.Site('en.wiktionary.org').pages['Wiktionary:Translations/Wikification'].edit ()
    for line in page.split ('\n'):
        m = reLangnamesToWikify.match(line)
        if line.find('----')!=-1: break
        if m:
            #print langname2iso(m.group('langname'))
            if type(langname2iso(m.group('langname'))) is types.ListType:
                # if we get a list grouping several codes, we assume it's the first item we need.
                # this assumption is reasonable because langs with iso639-1 codes are first in our list
                # and those are the most likely candidates for not needing wikification
                _r_wikifylangname[langname2iso(m.group('langname'))[0]]=None
            else:
                _r_wikifylangname[langname2iso(m.group('langname'))]=None

    print 'Loading capitalization'
    page = mwclient.Site('en.wiktionary.org').pages['User:PolyBot/Capitalization'].edit ()

    for line in page.split ('\n'):
        m = reCAP.match(line)
        if m:
            mwcode=m.group('MWcode')
            _r_cap[mwcode] = {}
            if m.group('noun').strip()!=u'?':
                _r_cap[mwcode]['noun']=tf(m.group('noun'))
            if m.group('proper').strip()!=u'?':
                _r_cap[mwcode]['proper']=tf(m.group('proper'))
            if m.group('weekday').strip()!=u'?':
                _r_cap[mwcode]['weekday']=tf(m.group('weekday'))
            if m.group('month').strip()!=u'?':
                _r_cap[mwcode]['month']=tf(m.group('month'))
            if m.group('lang').strip()!=u'?':
                _r_cap[mwcode]['lang']=tf(m.group('lang'))
            if m.group('demonym').strip()!=u'?':
                _r_cap[mwcode]['demonym']=tf(m.group('demonym'))
            if m.group('deity').strip()!=u'?':
                _r_cap[mwcode]['deity']=tf(m.group('deity'))
            if m.group('prondeity').strip()!=u'?':
                _r_cap[mwcode]['prondeity']=tf(m.group('prondeity'))
            if m.group('formal').strip()!=u'?':
                _r_cap[mwcode]['formal']=tf(m.group('formal'))
            if m.group('title').strip()!=u'?':
                _r_cap[mwcode]['title']=tf(m.group('title'))
            if m.group('properadj').strip()!=u'?':
                _r_cap[mwcode]['properadj']=tf(m.group('properadj'))
            if m.group('nationadj').strip()!=u'?':
                _r_cap[mwcode]['nationadj']=tf(m.group('nationadj'))
            if m.group('firstword').strip()!=u'?':
                _r_cap[mwcode]['firstword']=tf(m.group('firstword'))
            if m.group('holiday').strip()!=u'?':
                _r_cap[mwcode]['holiday']=tf(m.group('holiday'))

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
        _r_langnames.update(tup[0])
        _r_isocodes.update(tup[1])
        _l_langnames.update (tup[2])
        _l_isocodes.update (tup[3])
        _r_code2MW.update (tup[4])
        _r_MW2code.update (tup[5])
        _r_scripts.update (tup[6])
        _r_syns.update(tup[7])
        _r_wikifylangname.update(tup[8])
        _r_cap.update(tup[9])
        file.close ()
    except:
        if clear:
            clear_cache ()

def _save_dictionaries ():
    """
        @private Saves the pickled data to the cache.
    """
    print 'Pickling data'

    if not loaded: _load_dictionaries ()

    file = open(cache_file, 'w')
    pickle.dump ((_r_langnames, _r_isocodes, _l_langnames, _l_isocodes, _r_code2MW, _r_MW2code, _r_scripts,  _r_syns,  _r_wikifylangname,  _r_cap), file)
    file.close ()

def add_langname_for_iso (iso, langname):
    """
        Add this langname in the list of things that will
        return the given iso code.
    """

    (iso, langname) = (normalize (iso), normalize (langname))
    if not loaded: _load_dictionaries ()

    if _l_langnames == None:
        _load_dictionaries ()
    _l_langnames[len(langname)][langname]= iso
    _save_dictionaries ()
    return iso

def add_iso_in_language (iso, outputlang, langname):
    """
        Add a translation of an iso code into an outputlanguage
        to our local datastore.
    """

    (iso, outputlang) = (normalize(iso), normalize(outputlang))
    if not loaded: _load_dictionaries ()

    ln=normalize(langname)
    _l_langnames[len(ln)][ln] = iso
    if not iso in  _l_isocodes:
        _l_isocodes[iso] = {}
    _l_isocodes[iso][outputlang] = langname
    _save_dictionaries ()
    return langname

def langname2iso (langname, askforhelp=False):
    """
    Gets an iso-639 code from a language name. It first checks
    the remote data store (cached) and then any local amendments.

    If given an iso-639 code it will return it unchanged.

    If it still can't find the answer, it will ask the user.
    The user should give a "langname" response, that given langname
    will be looked up to find the relevant code. (This doesn't allow
    the addition of new codes yet...)

    >>> langname2iso("English")
    u'eng'
    >>> langname2iso("Engels")
    u'eng'
    >>> langname2iso("Engelsk")
    u'eng'
    >>> langname2iso("Dutch")
    u'nld'
    >>> langname2iso("Nederlands")
    u'nld'
    >>> langname2iso("French")
    u'fra'
    >>> langname2iso("Chinese")
    u'cmn'
    >>> langname2iso(u"Špansko")
    u'spa'
    >>> langname2iso(u"Spaans")
    u'spa'
    >>> langname2iso("North")
    [u'azj', u'gis', u'yir']
    """

    langname = normalize(langname)
    if not loaded: _load_dictionaries ()

    l=len(langname)
    if l in _r_langnames and langname in _r_langnames[l]:
        return _r_langnames[l][langname]

    if langname in _r_isocodes['en']:
        return langname

    if l in _l_langnames and langname in _l_langnames[l]:
        return _l_langnames[l][langname]

    if askforhelp:
        print >>sys.stderr,u"Couldn't recognise: '%s' as a language do you have any idea?" % langname
        return add_langname_for_iso (langname2iso(mwclient.editor.editline(langname), False), langname)

    raise UnknownLanguage(langname)

def iso2langname (iso, outputlang, askforhelp=False,  unknownIsBlank=False,  wikify=False):
    """
        Converts an iso code into a standard representation in the given outputlanguage.

        Looks for values that we have obtained from a dedicated Wiktionary page,
        then for values that we have given manually locally.

        If it can't find a suitable representation and askforhelp is True, it will
        query the user for the answer. If the user leaves the field blank, or askforhelp
        is False, then it will raise an UnknownLanguage exception.

        The user should enter the value with correct capitalisation, as would be found
        in standard writing.
    >>> iso2langname("nld","nl", askforhelp=False)
    u'Nederlands'
    >>> iso2langname("eng","nl", askforhelp=False)
    u'Engels'
    >>> iso2langname("nld","en", askforhelp=False)
    u'Dutch'
    >>> iso2langname("eng","en", askforhelp=False)
    u'English'
    >>> iso2langname("azj","en", askforhelp=False)
    u'Azerbaijani:North'
    >>> iso2langname("gis","en", askforhelp=False)
    u'Giziga:North'
    >>> iso2langname("yir","en", askforhelp=False)
    u'Awyu:North'

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
        else: raise UnknownLanguage((outputlang,  iso))
    else:
        raise UnknownLanguage((outputlang,  iso))

    if wikify:
        if iso in _r_wikifylangname:
            return result, result
        else:
            return result, u'[[' + result + u']]'
    else:
        return result

def alllangnamesforiso(outputlang):
    if not loaded: _load_dictionaries ()

    if outputlang in _r_isocodes:
        if outputlang in _l_isocodes:
            return _r_isocodes[outputlang].update(_l_isocodes[outputlang])
        else:
            return _r_isocodes[outputlang]
    else:
        return None

def iso2MW(iso,  unknownIsBlank=False):
    iso = normalize(iso)
    if not loaded: _load_dictionaries ()
    try:
        return _r_code2MW [iso]
    except KeyError:
        if unknownIsBlank:
            return u''
        else:
            raise UnknownLanguage(iso)

def MW2iso(code,  unknownIsBlank=False):
    code = normalize(code)
    if not loaded: _load_dictionaries ()
    try:
        return _r_MW2code[code]
    except KeyError:
        if code in _r_isocodes['en']:
           return code
        else:
            if unknownIsBlank:
                return u''
            else:
                raise UnknownLanguage(code)

def scripts(code,  unknownIsBlank=False):
    code = normalize(code)
    if not loaded: _load_dictionaries ()
    try:
        return _r_scripts[code]
    except KeyError:
        if unknownIsBlank:
            return u''
        else:
            raise UnknownLanguage(code)

def cap(MWcode,  type):
    try:
        return _r_cap[MWcode][type]
    except KeyError:
        return -1

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
            for key in _l_langnames:
                if not key in printed:
                    print u"%s -> %s" % (key, iso2langname(_l_langnames[key],u'en'))
            return
        elif sys.argv[1]=='doctest':
            _test()
    print """
        By directly running this module with the argument 'clearcache' you can purge the cache of remote data.
        By running it with the argument 'showlocal' you can see any local additions to the database.
        By running it with the argument 'doctest' a series of tests are executed to check whether it works as it should. No messages means all is well.
    """
  main ()




