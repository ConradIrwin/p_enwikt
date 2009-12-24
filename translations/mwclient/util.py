import codecs

def filelinks (filename):
    str = codecs.open(filename,'r','utf-8').read ()
    links = str.split('[[')[1:]
    for link in links:
        pipepos = link.find('|')
        bracpos = link.find(']]')
        if pipepos > 0 and bracpos > 0 and pipepos < bracpos:
            yield link[:pipepos]
        elif bracpos > 0:
            yield link[:bracpos]

