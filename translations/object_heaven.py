#!/usr/bin/python
# -*- coding: utf-8  -*-
import mwclient
import re

class Etymology(object):
    
    def __init__ (self, text):
        self.text = text

    def __unicode__ (self):
        return self.text

class Affix(Etymology):
    """
        Used when the etymology is just stuff stuck together.
    """
    
    def __init__ (self, *forms):
        self.forms = forms
        
    def __unicode__ (self):
        return map(unicode, self.forms).join (" + ")
        
    
class Form(object):
    """
        The base class to hold any data to do with how terms 
        are represented.
    """
    
    def __init__ (self, term=None):
        self.term = None
        self.spellings = {}
        if term: self.set_term (term)

    def add_spelling (self, spelling, context):
        self.spellings[spelling] = context

    def set_term (term):
        if self.term:
            raise Exception("Smelly")
        else:
            self.term = term
        
class Term(object):

    def __init__ (self):
        self.forms = {}

    def add_form (self, form, context):
        self.forms[form] = context

    def set_pos (self, pos, context):
        self.pos = (pos, context)



class Dictionary(object):

    def __init__ (self):
        self.strings = {}

    def add_string (self, string, form):
        if not string in self.strings:
            self.strings[string] = []
        self.strings[string].append (form)

    def get_forms (self, string):
        try:
            return self.strings[string]
        except:
            return []



def main ():
    
    term = Term ()

    term.
    term.add_etymology (Etymology ("chalcid + -ology"),"wiktionary")

    form = Form(term)

    form.add_spelling (u'chalcidology', 'wiktionary')
    form.





if __name__ == "__main__":
    main ()

