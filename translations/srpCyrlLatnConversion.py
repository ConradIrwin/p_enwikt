"""
serbian.py Module
Python module for converting Serbian text between its cyrillic and latin representations.
Written by Klaus A. Brunner (k.brunner (at) acm.org), 2003-12-21.

NOTES: This works for Serbian (ISO language code: "sr"), but probably not for other languages using cyrillic script
       (such as Russian): there's more than one variant of cyrillic. Also be aware that the "digraph" version of latin,
       which basically lumps things like "nj" into a single character, is apparently not widely supported. It's better
       for internal representation, though, as it allows safe round-trip conversion between latin and cyrillic.

DISCLAIMER: The author is neither a native speaker of Serbian nor a linguist nor a Python expert. There may be mistakes
            in the conversion, there may be mistakes in my terminology, there may be mistakes in the code. I also don't
            claim to know what the differences between Serbian, Bosnian, Croatian etc. are, so you have to know yourself
            whether this code is useful for you or not.
"""

# the conversion table
# ordering: cyrillic (unicode), latin (unicode, using digraphs), latin (unicode, not using digraphs).
__conversion_table =  ( (u"\u0410", u"\u0041", u"\u0041"),      # capital cyrillic A
                       (u"\u0430", u"\u0061", u"\u0061"),               # small cyrillic a

                       (u"\u0411", u"\u0042", u"\u0042"),               # capital cyrillic "BE" (latin "B")
                       (u"\u0431", u"\u0062", u"\u0062"),               # small cyrillic "be" (latin "b")

                       (u"\u0412", u"\u0056", u"\u0056"),               # capital cyrillic "VE" (latin "V")
                       (u"\u0432", u"\u0076", u"\u0076"),               # small cyrillic "ve" (latin "v")

                       (u"\u0413", u"\u0047", u"\u0047"),               # small cyrillic "GE" (latin "G")
                       (u"\u0433", u"\u0067", u"\u0067"),               # small cyrillic "ge" (latin "g")

                       (u"\u0414", u"\u0044", u"\u0044"),               # capital cyrillic "DE" (latin "D")
                       (u"\u0434", u"\u0064", u"\u0064"),               # small cyrillic "de" (latin "d")

                       (u"\u0402", u"\u0110", u"\u0110"),               # capital cyrillic "DJE"
                       (u"\u0452", u"\u0111", u"\u0111"),               # small cyrillic "dje"

                       (u"\u0415", u"\u0045", u"\u0045"),               # capital cyrillic "E"
                       (u"\u0435", u"\u0065", u"\u0065"),               # small cyrillic "e"

                       (u"\u0416", u"\u017d", u"\u017d"),               # capital cyrillic "ZHE"
                       (u"\u0436", u"\u017e", u"\u017e"),               # small cyrillic "zhe"

                       (u"\u0417", u"\u005a", u"\u005a"),               # capital cyrillic "ZE"
                       (u"\u0437", u"\u007a", u"\u007a"),               # small cyrillic "ze"

                       (u"\u0418", u"\u0049", u"\u0049"),               # capital cyrillic "I"
                       (u"\u0438", u"\u0069", u"\u0069"),               # small cyrillic "i"

                       (u"\u0408", u"\u004a", u"\u004a"),               # capital cyrillic "JE"
                       (u"\u0458", u"\u006a", u"\u006a"),               # small cyrillic "je"

                       (u"\u041a", u"\u004b", u"\u004b"),               # capital cyrillic "KA"
                       (u"\u043a", u"\u006b", u"\u006b"),               # small cyrillic "ka"

                       (u"\u041b", u"\u004c", u"\u004c"),               # capital cyrillic "EL"
                       (u"\u043b", u"\u006c", u"\u006c"),               # small cyrillic "el"

                       (u"\u0409", u"\u01c8", u"\u004c\u006a"),         # capital cyrillic "LJE" (as Lje) # MISSING LJE (4c,4a)?
                       (u"\u0459", u"\u01c9", u"\u006c\u006a"),         # small cyrillic "lje"

                       (u"\u041c", u"\u004d", u"\u004d"),               # capital cyrillic "EM"
                       (u"\u043c", u"\u006d", u"\u006d"),               # small cyrillic "em"

                       (u"\u041d", u"\u004e", u"\u004e"),               # capital cyrillic "EN"
                       (u"\u043d", u"\u006e", u"\u006e"),               # small cyrillic "en"

                       (u"\u040a", u"\u01cb", u"\u004e\u006a"),         # capital cyrillic "NJE" # MISSING NJE (4e,4a)?
                       (u"\u045a", u"\u01cc", u"\u006e\u006a"),         # small cyrillic "nje"

                       (u"\u041e", u"\u004f", u"\u004f"),               # capital cyrillic "O"
                       (u"\u043e", u"\u006f", u"\u006f"),               # small cyrillic "O"

                       (u"\u041f", u"\u0050", u"\u0050"),               # capital cyrillic "PE"
                       (u"\u043f", u"\u0070", u"\u0070"),               # small cyrillic "pe"

                       (u"\u0420", u"\u0052", u"\u0052"),               # capital cyrillic "ER"
                       (u"\u0440", u"\u0072", u"\u0072"),               # small cyrillic "er"

                       (u"\u0421", u"\u0053", u"\u0053"),               # capital cyrillic "ES"
                       (u"\u0441", u"\u0073", u"\u0073"),               # small cyrillic "es"

                       (u"\u0422", u"\u0054", u"\u0054"),               # capital cyrillic "TE"
                       (u"\u0442", u"\u0074", u"\u0074"),               # small cyrillic "te"

                       (u"\u040b", u"\u0106", u"\u0106"),               # capital cyrillic "TSHE"
                       (u"\u045b", u"\u0107", u"\u0107"),               # small cyrillic "tshe"

                       (u"\u0423", u"\u0055", u"\u0055"),               # capital cyrillic "U"
                       (u"\u0443", u"\u0075", u"\u0075"),               # small cyrillic "u"

                       (u"\u0424", u"\u0046", u"\u0046"),               # capital cyrillic "EF"
                       (u"\u0444", u"\u0066", u"\u0066"),               # small cyrillic "ef"

                       (u"\u0425", u"\u0048", u"\u0048"),               # capital cyrillic "HA"
                       (u"\u0445", u"\u0068", u"\u0068"),               # small cyrillic "ha"

                       (u"\u0426", u"\u0043", u"\u0043"),               # capital cyrillic "TSE"
                       (u"\u0446", u"\u0063", u"\u0063"),               # small cyrillic "tse"

                       (u"\u0427", u"\u010c", u"\u010c"),               # capital cyrillic "CHE"
                       (u"\u0447", u"\u010d", u"\u010d"),               # small cyrillic "che"

                       (u"\u040f", u"\u01c5", u"\u0044\u017e"),         # capital cyrillic "DZHE" (as Dzhe) # MISSING DZHE (44,17d)?
                       (u"\u045f", u"\u01c6", u"\u0064\u017e"),         # small cyrillic ""dzhe"

                       (u"\u0428", u"\u0160", u"\u0160"),               # capital cyrillic "SHA"
                       (u"\u0448", u"\u0161", u"\u0161"),               # small cyrillic ""sha"
                     )

