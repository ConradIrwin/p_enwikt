#!/bin/bash

path=`dirname $0`
date=`ls /public/dumps/public/enwiktionary | tail -n 1`
dump="/public/dumps/public/enwiktionary/$date/enwiktionary-$date-pages-articles.xml.bz2"
outprefix="/data/project/enwiktdefns/public_html/enwikt-defs-"

echo "Date: $date"
echo "Dump: $dump"

if [ "x--force" = "x$1" -o ! -f ${outprefix}$date-all.tsv.gz ]
then
	python $path/create.py $dump $path/TEMP$date.tsv
	if [ "`head $path/TEMP$date.tsv`" ]
	then
		/usr/bin/sort $path/TEMP$date.tsv > $path/TEMP-S$date.tsv
		grep '^English\b' $path/TEMP-S$date.tsv > $path/TEMP-E$date.tsv
		gzip $path/TEMP-S$date.tsv
		gzip $path/TEMP-E$date.tsv
		mv $path/TEMP-S$date.tsv.gz ${outprefix}$date-all.tsv.gz
		mv $path/TEMP-E$date.tsv.gz ${outprefix}$date-en.tsv.gz
		ln -f ${outprefix}$date-all.tsv.gz ${outprefix}latest-all.tsv.gz
		ln -f ${outprefix}$date-en.tsv.gz ${outprefix}latest-en.tsv.gz
		rm $path/TEMP$date.tsv
	fi
fi
