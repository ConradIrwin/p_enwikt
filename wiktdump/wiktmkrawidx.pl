#!/usr/bin/perl

# wiktmkrawidx dumpfile > en20081018-off.raw
#
# scans a wiktionary xml dump file
# looks for articles
# dumps the offset of each article as an unsigned int to STDOUT
#
# NOTE the offset is to the <title> line, not the <page> line just before it

use strict;

binmode STDOUT;

my $titlecount = 0;

#while (<>) {
while (1) {
#    print STDERR "mkrawidx reading dump...\n";
    last unless ($_ = <>);
	if (/<title>/i) {
#        print STDERR "* mkrawidx title ", ++$titlecount, ' ', (tell) - length, ': ', $_;
		print pack 'I', (tell) - length;	# dump file byte offset
	} else {
#        print STDERR "* mkrawidx ...\n";
    }
}

