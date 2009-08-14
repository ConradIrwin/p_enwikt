#! /bin/sh

# extract all the js and css pages from the English Wiktionary
# designed to be run from cron
# compares the current set of pages with the previous stored ones
# if there are any changes then make a new tarball
#   for other tools to use

emailto=hippytrail@gmail.com

date=`date +%Y%m%d`

olddir=enwiktcodeold
newdir=enwiktcodenew
diffile="enwiktcode-$date-diff.txt"
tmparc=enwiktcode.tar.gz
pubarc=~/public_html/enwiktionary-code.tar.gz

mkdir $newdir

if [ $? = 0 ] ; then
    nice -n 19 /usr/bin/perl -I/home/hippietrail/lib zipjs.pl

    diff -ru $olddir $newdir >$diffile

    if [ $? = 1 ] ; then
        echo "things have changed, man"
        mail $emailto <$diffile

        cd $newdir

        rm $tmparc
        if [ $? = 1 ] ; then
            echo "rm 1"
        else
            echo "rm 0"
        fi

        tar zcpvf $tmparc * >/dev/null
        if [ $? = 1 ] ; then
            echo "tar 1"
        else
            echo "tar 0"
            mv $tmparc $pubarc
            if [ $? = 1 ] ; then
                echo "pub 1"
            else
                echo "pub 0"
            fi
        fi

        cd ..

        rm -rf $olddir
        mv $newdir $olddir
    else
        echo "same old same old"
        rm -rf $newdir
    fi

    rm $diffile
fi

exit;

