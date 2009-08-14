#!/usr/bin/perl

# wiktmksortedidx namefile > en20081018-all-idx.raw

use strict;

our($NFH) = shift;
open NFH or die "no name file";

my $limit = 0;
my $prog = 10000;

my @names;
my @index_r;
my @index_s;
$#index_r = $#index_s = $#names = $limit ? $limit : 1200000;

print STDERR "limit is $limit\n";

my $i;
for ($i = 0; <NFH>; ++$i) {
	#last if $limit && $i >= $limit;
    chop;
    $names[$i] = $_;
    $index_r[$i] = $i;
    # progress display
    print STDERR "$i: $names[$i]\n" if ($i % $prog == 0 || $i == $limit - 1);
}
my $count = $i-1;
print STDERR "setting array lengths to $count\n";
$#names = $#index_r = $#index_s = $count;

print STDERR "sorting index\n";

@index_s = sort { $names[$a] cmp $names[$b] } @index_r;
#@index_s = sort { uc($names[$a]) cmp uc($names[$b]) || $names[$a] cmp $names[$b] } @index_r;

########## save

print STDERR "saving index\n";

binmode(STDOUT);

# write is not the opposite of read in perl - print is!
print STDOUT pack 'I*', @index_s;

