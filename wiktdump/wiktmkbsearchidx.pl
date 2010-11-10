#!/usr/bin/perl

# wiktmkbsearchidx namefile > en20081018-all-off.raw

use strict;
binmode STDOUT;

our($NFH) = shift;
open NFH or die "no name file";

my $opt_d = 0;
my $limit = $opt_d ? 20 : 0;
my $prog = 10000;

my $title;
my $oof = 0;

for (my $idx = 0; <NFH>; ++$idx) {
    last if $limit && $idx >= $limit;
    chomp;

    $title = $_;

    my $nof = (tell);
    if ($opt_d) {
        print STDERR $oof, " : '$title'\n";
    } else {
        print pack 'I', $oof;
    }

    # progress display
    $opt_d || print STDERR "$idx: $title\n" if ($idx % $prog == 0 || $idx == $limit - 1);

    $oof = $nof;
}
