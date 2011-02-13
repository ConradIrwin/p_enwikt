#!/bin/bash

path=`dirname $0`
dump=`ls /mnt/user-store/enwiktionary*-articles.xml | tail -n 1`
date=`echo $dump | tr -d -c '0-9'`
outprefix="/home/project/e/n/w/enwikt/public_html/definitions/enwikt-defs-"

if [ "x--force" = "x$1" -o ! -f ${outprefix}$date-all.tsv.gz ]
then
	nice python $path/create.py $dump $path/TEMP$date.tsv
	if [ "`head $path/TEMP$date.tsv`" ]
	then
		nice /usr/bin/sort $path/TEMP$date.tsv > $path/TEMP-S$date.tsv
		nice grep '^English\b' $path/TEMP-S$date.tsv > $path/TEMP-E$date.tsv
		nice gzip $path/TEMP-S$date.tsv
		nice gzip $path/TEMP-E$date.tsv
		mv $path/TEMP-S$date.tsv.gz ${outprefix}$date-all.tsv.gz
		mv $path/TEMP-E$date.tsv.gz ${outprefix}$date-en.tsv.gz
		ln -f ${outprefix}$date-all.tsv.gz ${outprefix}latest-all.tsv.gz
		ln -f ${outprefix}$date-en.tsv.gz ${outprefix}latest-en.tsv.gz
		rm $path/TEMP$date.tsv
	fi
fi
