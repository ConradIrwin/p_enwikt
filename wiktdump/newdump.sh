wget -O - http://download.wikipedia.org/enwiktionary/20091230/enwiktionary-20091230-pages-articles.xml.bz2 | bzip2 -d > /mnt/user-store/enwiktionary-20091230-pages-articles.xml & wget -O - http://download.wikimedia.org/enwiktionary/20091230/enwiktionary-20091230-categorylinks.sql.gz | gzip -cd > /mnt/user-store/enwiktionary-20091230-categorylinks.sql

nice -n 24 perl wiktdump/wiktmkrawidx.pl /mnt/user-store/enwiktionary-20091230-pages-articles.xml > /mnt/user-store/en20091230-off.raw ; nice -n 24 perl wiktdump/wiktallnames.pl /mnt/user-store/en20091230-off.raw /mnt/user-store/enwiktionary-20091230-pages-articles.xml | tee >(nice -n 24 perl wiktdump/wiktmkbsearchidx.pl - > /mnt/user-store/en20091230-all-off.raw) >(nice -n 24 perl wiktdump/wiktmksortedidx.pl - > /mnt/user-store/en20091230-all-idx.raw) > /mnt/user-store/en20091230-all.txt

rm __*
cd newdump/
rm -rf buxxo fluxxo
mkdir buxxo; mkdir fluxxo
rm __*

nice -n 24 perl ../wiktdump/wiktsplitnames.pl /mnt/user-store/en20091230-off.raw /mnt/user-store/enwiktionary-20091230-pages-articles.xml & nice -n 24 perl ../wiktdump/wiktsplitnames.pl -b /mnt/user-store/en20091230-off.raw /mnt/user-store/enwiktionary-20091230-pages-articles.xml & nice -n 24 perl ../wiktdump/wiktstruct.pl /mnt/user-store/en20091230-off.raw /mnt/user-store/enwiktionary-20091230-pages-articles.xml
#nice -n 24 perl ../wiktdump/wiktsplitnames.pl /mnt/user-store/en20091230-off.raw /mnt/user-store/enwiktionary-20091230-pages-articles.xml & nice -n 24 perl ../wiktdump/wiktstruct.pl /mnt/user-store/en20091230-off.raw /mnt/user-store/enwiktionary-20091230-pages-articles.xml

cd ..

rm -rf olddump/*
mv buxxo/ olddump/
mv fluxxo/ olddump/
mv newdump/* .

vim ews2.sql

