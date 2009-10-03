#!/usr/bin/perl

# wiktgrep needle dumpfile
#
# grep through a mediawiki dump file reporting the page title and language name for each result

use strict;
use Encode;
use HTML::Entities;
use Unicode::Normalize;

binmode STDIN, 'utf8';
binmode STDOUT, 'utf8';

my %nses = (
    'Talk' => 1,
    'User' => 2,
    'User talk' => 3,
    'Wiktionary' => 4,
    'Wiktionary talk' => 5,
    'File' => 6,
    'File talk' => 7,
    'MediaWiki' => 8,
    'MediaWiki talk' => 9,
    'Template' => 10,
    'Template talk' => 11,
    'Help' => 12,
    'Help talk' => 13,
    'Category' => 14,
    'Category talk' => 15,
    'Appendix' => 100,
    'Appendix talk' => 101,
    'Concordance' => 102,
    'Concordance talk' => 103,
    'Index' => 104,
    'Index talk' => 105,
    'Rhymes' => 106,
    'Rhymes talk' => 107,
    'Transwiki' => 108,
    'Transwiki talk' => 109,
    'Wikisaurus' => 110,
    'Wikisaurus talk' => 111,
    'WT' => 112,
    'WT talk' => 113,
    'Citations' => 114,
    'Citations talk' => 115,
);

my ($needle, $df);

if (scalar @ARGV != 2) {
    die "usage: wiktgrep <needle> <dumpfile>";
} else {
    ($needle, $df) = @ARGV;
    $needle = decode('utf8', $needle);
}
print "needle: '$needle'\n";
print "dump: '$df'\n";
open(DFH, $df) or die "no dump file";
binmode DFH, 'utf8';

print STDERR "** dump file: $df\n";

my ($r, $c);    # raw and cooked line
my $title = undef;
my $ns;
my $lang;
my $intext;
my $islast;
my $tetend;

#my $limit = 10000;
#my $linecount = $0;

while ($r = <DFH>) {
    if ($r =~ /<title>(.*)<\/title>/) {
        $title = $1;
        $ns = 0;
        my $colon = index($title, ':');
        if ($colon != -1) {
            my $l = substr($title, 0, $colon);
            $ns = $nses{$l} if exists $nses{$l};
        }
        $lang = $ns == 0 ? '(prolog)' : undef;
        #print "<title>$title</title>\n";
        next;
    }

    if (index($r, '      <text') == 0) {
        $intext = 1;
        $islast = 0;
        $r = substr($r, 33);
    }
    if (rindex($r, '</text>') != -1) {
        $r = substr($r, 0, -8);
        $islast = 1;
    }

    if ($intext) {
        $c = decode_entities($r);

        if ($ns == 0 && $c =~ /^(=+)\s*([^=]*?)\s*(=+)\s*$/) {
            my $head = $2;
            my $level = length $1 <= length $3 ? length $1 : length $3;
            if ($head =~ /^\[\[(.*)\]\]$/) {
                $head = $1;
            }
            if ($level == 2) {
                $lang = $head;
                #print "==$head==\n";
            }
        }




        elsif ($c =~ /$needle/) {
            print $., '||', $title, '||';
            $ns == 0 && print $lang, '||';
            print $c;
        }




        if ($islast) {
            $intext = 0;
        }
    }

    #last if ++$linecount > $limit;
}