# conversion for cyrillic text that's encoded using a mixture of latin and cyrillic characters
# (e.g. using 0x0043 for the cyrillic "C", instead of the correct 0x0421 -- they look the same
# on screen, but their meaning is different)
__mixed_to_cyrillic = {  u"B" : u"\u0412",
                     u"H" : u"\u004e",
                     u"P" : u"\u0420",
                     u"p" : u"\u0440",
                     u"C" : u"\u0421",
                     u"c" : u"\u0441",
                     u"Y" : u"\u0423",
                     u"y" : u"\u0443",
                     u"X" : u"\u0425",
                     u"x" : u"\u0445",
                     u"A" : u"\u0410",
                     u"a" : u"\u0430",
                     u"E" : u"\u0415",
                     u"e" : u"\u0435",
                     u"K" : u"\u041a",
                     u"k" : u"\u043a",
                     u"J" : u"\u0408",
                     u"j" : u"\u0458",
                     u"M" : u"\u041c",
                     u"m" : u"\u043c",
                     u"O" : u"\u041e",
                     u"o" : u"\u043e",
                     u"T" : u"\u0422",
                     u"t" : u"\u0442" }

__cyrillic_to_latin = {}
__latin_to_cyrillic = {}
__latin_to_latin_digraphless = {}

# initialise the dictionaries
for letter in __conversion_table:
   __cyrillic_to_latin[letter[0]] = letter[1]
   __latin_to_cyrillic[letter[1]] = letter[0]
   __latin_to_latin_digraphless[letter[1]] = letter[2]

def __translate_string(input_string, conversion_dictionary):
   result = ''
   for letter in input_string:
      try:
         replacement = conversion_dictionary[letter]
      except:
         replacement = letter
      result += replacement
   return result

def srCyrillicToLatin(cyrillic_text):
   """
   Return a conversion of the given string from cyrillic to latin, using
   'digraph' letters (this means that e.g. "nj" is encoded as one character). Unknown
   letters remain unchanged.
   CAVEAT: this will ONLY change letters from the cyrillic subset of Unicode.
   For instance, the plain ASCII letter "C" (code point 0x0043) will NOT be converted
   to "S", as opposed to the cyrillic letter "C" (code point 0x0421), which WILL be converted.
   If you are sure that your cyrillic string does not contain latin portions (e.g. quoted text,
   company names), you can "normalize" it to cyrillic by using srNormalizeToCyrillic first.
   """
   return __translate_string(cyrillic_text, __cyrillic_to_latin)


def srNormalizeToCyrillic(cyrillic_text_in_mixed_encoding):
   """
   Return a conversion of all latin characters B, C, H, P etc. in the given string to their cyrillic counterparts.
   Necessary for text that uses a "mixed encoding scheme", i.e. using ASCII "P" for the cyrillic "ER" letter (which
   usually looks the same on screen).
   """
   return __translate_string(cyrillic_text_in_mixed_encoding, __mixed_to_cyrillic)

