
import io
import math
import os
import platform
import re
import struct
import sys  # for commandline arguments (sys.argv)

# read dump path from config file

config_file_name = os.path.expanduser(os.path.join('~', '.wikipath'))
config_file = open(config_file_name, encoding = 'UTF-8')
config_line = config_file.readline().rstrip()
dumppath = config_line;

# parse commandline

[dumpcode, dumpdate, needle] = [sys.argv[1], sys.argv[2], sys.argv[3]]

# build names of index files
class Dump:
    # dump file
    file_name = dumpcode + 'wiktionary-' + dumpdate
        # enwiktionary-YYYYMMDD-pages-articles.xml
    file_name += '-pages-articles.xml'
        # mediawikiwiki-YYYYMMDD-pages-meta-history.xml
        # en-wikt-YYYYMMDD.xml
    # raw offsets into dump file
        # enYYYYMMDD-off.raw
    offset_file_name = dumpcode + dumpdate + '-off.raw'
    # titles file
        # enYYYYMMDD-all(-norm).txt
    title_file_name = dumpcode + dumpdate + '-all.txt'
    # raw offsets into titles file
        # enYYYYMMDD-all(-norm)-off.raw
    title_offset_file_name = dumpcode + dumpdate + '-all-off.raw'
    # sorted index of titles
        # enYYYYMMDD-all(-norm)-idx.raw
    title_sorted_index_file_name = dumpcode + dumpdate + '-all-idx.raw'

dump = Dump();

# open index files
dump.file = open(dumppath + dump.file_name, encoding = 'UTF-8')
dump.offset_file = open(dumppath + dump.offset_file_name, mode = 'rb')
dump.title_file = open(dumppath + dump.title_file_name, encoding = 'UTF-8')
dump.title_offset_file = open(dumppath + dump.title_offset_file_name, mode = 'rb')
dump.title_sorted_index_file = open(dumppath + dump.title_sorted_index_file_name, mode = 'rb')

# decide kind of index based on lengths of index files

if os.path.getsize(dumppath + dump.title_offset_file_name) == os.path.getsize(dumppath + dump.title_sorted_index_file_name):

    dump.size = os.path.getsize(dumppath + dump.title_offset_file_name) / 4
    index_record_size = os.path.getsize(dumppath + dump.offset_file_name) / os.path.getsize(dumppath + dump.title_offset_file_name)

    if index_record_size == 3:
        print('new dump format can handle huge files and multiple revisions')
    elif index_record_size == 1:
        print('old dump format can handle typical sized files without revisions')
    else:
        print('unknown ratio ' + index_record_size)
        raise NameError('two')
    index_record_size = int(index_record_size)

else:
    raise NameError('size of all-off.raw does not match size of all-idx.raw')

# search

def gettitle(index_s):

    #index_s < dumpsize || die "sorted index $index_s too big";

    # *-all-idx.raw
    dump.title_sorted_index_file.seek(index_s * 4, 0)
    index_r = dump.title_sorted_index_file.read(4)
    # FIXME Linux: struct.error: unpack requires a bytes argument of length 8
    index_r = struct.unpack("<L", index_r)[0]

    #$index_r < $haystacksize || die "raw index $index_r too big (sorted index $index_s)";

    # *-all-off.raw
    dump.title_offset_file.seek(index_r * 4, 0)
    offset = dump.title_offset_file.read(4)
    offset = struct.unpack("<L", offset)[0]

    #$offset < -s TFH || die "title offset $offset too big";

    dump.title_file.seek(offset, 0)
    title = dump.title_file.readline().rstrip()

    return title

def bsearch(needle):
    compcount = 0
    low = 0
    high = dump.size - 1
    midpoint = 0

    while (low <= high):
        midpoint = int((low + high) / 2)

        t = gettitle(midpoint)
        compcount += 1

        if (needle == t):
            return (midpoint, compcount)
        elif (needle < t):
            high = midpoint - 1
        else:
            low = midpoint + 1

    return (low - 0.5, compcount)

def getarticle(index_s):
    print('sorted index: {}'.format(index_s))

    #index_s < dumpsize || die "sorted index $index_s too big";

    # *-all-idx.raw
    dump.title_sorted_index_file.seek(index_s * 4, 0)
    index_r = dump.title_sorted_index_file.read(4)
    index_r = struct.unpack("<L", index_r)[0]

    print('raw index: {}'.format(index_r))
    #$index_r < $haystacksize || die "raw index $index_r too big (sorted index $index_s)";

    ## *-off.raw
    if index_record_size == 3:

        dump.offset_file.seek(index_r * index_record_size * 4, 0)
        offset = dump.offset_file.read(8)
        revoffset = dump.offset_file.read(4)

        offset = struct.unpack("<Q", offset)[0]
        print('article offset {}'.format(offset))
        revoffset = struct.unpack("<L", revoffset)[0]
        print('revision offset {}'.format(revoffset))

        offset += revoffset
        print('dump offset {}'.format(offset))

    elif index_record_size == 1:
        dump.offset_file.seek(index_r * index_record_size * 4, 0)
        offset = dump.offset_file.read(4)

        offset = struct.unpack("<L", offset)[0]
        print('article offset {}'.format(offset))

        print('dump offset {}'.format(offset))

    else:
        #die "** unhandled dump offset size $dumpoffsize\n";
        print('die!')

    #$offset < -s DFH || die "article offset $offset too big";

    dump.file.seek(offset, 0)

    while True:
        l = dump.file.readline()
        if re.search(r'<text ', l):
            break

    l = re.sub(r'^.*<text .*>', r'', l)

    art = l

    while True:
        l = dump.file.readline()
        if re.search(r'<\/text>', l):
            break
        art += l

    l = re.sub(r'<\/text>', r'', l)
    art += l

    print(art)
    

def search(needle):
    (index, count) = bsearch(needle)

    if isinstance(index, (int)):
        print('"{0:s}" found at index {1:d} ({2:d} compares)'.format(needle, index, count))

        getarticle(index)

    elif isinstance(index, (float)):
        before = math.floor(index)

        context = ' '
        if before < 0:
            context = ' first before "{0:s}"'.format(gettitle(before+1))
        else:
            context = ' between "{0:s}" and "{1:s}"'.format(gettitle(before), gettitle(before+1))

        print('"{0:s}" not found, belongs at {1:.1f}{2:s} ({3:d} compares)'.format(needle, index, context, count))
    else:
        print('WTF?')


search(needle)

##############################################################################


