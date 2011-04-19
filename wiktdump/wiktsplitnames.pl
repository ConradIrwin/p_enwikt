#!/usr/bin/perl

# wiktsplitnames indexfile dumpfile
#
# uses a binary index file to dump all the names from a dump file
#
# TODO support 64-bit indexes!

use bignum;
use strict;
use Encode;
use Getopt::Std;
use HTML::Entities;
#use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use Unicode::Normalize;

# $opt_b    emit bodies to fluxxo/ instead of titles to buxxo/
# $opt_n    Unicode normalization of titles

use vars qw($opt_b $opt_n $opt_6);

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

getopts('bn');

my $of = shift;
my $df = shift;

my $dfh;    # only used in the bzip2 case
my $mode;   # 0 for text, 1 for bzip2

open(DFH, $df) or die "no dump file";
open(OFH, $of) or die "no index file";

binmode(OFH);
if ($opt_n) {
	binmode(STDOUT, 'utf8');
} else {
	#this would set unix eol whereas the other tools seem to expect dos eol
	#binmode(STDOUT);
}

if (rindex($df, ".bz2") != -1) {
    print STDERR "** bzip2 compressed dump **\n";
    $mode = 1;
    #$dfh = new IO::Uncompress::Bunzip2(\*DFH) or die "IO::Uncompress::Bunzip2 failed: $Bunzip2Error\n";;
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

print STDERR "** index file: $of\n";
print STDERR "** dump file: $df\n";

# detect whether we have a 32-bit or 64+32-bit offset file

print STDERR '** dump offset size ', (-s OFH), "\n";
if ((-s OFH) % 12 == 0) {
    print STDERR "** an exact multiple of twelve, possibly a new-style 64-bit dump index\n";
    $opt_6 = 1;
} else {
    print STDERR "** not an exact multiple of twelve, an old-style 32-bit dump index\n";
    $opt_6 = 0;
}

my ($v, $o, $l, $t);

while (1) {
    if ($opt_6) {
        read(OFH, $v, 4) || last;
        $o = unpack('I', $v);
        read(OFH, $v, 4) || last;
        $o += unpack('I', $v) << 32;
        read(OFH, $v, 4) || last;
        $o += unpack('I', $v);
    } else {
        read(OFH, $v, 4) || last;
        $o = unpack('I', $v);
    }

    if ($mode == 0) {
        seek(DFH, $o, 0);# == 0 && die "seek doesnt work";
    } else {
        $dfh->seek($o, 0);
    }

    while (1) {
        if ($mode == 0) {
            $l = <DFH>;
        } else {
            $l = <$dfh>;
        }

        last if index($l, '<title>') != -1;
    }

    $l = decode('utf8', $l) if ($opt_n);

    # decode entities for tittle but not for line
    $t = decode_entities($l);

    $t = substr($t,11,length($t)-20);

    $t = NFD($t) if ($opt_n);

	my $ns = 0;
	my $colon = index($t, ':');
	if ($colon != -1) {
		my $nsname = substr($t, 0, $colon);
		$ns = $nses{$nsname};
		$ns = 0 if ($ns eq undef);
	}

    # don't look for == ??? == unless we're in the article namespace
    next unless $ns == 0;

    # this was here to allow prev/next in category but was never complete
    #if ($ns ne 0) {
    #    my ($left, $right) = ($t =~ /^([^:]*):(.*)$/);
    #    $opt_b || emit_title('_'.$left, $right);
    #    if ($opt_b) {
    #
    #        # ignore fields between title and text
    #        while (<DFH>) {
    #            last if (/<text /);
    #        }
    #
    #        $l = $_;
    #        my $islast = 0;
    #        my $body = '';
    #        while (1) {
    #            if (index($l, '      <text') == 0) {
    #                $l = substr($l, 33);
    #            }
    #            if (rindex($l, '</text>') != -1) {
    #                $l = substr($l, 0, -8);
    #                $islast = 1;
    #            }
    #
    #            $body .= $l;
    #
    #            $l = <DFH>;
    #
    #            last if $islast;
    #        }
    #        emit_prev_body('_'.$left, $t, $body);
    #    }
    #	next;
    #}

	# we have the title so now we need to check the namespace and look for language headings
	while (<DFH>) {
		last if (/<text /);
	}

	$l = $_;
	my $isfirst = 1;
	my $islast = 0;
	my $firstwikitextline;

    my $pagelang = '__prologs';
    my $body = '';

    # each line of <text>
	while (1) {
		if (index($l, '      <text') == 0) {
			$l = substr($l, 33);
		}
		if (rindex($l, '</text>') != -1) {
			$l = substr($l, 0, -8);
			$islast = 1;
		}
		if ($isfirst) {
			$firstwikitextline = $l;
			chomp $firstwikitextline;
            # TODO so far we only handle redirects in the article namespace
			if ($firstwikitextline =~ /^#\s*redirect\s*\[\[(.*?)\]\]/i) {
                # TODO a redirect page can have stuff after the redirect line
                $opt_b || emit_title('_Redirect', $t);
                $opt_b && emit_prev_body('_Redirect', $t, $l);
				last;
			}
			$isfirst = 0;
		}

        # have we come to a language heading?
		if ($l =~ /^==\s*([^=]*?)\s*==\s*$/) {
            $opt_b && emit_prev_body($pagelang, $t, $body);
			$pagelang = $1;
            $body = '';
			if ($pagelang =~ /^\[\[(.*)\]\]$/) {
				$pagelang = $1;
			}
            $opt_b || emit_title($pagelang, $t);
            $opt_b && ($body .= $l);
		}

        # not a language heading
        elsif ($opt_b && $pagelang) {
            $body .= $l;
        }

		if ($islast) {
            $opt_b && emit_prev_body($pagelang, $t, $body);
            last;
        }

		$l = <DFH>;
	}
}

sub emit_title {
    my $pagelang = shift;
    my $title = shift;

    # sanitize filenames. ==Portuguese / Spanish== has been seen
    if ($pagelang =~ /[\/%]/) {
        $pagelang =~ s/([\/%])/sprintf("%%%02X",ord($1))/eg;
    }

    if (open(LFH, ">>buxxo/$pagelang.txt")) {
        print LFH "$title\n";
        close(LFH);
    } else {
        print STDERR "can't open buxxo/$pagelang.txt\n";
    }
}

sub emit_prev_body {
    my $pagelang = shift;
    my $title = shift;
    my $body = shift;

    return unless $body ne '';

    # sanitize filenames. ==Portuguese / Spanish== has been seen
    if ($pagelang =~ /[\/%]/) {
        $pagelang =~ s/([\/%])/sprintf("%%%02X",ord($1))/eg;
    }

    if (open(LFH, ">>fluxxo/$pagelang.txt")) {
        print LFH "<page>\n  <title>$title</title>\n  <text>$body</text>\n</page><!--$title-->\n";
        close(LFH);
    } else {
        print STDERR "can't open fluxxo/$pagelang.txt\n";
    }
}
