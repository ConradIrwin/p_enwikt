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
    if [ $? = 0 ] ; then

        diff -ru $olddir $newdir >$diffile

        if [ $? = 1 ] ; then
            mail $emailto <$diffile

            cd $newdir

                # make sure we don't add to some old archive
                rm -f $tmparc

                # create a new archive
                tar zcpvf $tmparc * >/dev/null
                if [ $? = 0 ] ; then
                    mv $tmparc $pubarc
                fi

            cd ~

            # keep the new files and toss the old ones
            rm -rf $olddir
            mv $newdir $olddir
        fi

        rm $diffile
    fi
fi

# toss the new files since they haven't changed
# or clean up after error
rm -rf $newdir

exit;

