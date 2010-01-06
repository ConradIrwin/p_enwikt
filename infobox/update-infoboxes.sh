#! /bin/sh

# extract language, language family, and script infobox data from the English Wikipedia
# designed to be run from cron
# compares the current codes with the previous stored ones
# if there are any changes store the new version in a known place
#   for other tools to use

valid=1
which=

if [ $# -eq 1 ] ; then
    case "$1" in
        f)  which="family";;
        l)  which="lang";;
        s)  which="script";;
        *)  valid=0;;
    esac
else
    valid=0
fi

if [ $valid -eq 1 ] ; then
    echo "command line valid: $1 -> $which"
else
    echo "invalid command line"
    exit 1
fi

emailto=hippytrail@gmail.com
stdfile=${which}infobox.txt

date=`date +%Y%m%d`

newfile="${which}infobox-$date-cron.txt"
diffile="${which}infobox-$date-diff.txt"

nice -n 10 /usr/bin/perl -I/home/hippietrail/lib/ -I/home/hippietrail/perl5/lib/perl5/ /home/hippietrail/xmleasy.pl $1 50 >$newfile

rv=$?

#echo "$which update: $rv" >&2

if [ $rv = 0 ] ; then
    #echo "xmleasy success" >&2
    if [ -s $newfile ] ; then
        #echo "xmleasy output nonzero" >&2
        diff -u $stdfile $newfile >$diffile

        if [ $? = 1 ] ; then
            #echo "new file is different" >&2
            mail $emailto <$diffile
            mv $newfile $stdfile
        else
            #echo "no changes" >&2
            rm $newfile
        fi

        rm $diffile
    #else
        #echo "xmleasy output zero!" >&2
    fi
#else
    #echo "xmleasy fail" >&2
fi

exit;