def srLatinToCyrillic(latin_text_with_digraphs):
   """
   Return a conversion of the given string from latin to cyrillic. Unknown letters
   remain unchanged.
   """
   return __translate_string(latin_text_with_digraphs, __latin_to_cyrillic)

def srSplitDigraphs(latin_text_with_digraphs):
   """
   Return a conversion of the given latin string without digraphs. This means
   that one-character-encodings of things like "nj" or "lj" will be changed to
   two-character encodings. All other characters remain unchanged.
   """
   return __translate_string(latin_text_with_digraphs, __latin_to_latin_digraphless)


def __print_test_html():
   """print a simple utf-8-encoded html test page for the conversion functions"""
   print """<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
<title>Serbian cyrillic/latin conversion test</title>
</head>
<body>
<table border="1">
<tr>
<th>cyrillic</th><th>latin (using digraphs)</th><th>latin (w/o digraphs, i.e.using multiple characters when necessary)</th>
</tr>
"""
   for letter in __conversion_table:
      print("<tr><td>" + letter[0] + "</td><td>" + letter[1] + "</td><td>" + letter[2] + "</td></tr>").encode("utf-8")

   print "</table>"

   # a sample text from the charter of human rights, in mixed encoding
   srTestText = u"""C\u0432a\u043ao \u0438\u043ca \u043f\u0440a\u0432o \u043da \u0441\u043bo\u0431o\u0434\u0443 \u043c\u0438\u0441\u043b\u0438, \u0441\u0430\u0432e\u0441\u0442\u0438 \u0438 \u0432e\u0440e; o\u0432o \u043f\u0440a\u0432o \u0443\u043a\u0459\u0443\u0447\u0443je \u0441\u043bo\u0431o\u0434\u0443 \u043f\u0440o\u043ce\u043de \u0432e\u0440e \u0438\u043b\u0438 \u0443\u0431e\u0452e\u045aa \u0438 \u0441\u043bo\u0431o\u0434\u0443 \u0434a \u0447o\u0432e\u043a, \u0431\u0438\u043bo \u0441a\u043c \u0438\u043b\u0438 \u0443 \u0437aje\u0434\u043d\u0438\u0446\u0438 \u0441 \u0434\u0440\u0443\u0433\u0438\u043ca, ja\u0432\u043do \u0438\u043b\u0438 \u043f\u0440\u0438\u0432a\u0442\u043do, \u0443\u043f\u0440\u0430\u0436\u045a\u0430\u0432\u0430 \u0441\u0432\u043e\u0458\u0443 \u0432\u0435\u0440\u0443 \u0438\u043b\u0438 \u0443\u0431e\u0452e\u045ae \u043f\u0443\u0442e\u043c \u043da\u0441\u0442a\u0432e, \u0432\u0440\u0448e\u045aa \u043a\u0443\u043b\u0442a \u0438 o\u0431a\u0432\u0459a\u045aa o\u0431\u0440e\u0434a. C\u0432a\u043ao \u0438\u043ca \u043f\u0440a\u0432o \u043da \u0441\u043bo\u0431o\u0434\u0443 \u043c\u0438\u0448\u0459e\u045aa \u0438 \u0438\u0437\u0440a\u0436a\u0432a\u045aa, \u0448\u0442o o\u0431\u0443\u0445\u0432a\u0442a \u0438\u043f\u0440a\u0432o \u0434a \u043de \u0431\u0443\u0434e \u0443\u0437\u043de\u043c\u0438\u0440a\u0432a\u043d \u0437\u0431o\u0433 \u0441\u0432o\u0433 \u043c\u0438\u0448\u0459e\u045aa, \u043aao \u0438 \u043f\u0440a\u0432o \u0434a\u0442\u0440a\u0436\u0438, \u043f\u0440\u0438\u043ca \u0438 \u0448\u0438\u0440\u0438 o\u0431a\u0432e\u0448\u0442e\u045aa \u0438 \u0438\u0434eje \u0431\u0438\u043bo \u043aoj\u0438\u043c \u0441\u0440e\u0434\u0441\u0442\u0432\u0438\u043ca \u0438 \u0431e\u0437o\u0431\u0437\u0438\u0440a \u043da \u0433\u0440a\u043d\u0438\u0446e."""

   print("<p><em>Serbian cyrillic, mixed encoding:</em><br /> " + srTestText + "</p>").encode("utf-8")

   print("<p><em>Serbian cyrillic, normalized to full cyrillic (should look almost exactly the same on screen):</em><br />" + srNormalizeToCyrillic(srTestText) + "</p>").encode("utf-8")

   print("<p><em>Serbian latin using digraphs (some letters may not be rendered correctly): </em><br />" + srCyrillicToLatin(srNormalizeToCyrillic(srTestText)) + "</p>").encode("utf-8")

   print("<p><em>Serbian latin, no digraphs (should render properly on most systems): </em><br />" + srSplitDigraphs(srCyrillicToLatin(srNormalizeToCyrillic(srTestText))) + "</p>").encode("utf-8")

   print "</body></html>"


if __name__ == "__main__":
   __print_test_html()
