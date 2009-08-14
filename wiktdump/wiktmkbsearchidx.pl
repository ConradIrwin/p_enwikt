#!/usr/bin/perl

# wiktmkbsearchidx namefile > en20081018-all-off.raw

use strict;
binmode STDOUT;

our($NFH) = shift;
open NFH or die "no name file";

my $limit = 0;
my $prog = 10000;

my $title;
my $idx;
for ($idx = 0; <NFH>; ++$idx) {
    last if $limit && $idx >= $limit;
    my $eoll = chomp;                           # eol length for LF or CRLF

    $title = $_;

    print pack 'I', (tell) - (length) - $eoll;	# dump file byte offset -2 for CRLF on dos/win

    # progress display
    print STDERR "$idx: $title\n" if ($idx % $prog == 0 || $idx == $limit - 1);
}
