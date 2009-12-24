# -*- coding: utf-8  -*-

import re
t_templateRE = re.compile(ur'''\{{2}
    (t)                                 # match t or it wouldn't be a t template
    (?P<exists>\+|-|ø)*     # optionally match +, -, ø and put in group 'exists'
    \|
    (?P<langcode>[^\|]*) # match anything but | and put in group 'langcode'
    \|
    (?P<term>[^\|}]*)      # match anything but | and } and put in group 'term'
    \|*                                 # optionally match |
    (?P<restoftempl>[^\}]*)   # grab all the rest into 'restoftempl' for processing it the traditional way
    (\}{2})
    \s*                                  # optional whitespace
    ((\{\{|'')(?P<gender>[^\'\}]*)  # match anything but ' and } and put in group 'gender'
    \s*                                        # optional whitespace
    (\}{2}))*
    (?P<rest>.*)                        # grab all the rest into 'rest' for processing it the traditional way
    ''', re.VERBOSE | re.UNICODE)

linkedTermRE = re.compile(ur'''\[{1,3}
    (?P<term>.+?)                       # match everything between [[ ]], not greedily and put in group 'term'
    \]{1,3}
    \s*                                          # optional whitespace
    \s*                                          # optional whitespace
     (\{\{|'')(?P<gender>[^\'\}\{]*)(\}\}|'')       # match any letter, not greedily and put in group 'gender'
    (?P<rest>.*)                           # grab all the rest into 'rest' for processing it the traditional way
    ''', re.VERBOSE | re.UNICODE)

tradvertRE = re.compile(ur'''(?P<number>\d)*
    \s*
    \{{2}
    (?P<templname>
    trad(?P<exists>xx|-|\+)*        # this deals with trad, tradxx, trad- and trad+
    |vert(?P<xx>xx(?P<count>\d)*)*   # this deals with vert, vertxx, vertxx2, etc
    |ဘာသာ|P|ξεν|алга|ກ|xlatio|versk|overs|Wendung|ප|ö|çeviri|ter)    # this deals with other variations
    \|                                             # match |
    (?P<langcode>[^\|]*)             # match anything but | and put in group 'langcode'
    \|
    (?P<translations>[^\}]*)         # grab all the rest into 'restoftempl' for processing it the traditional way
    (\}{1,3})
    \s*                                            # optional whitespace
    ((\{{2}|'')(?P<gender>[^\'\}]*)  # match anything but ' and } and put in group 'gender'
    \s*                                            # optional whitespace
    (\}{2}|''))*
    (?P<rest>.*)                             # grab all the rest into 'rest' for processing it the traditional way
    ''', re.VERBOSE | re.UNICODE )

iso23RE = re.compile(ur'''\{{2}
    (?P<isoMW>[a-z]{2,3})           # match 2 or 3 letter iso code
    (\|)
    (?P<translations>[^\}]*)         # grab all the rest into 'translations'
    \{{2}
    ''', re.VERBOSE | re.UNICODE)

