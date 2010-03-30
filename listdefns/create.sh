#!/bin/bash

path=`dirname $0`
date=`$path/latest_dump.sh | tr -d -c '0-9'`

if [ ! -f ~enwikt/public_html/definitions/enwikt-defs-$date-all.tsv.gz ]
then
	nice python $path/create.py $path/TEMP$date.tsv $path/errors/enwikt-badhashes-$date.tsv
	nice sort $path/TEMP$date.tsv > $path/TEMP-S$date.tsv
	nice grep '^English\b' $path/TEMP-S$date.tsv > $path/TEMP-E$date.tsv
	nice gzip $path/TEMP-S$date.tsv
	nice gzip $path/TEMP-E$date.tsv
	mv $path/TEMP-S$date.tsv.gz ~enwikt/public_html/definitions/enwikt-defs-$date-all.tsv.gz
	mv $path/TEMP-E$date.tsv.gz ~enwikt/public_html/definitions/enwikt-defs-$date-en.tsv.gz
	ln -f ~enwikt/public_html/definitions/enwikt-defs-$date-all.tsv.gz ~enwikt/public_html/definitions/enwikt-defs-all-latest.tsv.gz
	ln -f ~enwikt/public_html/definitions/enwikt-defs-$date-en.tsv.gz ~enwikt/public_html/definitions/enwikt-defs-en-latest.tsv.gz
fi
