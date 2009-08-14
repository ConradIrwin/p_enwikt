#!/usr/bin/perl

# wiktallnames indexfile dumpfile > en20081018-all.txt
#
# uses a binary index file to dump all the names from a dump file

use strict;
use Encode;
use Getopt::Std;
use HTML::Entities;
#use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use Unicode::Normalize;

use vars qw($opt_n);

getopts('n');

my $if = shift;
my $df = shift;

my $dfh;    # only used in the bzip2 case
my $mode;   # 0 for text, 1 for bzip2

open(DFH, $df) or die "no dump file";
open(IFH, $if) or die "no index file";

binmode(IFH);
if ($opt_n) {
	binmode(STDOUT, 'utf8');
} else {
	#this would set unix eol whereas the other tools seem to expect dos eol
	#binmode(STDOUT);
}

if (!-f DFH || rindex($df, ".bz2") != -1) {
    if (!-f DFH) {
        print STDERR "** dump not a regular file **\n";
        $mode = 0;
    } else {
        print STDERR "** bzip2 compressed dump **\n";
        $mode = 1;
        #$dfh = new IO::Uncompress::Bunzip2(\*DFH) or die "IO::Uncompress::Bunzip2 failed: $Bunzip2Error\n";;
    }
} else {
    print STDERR "** uncompressed dump **\n";
    $mode = 0;

    my ($s, $e);

    $s = <DFH>;
    chomp $s;
    seek(DFH, -12, 2);
    $e = <DFH>;
    chomp $e;
    print STDERR "START: '$s', END: '$e'\n";

    seek(DFH, 0, 0);
}

print STDERR "** index file: $if\n";
print STDERR "** dump file: $df\n";

my $old_o = 0;
my ($v, $o, $l);

while (1) {
    read(IFH, $v, 4) || do { print STDERR "* allnames index EOF\n"; last; };

    $o = unpack('I', $v);

    if (!-f DFH) {
        my $junk;
        $old_o += read(DFH, $junk, $o - $old_o);
        $l = <DFH>;
        $old_o += length($l);
    } elsif ($mode == 0) {
        seek(DFH, $o, 0) == 0 && die "seek doesnt work";
        $l = <DFH>;
    } else {
        $dfh->seek($o, 0);
        $l = <$dfh>;
    }

    $l = decode('utf8', $l) if ($opt_n);

    $l = decode_entities($l);

    $l = substr($l,11,length($l)-20);

    $l = NFD($l) if ($opt_n);

    print $l, "\n";
}

print STDERR "allnames.pl terminating successfully\n";

exit 0;

