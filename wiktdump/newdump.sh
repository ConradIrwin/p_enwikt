#
# download and index new English Wiktionary dump
#
# creates low level indeces then high level ones for the database to import
#
# -G : don't wget and un- bzip2/gzip dump files, assume they are in /mnt/user-store/
# -L : don't do low-level indexing of dump files, assume those files have already been created in /mnt/user-store/
#

date=
wget_and_unzip=1
low_level_index=1

while getopts gGlL opt
do
    case "$opt" in
        g)  wget_and_unzip=1;;
        G)  wget_and_unzip=0;;
        l)  low_level_index=1;;
        L)  low_level_index=0;;
    esac
done
shift `expr $OPTIND - 1`

if [ $# -eq 1 ] ; then
    date=$1
	echo "date: $date"
else
	echo "you need to supply a date: yyyymmdd"
	exit 1
fi

if [ $wget_and_unzip -eq 1 ] ; then
    echo "will get and unzip..."
else
    echo "won't get and unzip..."
fi

if [ $low_level_index -eq 1 ] ; then
    echo "will create low-level index of dump files..."
else
    echo "won't create low-level index of dump files..."
fi

echo "getting and unzipping pages and categories..."

if [ $wget_and_unzip -eq 1 ] ; then
    wget -O - http://download.wikipedia.org/enwiktionary/$date/enwiktionary-$date-pages-articles.xml.bz2 | bzip2 -d > /mnt/user-store/enwiktionary-$date-pages-articles.xml & pagepid=$!; wget -O - http://download.wikimedia.org/enwiktionary/$date/enwiktionary-$date-categorylinks.sql.gz | gzip -cd > /mnt/user-store/enwiktionary-$date-categorylinks.sql & catpid=$!
fi

wait ${pagepid}; pagerc=$?
wait ${catpid}; catrc=$?

echo "finished getting and unzipping pages and categories."

if [ $pagerc -ne 0 ] || [ $catrc -ne 0 ] ; then
    echo "page and/or cat failed (${pagerc}, ${catrc})"
    exit 1
else
    echo "page and cat both ok";
fi

if [ $low_level_index -eq 1 ] ; then
    nice -n 24 perl wiktdump/wiktmkrawidx.pl /mnt/user-store/enwiktionary-$date-pages-articles.xml > /mnt/user-store/en$date-off.raw ; nice -n 24 perl wiktdump/wiktallnames.pl /mnt/user-store/en$date-off.raw /mnt/user-store/enwiktionary-$date-pages-articles.xml | tee >(nice -n 24 perl wiktdump/wiktmkbsearchidx.pl - > /mnt/user-store/en$date-all-off.raw) >(nice -n 24 perl wiktdump/wiktmksortedidx.pl - > /mnt/user-store/en$date-all-idx.raw) > /mnt/user-store/en$date-all.txt
fi

rm __*
cd newdump/
rm -rf buxxo fluxxo
mkdir buxxo; mkdir fluxxo
rm __*

nice -n 24 perl ../wiktdump/wiktsplitnames.pl /mnt/user-store/en$date-off.raw /mnt/user-store/enwiktionary-$date-pages-articles.xml & nice -n 24 perl ../wiktdump/wiktsplitnames.pl -b /mnt/user-store/en$date-off.raw /mnt/user-store/enwiktionary-$date-pages-articles.xml & nice -n 24 perl ../wiktdump/wiktstruct.pl /mnt/user-store/en$date-off.raw /mnt/user-store/enwiktionary-$date-pages-articles.xml
#nice -n 24 perl ../wiktdump/wiktsplitnames.pl /mnt/user-store/en$date-off.raw /mnt/user-store/enwiktionary-$date-pages-articles.xml & nice -n 24 perl ../wiktdump/wiktstruct.pl /mnt/user-store/en$date-off.raw /mnt/user-store/enwiktionary-$date-pages-articles.xml

cd ..

rm -rf olddump/*
mv buxxo/ olddump/
mv fluxxo/ olddump/
mv newdump/* .

vim ews2.sql

