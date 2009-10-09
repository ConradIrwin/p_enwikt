#!/usr/bin/perl

# wiktperlang indexfile dumpfile
#
# uses a binary index file to dump the section structure of all the pages from a dump file

use strict;
use Encode;
use Getopt::Std;
use HTML::Entities;
use Unicode::Normalize;

# $opt_n    Unicode normalization of titles

use vars qw($opt_n);

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

my %lang2id;
my @id2lang;
my $lang_id_auto_inc = 0;

my %head2id;
my @id2head;
my $head_id_auto_inc = 0;

getopts('bn');

my $if = shift;
my $df = shift;

open(DFH, $df) or die "no dump file";
open(IFH, $if) or die "no index file";

binmode(IFH);
if ($opt_n) {
    binmode(STDOUT, 'utf8');
} else {
    #this would set unix eol whereas the other tools seem to expect dos eol
    #binmode(STDOUT);
}

my ($s, $e);

$s = <DFH>;
chomp $s;
seek(DFH, -12, 2);
$e = <DFH>;
chomp $e;
print STDERR "START: '$s', END: '$e'\n";

seek(DFH, 0, 0);

print STDERR "** index file: $if\n";
print STDERR "** dump file: $df\n";

my ($v, $o, $l, $t);

# each page in dump
for (my $page_i = 0; read(IFH, $v, 4); ++$page_i) {
    my $page;

    $o = unpack('I', $v);

    seek(DFH, $o, 0);# == 0 && die "seek doesnt work";
    $l = <DFH>;

    $l = decode('utf8', $l) if ($opt_n);

    $l = decode_entities($l);

    # -9 is for \n so probably needs to be -10 for \r\n
    $t = substr($l,11,-9);

    $t = NFD($t) if ($opt_n);

    # MySQL LOAD DATA INFILE requires backslashes to be escaped
    $t =~ s/\\/\\\\/g;

    $page->{title} = $t;
    #print "{t '$t')\n";

    my $ns = 0;
    my $colon = index($t, ':');
    if ($colon != -1) {
        my $nsname = substr($t, 0, $colon);
        $ns = $nses{$nsname};
        $ns = 0 if ($ns eq undef);
        $page->{nsnum} = $ns;
    }

    if ($ns ne 0) {
        my ($left, $right) = ($t =~ /^([^:]*):(.*)$/);
        $page->{nsname} = $left;
        id_for_lang('_'.$left);
        # TODO output namespace article bodies to a per-namespace file

        next;
    }

    # XXX we rudely assume that <id> is always on the line after <title>
    $page->{id} = <DFH>;
    # -6 is for \n so probably needs to be -7 for \r\n
    $page->{id} = substr($page->{id},8,-6);

    # we have the title so now we need to check the namespace and look for language headings
    while (<DFH>) {
        last if (/<text /);
    }

    $l = $_;
    my $isfirst = 1;
    my $islast = 0;
    my $firstwikitextline;

    my $pagehead = undef;

    # each line of <text>
    while (1) {
        if (index($l, '      <text') == 0) {
            $l = substr($l, 33);
        }
        if (rindex($l, '</text>') != -1) {
            $l = substr($l, 0, -8);
            $islast = 1;
        }
        $l = decode_entities($l);
        if ($isfirst) {
            $firstwikitextline = $l;
            chomp $firstwikitextline;

            # TODO so far we only handle redirects in the article namespace
            if ($firstwikitextline =~ /^#\s*redirect\s*\[\[(.*?)\]\]/i) {
                id_for_lang('_Redirect');

                last;
            }
            $isfirst = 0;
        }

        # have we come to a heading?
        if ($l =~ /^(=+)\s*([^=]*?)\s*(=+)\s*$/) {
            $pagehead = $2;
            my $level = length $1 <= length $3 ? length $1 : length $3;
            if ($pagehead =~ /^\[\[(.*)\]\]$/) {
                $pagehead = $1;
            }

            if ($level == 2) {
                id_for_lang($pagehead);

                push @{$page->{entries}}, { 'lang' => $lang2id{$pagehead} . "\t" . $pagehead };

            } elsif ($level > 2) {
                id_for_head($pagehead);

                unless (exists $page->{entries}) {
                    print STDERR "** section heading before any language heading. level $level: $t: $pagehead\n";
                    push @{$page->{entries}}, { 'lang' => "\\N\t\\N" };
                }

                push @{$page->{entries}->[-1]->{sects}}, $level . "\t" . $head2id{$pagehead} . "\t" . $pagehead;

            } else {
                print STDERR "** bad heading level $level: $t: $pagehead\n";
            }
        }

        if ($islast) {
            emit_page($page);

            last;
        }

        $l = <DFH>;
    }
}

sub id_for_lang {
    my $lang = shift;
    my $id;

    if (exists $lang2id{$lang}) {
        $id = $lang2id{$lang};
    } else {
        $id = $lang_id_auto_inc++;
        $lang2id{$lang} = $id;
        $id2lang[$id] = $lang;
        emit_lang($id . ':' . $lang);
    }

    return $id;
}

sub id_for_head {
    my $head = shift;
    my $id;

    if (exists $head2id{$head}) {
        $id = $head2id{$head};
    } else {
        $id = $head_id_auto_inc++;
        $head2id{$head} = $id;
        $id2head[$id] = $head;
        emit_head($id . ':' . $head);
    }

    return $id;
}

sub emit_lang {
    my $lang = shift;

    if (open(LFH, ">>__langnames.txt")) {
        print LFH "$lang\n";
        close(LFH);
    } else {
        print STDERR "can't open __langnames.txt\n";
    }
}

sub emit_head {
    my $head = shift;

    if (open(LFH, ">>__headings.txt")) {
        print LFH "$head\n";
        close(LFH);
    } else {
        print STDERR "can't open __headings.txt\n";
    }
}

sub emit_page {
    my $p = shift;

    if (open(PFH, ">>__pages.txt")) {
        foreach my $e (@{$p->{entries}}) {
            print PFH "$p->{id}\t$p->{title}\t$e->{lang}\t\\N\t\\N\t\\N\n";
            foreach my $s (@{$e->{sects}}) {
                print PFH "$p->{id}\t$p->{title}\t$e->{lang}\t$s\n";
            }
        }
        close(PFH);
    } else {
        print STDERR "can't open __pages.txt\n";
    }
}

