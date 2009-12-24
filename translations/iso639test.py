#!/usr/bin/python
# -*- coding: utf-8  -*-

"""Unit tests for Wiktionarypage.py"""

import iso639
import unittest

class TestKnownValuesInParser(unittest.TestCase):
    """This class will check known values"""
    knownvalues=(
            (u'en', u'Dutch', u'nld', u'nl'), 
            (u'en', u'English', u'eng', u'en'), 
            (u'nl', u'Nederlands', u'nld', u'nl'), 
            (u'nl', u'Engels', u'eng', u'en'), 
            )
    def testiso2langname(self):
        for outputlang,  langname, code, isoMW in self.knownvalues:
            result=iso639.iso2langname(code,  outputlang)
            print result
            self.assertEqual(langname, result)

    def testlangname2iso(self):
        for outputlang,  langname, code, isoMW in self.knownvalues:
            print langname,  code, 
            result=iso639.langname2iso(langname)
            print result
            self.assertEqual(code, result)
    
if __name__ == "__main__":
    unittest.main()
