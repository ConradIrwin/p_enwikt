#!/usr/bin/perl

# wiktbsearch langcode date -thumb
# wiktbsearch langcode date needle
# wiktbsearch langcode date -p prefix
# wiktbsearch langcode date -lxx needle
#													  xx = langcode | "all"
# wiktbsearch langcode date [pP](att|ern)
#                           -d = debug
#                           -c = case insensitive

# TODO allow mixing of -l -c and patterns
# TODO support for combining chars
# TODO trees or other graphs rather than just sequences
# TODO eg fa(ç|c(|¸))ade
# TODO    fa-c-¸?-ade
# TODO      \ç---/

use utf8;
use strict;

use Encode;
use Getopt::Std;
use Unicode::Normalize;

use vars qw($opt_c $opt_d $opt_l $opt_n $opt_p $opt_r $opt_t $opt_u $opt_1);

getopts('cdl:nprtu1');

my $usethumb = 1;

my %thumbindex;

#my $dumppath = "E:\\Archives\\wiktdump\\";
#my $dumppath = "D:\\wiktdump\\";
my $dumppath = '/mnt/user-store/';

my ($dumplang, $date) = (shift, shift);

if ($dumplang eq 'en' && $date eq '20081028') {
	%thumbindex = (
    'A' => [ 2587, 9606 ], 'B' => [ 9607, 13300 ], 'C' => [ 13301, 39909 ],
    'D' => [ 39910, 42165 ], 'E' => [ 42166, 44757 ], 'F' => [ 44758, 46776 ],
    'G' => [ 46777, 49139 ], 'H' => [ 49140, 51426 ], 'I' => [ 51427, 55355 ],
    'J' => [ 55356, 56577 ], 'K' => [ 56578, 59069 ], 'L' => [ 59070, 61319 ],
    'M' => [ 61320, 65107 ], 'N' => [ 65108, 67080 ], 'O' => [ 67081, 68254 ],
    'P' => [ 68255, 71698 ], 'Q' => [ 71699, 71993 ], 'R' => [ 71994, 77849 ],
    'S' => [ 77850, 83261 ], 'T' => [ 83262, 95783 ], 'U' => [ 95784, 96535 ],
    'V' => [ 96536, 97862 ], 'W' => [ 97863, 99322 ], 'X' => [ 99323, 99540 ],
    'Y' => [ 99541, 99909 ], 'Z' => [ 99910, 100646 ],
    'a' => [ 100655, 193975 ], 'b' => [ 193976, 228362 ], 'c' => [ 228363, 305394 ],
    'd' => [ 305395, 369210 ], 'e' => [ 369211, 416678 ], 'f' => [ 416679, 445818 ],
    'g' => [ 445819, 468341 ], 'h' => [ 468342, 491544 ], 'i' => [ 491545, 536429 ],
    'j' => [ 536430, 543300 ], 'k' => [ 543301, 561804 ], 'l' => [ 561805, 587328 ],
    'm' => [ 587329, 628289 ], 'n' => [ 628290, 647139 ], 'o' => [ 647140, 668207 ],
    'p' => [ 668208, 733947 ], 'q' => [ 733948, 737235 ], 'r' => [ 737236, 809617 ],
    's' => [ 809618, 901989 ], 't' => [ 901990, 942815 ], 'u' => [ 942816, 952454 ],
    'v' => [ 952455, 973167 ], 'w' => [ 973168, 979597 ], 'x' => [ 979598, 980622 ],
    'y' => [ 980623, 983741 ], 'z' => [ 983742, 989046 ],
    'before' => [ 0, 2586 ], 'between' => [ 100647, 100654 ], 'after' => [ 989047, 1090663 ]
	);
} elsif ($dumplang eq 'en' && $date eq '20080613') {
	%thumbindex = (
		'A' => [ 2408, 9566 ], 'B' => [ 9567, 13570 ], 'C' => [ 13571, 38637 ],
		'D' => [ 38638, 41158 ], 'E' => [ 41159, 43822 ], 'F' => [ 43823, 46089 ],
		'G' => [ 46090, 48522 ], 'H' => [ 48523, 51044 ], 'I' => [ 51045, 55068 ],
		'J' => [ 55069, 56321 ], 'K' => [ 56322, 58806 ], 'L' => [ 58807, 61161 ],
		'M' => [ 61162, 65363 ], 'N' => [ 65364, 67398 ], 'O' => [ 67399, 68680 ],
		'P' => [ 68681, 72723 ], 'Q' => [ 72724, 73055 ], 'R' => [ 73056, 78913 ],
		'S' => [ 78914, 84743 ], 'T' => [ 84744, 100876 ], 'U' => [ 100877, 101821 ],
		'V' => [ 101822, 103426 ], 'W' => [ 103427, 109646 ], 'X' => [ 109647, 109879 ],
		'Y' => [ 109880, 110331 ], 'Z' => [ 110332, 111144 ],
		'a' => [ 111152, 181443 ], 'b' => [ 181444, 209829 ], 'c' => [ 209830, 270179 ],
		'd' => [ 270180, 319449 ], 'e' => [ 319450, 355498 ], 'f' => [ 355499, 379846 ],
		'g' => [ 379847, 398635 ], 'h' => [ 398636, 418232 ], 'i' => [ 418233, 450867 ],
		'j' => [ 450868, 456810 ], 'k' => [ 456811, 473336 ], 'l' => [ 473337, 493530 ],
		'm' => [ 493531, 527206 ], 'n' => [ 527207, 541651 ], 'o' => [ 541652, 557558 ],
		'p' => [ 557559, 612457 ], 'q' => [ 612458, 615166 ], 'r' => [ 615167, 677406 ],
		's' => [ 677407, 750914 ], 't' => [ 750915, 785639 ], 'u' => [ 785640, 794065 ],
		'v' => [ 794066, 811679 ], 'w' => [ 811680, 817726 ], 'x' => [ 817727, 818415 ],
		'y' => [ 818416, 821038 ], 'z' => [ 821039, 825451 ],
		'before' => [ 0, 2407 ], 'between' => [ 111145, 111151 ], 'after' => [ 825452, 920068 ]
	);
} elsif ($dumplang eq 'ja' && $date eq '20080617') {
	%thumbindex = (
		'A' => [ 119, 292 ], 'B' => [ 293, 383 ], 'C' => [ 384, 1893 ],
		'D' => [ 1894, 1985 ], 'E' => [ 1986, 2059 ], 'F' => [ 2060, 2149 ],
		'G' => [ 2150, 2234 ], 'H' => [ 2235, 2316 ], 'I' => [ 2317, 2392 ],
		'J' => [ 2393, 2483 ], 'K' => [ 2484, 2530 ], 'L' => [ 2531, 2612 ],
		'M' => [ 2613, 4488 ], 'N' => [ 4489, 4591 ], 'O' => [ 4592, 4644 ],
		'P' => [ 4645, 4769 ], 'Q' => [ 4770, 4784 ], 'R' => [ 4785, 4851 ],
		'S' => [ 4852, 5048 ], 'T' => [ 5049, 8107 ], 'U' => [ 8108, 8149 ],
		'V' => [ 8150, 8194 ], 'W' => [ 8195, 9126 ], 'X' => [ 9127, 9143 ],
		'Y' => [ 9144, 9160 ], 'Z' => [ 9161, 9190 ],
		'a' => [ 9191, 10218 ], 'b' => [ 10219, 10652 ], 'c' => [ 10653, 11405 ],
		'd' => [ 11406, 11956 ], 'e' => [ 11957, 12457 ], 'f' => [ 12458, 12948 ],
		'g' => [ 12949, 13257 ], 'h' => [ 13258, 13644 ], 'i' => [ 13645, 14059 ],
		'j' => [ 14060, 14184 ], 'k' => [ 14185, 14392 ], 'l' => [ 14393, 14791 ],
		'm' => [ 14792, 15382 ], 'n' => [ 15383, 15627 ], 'o' => [ 15628, 15921 ],
		'p' => [ 15922, 16930 ], 'q' => [ 16931, 16997 ], 'r' => [ 16998, 17391 ],
		's' => [ 17392, 18342 ], 't' => [ 18343, 18847 ], 'u' => [ 18848, 19007 ],
		'v' => [ 19008, 19584 ], 'w' => [ 19585, 19799 ], 'x' => [ 19800, 19812 ],
		'y' => [ 19813, 19887 ], 'z' => [ 19888, 19926 ],
		'before' => [ 0, 118 ], 'between' => [ 9191, 9190 ], 'after' => [ 19927, 39249 ]
	);
} elsif ($dumplang eq 'de' && $date eq '20080617') {
   %thumbindex = (
		'A' => [ 271, 3398 ], 'B' => [ 3399, 5484 ], 'C' => [ 5485, 6096 ],
		'D' => [ 6097, 7101 ], 'E' => [ 7102, 8545 ], 'F' => [ 8546, 9713 ],
		'G' => [ 9714, 11041 ], 'H' => [ 11042, 12478 ], 'I' => [ 12479, 13080 ],
		'J' => [ 13081, 13363 ], 'K' => [ 13364, 17020 ], 'L' => [ 17021, 17933 ],
		'M' => [ 17934, 20729 ], 'N' => [ 20730, 21475 ], 'O' => [ 21476, 21930 ],
		'P' => [ 21931, 23416 ], 'Q' => [ 23417, 23571 ], 'R' => [ 23572, 24643 ],
		'S' => [ 24644, 27504 ], 'T' => [ 27505, 28533 ], 'U' => [ 28534, 28935 ],
		'V' => [ 28936, 32473 ], 'W' => [ 32474, 34227 ], 'X' => [ 34228, 34298 ],
		'Y' => [ 34299, 34341 ], 'Z' => [ 34342, 34801 ],
		'a' => [ 34805, 42696 ], 'b' => [ 42697, 45536 ], 'c' => [ 45537, 49455 ],
		'd' => [ 49456, 52248 ], 'e' => [ 52249, 54167 ], 'f' => [ 54168, 56289 ],
		'g' => [ 56290, 58055 ], 'h' => [ 58056, 59297 ], 'i' => [ 59298, 60995 ],
		'j' => [ 60996, 61571 ], 'k' => [ 61572, 62994 ], 'l' => [ 62995, 64551 ],
		'm' => [ 64552, 67468 ], 'n' => [ 67469, 68599 ], 'o' => [ 68600, 69688 ],
		'p' => [ 69689, 73835 ], 'q' => [ 73836, 74105 ], 'r' => [ 74106, 76190 ],
		's' => [ 76191, 80541 ], 't' => [ 80542, 82736 ], 'u' => [ 82737, 83334 ],
		'v' => [ 83335, 85008 ], 'w' => [ 85009, 85622 ], 'x' => [ 85623, 85701 ],
		'y' => [ 85702, 85773 ], 'z' => [ 85774, 86286 ],
		'before' => [ 0, 270 ], 'between' => [ 34802, 34804 ], 'after' => [ 86287, 90377 ]
	);
} elsif ($dumplang eq 'es' && $date eq '20080613') {
   %thumbindex = (
		'A' => [ 223, 748 ], 'B' => [ 749, 1073 ], 'C' => [ 1074, 4159 ],
		'D' => [ 4160, 4295 ], 'E' => [ 4296, 4479 ], 'F' => [ 4480, 4630 ],
		'G' => [ 4631, 4808 ], 'H' => [ 4809, 5000 ], 'I' => [ 5001, 5183 ],
		'J' => [ 5184, 5268 ], 'K' => [ 5269, 5395 ], 'L' => [ 5396, 5567 ],
		'M' => [ 5568, 7320 ], 'N' => [ 7321, 7445 ], 'O' => [ 7446, 7529 ],
		'P' => [ 7530, 10901 ], 'Q' => [ 10902, 10917 ], 'R' => [ 10918, 11041 ],
		'S' => [ 11042, 11348 ], 'T' => [ 11349, 11539 ], 'U' => [ 11540, 11628 ],
		'V' => [ 11629, 11699 ], 'W' => [ 11700, 12676 ], 'X' => [ 12677, 12685 ],
		'Y' => [ 12686, 12717 ], 'Z' => [ 12718, 12744 ],
		'a' => [ 12745, 16356 ], 'b' => [ 16357, 17924 ], 'c' => [ 17925, 21070 ],
		'd' => [ 21071, 22290 ], 'e' => [ 22291, 23463 ], 'f' => [ 23464, 24557 ],
		'g' => [ 24558, 25524 ], 'h' => [ 25525, 26497 ], 'i' => [ 26498, 27187 ],
		'j' => [ 27188, 27566 ], 'k' => [ 27567, 28377 ], 'l' => [ 28378, 29359 ],
		'm' => [ 29360, 31075 ], 'n' => [ 31076, 31868 ], 'o' => [ 31869, 32464 ],
		'p' => [ 32465, 34536 ], 'q' => [ 34537, 34801 ], 'r' => [ 34802, 35650 ],
		's' => [ 35651, 37374 ], 't' => [ 37375, 38754 ], 'u' => [ 38755, 39072 ],
		'v' => [ 39073, 39776 ], 'w' => [ 39777, 40337 ], 'x' => [ 40338, 40398 ],
		'y' => [ 40399, 40600 ], 'z' => [ 40601, 40857 ],
		'before' => [ 0, 222 ], 'between' => [ 12745, 12744 ], 'after' => [ 40858, 43658 ]
	);
}

our($IFH, $TOFH, $TFH) = (
	$dumppath.$dumplang.$date.'-all' . ($opt_n ? '-norm' : '') . '-idx.raw',
	$dumppath.$dumplang.$date.'-all' . ($opt_n ? '-norm' : '') . '-off.raw',
	$dumppath.$dumplang.$date.'-all' . ($opt_n ? '-norm' : '') . '.txt');

open IFH or die "no index file (*-all-idx.raw) $IFH";
binmode IFH;
open TOFH or die "no title offset file (*-all-off.raw)";
binmode TOFH;
open TFH or die "no title file (*-all.txt)";

our($DFH, $OFH);
$DFH = $dumppath.$dumplang.'wiktionary-'.$date.'-pages-articles.xml';
unless (open DFH) {
	#print STDERR "no dump file (xxwiktionary-*-pages-articles.xml)\n";
	$DFH = $dumppath.$dumplang.'-wikt-'.$date.'.xml';
	unless (open DFH) {
		#print STDERR "no dump file (xx-wikt-*.xml)\n";
		die "no dump file";
	}
	$OFH = $dumppath.$dumplang.$date.'-off.raw',
	open OFH or die "no raw offset file (*-off.raw)";
	binmode OFH;
}

my $args = shift or die "no term to search for" unless ($opt_r);

-s $IFH == -s $TOFH or die "file sizes don't match";

my $haystacksize = (-s $IFH) / 4;

# generate thumb index
if ($args eq '-thumb') {
	$opt_d = 0;
	$usethumb = 0;
	my $cc;
	my %h;
	for (my $o = ord('A'); $o <= ord('Z') + 1; ++$o) {
		($h{$o}, $cc) = bsearch(chr($o));
	}
	for (my $o = ord('a'); $o <= ord('z') + 1; ++$o) {
		($h{$o}, $cc) = bsearch(chr($o));
	}
	my ($low, $high, $num, $mid);
	foreach (sort {$a <=> $b} keys %h) {
		my $o = $_;
		my $c = chr($_);
		if ($h{$o+1}) {
			($low, $high, $num, $mid) = calc($h{$o}, $h{$o+1});
		} else {
			($low, $high, $num, $mid) = ('-', '-', '-', '-');
		}
		print "    '$c' => [ $low, $high ],\n" if ($low ne '-');
		#print "    '$c' => [ $low, $high, $cc ],\n" if ($low ne '-');
	}
	($low, $high, $num, $mid) = calc(0, $h{ord('A')});
	print "    'before' => [ $low, $high ],\n";
	($low, $high, $num, $mid) = calc($h{ord('Z')+1}, $h{ord('a')});
	print "    'between' => [ $low, $high ],\n";
	($low, $high, $num, $mid) = calc($h{ord('z')+1}, $haystacksize);
	print "    'after' => [ $low, $high ]\n";
	print "$haystacksize entries\n";

	sub calc {
		my $start = shift;
		if ($start != int($start)) {
			$start = int($start + 0.5);
		}
		my $pastend = shift;
		if ($pastend != int($pastend)) {
			$pastend = int($pastend + 0.5);
		}
		my $num = $pastend - $start;
		my $mid = int(($start + $pastend) / 2);
		return ($start, $pastend - 1, $num, $mid);
	}

# search
} elsif ($opt_r) {
	print STDERR "reading from STDIN\n";
	if ($opt_u) {
		binmode STDIN, 'utf8';
		binmode STDOUT, 'utf8';
	}
	while (<>) {
		chop;
		callsearch($_);
	}
} else {
	callsearch($args);
}

exit;

###############################

sub callsearch {
	my $arg = shift;

	$arg = NFD($arg) if ($opt_n);

	if ($opt_p) {
		searchprefix($arg);
	} elsif ($opt_c) {
		searchcase($arg);
	} elsif ($opt_l) {
		if (!$opt_1 || length($arg) > 1) {
			searchlang($arg);
		}
	} elsif (index($arg, '[') != -1 || index($arg, '|') != -1) {
		searchvar($arg);
	} else {
		search($arg);
	}
}

sub search {
	print STDERR "regular search\n";
	my $needle = shift;

	my ($result, $compcount) = bsearch($needle);

	if ($result == int($result)) {
		print "'$needle' found at $result ($compcount comparisons)\n";
		
		if ($opt_t) {
			my $article = getarticle($result);

			print $article, "\n";
		}
	} else {
		print "'$needle' belongs at $result, between ",
		$result < 0 ? 'the beginning' : "'".gettitle($result - 0.5)."'",
		" and ",
		"'".gettitle($result + 0.5)."'",
		" ($compcount comparisons)\n";
	}
}

sub getarticle {
	my $index_s = shift;
	my $index_r;
	my $offset;
	my $article = undef;

	print STDERR "getting text of article #$index_s\n";

	$index_s < $haystacksize || die "sorted index $index_s too big";

	seek(IFH, $index_s * 4, 0) || die "sorted index seek error";
	read(IFH, $index_r, 4);
	$index_r = unpack 'I', $index_r;

	$index_r < $haystacksize || die "raw index $index_r too big (sorted index $index_s)";

	seek(OFH, $index_r * 4, 0) || die "raw index seek error";
	read(OFH, $offset, 4);
	$offset = unpack 'I', $offset;

	$offset < -s DFH || die "article offset $offset too big";

	seek(DFH, $offset, 0) || die "article eek error";

	my $l;
	while (1) {
		$l = <DFH>;
		last if ($l =~ /<text /);
	}

	$l =~ s/^.*<text .*>//;
	$article = $l;

	while (1) {
		$l = <DFH>;
		last if ($l =~ /<\/text>/);
		$article .= $l;
	}

	$l =~ s/<\/text>//;
	$article .= $l;

	return $article;
}

sub bsearch {
	my $size = $haystacksize;
	my $needle = shift;
	my $compcount = 0;

	my ($low, $high, $midpoint) = (0, $size - 1, 0);

	($low, $high) = thumb($needle, $size);

	$opt_d && print STDERR "$needle($low, $high)\n";

	my $c;
	while ($low <= $high) {
		$midpoint = int(($low + $high) / 2);
		$opt_d && print STDERR "mid $midpoint\n";

		$c = $needle cmp gettitle($midpoint);
		++$compcount;

		if ($c == 0) {
			return ($midpoint, $compcount);
		} elsif ($c == -1) {
			$high = $midpoint - 1;
		} else {
			$low = $midpoint + 1;
		}
	}
	return ($low - 0.5, $compcount);
}

sub searchprefix {
	print STDERR "prefix range search\n";
	my $prefix = shift;

	my ($left, $right, $compcount);
	($left, $right, $compcount) = bsearchp($prefix);

	if ($left == $right) {
		print "'$prefix' belongs at $left, between ",
		$left < 0 ? 'the beginning' : "'".gettitle($left - 0.5)."'",
		" and ",
		"'".gettitle($left + 0.5)."'",
		" ($compcount comparisons)\n";
	} else {
		$left = int($left + 0.5);
		$right = int($right - 0.5);

		print "'$prefix' ranges from $left to $right, from ",
		$left < 0 ? 'the beginning' : "'".gettitle($left)."'",
		" to ",
		"'".gettitle($right)."'",
		" ($compcount comparisons)\n";

		print "('".gettitle($left - 1)."') '".gettitle($left)."' ... '".gettitle($right)."' ('".gettitle($right + 1)."')\n";
	}
}

sub bsearchp {
	my $size = $haystacksize;
	my $prefix = shift;
	my $len = length($prefix);
	my ($left, $right);
	my $c;
	my $compcount = 0;

	my ($low, $high, $midpoint) = (0, $size - 1, 0);

	if (scalar @_ == 2 && $_[0] ne undef) {
		($low, $high) = @_;
		#$opt_d && print STDERR "$prefix passed low $low ", gettitle($low), ", high $high ", gettitle($high), "\n";
	} else {
		($low, $high) = thumb($prefix, $size);
		#$opt_d && print STDERR "$prefix low & high not passed\n";
	}

	my $highest = $high;

	$opt_d && print STDERR "$prefix($low, $high)\n";

	while ($low <= $high) {
		$midpoint = int(($low + $high) / 2);
		#$opt_d && print STDERR "mid $midpoint ", gettitle($midpoint), "\n";

		my $sub = substr(gettitle($midpoint), 0, $len);
		$c = $prefix cmp $sub;
		++$compcount;

		if ($c == 1) {
			$low = $midpoint + 1;
		} else {
			$high = $midpoint - 1;
		}
	}
	$left = $low - 0.5;

	$opt_d && print STDERR "----\n";

	$low = $left + 0.5;
	$high = $highest;

	while ($low <= $high) {
		$midpoint = int(($low + $high) / 2);
		#$opt_d && print STDERR "mid $midpoint ", gettitle($midpoint), "\n";

		my $sub = substr(gettitle($midpoint), 0, $len);
		$c = $prefix cmp $sub;
		++$compcount;

		if ($c == -1) {
			$high = $midpoint - 1;
		} else {
			$low = $midpoint + 1;
		}
	}
	$right = $low - 0.5;

	if ($opt_d) {
		my ($l, $r);
		if ($left == $right) {
			$l = int($left - 0.5);
			$r = int($right + 0.5);
		} else {
			$l = int($left + 0.5);
			$r = int($right - 0.5);
		}
		my ($tl, $tr) = (gettitle($l), gettitle($r));
		if ($left == $right) {
			print STDERR "$prefix belongs between $l $tl and $r $tr\n";
		} else {
			print STDERR "$prefix ranges from $l $tl to $r $tr\n";
		}
	}

	return ($left, $right, $compcount);
}

sub searchvar {
	print STDERR "variant search\n";
	my $arg = shift;

	my $r = do_searchvar($arg);

	printresults($arg, $r);
}

sub do_searchvar {
	my $arg = shift;
	$opt_d && print STDERR "arg: $arg\n";

	my @parts = ();
	my $chunk = '';
	my $l = length($arg);
	my $i = 0;
	my $e;
	my $c;

	while (1) {
		if (substr($arg, $i, 1) eq '(') {
			$e = index($arg, ')', $i + 1);
			if ($e == -1) {
				die "unmatched (";
			}
			my @alts = split('\|', substr($arg, $i + 1, $e - $i - 1));
			push @parts, \@alts;
			$opt_d && print "(alts): \"", join('", "', @alts), "\"\n";
			$i = $e + 1;
		} elsif (substr($arg, $i, 1) eq '[') {
			$e = index($arg, ']', $i + 1);
			if ($e == -1) {
				die "unmatched [";
			}
			my @alts = split('', substr($arg, $i + 1, $e - $i - 1));
			push @parts, \@alts;
			$opt_d && print "[alts]: \"", join('", "', @alts), "\"\n";
			$i = $e + 1;
		} else {
			my ($b, $p) = (index($arg, '[', $i), index($arg, '(', $i));
			if ($b == -1) {
				$e = $p;
			} elsif ($p == -1) {
				$e = $b;
			} else {
				$e = $b < $p ? $b : $p;
			}
			if ($e == -1) {
				$e = $l;
			}
			push @parts, substr($arg, $i, $e - $i);
			$opt_d && print '"lit": ', substr($arg, $i, $e - $i), "\n";
			$i = $e;
		}
		last if ($i >= $l);
	}

	if ($opt_d) {
		for my $p (@parts) {
			if (ref($p) eq 'ARRAY') {
				print "[";
				print join('|', @$p);
				print "]\n";
			} else {
				print "\"$p\"\n";
			}
		}
	}

	my @results;
	my $compcount = 0;
	my %shared = (
		'results' => \@results,
		'compcount' => \$compcount,
		'parts' => \@parts
	);

	searchvar_recur(\%shared, '', 0, undef, undef);

	@results = sort {uc($a) cmp uc($b) || $b cmp $a} @results;

	return { 'results' => \@results, 'compcount' => $compcount };
}

sub searchvar_recur {
	my ($shared, $prefix, $i, $low, $high) = @_;
	$opt_d && print STDERR "recur prefix '$prefix' i $i low $low high $high\n";

	# all parts matched, but maybe there is extra stuff at the end
	if ($i == scalar @{$shared->{'parts'}}) {
		if (gettitle($low) eq encode('utf8', $prefix)) {
			$opt_d && print STDERR "** found \"$prefix\" ($low)\n";
			push @{$shared->{'results'}}, $prefix;
		}
		return;
	}

	my $p = $shared->{'parts'}->[$i];

	$p = [ $p ] unless (ref($p) eq 'ARRAY');
	my @sp = sort @$p;

	for (my $vi = 0; $vi < scalar @sp; ++$vi) {
		my $thisvar = $sp[$vi];
		my $nextvar = $sp[$vi + 1];
		my $newpre = $prefix . $thisvar;
		$opt_d && print STDERR encode('utf8', "\"$newpre\" : \"$prefix\" + \"$thisvar\"\n");
		my ($l, $r, $cc) = bsearchp(encode('utf8', $newpre), $low, $high);
		${$shared->{'compcount'}} += $cc;
		if ($l == $r) {
			#print STDERR "X $newpre ($l, $r)\n";
		} else {
			searchvar_recur($shared, $prefix . $thisvar, $i + 1, int($l + 0.5), int($r - 0.5));
		}

		# only if we were called with upper and lower bounds
		$opt_d && print STDERR "prefix $prefix thisvar $thisvar\n";
		if ($low ne undef) {
			if ($thisvar ne '') {
				$opt_d && print STDERR "nextvar '$nextvar' thisvar '$thisvar' index ", index($nextvar, $thisvar), "\n";
				if (index($nextvar, $thisvar) == -1) {
					$opt_d && print STDERR "trying shortcut\n";
					# if we make $low higher than $r then terms which start the same will be skipped
					$low = int($r + 0.5);
					$opt_d && print STDERR "low -> $low, high $high\n";
					if ($low > $high) {
						$opt_d && print STDERR "low > high\n";
						last;
					}
				} else {
					$opt_d && print STDERR "not trying shortcut (nextvar is an extension of thisvar)\n";
				}
			} else {
				$opt_d && print STDERR "not trying shortcut (thisvar not empty)\n";
			}
		} else {
			$opt_d && print STDERR "not trying shortcut (low)\n";
		}
	}
}

sub searchcase {
	print STDERR "case independent search\n";
	my $arg = shift;
	my $exp = '';
	my $i;
	my $c;
	my ($l, $u);
	my $v;

	$opt_d && print STDERR "arg: $arg\n";

	for ($i = 0; $i < length($arg); ++$i) {
		$c = substr($arg, $i, 1);
		if ($c eq '[' || $c eq '(') {
			my $e = index($arg, ($c eq '[' ? ']' : ')'), $i + 1);
			if ($e == -1) {
				die "unmatched $c";
			}
			$v = substr($arg, $i, $e - $i + 1);
			$opt_d && print "[literal alts]: \"$v\"\n";
			$i = $e;
		} else {
			$l = lc($c);
			$u = uc($c);

			$v = ($l eq $u) ? $c : ('[' . $l . $u . ']');
		}
		$exp .= $v;
	}

	$opt_d && print STDERR "arg: $arg, exp: $exp\n";

	my $r = do_searchvar($exp);

	printresults($arg, $r);
}

sub searchlang {
	print STDERR "language variant search\n" unless ($opt_r);
	my $arg = shift;
	my $exp = '';
	my $i;
	my ($c, $c2);
	my $v;

	$opt_d && print STDERR "arg: $arg\n";

	for ($i = 0; $i < length($arg); ++$i) {
		$c = substr($arg, $i, 1);
		$c2 = substr($arg, $i + 1, 1);
		if ($c eq '[' || $c eq '(') {
			my $e = index($arg, ($c eq '[' ? ']' : ')'), $i + 1);
			if ($e == -1) {
				die "unmatched $c";
			}
			$v = substr($arg, $i, $e - $i + 1);
			$opt_d && print "[literal alts]: \"$v\"\n";
			$i = $e;
		} else {
			my $l;
			($v, $l) = getvariants($opt_l, $c, $c2);
			$i += $l;
		}
		$exp .= $v;
	}

	$opt_d && print STDERR "lang: $opt_l, arg: $arg, exp: $exp\n";

	my $r = do_searchvar($exp);

	if (!$opt_1 || scalar @{$r->{'results'}} > 1) {
		printresults($arg, $r);
	}
}

sub getvariants {
	my ($dumplang, $ch, $ch2) = @_;
	my ($oc, $oc2) = (ord($ch), ord($ch2));
	my $vars = $ch;
	my $len = 0;

	if ($dumplang eq 'all') {
		my $acute = 'áćéíĺńóŕśúẃýź';
		my $Acute = 'ÁĆÉÍĹŃÓŔŚÚẂÝŹ';
		my $grave = 'àèìòùẁỳ';
		my $Grave = 'ÀÈÌÒÙẀỲ';
		my $cirumflex = 'âĉêĝĥîĵôŝûŵŷ';
		my $Cirumflex = 'ÂĈÊĜĤÎĴÔŜÛŴŶ';
		my $diaresis = 'äëïöüẅÿ';
		my $Diaresis = 'ÄËÏÖÜẄŸ';
		my $tilde = 'ãẽĩñõũỹ';
		my $Tilde = 'ÃẼĨÑÕŨỸ';
		my $macron = 'āēīōū';
		my $Macron = 'ĀĒĪŌŪ';
		my $hacek = 'ǎčďěǐňǒřšťǔž';
		my $Hacek = 'ǍČĎĚǏŇǑŘŠŤǓŽ';
		my $breve = 'ăĕğĭŏŭ';
		my $Breve = 'ĂĔĞĬŎŬ';
		my $ring = 'åů';
		my $Ring = 'ÅŮ';
		my $ogonek = 'ąęįų';
		my $Ogonek = 'ĄĘĮŲ';
		my $vq = 'ảẻỉỏủỷ';
		my $Vq = 'ẢẺỈỎỦỶ';
		my $cedilla = 'çģķļņŗşţ';
		my $Cedilla = 'ÇĢĶĻŅŖŞŢ';
		my $dot = 'ċėġıż';
		my $Dot = 'ĊĖĠİŻ';
		my $bar = 'đħŧ';
		my $Bar = 'ĐĦŦ';
		my $slash = 'łø';
		my $Slash = 'ŁØ';
		my $doubleacute = 'őű';
		my $Doubleacute = 'ŐŰ';
		my $horn = 'ơư';
		my $Horn = 'ƠƯ';

		my $a = 'áàâäãāǎăåąảấầẩẫậắằẳẵặ';
		my $ae = 'æ';
		my $c = 'ćçčĉċ';
		my $d = 'ďđ';
		my $e = 'éèêëẽēěĕėęẻếềểễệ';
		my ($fi, $fl) = 'ﬁﬂ';
		my $g = 'ĝğġģ';
		my $h = 'ĥħ';
		my $i = 'íìîïĩīǐĭıįỉ';
		my $ij = 'ĳ';
		my $j = 'ĵ';
		my $k = 'ķ';
		my $l = 'łľļĺ';
		my $n = 'ñŋńņňŉ';
		my $o = 'óòôöõōǒŏøőơỏốồổỗộớờởỡợ';
		my $oe = 'œ';
		my $r = 'ŕřŗ';
		my $s = 'šśşŝ';
		my $ss = 'ß';
		my $t = 'ţťŧ';
		my $u = 'úùûüũūǔŭűųůưủǖǘǚǜứừửữự';
		my $w = 'ẃẁẅŵ';
		my $y = 'ýỳÿỷŷỹ';
		my $z = 'żžź';
		my $lig = $ae . $fi . $fl . $ij . $oe . $ss;
		my $A = 'ÁÀÂÄÃĀǍĂÅĄẢẤẦẨẪẬẮẰẲẴẶ';
		my $Ae = 'Æ';
		my $C = 'ĆÇČĈĊ';
		my $D = 'ĎĐ';
		my $E = 'ÉÈÊËẼĒĚĔĖĘẺẾỀỂỄỆ';
		my $G = 'ĜĞĠĢ';
		my $H = 'ĤĦ';
		my $I = 'ÍÌÎÏĨĪǏĬĮİỈ';
		my $Ij = 'Ĳ';
		my $J = 'Ĵ';
		my $K = 'Ķ';
		my $L = 'ŁĽĻĹ';
		my $N = 'ÑŊŃŅŇ';
		my $O = 'ÓÒÔÖÕŌǑŎŐƠỎỐỒỔỖỘỚỜỞỠỢ';
		my $Oe = 'Œ';
		my $R = 'ŔŘŖ';
		my $S = 'ŠŚŞŜ';
		my $T = 'ŢŤŦ';
		my $U = 'ÚÙÛÜŨŪǓŬŰŲŮƯỦǕǗǙǛỨỪỬỮỰ';
		my $W = 'ẂẀẄ';
		my $Y = 'ÝỲŸỶŶỸ';
		my $Z = 'ŻŽŹ';
		my $Lig = $Ae . $Ij . $Oe;

		if ($ch eq '?') {
			$vars = '[àáâãäåāăąǎảấầẩẫậắằẳẵặæćĉçċčďđèéêẽëēĕėęěẻếềểễệﬁﬂĝģğġĥħìíîĩïīĭıįǐỉĳĵķĺļľłńñņňŋŉóòôöõōǒŏőơỏốồổỗộớờởỡợœŕřŗšśşŝßţťŧúùûüũūǔŭűųůưủǖǘǚǜứừửữựẃẁẅýỳÿỷŷỹżžźÁÀÂÄÃĀǍĂÅĄẢẤẦẨẪẬẮẰẲẴẶÆĆÇČĈĊĎĐÉÈÊËẼĒĚĔĖĘẺẾỀỂỄỆĜĞĠĢĤĦÍÌÎÏĨĪǏĬĮİỈĲĴĶŁĽĻĹÑŊŃŅŇÓÒÔÖÕŌǑŎŐƠỎỐỒỔỖỘỚỜỞỠỢŒŔŘŖŠŚŞŜŢŤŦÚÙÛÜŨŪǓŬŰŲŮƯỦǕǗǙǛỨỪỬỮỰẂẀẄÝỲŸỶŶỸŻŽŹ]';
		} elsif ($ch eq 'a' && $ch2 eq 'e') {
			$vars = '(ae|æ)'; $len = 1;
		} elsif ($ch eq 'a') {
			$vars = '[' . 'a' . $a . ']';
		} elsif ($ch eq 'c') {
			$vars = '[' . 'c' . $c . ']';
		} elsif ($ch eq 'd') {
			$vars = '[' . 'd' . $d . ']';
		} elsif ($ch eq 'e') {
			$vars = '[' . 'e' . $e . ']';
		} elsif ($ch eq 'f' && $ch2 eq 'i') {
			$vars = '(fi|ﬁ)'; $len = 1;
		} elsif ($ch eq 'f' && $ch2 eq 'l') {
			$vars = '(fl|ﬂ)'; $len = 1;
		} elsif ($ch eq 'g') {
			$vars = '[' . 'g' . $g . ']';
		} elsif ($ch eq 'h') {
			$vars = '[' . 'h' . $h . ']';
		} elsif ($ch eq 'i' && $ch2 eq 'j') {
			$vars = '(ij|ĳ)'; $len = 1;
		} elsif ($ch eq 'i') {
			$vars = '[' . 'i' . $i . ']';
		} elsif ($ch eq 'j') {
			$vars = '[' . 'j' . $j . ']';
		} elsif ($ch eq 'k') {
			$vars = '[' . 'k' . $k . ']';
		} elsif ($ch eq 'l') {
			$vars = '[' . 'l' . $l . ']';
		} elsif ($ch eq 'n') {
			$vars = '[' . 'n' . $n . ']';
		} elsif ($ch eq 'o' && $ch2 eq 'e') {
			$vars = '(oe|œ)'; $len = 1;
		} elsif ($ch eq 'o') {
			$vars = '[' . 'o' . $o . ']';
		} elsif ($ch eq 'r') {
			$vars = '[' . 'r' . $r . ']';
		} elsif ($ch eq 's' && $ch2 eq 's') {
			$vars = '(ss|ß)'; $len = 1;
		} elsif ($ch eq 's') {
			$vars = '[' . 's' . $s . ']';
		} elsif ($ch eq 't') {
			$vars = '[' . 't' . $t . ']';
		} elsif ($ch eq 'u') {
			$vars = '[' . 'u' . $u . ']';
		} elsif ($ch eq 'w') {
			$vars = '[' . 'w' . $w . ']';
		} elsif ($ch eq 'y') {
			$vars = '[' . 'y' . $y . ']';
		} elsif ($ch eq 'z') {
			$vars = '[' . 'z' . $z . ']';

		} elsif ($ch eq 'A' && $ch2 eq 'E') {
			$vars = '(AE|Æ)'; $len = 1;
		} elsif ($ch eq 'A') {
			$vars = '[' . 'A' . $A . ']';
		} elsif ($ch eq 'C') {
			$vars = '[' . 'C' . $C . ']';
		} elsif ($ch eq 'D') {
			$vars = '[' . 'D' . $D . ']';
		} elsif ($ch eq 'E') {
			$vars = '[' . 'E' . $E . ']';
		} elsif ($ch eq 'F' && $ch2 eq 'I') {
			$vars = '(FI|ﬁ)'; $len = 1;
		} elsif ($ch eq 'F' && $ch2 eq 'L') {
			$vars = '(FL|ﬂ)'; $len = 1;
		} elsif ($ch eq 'G') {
			$vars = '[' . 'G' . $G . ']';
		} elsif ($ch eq 'H') {
			$vars = '[' . 'H' . $H . ']';
		} elsif ($ch eq 'I' && $ch2 eq 'J') {
			$vars = '(IJ|Ĳ)'; $len = 1;
		} elsif ($ch eq 'I') {
			$vars = '[' . 'I' . $I . ']';
		} elsif ($ch eq 'J') {
			$vars = '[' . 'J' . $J . ']';
		} elsif ($ch eq 'K') {
			$vars = '[' . 'K' . $K . ']';
		} elsif ($ch eq 'L') {
			$vars = '[' . 'L' . $L . ']';
		} elsif ($ch eq 'N') {
			$vars = '[' . 'N' . $N . ']';
		} elsif ($ch eq 'O' && $ch2 eq 'E') {
			$vars = '(OE|Œ)'; $len = 1;
		} elsif ($ch eq 'O') {
			$vars = '[' . 'O' . $O . ']';
		} elsif ($ch eq 'R') {
			$vars = '[' . 'R' . $R . ']';
		} elsif ($ch eq 'S' && $ch2 eq 'S') {
			$vars = '(SS|ß)'; $len = 1;
		} elsif ($ch eq 'S') {
			$vars = '[' . 'S' . $S . ']';
		} elsif ($ch eq 'T') {
			$vars = '[' . 'T' . $T . ']';
		} elsif ($ch eq 'U') {
			$vars = '[' . 'U' . $U . ']';
		} elsif ($ch eq 'W') {
			$vars = '[' . 'W' . $W . ']';
		} elsif ($ch eq 'Y') {
			$vars = '[' . 'Y' . $Y . ']';
		} elsif ($ch eq 'Z') {
			$vars = '[' . 'Z' . $Z . ']';
		}
	} elsif ($dumplang eq 'cjk') {
		if ($ch eq '一') {
			$vars = '[一壹弌]';
		} elsif ($ch eq '七') {
			$vars = '[七柒]';
		} elsif ($ch eq '万') {
			$vars = '[万萬卍]';
		} elsif ($ch eq '三') {
			$vars = '[三叁]';
		} elsif ($ch eq '丌') {
			$vars = '[丌其]';
		} elsif ($ch eq '不') {
			$vars = '[不不]';
		} elsif ($ch eq '与') {
			$vars = '[与與]';
		} elsif ($ch eq '丑') {
			$vars = '[丑醜]';
		} elsif ($ch eq '专') {
			$vars = '[专專]';
		} elsif ($ch eq '丕') {
			$vars = '[丕仳]';
		} elsif ($ch eq '世') {
			$vars = '[世丗]';
		} elsif ($ch eq '丗') {
			$vars = '[丗世]';
		} elsif ($ch eq '丘') {
			$vars = '[丘坵]';
		} elsif ($ch eq '业') {
			$vars = '[业業]';
		} elsif ($ch eq '丛') {
			$vars = '[丛叢]';
		} elsif ($ch eq '东') {
			$vars = '[东東]';
		} elsif ($ch eq '丝') {
			$vars = '[丝絲]';
		} elsif ($ch eq '丟') {
			$vars = '[丟丢]';
		} elsif ($ch eq '両') {
			$vars = '[両两兩]';
		} elsif ($ch eq '丢') {
			$vars = '[丢丟]';
		} elsif ($ch eq '两') {
			$vars = '[两両兩]';
		} elsif ($ch eq '严') {
			$vars = '[严嚴]';
		} elsif ($ch eq '並') {
			$vars = '[並幷并竝]';
		} elsif ($ch eq '丧') {
			$vars = '[丧喪]';
		} elsif ($ch eq '个') {
			$vars = '[个個箇]';
		} elsif ($ch eq '丬') {
			$vars = '[丬爿]';
		} elsif ($ch eq '中') {
			$vars = '[中塚]';
		} elsif ($ch eq '丰') {
			$vars = '[丰豐]';
		} elsif ($ch eq '串') {
			$vars = '[串串]';
		} elsif ($ch eq '临') {
			$vars = '[临臨]';
		} elsif ($ch eq '丹') {
			$vars = '[丹丹]';
		} elsif ($ch eq '为') {
			$vars = '[为爲為]';
		} elsif ($ch eq '丼') {
			$vars = '[丼井]';
		} elsif ($ch eq '丽') {
			$vars = '[丽麗]';
		} elsif ($ch eq '举') {
			$vars = '[举舉]';
		} elsif ($ch eq '乃') {
			$vars = '[乃廼迺]';
		} elsif ($ch eq '乇') {
			$vars = '[乇虐]';
		} elsif ($ch eq '么') {
			$vars = '[么麼幺麽]';
		} elsif ($ch eq '义') {
			$vars = '[义義]';
		} elsif ($ch eq '乌') {
			$vars = '[乌烏]';
		} elsif ($ch eq '乐') {
			$vars = '[乐樂]';
		} elsif ($ch eq '乔') {
			$vars = '[乔喬]';
		} elsif ($ch eq '乕') {
			$vars = '[乕虎]';
		} elsif ($ch eq '乗') {
			$vars = '[乗乘]';
		} elsif ($ch eq '乘') {
			$vars = '[乘乗]';
		} elsif ($ch eq '九') {
			$vars = '[九玖]';
		} elsif ($ch eq '习') {
			$vars = '[习習]';
		} elsif ($ch eq '乡') {
			$vars = '[乡鄉]';
		} elsif ($ch eq '书') {
			$vars = '[书書]';
		} elsif ($ch eq '乩') {
			$vars = '[乩稽]';
		} elsif ($ch eq '买') {
			$vars = '[买買]';
		} elsif ($ch eq '乱') {
			$vars = '[乱亂]';
		} elsif ($ch eq '乾') {
			$vars = '[乾干]';
		} elsif ($ch eq '亀') {
			$vars = '[亀龜]';
		} elsif ($ch eq '亂') {
			$vars = '[亂乱]';
		} elsif ($ch eq '了') {
			$vars = '[了了]';
		} elsif ($ch eq '予') {
			$vars = '[予余豫]';
		} elsif ($ch eq '争') {
			$vars = '[争爭]';
		} elsif ($ch eq '亊') {
			$vars = '[亊事]';
		} elsif ($ch eq '事') {
			$vars = '[事亊]';
		} elsif ($ch eq '二') {
			$vars = '[二貳弍贰]';
		} elsif ($ch eq '于') {
			$vars = '[于於]';
		} elsif ($ch eq '亏') {
			$vars = '[亏虧於]';
		} elsif ($ch eq '云') {
			$vars = '[云雲]';
		} elsif ($ch eq '亓') {
			$vars = '[亓其]';
		} elsif ($ch eq '五') {
			$vars = '[五伍]';
		} elsif ($ch eq '井') {
			$vars = '[井丼]';
		} elsif ($ch eq '亘') {
			$vars = '[亘亙]';
		} elsif ($ch eq '亚') {
			$vars = '[亚亞]';
		} elsif ($ch eq '亜') {
			$vars = '[亜亞]';
		} elsif ($ch eq '亞') {
			$vars = '[亞亜亚]';
		} elsif ($ch eq '产') {
			$vars = '[产産產]';
		} elsif ($ch eq '亩') {
			$vars = '[亩畝]';
		} elsif ($ch eq '京') {
			$vars = '[京亰]';
		} elsif ($ch eq '亮') {
			$vars = '[亮亮]';
		} elsif ($ch eq '亰') {
			$vars = '[亰京]';
		} elsif ($ch eq '亲') {
			$vars = '[亲榛親]';
		} elsif ($ch eq '亵') {
			$vars = '[亵褻]';
		} elsif ($ch eq '人') {
			$vars = '[人亻]';
		} elsif ($ch eq '亻') {
			$vars = '[亻人]';
		} elsif ($ch eq '亿') {
			$vars = '[亿億]';
		} elsif ($ch eq '什') {
			$vars = '[什什]';
		} elsif ($ch eq '仂') {
			$vars = '[仂働]';
		} elsif ($ch eq '仃') {
			$vars = '[仃停]';
		} elsif ($ch eq '仅') {
			$vars = '[仅僅]';
		} elsif ($ch eq '仆') {
			$vars = '[仆僕]';
		} elsif ($ch eq '仇') {
			$vars = '[仇讐讎]';
		} elsif ($ch eq '从') {
			$vars = '[从從]';
		} elsif ($ch eq '仏') {
			$vars = '[仏佛]';
		} elsif ($ch eq '仑') {
			$vars = '[仑侖]';
		} elsif ($ch eq '仓') {
			$vars = '[仓倉]';
		} elsif ($ch eq '他') {
			$vars = '[他她牠]';
		} elsif ($ch eq '仙') {
			$vars = '[仙僊]';
		} elsif ($ch eq '仝') {
			$vars = '[仝同]';
		} elsif ($ch eq '仞') {
			$vars = '[仞仭]';
		} elsif ($ch eq '仟') {
			$vars = '[仟阡千]';
		} elsif ($ch eq '令') {
			$vars = '[令令]';
		} elsif ($ch eq '仪') {
			$vars = '[仪儀]';
		} elsif ($ch eq '们') {
			$vars = '[们們]';
		} elsif ($ch eq '仭') {
			$vars = '[仭仞]';
		} elsif ($ch eq '仮') {
			$vars = '[仮假]';
		} elsif ($ch eq '仳') {
			$vars = '[仳丕]';
		} elsif ($ch eq '价') {
			$vars = '[价價]';
		} elsif ($ch eq '份') {
			$vars = '[份彬分]';
		} elsif ($ch eq '仿') {
			$vars = '[仿倣]';
		} elsif ($ch eq '伀') {
			$vars = '[伀彸]';
		} elsif ($ch eq '伍') {
			$vars = '[伍五]';
		} elsif ($ch eq '众') {
			$vars = '[众眾衆]';
		} elsif ($ch eq '优') {
			$vars = '[优優]';
		} elsif ($ch eq '伙') {
			$vars = '[伙夥]';
		} elsif ($ch eq '会') {
			$vars = '[会會]';
		} elsif ($ch eq '伛') {
			$vars = '[伛傴]';
		} elsif ($ch eq '伜') {
			$vars = '[伜倅]';
		} elsif ($ch eq '伝') {
			$vars = '[伝傳]';
		} elsif ($ch eq '伞') {
			$vars = '[伞傘]';
		} elsif ($ch eq '伟') {
			$vars = '[伟偉]';
		} elsif ($ch eq '传') {
			$vars = '[传傳]';
		} elsif ($ch eq '伤') {
			$vars = '[伤傷]';
		} elsif ($ch eq '伥') {
			$vars = '[伥倀]';
		} elsif ($ch eq '伦') {
			$vars = '[伦倫]';
		} elsif ($ch eq '伧') {
			$vars = '[伧傖]';
		} elsif ($ch eq '伪') {
			$vars = '[伪僞偽]';
		} elsif ($ch eq '伫') {
			$vars = '[伫佇]';
		} elsif ($ch eq '伭') {
			$vars = '[伭玄]';
		} elsif ($ch eq '伲') {
			$vars = '[伲你]';
		} elsif ($ch eq '佇') {
			$vars = '[佇竚伫]';
		} elsif ($ch eq '佈') {
			$vars = '[佈布]';
		} elsif ($ch eq '佑') {
			$vars = '[佑祐]';
		} elsif ($ch eq '体') {
			$vars = '[体軆體]';
		} elsif ($ch eq '佔') {
			$vars = '[佔占]';
		} elsif ($ch eq '佗') {
			$vars = '[佗它]';
		} elsif ($ch eq '余') {
			$vars = '[余馀餘予]';
		} elsif ($ch eq '佛') {
			$vars = '[佛仏]';
		} elsif ($ch eq '佞') {
			$vars = '[佞侫]';
		} elsif ($ch eq '你') {
			$vars = '[你妳]';
		} elsif ($ch eq '佣') {
			$vars = '[佣傭]';
		} elsif ($ch eq '佥') {
			$vars = '[佥僉]';
		} elsif ($ch eq '佬') {
			$vars = '[佬姆]';
		} elsif ($ch eq '佰') {
			$vars = '[佰百]';
		} elsif ($ch eq '併') {
			$vars = '[併并倂]';
		} elsif ($ch eq '侁') {
			$vars = '[侁詵駪]';
		} elsif ($ch eq '侂') {
			$vars = '[侂託]';
		} elsif ($ch eq '侄') {
			$vars = '[侄姪]';
		} elsif ($ch eq '侅') {
			$vars = '[侅賅]';
		} elsif ($ch eq '來') {
			$vars = '[來來来耒]';
		} elsif ($ch eq '侉') {
			$vars = '[侉誇]';
		} elsif ($ch eq '侖') {
			$vars = '[侖仑崙]';
		} elsif ($ch eq '侚') {
			$vars = '[侚殉]';
		} elsif ($ch eq '侠') {
			$vars = '[侠俠]';
		} elsif ($ch eq '価') {
			$vars = '[価價]';
		} elsif ($ch eq '侣') {
			$vars = '[侣侶]';
		} elsif ($ch eq '侥') {
			$vars = '[侥僥]';
		} elsif ($ch eq '侦') {
			$vars = '[侦偵]';
		} elsif ($ch eq '侧') {
			$vars = '[侧側]';
		} elsif ($ch eq '侨') {
			$vars = '[侨僑]';
		} elsif ($ch eq '侩') {
			$vars = '[侩儈]';
		} elsif ($ch eq '侪') {
			$vars = '[侪儕]';
		} elsif ($ch eq '侫') {
			$vars = '[侫佞]';
		} elsif ($ch eq '侬') {
			$vars = '[侬儂]';
		} elsif ($ch eq '侭') {
			$vars = '[侭儘]';
		} elsif ($ch eq '侶') {
			$vars = '[侶侣]';
		} elsif ($ch eq '便') {
			$vars = '[便便]';
		} elsif ($ch eq '俁') {
			$vars = '[俁俣]';
		} elsif ($ch eq '係') {
			$vars = '[係系]';
		} elsif ($ch eq '俊') {
			$vars = '[俊儁]';
		} elsif ($ch eq '俎') {
			$vars = '[俎爼]';
		} elsif ($ch eq '俓') {
			$vars = '[俓勁徑]';
		} elsif ($ch eq '俞') {
			$vars = '[俞兪]';
		} elsif ($ch eq '俟') {
			$vars = '[俟竢]';
		} elsif ($ch eq '俠') {
			$vars = '[俠侠]';
		} elsif ($ch eq '俣') {
			$vars = '[俣俁]';
		} elsif ($ch eq '俦') {
			$vars = '[俦儔]';
		} elsif ($ch eq '俨') {
			$vars = '[俨儼]';
		} elsif ($ch eq '俩') {
			$vars = '[俩倆]';
		} elsif ($ch eq '俪') {
			$vars = '[俪儷]';
		} elsif ($ch eq '俭') {
			$vars = '[俭儉]';
		} elsif ($ch eq '俯') {
			$vars = '[俯頫]';
		} elsif ($ch eq '俱') {
			$vars = '[俱倶]';
		} elsif ($ch eq '倀') {
			$vars = '[倀伥]';
		} elsif ($ch eq '倂') {
			$vars = '[倂併]';
		} elsif ($ch eq '倅') {
			$vars = '[倅伜]';
		} elsif ($ch eq '倆') {
			$vars = '[倆俩]';
		} elsif ($ch eq '倉') {
			$vars = '[倉仓]';
		} elsif ($ch eq '個') {
			$vars = '[個个箇]';
		} elsif ($ch eq '們') {
			$vars = '[們们]';
		} elsif ($ch eq '倖') {
			$vars = '[倖囟幸]';
		} elsif ($ch eq '倘') {
			$vars = '[倘儻]';
		} elsif ($ch eq '借') {
			$vars = '[借藉]';
		} elsif ($ch eq '倣') {
			$vars = '[倣仿]';
		} elsif ($ch eq '値') {
			$vars = '[値值]';
		} elsif ($ch eq '倫') {
			$vars = '[倫伦倫]';
		} elsif ($ch eq '倶') {
			$vars = '[倶俱]';
		} elsif ($ch eq '倹') {
			$vars = '[倹儉]';
		} elsif ($ch eq '债') {
			$vars = '[债債]';
		} elsif ($ch eq '值') {
			$vars = '[值値]';
		} elsif ($ch eq '倾') {
			$vars = '[倾傾]';
		} elsif ($ch eq '偁') {
			$vars = '[偁稱]';
		} elsif ($ch eq '假') {
			$vars = '[假仮]';
		} elsif ($ch eq '偉') {
			$vars = '[偉伟]';
		} elsif ($ch eq '偊') {
			$vars = '[偊踽]';
		} elsif ($ch eq '偎') {
			$vars = '[偎渨]';
		} elsif ($ch eq '偐') {
			$vars = '[偐贗贋]';
		} elsif ($ch eq '停') {
			$vars = '[停仃]';
		} elsif ($ch eq '偪') {
			$vars = '[偪逼]';
		} elsif ($ch eq '偬') {
			$vars = '[偬傯]';
		} elsif ($ch eq '側') {
			$vars = '[側侧]';
		} elsif ($ch eq '偵') {
			$vars = '[偵侦]';
		} elsif ($ch eq '偷') {
			$vars = '[偷偸]';
		} elsif ($ch eq '偸') {
			$vars = '[偸偷]';
		} elsif ($ch eq '偺') {
			$vars = '[偺咱昝喒]';
		} elsif ($ch eq '偻') {
			$vars = '[偻僂]';
		} elsif ($ch eq '偽') {
			$vars = '[偽伪]';
		} elsif ($ch eq '偾') {
			$vars = '[偾僨]';
		} elsif ($ch eq '偿') {
			$vars = '[偿償]';
		} elsif ($ch eq '傌') {
			$vars = '[傌罵]';
		} elsif ($ch eq '傍') {
			$vars = '[傍旁]';
		} elsif ($ch eq '傑') {
			$vars = '[傑杰]';
		} elsif ($ch eq '傖') {
			$vars = '[傖伧]';
		} elsif ($ch eq '傘') {
			$vars = '[傘伞繖]';
		} elsif ($ch eq '備') {
			$vars = '[備备]';
		} elsif ($ch eq '傜') {
			$vars = '[傜徭]';
		} elsif ($ch eq '傢') {
			$vars = '[傢家]';
		} elsif ($ch eq '傥') {
			$vars = '[傥儻]';
		} elsif ($ch eq '傧') {
			$vars = '[傧儐]';
		} elsif ($ch eq '储') {
			$vars = '[储儲]';
		} elsif ($ch eq '傩') {
			$vars = '[傩儺]';
		} elsif ($ch eq '傭') {
			$vars = '[傭佣]';
		} elsif ($ch eq '傯') {
			$vars = '[傯偬]';
		} elsif ($ch eq '傳') {
			$vars = '[傳传]';
		} elsif ($ch eq '傴') {
			$vars = '[傴伛]';
		} elsif ($ch eq '債') {
			$vars = '[債债]';
		} elsif ($ch eq '傷') {
			$vars = '[傷伤]';
		} elsif ($ch eq '傽') {
			$vars = '[傽慞]';
		} elsif ($ch eq '傾') {
			$vars = '[傾倾]';
		} elsif ($ch eq '僂') {
			$vars = '[僂偻]';
		} elsif ($ch eq '僅') {
			$vars = '[僅仅]';
		} elsif ($ch eq '僉') {
			$vars = '[僉佥]';
		} elsif ($ch eq '僊') {
			$vars = '[僊仙]';
		} elsif ($ch eq '働') {
			$vars = '[働仂]';
		} elsif ($ch eq '像') {
			$vars = '[像象]';
		} elsif ($ch eq '僑') {
			$vars = '[僑侨]';
		} elsif ($ch eq '僕') {
			$vars = '[僕仆]';
		} elsif ($ch eq '僚') {
			$vars = '[僚僚]';
		} elsif ($ch eq '僞') {
			$vars = '[僞伪偽]';
		} elsif ($ch eq '僣') {
			$vars = '[僣僭]';
		} elsif ($ch eq '僥') {
			$vars = '[僥侥]';
		} elsif ($ch eq '僨') {
			$vars = '[僨偾]';
		} elsif ($ch eq '僭') {
			$vars = '[僭僣]';
		} elsif ($ch eq '僱') {
			$vars = '[僱雇]';
		} elsif ($ch eq '價') {
			$vars = '[價价]';
		} elsif ($ch eq '儀') {
			$vars = '[儀仪]';
		} elsif ($ch eq '儁') {
			$vars = '[儁俊]';
		} elsif ($ch eq '儂') {
			$vars = '[儂侬]';
		} elsif ($ch eq '億') {
			$vars = '[億亿]';
		} elsif ($ch eq '儆') {
			$vars = '[儆警]';
		} elsif ($ch eq '儈') {
			$vars = '[儈侩]';
		} elsif ($ch eq '儉') {
			$vars = '[儉俭]';
		} elsif ($ch eq '儌') {
			$vars = '[儌僥]';
		} elsif ($ch eq '儐') {
			$vars = '[儐傧]';
		} elsif ($ch eq '儓') {
			$vars = '[儓檯]';
		} elsif ($ch eq '儔') {
			$vars = '[儔俦]';
		} elsif ($ch eq '儕') {
			$vars = '[儕侪]';
		} elsif ($ch eq '儘') {
			$vars = '[儘尽]';
		} elsif ($ch eq '償') {
			$vars = '[償偿]';
		} elsif ($ch eq '儡') {
			$vars = '[儡酹]';
		} elsif ($ch eq '優') {
			$vars = '[優优]';
		} elsif ($ch eq '儭') {
			$vars = '[儭襯]';
		} elsif ($ch eq '儲') {
			$vars = '[儲储]';
		} elsif ($ch eq '儷') {
			$vars = '[儷俪]';
		} elsif ($ch eq '儺') {
			$vars = '[儺傩]';
		} elsif ($ch eq '儻') {
			$vars = '[儻倘傥]';
		} elsif ($ch eq '儼') {
			$vars = '[儼俨]';
		} elsif ($ch eq '儿') {
			$vars = '[儿兒]';
		} elsif ($ch eq '兀') {
			$vars = '[兀兀]';
		} elsif ($ch eq '兇') {
			$vars = '[兇凶]';
		} elsif ($ch eq '克') {
			$vars = '[克剋]';
		} elsif ($ch eq '兌') {
			$vars = '[兌兑]';
		} elsif ($ch eq '兎') {
			$vars = '[兎兔]';
		} elsif ($ch eq '児') {
			$vars = '[児兒]';
		} elsif ($ch eq '兑') {
			$vars = '[兑兌]';
		} elsif ($ch eq '兒') {
			$vars = '[兒儿]';
		} elsif ($ch eq '兔') {
			$vars = '[兔兎]';
		} elsif ($ch eq '兖') {
			$vars = '[兖兗]';
		} elsif ($ch eq '兗') {
			$vars = '[兗兖]';
		} elsif ($ch eq '党') {
			$vars = '[党黨]';
		} elsif ($ch eq '內') {
			$vars = '[內内]';
		} elsif ($ch eq '兩') {
			$vars = '[兩両两]';
		} elsif ($ch eq '兪') {
			$vars = '[兪俞]';
		} elsif ($ch eq '八') {
			$vars = '[八捌]';
		} elsif ($ch eq '六') {
			$vars = '[六六陸]';
		} elsif ($ch eq '兰') {
			$vars = '[兰蘭]';
		} elsif ($ch eq '关') {
			$vars = '[关關]';
		} elsif ($ch eq '兴') {
			$vars = '[兴興]';
		} elsif ($ch eq '其') {
			$vars = '[其丌]';
		} elsif ($ch eq '兹') {
			$vars = '[兹茲玆]';
		} elsif ($ch eq '养') {
			$vars = '[养養]';
		} elsif ($ch eq '兽') {
			$vars = '[兽獸]';
		} elsif ($ch eq '冁') {
			$vars = '[冁囅]';
		} elsif ($ch eq '冂') {
			$vars = '[冂坰]';
		} elsif ($ch eq '内') {
			$vars = '[内內]';
		} elsif ($ch eq '円') {
			$vars = '[円圓]';
		} elsif ($ch eq '冈') {
			$vars = '[冈岡]';
		} elsif ($ch eq '冊') {
			$vars = '[冊册]';
		} elsif ($ch eq '册') {
			$vars = '[册冊]';
		} elsif ($ch eq '冐') {
			$vars = '[冐冒]';
		} elsif ($ch eq '冑') {
			$vars = '[冑胄]';
		} elsif ($ch eq '写') {
			$vars = '[写寫]';
		} elsif ($ch eq '军') {
			$vars = '[军軍]';
		} elsif ($ch eq '农') {
			$vars = '[农農]';
		} elsif ($ch eq '冢') {
			$vars = '[冢塚]';
		} elsif ($ch eq '冤') {
			$vars = '[冤寃]';
		} elsif ($ch eq '冦') {
			$vars = '[冦寇]';
		} elsif ($ch eq '冨') {
			$vars = '[冨富]';
		} elsif ($ch eq '冩') {
			$vars = '[冩寫]';
		} elsif ($ch eq '冪') {
			$vars = '[冪幂羃鼏]';
		} elsif ($ch eq '冫') {
			$vars = '[冫冰氷]';
		} elsif ($ch eq '冬') {
			$vars = '[冬鼕]';
		} elsif ($ch eq '冯') {
			$vars = '[冯馮]';
		} elsif ($ch eq '冰') {
			$vars = '[冰氷冫]';
		} elsif ($ch eq '冱') {
			$vars = '[冱沍]';
		} elsif ($ch eq '冲') {
			$vars = '[冲衝沖]';
		} elsif ($ch eq '决') {
			$vars = '[决決]';
		} elsif ($ch eq '况') {
			$vars = '[况況]';
		} elsif ($ch eq '冷') {
			$vars = '[冷冷]';
		} elsif ($ch eq '冻') {
			$vars = '[冻凍]';
		} elsif ($ch eq '冽') {
			$vars = '[冽洌]';
		} elsif ($ch eq '净') {
			$vars = '[净淨凈]';
		} elsif ($ch eq '凄') {
			$vars = '[凄淒]';
		} elsif ($ch eq '凅') {
			$vars = '[凅涸]';
		} elsif ($ch eq '准') {
			$vars = '[准準]';
		} elsif ($ch eq '凈') {
			$vars = '[凈淨净]';
		} elsif ($ch eq '凉') {
			$vars = '[凉涼]';
		} elsif ($ch eq '凋') {
			$vars = '[凋雕]';
		} elsif ($ch eq '凌') {
			$vars = '[凌凌]';
		} elsif ($ch eq '凍') {
			$vars = '[凍冻]';
		} elsif ($ch eq '减') {
			$vars = '[减減]';
		} elsif ($ch eq '凑') {
			$vars = '[凑湊]';
		} elsif ($ch eq '凖') {
			$vars = '[凖準]';
		} elsif ($ch eq '凛') {
			$vars = '[凛懔凜]';
		} elsif ($ch eq '凜') {
			$vars = '[凜凛]';
		} elsif ($ch eq '几') {
			$vars = '[几幾]';
		} elsif ($ch eq '凤') {
			$vars = '[凤鳳]';
		} elsif ($ch eq '処') {
			$vars = '[処處]';
		} elsif ($ch eq '凫') {
			$vars = '[凫鳧鳬]';
		} elsif ($ch eq '凭') {
			$vars = '[凭憑]';
		} elsif ($ch eq '凯') {
			$vars = '[凯凱]';
		} elsif ($ch eq '凱') {
			$vars = '[凱凯]';
		} elsif ($ch eq '凶') {
			$vars = '[凶兇]';
		} elsif ($ch eq '击') {
			$vars = '[击擊]';
		} elsif ($ch eq '凼') {
			$vars = '[凼幽]';
		} elsif ($ch eq '函') {
			$vars = '[函凾]';
		} elsif ($ch eq '凾') {
			$vars = '[凾函]';
		} elsif ($ch eq '凿') {
			$vars = '[凿鑿]';
		} elsif ($ch eq '刀') {
			$vars = '[刀刂]';
		} elsif ($ch eq '刂') {
			$vars = '[刂刀]';
		} elsif ($ch eq '刃') {
			$vars = '[刃刄]';
		} elsif ($ch eq '刄') {
			$vars = '[刄刃]';
		} elsif ($ch eq '分') {
			$vars = '[分份]';
		} elsif ($ch eq '切') {
			$vars = '[切切]';
		} elsif ($ch eq '刈') {
			$vars = '[刈苅]';
		} elsif ($ch eq '刊') {
			$vars = '[刊刋]';
		} elsif ($ch eq '刋') {
			$vars = '[刋刊]';
		} elsif ($ch eq '刍') {
			$vars = '[刍芻]';
		} elsif ($ch eq '划') {
			$vars = '[划劃畫]';
		} elsif ($ch eq '刓') {
			$vars = '[刓园]';
		} elsif ($ch eq '刔') {
			$vars = '[刔抉]';
		} elsif ($ch eq '列') {
			$vars = '[列列]';
		} elsif ($ch eq '刘') {
			$vars = '[刘劉]';
		} elsif ($ch eq '则') {
			$vars = '[则則]';
		} elsif ($ch eq '刚') {
			$vars = '[刚剛]';
		} elsif ($ch eq '创') {
			$vars = '[创創]';
		} elsif ($ch eq '删') {
			$vars = '[删刪]';
		} elsif ($ch eq '別') {
			$vars = '[別别]';
		} elsif ($ch eq '刧') {
			$vars = '[刧劫]';
		} elsif ($ch eq '刨') {
			$vars = '[刨鉋]';
		} elsif ($ch eq '利') {
			$vars = '[利利]';
		} elsif ($ch eq '刪') {
			$vars = '[刪删]';
		} elsif ($ch eq '别') {
			$vars = '[别別]';
		} elsif ($ch eq '刭') {
			$vars = '[刭剄]';
		} elsif ($ch eq '刮') {
			$vars = '[刮颳]';
		} elsif ($ch eq '刱') {
			$vars = '[刱創剏]';
		} elsif ($ch eq '制') {
			$vars = '[制製]';
		} elsif ($ch eq '刹') {
			$vars = '[刹剎]';
		} elsif ($ch eq '刺') {
			$vars = '[刺莿]';
		} elsif ($ch eq '刽') {
			$vars = '[刽劊]';
		} elsif ($ch eq '刿') {
			$vars = '[刿劌]';
		} elsif ($ch eq '剀') {
			$vars = '[剀剴]';
		} elsif ($ch eq '剂') {
			$vars = '[剂劑]';
		} elsif ($ch eq '剄') {
			$vars = '[剄刭]';
		} elsif ($ch eq '則') {
			$vars = '[則则]';
		} elsif ($ch eq '剉') {
			$vars = '[剉銼]';
		} elsif ($ch eq '剋') {
			$vars = '[剋克尅]';
		} elsif ($ch eq '剎') {
			$vars = '[剎刹]';
		} elsif ($ch eq '剏') {
			$vars = '[剏刱]';
		} elsif ($ch eq '剐') {
			$vars = '[剐剮]';
		} elsif ($ch eq '剑') {
			$vars = '[剑劍]';
		} elsif ($ch eq '剛') {
			$vars = '[剛刚]';
		} elsif ($ch eq '剝') {
			$vars = '[剝剥]';
		} elsif ($ch eq '剣') {
			$vars = '[剣劍]';
		} elsif ($ch eq '剤') {
			$vars = '[剤劑]';
		} elsif ($ch eq '剥') {
			$vars = '[剥剝]';
		} elsif ($ch eq '剧') {
			$vars = '[剧劇]';
		} elsif ($ch eq '剩') {
			$vars = '[剩剰賸]';
		} elsif ($ch eq '剪') {
			$vars = '[剪翦]';
		} elsif ($ch eq '剮') {
			$vars = '[剮剐]';
		} elsif ($ch eq '剰') {
			$vars = '[剰剩]';
		} elsif ($ch eq '剱') {
			$vars = '[剱劍]';
		} elsif ($ch eq '剳') {
			$vars = '[剳箚劄]';
		} elsif ($ch eq '剴') {
			$vars = '[剴剀]';
		} elsif ($ch eq '創') {
			$vars = '[創创戧刱]';
		} elsif ($ch eq '剷') {
			$vars = '[剷鏟]';
		} elsif ($ch eq '剿') {
			$vars = '[剿勦]';
		} elsif ($ch eq '劃') {
			$vars = '[劃划]';
		} elsif ($ch eq '劄') {
			$vars = '[劄剳]';
		} elsif ($ch eq '劇') {
			$vars = '[劇剧]';
		} elsif ($ch eq '劈') {
			$vars = '[劈擗]';
		} elsif ($ch eq '劉') {
			$vars = '[劉刘]';
		} elsif ($ch eq '劊') {
			$vars = '[劊刽]';
		} elsif ($ch eq '劌') {
			$vars = '[劌刿]';
		} elsif ($ch eq '劍') {
			$vars = '[劍劒剑]';
		} elsif ($ch eq '劑') {
			$vars = '[劑剂剤]';
		} elsif ($ch eq '劒') {
			$vars = '[劒劍]';
		} elsif ($ch eq '劔') {
			$vars = '[劔劍]';
		} elsif ($ch eq '力') {
			$vars = '[力力]';
		} elsif ($ch eq '劝') {
			$vars = '[劝勸]';
		} elsif ($ch eq '办') {
			$vars = '[办辦]';
		} elsif ($ch eq '务') {
			$vars = '[务務]';
		} elsif ($ch eq '劢') {
			$vars = '[劢勱勵]';
		} elsif ($ch eq '劣') {
			$vars = '[劣劣]';
		} elsif ($ch eq '动') {
			$vars = '[动動]';
		} elsif ($ch eq '劫') {
			$vars = '[劫刧]';
		} elsif ($ch eq '励') {
			$vars = '[励勵]';
		} elsif ($ch eq '劲') {
			$vars = '[劲勁]';
		} elsif ($ch eq '劳') {
			$vars = '[劳勞]';
		} elsif ($ch eq '労') {
			$vars = '[労勞]';
		} elsif ($ch eq '劵') {
			$vars = '[劵券]';
		} elsif ($ch eq '効') {
			$vars = '[効效]';
		} elsif ($ch eq '势') {
			$vars = '[势勢]';
		} elsif ($ch eq '勁') {
			$vars = '[勁俓劲]';
		} elsif ($ch eq '勃') {
			$vars = '[勃艴]';
		} elsif ($ch eq '勅') {
			$vars = '[勅敕]';
		} elsif ($ch eq '勋') {
			$vars = '[勋勛]';
		} elsif ($ch eq '勒') {
			$vars = '[勒勒]';
		} elsif ($ch eq '動') {
			$vars = '[動动]';
		} elsif ($ch eq '勖') {
			$vars = '[勖勗]';
		} elsif ($ch eq '勗') {
			$vars = '[勗勖]';
		} elsif ($ch eq '務') {
			$vars = '[務务]';
		} elsif ($ch eq '勛') {
			$vars = '[勛勳勲勋]';
		} elsif ($ch eq '勝') {
			$vars = '[勝胜]';
		} elsif ($ch eq '勞') {
			$vars = '[勞勞劳]';
		} elsif ($ch eq '勢') {
			$vars = '[勢势]';
		} elsif ($ch eq '勤') {
			$vars = '[勤懃]';
		} elsif ($ch eq '勦') {
			$vars = '[勦剿]';
		} elsif ($ch eq '勧') {
			$vars = '[勧勸]';
		} elsif ($ch eq '勰') {
			$vars = '[勰協脅恊]';
		} elsif ($ch eq '勱') {
			$vars = '[勱劢]';
		} elsif ($ch eq '勲') {
			$vars = '[勲勛]';
		} elsif ($ch eq '勳') {
			$vars = '[勳勛]';
		} elsif ($ch eq '勵') {
			$vars = '[勵劢励]';
		} elsif ($ch eq '勸') {
			$vars = '[勸劝勧]';
		} elsif ($ch eq '勹') {
			$vars = '[勹包]';
		} elsif ($ch eq '勻') {
			$vars = '[勻匀]';
		} elsif ($ch eq '勾') {
			$vars = '[勾句]';
		} elsif ($ch eq '匀') {
			$vars = '[匀勻]';
		} elsif ($ch eq '包') {
			$vars = '[包勹]';
		} elsif ($ch eq '匆') {
			$vars = '[匆怱悤]';
		} elsif ($ch eq '匈') {
			$vars = '[匈胸]';
		} elsif ($ch eq '匊') {
			$vars = '[匊掬]';
		} elsif ($ch eq '匋') {
			$vars = '[匋陶]';
		} elsif ($ch eq '匏') {
			$vars = '[匏瓟]';
		} elsif ($ch eq '北') {
			$vars = '[北北]';
		} elsif ($ch eq '匙') {
			$vars = '[匙鍉]';
		} elsif ($ch eq '匦') {
			$vars = '[匦匭]';
		} elsif ($ch eq '匭') {
			$vars = '[匭匦]';
		} elsif ($ch eq '匮') {
			$vars = '[匮匱]';
		} elsif ($ch eq '匯') {
			$vars = '[匯汇]';
		} elsif ($ch eq '匱') {
			$vars = '[匱鐀櫃樻饋匮]';
		} elsif ($ch eq '匳') {
			$vars = '[匳奩]';
		} elsif ($ch eq '匹') {
			$vars = '[匹疋]';
		} elsif ($ch eq '区') {
			$vars = '[区區]';
		} elsif ($ch eq '医') {
			$vars = '[医醫]';
		} elsif ($ch eq '匿') {
			$vars = '[匿匿]';
		} elsif ($ch eq '區') {
			$vars = '[區区]';
		} elsif ($ch eq '十') {
			$vars = '[十拾拾]';
		} elsif ($ch eq '千') {
			$vars = '[千仟]';
		} elsif ($ch eq '卄') {
			$vars = '[卄廿]';
		} elsif ($ch eq '卆') {
			$vars = '[卆卒]';
		} elsif ($ch eq '升') {
			$vars = '[升昇]';
		} elsif ($ch eq '卉') {
			$vars = '[卉芔]';
		} elsif ($ch eq '卍') {
			$vars = '[卍萬万]';
		} elsif ($ch eq '华') {
			$vars = '[华華]';
		} elsif ($ch eq '协') {
			$vars = '[协協]';
		} elsif ($ch eq '卒') {
			$vars = '[卒卆]';
		} elsif ($ch eq '卓') {
			$vars = '[卓棹]';
		} elsif ($ch eq '協') {
			$vars = '[協恊勰协]';
		} elsif ($ch eq '单') {
			$vars = '[单單]';
		} elsif ($ch eq '卖') {
			$vars = '[卖賣]';
		} elsif ($ch eq '単') {
			$vars = '[単單]';
		} elsif ($ch eq '博') {
			$vars = '[博愽]';
		} elsif ($ch eq '卜') {
			$vars = '[卜蔔]';
		} elsif ($ch eq '占') {
			$vars = '[占佔]';
		} elsif ($ch eq '卢') {
			$vars = '[卢盧]';
		} elsif ($ch eq '卤') {
			$vars = '[卤滷鹵]';
		} elsif ($ch eq '卧') {
			$vars = '[卧臥]';
		} elsif ($ch eq '卩') {
			$vars = '[卩部節]';
		} elsif ($ch eq '卫') {
			$vars = '[卫衛]';
		} elsif ($ch eq '卮') {
			$vars = '[卮巵]';
		} elsif ($ch eq '即') {
			$vars = '[即卽]';
		} elsif ($ch eq '却') {
			$vars = '[却卻]';
		} elsif ($ch eq '卵') {
			$vars = '[卵卵]';
		} elsif ($ch eq '卷') {
			$vars = '[卷捲]';
		} elsif ($ch eq '卹') {
			$vars = '[卹恤]';
		} elsif ($ch eq '卻') {
			$vars = '[卻却]';
		} elsif ($ch eq '卽') {
			$vars = '[卽即]';
		} elsif ($ch eq '厂') {
			$vars = '[厂廠]';
		} elsif ($ch eq '厄') {
			$vars = '[厄阨]';
		} elsif ($ch eq '厅') {
			$vars = '[厅廳]';
		} elsif ($ch eq '历') {
			$vars = '[历曆厲歷]';
		} elsif ($ch eq '厉') {
			$vars = '[厉厲]';
		} elsif ($ch eq '压') {
			$vars = '[压壓]';
		} elsif ($ch eq '厌') {
			$vars = '[厌厭]';
		} elsif ($ch eq '厍') {
			$vars = '[厍厙]';
		} elsif ($ch eq '厎') {
			$vars = '[厎砥]';
		} elsif ($ch eq '厓') {
			$vars = '[厓崖]';
		} elsif ($ch eq '厕') {
			$vars = '[厕廁厠]';
		} elsif ($ch eq '厖') {
			$vars = '[厖龐庬]';
		} elsif ($ch eq '厘') {
			$vars = '[厘釐]';
		} elsif ($ch eq '厙') {
			$vars = '[厙厍]';
		} elsif ($ch eq '厠') {
			$vars = '[厠厕廁]';
		} elsif ($ch eq '厢') {
			$vars = '[厢廂]';
		} elsif ($ch eq '厣') {
			$vars = '[厣厴]';
		} elsif ($ch eq '厤') {
			$vars = '[厤曆]';
		} elsif ($ch eq '厦') {
			$vars = '[厦廈]';
		} elsif ($ch eq '厨') {
			$vars = '[厨廚]';
		} elsif ($ch eq '厩') {
			$vars = '[厩廄廐]';
		} elsif ($ch eq '厭') {
			$vars = '[厭厌]';
		} elsif ($ch eq '厮') {
			$vars = '[厮廝]';
		} elsif ($ch eq '厰') {
			$vars = '[厰廠]';
		} elsif ($ch eq '厲') {
			$vars = '[厲厉历]';
		} elsif ($ch eq '厳') {
			$vars = '[厳嚴]';
		} elsif ($ch eq '厴') {
			$vars = '[厴厣]';
		} elsif ($ch eq '厶') {
			$vars = '[厶某私]';
		} elsif ($ch eq '县') {
			$vars = '[县縣]';
		} elsif ($ch eq '叁') {
			$vars = '[叁三參]';
		} elsif ($ch eq '参') {
			$vars = '[参參]';
		} elsif ($ch eq '參') {
			$vars = '[參参參]';
		} elsif ($ch eq '叉') {
			$vars = '[叉釵]';
		} elsif ($ch eq '双') {
			$vars = '[双雙]';
		} elsif ($ch eq '収') {
			$vars = '[収收]';
		} elsif ($ch eq '发') {
			$vars = '[发髮發]';
		} elsif ($ch eq '变') {
			$vars = '[变變]';
		} elsif ($ch eq '叙') {
			$vars = '[叙敘敍]';
		} elsif ($ch eq '叠') {
			$vars = '[叠疊]';
		} elsif ($ch eq '叡') {
			$vars = '[叡睿]';
		} elsif ($ch eq '叢') {
			$vars = '[叢丛]';
		} elsif ($ch eq '句') {
			$vars = '[句句]';
		} elsif ($ch eq '叨') {
			$vars = '[叨饕]';
		} elsif ($ch eq '只') {
			$vars = '[只子衹止隻]';
		} elsif ($ch eq '台') {
			$vars = '[台臺檯颱]';
		} elsif ($ch eq '叶') {
			$vars = '[叶葉]';
		} elsif ($ch eq '号') {
			$vars = '[号號]';
		} elsif ($ch eq '叹') {
			$vars = '[叹嘆]';
		} elsif ($ch eq '叽') {
			$vars = '[叽嘰]';
		} elsif ($ch eq '吁') {
			$vars = '[吁籲]';
		} elsif ($ch eq '吃') {
			$vars = '[吃喫]';
		} elsif ($ch eq '合') {
			$vars = '[合閤]';
		} elsif ($ch eq '吊') {
			$vars = '[吊弔]';
		} elsif ($ch eq '吋') {
			$vars = '[吋寸]';
		} elsif ($ch eq '同') {
			$vars = '[同衕仝]';
		} elsif ($ch eq '后') {
			$vars = '[后後]';
		} elsif ($ch eq '吏') {
			$vars = '[吏吏]';
		} elsif ($ch eq '向') {
			$vars = '[向嚮曏]';
		} elsif ($ch eq '吒') {
			$vars = '[吒咤]';
		} elsif ($ch eq '吓') {
			$vars = '[吓嚇]';
		} elsif ($ch eq '吕') {
			$vars = '[吕呂]';
		} elsif ($ch eq '吗') {
			$vars = '[吗嗎]';
		} elsif ($ch eq '吝') {
			$vars = '[吝悋吝]';
		} elsif ($ch eq '吞') {
			$vars = '[吞呑]';
		} elsif ($ch eq '吣') {
			$vars = '[吣唚]';
		} elsif ($ch eq '吨') {
			$vars = '[吨啍噸]';
		} elsif ($ch eq '含') {
			$vars = '[含唅]';
		} elsif ($ch eq '听') {
			$vars = '[听聽]';
		} elsif ($ch eq '启') {
			$vars = '[启啟啓]';
		} elsif ($ch eq '吲') {
			$vars = '[吲哂]';
		} elsif ($ch eq '吳') {
			$vars = '[吳呉吴]';
		} elsif ($ch eq '吴') {
			$vars = '[吴吳]';
		} elsif ($ch eq '吶') {
			$vars = '[吶訥呐]';
		} elsif ($ch eq '吻') {
			$vars = '[吻呡]';
		} elsif ($ch eq '呂') {
			$vars = '[呂吕呂]';
		} elsif ($ch eq '呃') {
			$vars = '[呃阨]';
		} elsif ($ch eq '呆') {
			$vars = '[呆騃獃]';
		} elsif ($ch eq '呉') {
			$vars = '[呉吳]';
		} elsif ($ch eq '呐') {
			$vars = '[呐吶]';
		} elsif ($ch eq '呑') {
			$vars = '[呑吞]';
		} elsif ($ch eq '呒') {
			$vars = '[呒嘸]';
		} elsif ($ch eq '呓') {
			$vars = '[呓囈]';
		} elsif ($ch eq '呕') {
			$vars = '[呕嘔]';
		} elsif ($ch eq '呖') {
			$vars = '[呖嚦]';
		} elsif ($ch eq '呗') {
			$vars = '[呗唄]';
		} elsif ($ch eq '员') {
			$vars = '[员員]';
		} elsif ($ch eq '呙') {
			$vars = '[呙咼]';
		} elsif ($ch eq '呛') {
			$vars = '[呛嗆]';
		} elsif ($ch eq '呜') {
			$vars = '[呜嗚]';
		} elsif ($ch eq '呠') {
			$vars = '[呠噴歕]';
		} elsif ($ch eq '呡') {
			$vars = '[呡吻]';
		} elsif ($ch eq '周') {
			$vars = '[周週]';
		} elsif ($ch eq '呪') {
			$vars = '[呪咒]';
		} elsif ($ch eq '呱') {
			$vars = '[呱哌]';
		} elsif ($ch eq '呴') {
			$vars = '[呴詬]';
		} elsif ($ch eq '呵') {
			$vars = '[呵訶]';
		} elsif ($ch eq '呼') {
			$vars = '[呼謼]';
		} elsif ($ch eq '咀') {
			$vars = '[咀嘴觜]';
		} elsif ($ch eq '和') {
			$vars = '[和龢]';
		} elsif ($ch eq '咏') {
			$vars = '[咏詠]';
		} elsif ($ch eq '咒') {
			$vars = '[咒呪]';
		} elsif ($ch eq '咙') {
			$vars = '[咙嚨]';
		} elsif ($ch eq '咛') {
			$vars = '[咛嚀]';
		} elsif ($ch eq '咤') {
			$vars = '[咤吒]';
		} elsif ($ch eq '咥') {
			$vars = '[咥嘻]';
		} elsif ($ch eq '咨') {
			$vars = '[咨谘諮]';
		} elsif ($ch eq '咮') {
			$vars = '[咮胄]';
		} elsif ($ch eq '咯') {
			$vars = '[咯詻]';
		} elsif ($ch eq '咱') {
			$vars = '[咱偺喒]';
		} elsif ($ch eq '咲') {
			$vars = '[咲笑]';
		} elsif ($ch eq '咳') {
			$vars = '[咳欬]';
		} elsif ($ch eq '咷') {
			$vars = '[咷啕]';
		} elsif ($ch eq '咸') {
			$vars = '[咸鹹]';
		} elsif ($ch eq '咼') {
			$vars = '[咼呙]';
		} elsif ($ch eq '咽') {
			$vars = '[咽咽嚥]';
		} elsif ($ch eq '哂') {
			$vars = '[哂吲]';
		} elsif ($ch eq '哄') {
			$vars = '[哄閧]';
		} elsif ($ch eq '哌') {
			$vars = '[哌呱]';
		} elsif ($ch eq '响') {
			$vars = '[响響]';
		} elsif ($ch eq '哑') {
			$vars = '[哑啞]';
		} elsif ($ch eq '哒') {
			$vars = '[哒噠]';
		} elsif ($ch eq '哓') {
			$vars = '[哓嘵]';
		} elsif ($ch eq '哔') {
			$vars = '[哔嗶]';
		} elsif ($ch eq '哕') {
			$vars = '[哕噦]';
		} elsif ($ch eq '哗') {
			$vars = '[哗嘩]';
		} elsif ($ch eq '哙') {
			$vars = '[哙噲]';
		} elsif ($ch eq '哜') {
			$vars = '[哜嚌]';
		} elsif ($ch eq '哝') {
			$vars = '[哝噥]';
		} elsif ($ch eq '哟') {
			$vars = '[哟喲]';
		} elsif ($ch eq '員') {
			$vars = '[員员]';
		} elsif ($ch eq '哲') {
			$vars = '[哲喆悊]';
		} elsif ($ch eq '哼') {
			$vars = '[哼苛]';
		} elsif ($ch eq '唁') {
			$vars = '[唁喭]';
		} elsif ($ch eq '唄') {
			$vars = '[唄呗]';
		} elsif ($ch eq '唅') {
			$vars = '[唅含]';
		} elsif ($ch eq '唇') {
			$vars = '[唇脣]';
		} elsif ($ch eq '唉') {
			$vars = '[唉誒欸]';
		} elsif ($ch eq '唊') {
			$vars = '[唊硤]';
		} elsif ($ch eq '唖') {
			$vars = '[唖啞]';
		} elsif ($ch eq '唚') {
			$vars = '[唚吣]';
		} elsif ($ch eq '唛') {
			$vars = '[唛嘜]';
		} elsif ($ch eq '唠') {
			$vars = '[唠嘮]';
		} elsif ($ch eq '唢') {
			$vars = '[唢嗩]';
		} elsif ($ch eq '唤') {
			$vars = '[唤喚]';
		} elsif ($ch eq '唧') {
			$vars = '[唧喞]';
		} elsif ($ch eq '唬') {
			$vars = '[唬虓猇諕]';
		} elsif ($ch eq '唷') {
			$vars = '[唷唹]';
		} elsif ($ch eq '啃') {
			$vars = '[啃齦]';
		} elsif ($ch eq '啊') {
			$vars = '[啊阿]';
		} elsif ($ch eq '啍') {
			$vars = '[啍吨]';
		} elsif ($ch eq '啎') {
			$vars = '[啎忤]';
		} elsif ($ch eq '問') {
			$vars = '[問问]';
		} elsif ($ch eq '啓') {
			$vars = '[啓启啟]';
		} elsif ($ch eq '啕') {
			$vars = '[啕咷]';
		} elsif ($ch eq '啖') {
			$vars = '[啖噉啗]';
		} elsif ($ch eq '啗') {
			$vars = '[啗噉啖]';
		} elsif ($ch eq '啜') {
			$vars = '[啜歠欼]';
		} elsif ($ch eq '啞') {
			$vars = '[啞唖哑]';
		} elsif ($ch eq '啟') {
			$vars = '[啟启啓]';
		} elsif ($ch eq '啧') {
			$vars = '[啧嘖]';
		} elsif ($ch eq '啬') {
			$vars = '[啬嗇]';
		} elsif ($ch eq '啭') {
			$vars = '[啭囀]';
		} elsif ($ch eq '啮') {
			$vars = '[啮嚙]';
		} elsif ($ch eq '啸') {
			$vars = '[啸嘯]';
		} elsif ($ch eq '喂') {
			$vars = '[喂餵餧]';
		} elsif ($ch eq '喃') {
			$vars = '[喃嫐諵]';
		} elsif ($ch eq '善') {
			$vars = '[善譱]';
		} elsif ($ch eq '喆') {
			$vars = '[喆哲]';
		} elsif ($ch eq '喇') {
			$vars = '[喇喇]';
		} elsif ($ch eq '喒') {
			$vars = '[喒咱偺昝]';
		} elsif ($ch eq '喚') {
			$vars = '[喚唤]';
		} elsif ($ch eq '喜') {
			$vars = '[喜憙]';
		} elsif ($ch eq '喞') {
			$vars = '[喞唧]';
		} elsif ($ch eq '喧') {
			$vars = '[喧諠]';
		} elsif ($ch eq '喩') {
			$vars = '[喩喻]';
		} elsif ($ch eq '喪') {
			$vars = '[喪丧]';
		} elsif ($ch eq '喫') {
			$vars = '[喫吃]';
		} elsif ($ch eq '喬') {
			$vars = '[喬乔]';
		} elsif ($ch eq '喭') {
			$vars = '[喭唁]';
		} elsif ($ch eq '單') {
			$vars = '[單单単]';
		} elsif ($ch eq '喰') {
			$vars = '[喰餐]';
		} elsif ($ch eq '喲') {
			$vars = '[喲哟]';
		} elsif ($ch eq '営') {
			$vars = '[営營]';
		} elsif ($ch eq '喷') {
			$vars = '[喷噴]';
		} elsif ($ch eq '喻') {
			$vars = '[喻喩]';
		} elsif ($ch eq '喽') {
			$vars = '[喽嘍]';
		} elsif ($ch eq '喾') {
			$vars = '[喾嚳]';
		} elsif ($ch eq '喿') {
			$vars = '[喿噪]';
		} elsif ($ch eq '嗀') {
			$vars = '[嗀嗀]';
		} elsif ($ch eq '嗆') {
			$vars = '[嗆呛]';
		} elsif ($ch eq '嗇') {
			$vars = '[嗇啬]';
		} elsif ($ch eq '嗉') {
			$vars = '[嗉膆]';
		} elsif ($ch eq '嗎') {
			$vars = '[嗎吗]';
		} elsif ($ch eq '嗚') {
			$vars = '[嗚呜]';
		} elsif ($ch eq '嗥') {
			$vars = '[嗥嚎]';
		} elsif ($ch eq '嗩') {
			$vars = '[嗩唢]';
		} elsif ($ch eq '嗫') {
			$vars = '[嗫囁]';
		} elsif ($ch eq '嗬') {
			$vars = '[嗬呵]';
		} elsif ($ch eq '嗳') {
			$vars = '[嗳噯]';
		} elsif ($ch eq '嗶') {
			$vars = '[嗶哔]';
		} elsif ($ch eq '嘆') {
			$vars = '[嘆叹歎]';
		} elsif ($ch eq '嘍') {
			$vars = '[嘍謱喽]';
		} elsif ($ch eq '嘎') {
			$vars = '[嘎尜]';
		} elsif ($ch eq '嘔') {
			$vars = '[嘔慪呕]';
		} elsif ($ch eq '嘖') {
			$vars = '[嘖啧]';
		} elsif ($ch eq '嘗') {
			$vars = '[嘗尝甞]';
		} elsif ($ch eq '嘘') {
			$vars = '[嘘噓]';
		} elsif ($ch eq '嘜') {
			$vars = '[嘜唛]';
		} elsif ($ch eq '嘤') {
			$vars = '[嘤嚶]';
		} elsif ($ch eq '嘩') {
			$vars = '[嘩哗譁]';
		} elsif ($ch eq '嘮') {
			$vars = '[嘮唠]';
		} elsif ($ch eq '嘯') {
			$vars = '[嘯啸]';
		} elsif ($ch eq '嘰') {
			$vars = '[嘰叽]';
		} elsif ($ch eq '嘱') {
			$vars = '[嘱囑]';
		} elsif ($ch eq '嘴') {
			$vars = '[嘴觜咀]';
		} elsif ($ch eq '嘵') {
			$vars = '[嘵哓]';
		} elsif ($ch eq '嘸') {
			$vars = '[嘸呒]';
		} elsif ($ch eq '嘻') {
			$vars = '[嘻咥]';
		} elsif ($ch eq '嘿') {
			$vars = '[嘿默]';
		} elsif ($ch eq '噁') {
			$vars = '[噁恶]';
		} elsif ($ch eq '噂') {
			$vars = '[噂譐]';
		} elsif ($ch eq '噉') {
			$vars = '[噉啖啗]';
		} elsif ($ch eq '噐') {
			$vars = '[噐器]';
		} elsif ($ch eq '噓') {
			$vars = '[噓嘘]';
		} elsif ($ch eq '噜') {
			$vars = '[噜嚕]';
		} elsif ($ch eq '噠') {
			$vars = '[噠哒]';
		} elsif ($ch eq '噥') {
			$vars = '[噥哝]';
		} elsif ($ch eq '噦') {
			$vars = '[噦哕]';
		} elsif ($ch eq '器') {
			$vars = '[器噐]';
		} elsif ($ch eq '噪') {
			$vars = '[噪喿譟]';
		} elsif ($ch eq '噯') {
			$vars = '[噯嗳]';
		} elsif ($ch eq '噲') {
			$vars = '[噲哙]';
		} elsif ($ch eq '噴') {
			$vars = '[噴喷呠歕]';
		} elsif ($ch eq '噸') {
			$vars = '[噸吨]';
		} elsif ($ch eq '噹') {
			$vars = '[噹当]';
		} elsif ($ch eq '嚀') {
			$vars = '[嚀咛]';
		} elsif ($ch eq '嚇') {
			$vars = '[嚇吓]';
		} elsif ($ch eq '嚌') {
			$vars = '[嚌哜]';
		} elsif ($ch eq '嚎') {
			$vars = '[嚎嗥]';
		} elsif ($ch eq '嚏') {
			$vars = '[嚏嚔]';
		} elsif ($ch eq '嚔') {
			$vars = '[嚔嚏]';
		} elsif ($ch eq '嚕') {
			$vars = '[嚕噜]';
		} elsif ($ch eq '嚙') {
			$vars = '[嚙啮齧]';
		} elsif ($ch eq '嚠') {
			$vars = '[嚠瀏]';
		} elsif ($ch eq '嚢') {
			$vars = '[嚢囊]';
		} elsif ($ch eq '嚣') {
			$vars = '[嚣囂]';
		} elsif ($ch eq '嚥') {
			$vars = '[嚥咽咽]';
		} elsif ($ch eq '嚦') {
			$vars = '[嚦呖]';
		} elsif ($ch eq '嚨') {
			$vars = '[嚨咙]';
		} elsif ($ch eq '嚬') {
			$vars = '[嚬顰]';
		} elsif ($ch eq '嚳') {
			$vars = '[嚳喾]';
		} elsif ($ch eq '嚴') {
			$vars = '[嚴严厳]';
		} elsif ($ch eq '嚵') {
			$vars = '[嚵饞]';
		} elsif ($ch eq '嚶') {
			$vars = '[嚶嘤]';
		} elsif ($ch eq '囀') {
			$vars = '[囀啭]';
		} elsif ($ch eq '囁') {
			$vars = '[囁嗫讘]';
		} elsif ($ch eq '囂') {
			$vars = '[囂嚣]';
		} elsif ($ch eq '囅') {
			$vars = '[囅冁]';
		} elsif ($ch eq '囈') {
			$vars = '[囈呓]';
		} elsif ($ch eq '囊') {
			$vars = '[囊嚢]';
		} elsif ($ch eq '囌') {
			$vars = '[囌蘇]';
		} elsif ($ch eq '囑') {
			$vars = '[囑嘱]';
		} elsif ($ch eq '囓') {
			$vars = '[囓嚙齧]';
		} elsif ($ch eq '囘') {
			$vars = '[囘回]';
		} elsif ($ch eq '四') {
			$vars = '[四肆]';
		} elsif ($ch eq '回') {
			$vars = '[回廻囘]';
		} elsif ($ch eq '囟') {
			$vars = '[囟倖幸]';
		} elsif ($ch eq '团') {
			$vars = '[团團]';
		} elsif ($ch eq '団') {
			$vars = '[団團]';
		} elsif ($ch eq '囪') {
			$vars = '[囪囱]';
		} elsif ($ch eq '园') {
			$vars = '[园刓園]';
		} elsif ($ch eq '囮') {
			$vars = '[囮諤]';
		} elsif ($ch eq '困') {
			$vars = '[困睏]';
		} elsif ($ch eq '囱') {
			$vars = '[囱囪]';
		} elsif ($ch eq '囲') {
			$vars = '[囲圍]';
		} elsif ($ch eq '図') {
			$vars = '[図圖]';
		} elsif ($ch eq '围') {
			$vars = '[围圍]';
		} elsif ($ch eq '囵') {
			$vars = '[囵圇]';
		} elsif ($ch eq '囹') {
			$vars = '[囹囹]';
		} elsif ($ch eq '国') {
			$vars = '[国國]';
		} elsif ($ch eq '图') {
			$vars = '[图圖]';
		} elsif ($ch eq '圀') {
			$vars = '[圀國]';
		} elsif ($ch eq '圆') {
			$vars = '[圆圓]';
		} elsif ($ch eq '圇') {
			$vars = '[圇囵]';
		} elsif ($ch eq '圈') {
			$vars = '[圈圏]';
		} elsif ($ch eq '國') {
			$vars = '[國圀国]';
		} elsif ($ch eq '圍') {
			$vars = '[圍围囲]';
		} elsif ($ch eq '圏') {
			$vars = '[圏圈]';
		} elsif ($ch eq '園') {
			$vars = '[園园]';
		} elsif ($ch eq '圓') {
			$vars = '[圓圆]';
		} elsif ($ch eq '圖') {
			$vars = '[圖図图]';
		} elsif ($ch eq '團') {
			$vars = '[團团団]';
		} elsif ($ch eq '圢') {
			$vars = '[圢町]';
		} elsif ($ch eq '圣') {
			$vars = '[圣聖]';
		} elsif ($ch eq '圧') {
			$vars = '[圧壓]';
		} elsif ($ch eq '圬') {
			$vars = '[圬杇]';
		} elsif ($ch eq '圭') {
			$vars = '[圭珪]';
		} elsif ($ch eq '圹') {
			$vars = '[圹壙]';
		} elsif ($ch eq '场') {
			$vars = '[场場]';
		} elsif ($ch eq '圻') {
			$vars = '[圻垠]';
		} elsif ($ch eq '址') {
			$vars = '[址阯]';
		} elsif ($ch eq '坂') {
			$vars = '[坂阪]';
		} elsif ($ch eq '坋') {
			$vars = '[坋坌]';
		} elsif ($ch eq '坌') {
			$vars = '[坌坋]';
		} elsif ($ch eq '坎') {
			$vars = '[坎埳]';
		} elsif ($ch eq '坏') {
			$vars = '[坏壞坯]';
		} elsif ($ch eq '坐') {
			$vars = '[坐座]';
		} elsif ($ch eq '坑') {
			$vars = '[坑阬]';
		} elsif ($ch eq '块') {
			$vars = '[块塊]';
		} elsif ($ch eq '坚') {
			$vars = '[坚堅]';
		} elsif ($ch eq '坛') {
			$vars = '[坛罈壇]';
		} elsif ($ch eq '坜') {
			$vars = '[坜壢]';
		} elsif ($ch eq '坝') {
			$vars = '[坝壩]';
		} elsif ($ch eq '坞') {
			$vars = '[坞塢]';
		} elsif ($ch eq '坟') {
			$vars = '[坟墳]';
		} elsif ($ch eq '坠') {
			$vars = '[坠墜]';
		} elsif ($ch eq '坫') {
			$vars = '[坫店]';
		} elsif ($ch eq '坭') {
			$vars = '[坭泥]';
		} elsif ($ch eq '坯') {
			$vars = '[坯壞坏]';
		} elsif ($ch eq '坰') {
			$vars = '[坰冂]';
		} elsif ($ch eq '坵') {
			$vars = '[坵丘]';
		} elsif ($ch eq '垂') {
			$vars = '[垂埀]';
		} elsif ($ch eq '垄') {
			$vars = '[垄壟]';
		} elsif ($ch eq '垆') {
			$vars = '[垆壚]';
		} elsif ($ch eq '垒') {
			$vars = '[垒壘]';
		} elsif ($ch eq '垓') {
			$vars = '[垓陔]';
		} elsif ($ch eq '垔') {
			$vars = '[垔堙]';
		} elsif ($ch eq '垠') {
			$vars = '[垠圻]';
		} elsif ($ch eq '垦') {
			$vars = '[垦墾]';
		} elsif ($ch eq '垩') {
			$vars = '[垩聖堊]';
		} elsif ($ch eq '垫') {
			$vars = '[垫墊]';
		} elsif ($ch eq '垭') {
			$vars = '[垭埡]';
		} elsif ($ch eq '垲') {
			$vars = '[垲塏]';
		} elsif ($ch eq '垵') {
			$vars = '[垵埯]';
		} elsif ($ch eq '埀') {
			$vars = '[埀垂]';
		} elsif ($ch eq '埇') {
			$vars = '[埇甬]';
		} elsif ($ch eq '埒') {
			$vars = '[埒埓]';
		} elsif ($ch eq '埘') {
			$vars = '[埘塒]';
		} elsif ($ch eq '埙') {
			$vars = '[埙塤]';
		} elsif ($ch eq '埚') {
			$vars = '[埚堝]';
		} elsif ($ch eq '埜') {
			$vars = '[埜野]';
		} elsif ($ch eq '域') {
			$vars = '[域譽]';
		} elsif ($ch eq '埡') {
			$vars = '[埡垭]';
		} elsif ($ch eq '埯') {
			$vars = '[埯垵]';
		} elsif ($ch eq '埰') {
			$vars = '[埰采]';
		} elsif ($ch eq '埳') {
			$vars = '[埳坎]';
		} elsif ($ch eq '埶') {
			$vars = '[埶藝蓺]';
		} elsif ($ch eq '執') {
			$vars = '[執执]';
		} elsif ($ch eq '基') {
			$vars = '[基拯]';
		} elsif ($ch eq '埼') {
			$vars = '[埼崎]';
		} elsif ($ch eq '埽') {
			$vars = '[埽掃]';
		} elsif ($ch eq '堅') {
			$vars = '[堅坚]';
		} elsif ($ch eq '堇') {
			$vars = '[堇菫]';
		} elsif ($ch eq '堈') {
			$vars = '[堈缸]';
		} elsif ($ch eq '堊') {
			$vars = '[堊聖垩]';
		} elsif ($ch eq '堑') {
			$vars = '[堑塹]';
		} elsif ($ch eq '堕') {
			$vars = '[堕墮]';
		} elsif ($ch eq '堙') {
			$vars = '[堙垔]';
		} elsif ($ch eq '堝') {
			$vars = '[堝埚]';
		} elsif ($ch eq '堤') {
			$vars = '[堤隄]';
		} elsif ($ch eq '堭') {
			$vars = '[堭隍]';
		} elsif ($ch eq '堯') {
			$vars = '[堯尧]';
		} elsif ($ch eq '報') {
			$vars = '[報报]';
		} elsif ($ch eq '場') {
			$vars = '[場场塲]';
		} elsif ($ch eq '堺') {
			$vars = '[堺界]';
		} elsif ($ch eq '堿') {
			$vars = '[堿鹼]';
		} elsif ($ch eq '塊') {
			$vars = '[塊块]';
		} elsif ($ch eq '塋') {
			$vars = '[塋茔]';
		} elsif ($ch eq '塏') {
			$vars = '[塏垲]';
		} elsif ($ch eq '塒') {
			$vars = '[塒埘]';
		} elsif ($ch eq '塗') {
			$vars = '[塗涂]';
		} elsif ($ch eq '塚') {
			$vars = '[塚中]';
		} elsif ($ch eq '塞') {
			$vars = '[塞塞]';
		} elsif ($ch eq '塡') {
			$vars = '[塡窴填]';
		} elsif ($ch eq '塢') {
			$vars = '[塢鄔坞]';
		} elsif ($ch eq '塤') {
			$vars = '[塤埙壎]';
		} elsif ($ch eq '塩') {
			$vars = '[塩鹽]';
		} elsif ($ch eq '填') {
			$vars = '[填塡]';
		} elsif ($ch eq '塲') {
			$vars = '[塲場]';
		} elsif ($ch eq '塵') {
			$vars = '[塵尘]';
		} elsif ($ch eq '塹') {
			$vars = '[塹堑]';
		} elsif ($ch eq '塾') {
			$vars = '[塾孰]';
		} elsif ($ch eq '墈') {
			$vars = '[墈磡]';
		} elsif ($ch eq '墊') {
			$vars = '[墊垫]';
		} elsif ($ch eq '増') {
			$vars = '[増增]';
		} elsif ($ch eq '墙') {
			$vars = '[墙牆墻]';
		} elsif ($ch eq '墜') {
			$vars = '[墜坠]';
		} elsif ($ch eq '墝') {
			$vars = '[墝磽]';
		} elsif ($ch eq '墫') {
			$vars = '[墫樽]';
		} elsif ($ch eq '墮') {
			$vars = '[墮堕]';
		} elsif ($ch eq '墳') {
			$vars = '[墳坟]';
		} elsif ($ch eq '墻') {
			$vars = '[墻牆廧墙]';
		} elsif ($ch eq '墾') {
			$vars = '[墾垦]';
		} elsif ($ch eq '壇') {
			$vars = '[壇坛]';
		} elsif ($ch eq '壊') {
			$vars = '[壊壞]';
		} elsif ($ch eq '壌') {
			$vars = '[壌壤]';
		} elsif ($ch eq '壎') {
			$vars = '[壎塤]';
		} elsif ($ch eq '壓') {
			$vars = '[壓压圧]';
		} elsif ($ch eq '壘') {
			$vars = '[壘塁垒]';
		} elsif ($ch eq '壙') {
			$vars = '[壙圹]';
		} elsif ($ch eq '壚') {
			$vars = '[壚垆]';
		} elsif ($ch eq '壜') {
			$vars = '[壜罈]';
		} elsif ($ch eq '壞') {
			$vars = '[壞壊坏]';
		} elsif ($ch eq '壟') {
			$vars = '[壟垄壟]';
		} elsif ($ch eq '壢') {
			$vars = '[壢坜]';
		} elsif ($ch eq '壤') {
			$vars = '[壤壌]';
		} elsif ($ch eq '壩') {
			$vars = '[壩坝]';
		} elsif ($ch eq '壮') {
			$vars = '[壮壯]';
		} elsif ($ch eq '壯') {
			$vars = '[壯壮]';
		} elsif ($ch eq '声') {
			$vars = '[声聲]';
		} elsif ($ch eq '売') {
			$vars = '[売賣]';
		} elsif ($ch eq '壳') {
			$vars = '[壳殻殼]';
		} elsif ($ch eq '壶') {
			$vars = '[壶壺]';
		} elsif ($ch eq '壷') {
			$vars = '[壷壺]';
		} elsif ($ch eq '壹') {
			$vars = '[壹一搋弌]';
		} elsif ($ch eq '壺') {
			$vars = '[壺壷壶]';
		} elsif ($ch eq '壻') {
			$vars = '[壻婿]';
		} elsif ($ch eq '壽') {
			$vars = '[壽寿]';
		} elsif ($ch eq '处') {
			$vars = '[处處]';
		} elsif ($ch eq '备') {
			$vars = '[备備]';
		} elsif ($ch eq '変') {
			$vars = '[変變]';
		} elsif ($ch eq '夊') {
			$vars = '[夊攵]';
		} elsif ($ch eq '复') {
			$vars = '[复複復覆]';
		} elsif ($ch eq '夐') {
			$vars = '[夐敻]';
		} elsif ($ch eq '外') {
			$vars = '[外舀]';
		} elsif ($ch eq '夘') {
			$vars = '[夘卯]';
		} elsif ($ch eq '多') {
			$vars = '[多夛]';
		} elsif ($ch eq '夛') {
			$vars = '[夛多]';
		} elsif ($ch eq '够') {
			$vars = '[够夠彀]';
		} elsif ($ch eq '夠') {
			$vars = '[夠够彀]';
		} elsif ($ch eq '夢') {
			$vars = '[夢梦]';
		} elsif ($ch eq '夥') {
			$vars = '[夥伙]';
		} elsif ($ch eq '夭') {
			$vars = '[夭殀]';
		} elsif ($ch eq '头') {
			$vars = '[头頭]';
		} elsif ($ch eq '夸') {
			$vars = '[夸誇]';
		} elsif ($ch eq '夹') {
			$vars = '[夹夾]';
		} elsif ($ch eq '夺') {
			$vars = '[夺奪]';
		} elsif ($ch eq '夾') {
			$vars = '[夾夹]';
		} elsif ($ch eq '奁') {
			$vars = '[奁奩]';
		} elsif ($ch eq '奂') {
			$vars = '[奂奐]';
		} elsif ($ch eq '奇') {
			$vars = '[奇竒]';
		} elsif ($ch eq '奈') {
			$vars = '[奈柰]';
		} elsif ($ch eq '奋') {
			$vars = '[奋奮]';
		} elsif ($ch eq '奐') {
			$vars = '[奐奂]';
		} elsif ($ch eq '契') {
			$vars = '[契契]';
		} elsif ($ch eq '奔') {
			$vars = '[奔犇]';
		} elsif ($ch eq '奕') {
			$vars = '[奕弈]';
		} elsif ($ch eq '奖') {
			$vars = '[奖獎奬]';
		} elsif ($ch eq '奘') {
			$vars = '[奘弉]';
		} elsif ($ch eq '奥') {
			$vars = '[奥奧]';
		} elsif ($ch eq '奧') {
			$vars = '[奧奥]';
		} elsif ($ch eq '奨') {
			$vars = '[奨奬]';
		} elsif ($ch eq '奩') {
			$vars = '[奩奁匳]';
		} elsif ($ch eq '奪') {
			$vars = '[奪夺]';
		} elsif ($ch eq '奬') {
			$vars = '[奬奖]';
		} elsif ($ch eq '奮') {
			$vars = '[奮奋]';
		} elsif ($ch eq '女') {
			$vars = '[女女]';
		} elsif ($ch eq '奶') {
			$vars = '[奶嬭妳]';
		} elsif ($ch eq '奸') {
			$vars = '[奸姦]';
		} elsif ($ch eq '她') {
			$vars = '[她他]';
		} elsif ($ch eq '奼') {
			$vars = '[奼姹]';
		} elsif ($ch eq '妆') {
			$vars = '[妆妝]';
		} elsif ($ch eq '妇') {
			$vars = '[妇婦]';
		} elsif ($ch eq '妈') {
			$vars = '[妈媽]';
		} elsif ($ch eq '妊') {
			$vars = '[妊姙]';
		} elsif ($ch eq '妍') {
			$vars = '[妍姸]';
		} elsif ($ch eq '妒') {
			$vars = '[妒妬]';
		} elsif ($ch eq '妙') {
			$vars = '[妙玅]';
		} elsif ($ch eq '妝') {
			$vars = '[妝妆粧]';
		} elsif ($ch eq '妩') {
			$vars = '[妩嫵]';
		} elsif ($ch eq '妪') {
			$vars = '[妪嫗]';
		} elsif ($ch eq '妫') {
			$vars = '[妫媯]';
		} elsif ($ch eq '妬') {
			$vars = '[妬妒]';
		} elsif ($ch eq '妳') {
			$vars = '[妳嬭奶你]';
		} elsif ($ch eq '姆') {
			$vars = '[姆佬姥]';
		} elsif ($ch eq '姉') {
			$vars = '[姉姊]';
		} elsif ($ch eq '姊') {
			$vars = '[姊姉]';
		} elsif ($ch eq '姍') {
			$vars = '[姍姗]';
		} elsif ($ch eq '姗') {
			$vars = '[姗姍]';
		} elsif ($ch eq '姙') {
			$vars = '[姙妊]';
		} elsif ($ch eq '姜') {
			$vars = '[姜薑]';
		} elsif ($ch eq '姥') {
			$vars = '[姥姆]';
		} elsif ($ch eq '姦') {
			$vars = '[姦奸]';
		} elsif ($ch eq '姪') {
			$vars = '[姪侄]';
		} elsif ($ch eq '姫') {
			$vars = '[姫姬]';
		} elsif ($ch eq '姬') {
			$vars = '[姬姫]';
		} elsif ($ch eq '姸') {
			$vars = '[姸妍]';
		} elsif ($ch eq '姹') {
			$vars = '[姹奼]';
		} elsif ($ch eq '娄') {
			$vars = '[娄婁]';
		} elsif ($ch eq '娅') {
			$vars = '[娅婭]';
		} elsif ($ch eq '娆') {
			$vars = '[娆嬈]';
		} elsif ($ch eq '娇') {
			$vars = '[娇嬌]';
		} elsif ($ch eq '娈') {
			$vars = '[娈孌]';
		} elsif ($ch eq '娘') {
			$vars = '[娘孃]';
		} elsif ($ch eq '娚') {
			$vars = '[娚喃]';
		} elsif ($ch eq '娛') {
			$vars = '[娛娱]';
		} elsif ($ch eq '娠') {
			$vars = '[娠煖]';
		} elsif ($ch eq '娯') {
			$vars = '[娯娛]';
		} elsif ($ch eq '娱') {
			$vars = '[娱娛]';
		} elsif ($ch eq '娲') {
			$vars = '[娲媧]';
		} elsif ($ch eq '娴') {
			$vars = '[娴嫻]';
		} elsif ($ch eq '婁') {
			$vars = '[婁娄]';
		} elsif ($ch eq '婦') {
			$vars = '[婦妇]';
		} elsif ($ch eq '婬') {
			$vars = '[婬淫]';
		} elsif ($ch eq '婭') {
			$vars = '[婭娅]';
		} elsif ($ch eq '婴') {
			$vars = '[婴嬰]';
		} elsif ($ch eq '婵') {
			$vars = '[婵嬋]';
		} elsif ($ch eq '婶') {
			$vars = '[婶嬸]';
		} elsif ($ch eq '婿') {
			$vars = '[婿聟壻]';
		} elsif ($ch eq '媧') {
			$vars = '[媧娲]';
		} elsif ($ch eq '媪') {
			$vars = '[媪媼]';
		} elsif ($ch eq '媯') {
			$vars = '[媯妫]';
		} elsif ($ch eq '媼') {
			$vars = '[媼媪]';
		} elsif ($ch eq '媽') {
			$vars = '[媽妈]';
		} elsif ($ch eq '媿') {
			$vars = '[媿愧]';
		} elsif ($ch eq '嫋') {
			$vars = '[嫋嬝]';
		} elsif ($ch eq '嫐') {
			$vars = '[嫐喃]';
		} elsif ($ch eq '嫒') {
			$vars = '[嫒嬡]';
		} elsif ($ch eq '嫔') {
			$vars = '[嫔嬪]';
		} elsif ($ch eq '嫕') {
			$vars = '[嫕嫛]';
		} elsif ($ch eq '嫗') {
			$vars = '[嫗妪]';
		} elsif ($ch eq '嫛') {
			$vars = '[嫛嫕]';
		} elsif ($ch eq '嫫') {
			$vars = '[嫫嬷]';
		} elsif ($ch eq '嫱') {
			$vars = '[嫱嬙]';
		} elsif ($ch eq '嫵') {
			$vars = '[嫵妩]';
		} elsif ($ch eq '嫺') {
			$vars = '[嫺嫻]';
		} elsif ($ch eq '嫻') {
			$vars = '[嫻娴嫺]';
		} elsif ($ch eq '嬈') {
			$vars = '[嬈娆]';
		} elsif ($ch eq '嬋') {
			$vars = '[嬋婵]';
		} elsif ($ch eq '嬌') {
			$vars = '[嬌撟娇]';
		} elsif ($ch eq '嬙') {
			$vars = '[嬙嫱]';
		} elsif ($ch eq '嬝') {
			$vars = '[嬝裊]';
		} elsif ($ch eq '嬡') {
			$vars = '[嬡嫒]';
		} elsif ($ch eq '嬢') {
			$vars = '[嬢娘]';
		} elsif ($ch eq '嬤') {
			$vars = '[嬤嬷]';
		} elsif ($ch eq '嬪') {
			$vars = '[嬪嫔]';
		} elsif ($ch eq '嬭') {
			$vars = '[嬭妳奶]';
		} elsif ($ch eq '嬰') {
			$vars = '[嬰婴]';
		} elsif ($ch eq '嬲') {
			$vars = '[嬲惱]';
		} elsif ($ch eq '嬷') {
			$vars = '[嬷嬤嫫]';
		} elsif ($ch eq '嬸') {
			$vars = '[嬸婶]';
		} elsif ($ch eq '嬾') {
			$vars = '[嬾懶]';
		} elsif ($ch eq '孀') {
			$vars = '[孀霜]';
		} elsif ($ch eq '孃') {
			$vars = '[孃娘]';
		} elsif ($ch eq '孌') {
			$vars = '[孌娈]';
		} elsif ($ch eq '子') {
			$vars = '[子只]';
		} elsif ($ch eq '孙') {
			$vars = '[孙孫]';
		} elsif ($ch eq '孚') {
			$vars = '[孚孵]';
		} elsif ($ch eq '孛') {
			$vars = '[孛柏栢]';
		} elsif ($ch eq '学') {
			$vars = '[学學]';
		} elsif ($ch eq '孪') {
			$vars = '[孪孿]';
		} elsif ($ch eq '孫') {
			$vars = '[孫孙]';
		} elsif ($ch eq '孰') {
			$vars = '[孰塾]';
		} elsif ($ch eq '孵') {
			$vars = '[孵孚]';
		} elsif ($ch eq '學') {
			$vars = '[學学斈]';
		} elsif ($ch eq '孼') {
			$vars = '[孼孽]';
		} elsif ($ch eq '孽') {
			$vars = '[孽孼]';
		} elsif ($ch eq '孿') {
			$vars = '[孿孪]';
		} elsif ($ch eq '宁') {
			$vars = '[宁寧]';
		} elsif ($ch eq '它') {
			$vars = '[它佗牠]';
		} elsif ($ch eq '宅') {
			$vars = '[宅宅]';
		} elsif ($ch eq '完') {
			$vars = '[完烟煙]';
		} elsif ($ch eq '宍') {
			$vars = '[宍肉]';
		} elsif ($ch eq '宝') {
			$vars = '[宝寶寳]';
		} elsif ($ch eq '实') {
			$vars = '[实實]';
		} elsif ($ch eq '実') {
			$vars = '[実實]';
		} elsif ($ch eq '宠') {
			$vars = '[宠寵]';
		} elsif ($ch eq '审') {
			$vars = '[审審]';
		} elsif ($ch eq '宪') {
			$vars = '[宪憲]';
		} elsif ($ch eq '宫') {
			$vars = '[宫宮]';
		} elsif ($ch eq '宮') {
			$vars = '[宮宫]';
		} elsif ($ch eq '宴') {
			$vars = '[宴讌]';
		} elsif ($ch eq '家') {
			$vars = '[家傢]';
		} elsif ($ch eq '宽') {
			$vars = '[宽寬]';
		} elsif ($ch eq '宾') {
			$vars = '[宾賓]';
		} elsif ($ch eq '寃') {
			$vars = '[寃冤]';
		} elsif ($ch eq '富') {
			$vars = '[富冨]';
		} elsif ($ch eq '寍') {
			$vars = '[寍寧]';
		} elsif ($ch eq '寔') {
			$vars = '[寔實]';
		} elsif ($ch eq '寗') {
			$vars = '[寗甯]';
		} elsif ($ch eq '寘') {
			$vars = '[寘置]';
		} elsif ($ch eq '寛') {
			$vars = '[寛寬]';
		} elsif ($ch eq '寝') {
			$vars = '[寝寢]';
		} elsif ($ch eq '寠') {
			$vars = '[寠窶]';
		} elsif ($ch eq '寡') {
			$vars = '[寡關]';
		} elsif ($ch eq '寢') {
			$vars = '[寢寝]';
		} elsif ($ch eq '實') {
			$vars = '[實寔实実]';
		} elsif ($ch eq '寧') {
			$vars = '[寧寍宁]';
		} elsif ($ch eq '寨') {
			$vars = '[寨砦]';
		} elsif ($ch eq '審') {
			$vars = '[審审]';
		} elsif ($ch eq '寫') {
			$vars = '[寫冩写]';
		} elsif ($ch eq '寬') {
			$vars = '[寬宽寛]';
		} elsif ($ch eq '寮') {
			$vars = '[寮寮]';
		} elsif ($ch eq '寳') {
			$vars = '[寳宝寶]';
		} elsif ($ch eq '寵') {
			$vars = '[寵宠]';
		} elsif ($ch eq '寶') {
			$vars = '[寶宝寳]';
		} elsif ($ch eq '寸') {
			$vars = '[寸吋]';
		} elsif ($ch eq '对') {
			$vars = '[对對]';
		} elsif ($ch eq '寻') {
			$vars = '[寻尋]';
		} elsif ($ch eq '导') {
			$vars = '[导導]';
		} elsif ($ch eq '寿') {
			$vars = '[寿壽]';
		} elsif ($ch eq '専') {
			$vars = '[専專]';
		} elsif ($ch eq '尃') {
			$vars = '[尃敷]';
		} elsif ($ch eq '尅') {
			$vars = '[尅剋]';
		} elsif ($ch eq '将') {
			$vars = '[将將]';
		} elsif ($ch eq '將') {
			$vars = '[將畺将]';
		} elsif ($ch eq '專') {
			$vars = '[專耑专]';
		} elsif ($ch eq '尉') {
			$vars = '[尉熨]';
		} elsif ($ch eq '尋') {
			$vars = '[尋寻]';
		} elsif ($ch eq '對') {
			$vars = '[對对]';
		} elsif ($ch eq '導') {
			$vars = '[導导]';
		} elsif ($ch eq '尒') {
			$vars = '[尒爾尔]';
		} elsif ($ch eq '尓') {
			$vars = '[尓爾]';
		} elsif ($ch eq '尔') {
			$vars = '[尔爾尒]';
		} elsif ($ch eq '尘') {
			$vars = '[尘塵]';
		} elsif ($ch eq '尙') {
			$vars = '[尙尚]';
		} elsif ($ch eq '尚') {
			$vars = '[尚尙]';
		} elsif ($ch eq '尜') {
			$vars = '[尜嘎]';
		} elsif ($ch eq '尝') {
			$vars = '[尝嘗]';
		} elsif ($ch eq '尠') {
			$vars = '[尠鮮]';
		} elsif ($ch eq '尧') {
			$vars = '[尧堯]';
		} elsif ($ch eq '尨') {
			$vars = '[尨龍]';
		} elsif ($ch eq '尭') {
			$vars = '[尭堯]';
		} elsif ($ch eq '尰') {
			$vars = '[尰腫]';
		} elsif ($ch eq '尴') {
			$vars = '[尴尷]';
		} elsif ($ch eq '尷') {
			$vars = '[尷尴]';
		} elsif ($ch eq '尸') {
			$vars = '[尸屍]';
		} elsif ($ch eq '尽') {
			$vars = '[尽盡儘]';
		} elsif ($ch eq '尿') {
			$vars = '[尿尿溺]';
		} elsif ($ch eq '层') {
			$vars = '[层層]';
		} elsif ($ch eq '屆') {
			$vars = '[屆届]';
		} elsif ($ch eq '屉') {
			$vars = '[屉屜]';
		} elsif ($ch eq '届') {
			$vars = '[届屆]';
		} elsif ($ch eq '屍') {
			$vars = '[屍尸]';
		} elsif ($ch eq '屏') {
			$vars = '[屏摒]';
		} elsif ($ch eq '屛') {
			$vars = '[屛摒]';
		} elsif ($ch eq '屜') {
			$vars = '[屜屉]';
		} elsif ($ch eq '属') {
			$vars = '[属屬]';
		} elsif ($ch eq '屡') {
			$vars = '[屡屢]';
		} elsif ($ch eq '屢') {
			$vars = '[屢屡屢]';
		} elsif ($ch eq '屣') {
			$vars = '[屣蹝]';
		} elsif ($ch eq '層') {
			$vars = '[層层]';
		} elsif ($ch eq '履') {
			$vars = '[履履]';
		} elsif ($ch eq '屦') {
			$vars = '[屦屨]';
		} elsif ($ch eq '屨') {
			$vars = '[屨屦]';
		} elsif ($ch eq '屩') {
			$vars = '[屩蹺]';
		} elsif ($ch eq '屬') {
			$vars = '[屬属]';
		} elsif ($ch eq '屭') {
			$vars = '[屭屓]';
		} elsif ($ch eq '屿') {
			$vars = '[屿嶼]';
		} elsif ($ch eq '岁') {
			$vars = '[岁歲]';
		} elsif ($ch eq '岂') {
			$vars = '[岂豈]';
		} elsif ($ch eq '岐') {
			$vars = '[岐歧]';
		} elsif ($ch eq '岖') {
			$vars = '[岖嶇]';
		} elsif ($ch eq '岗') {
			$vars = '[岗崗岡]';
		} elsif ($ch eq '岘') {
			$vars = '[岘峴]';
		} elsif ($ch eq '岙') {
			$vars = '[岙嶴]';
		} elsif ($ch eq '岚') {
			$vars = '[岚嵐]';
		} elsif ($ch eq '岛') {
			$vars = '[岛島]';
		} elsif ($ch eq '岡') {
			$vars = '[岡崗冈]';
		} elsif ($ch eq '岨') {
			$vars = '[岨砠]';
		} elsif ($ch eq '岩') {
			$vars = '[岩巖]';
		} elsif ($ch eq '岫') {
			$vars = '[岫峀]';
		} elsif ($ch eq '岭') {
			$vars = '[岭嶺岺]';
		} elsif ($ch eq '岳') {
			$vars = '[岳嶽]';
		} elsif ($ch eq '岺') {
			$vars = '[岺岭]';
		} elsif ($ch eq '岽') {
			$vars = '[岽崠]';
		} elsif ($ch eq '岿') {
			$vars = '[岿巋]';
		} elsif ($ch eq '峀') {
			$vars = '[峀岫]';
		} elsif ($ch eq '峄') {
			$vars = '[峄嶧]';
		} elsif ($ch eq '峒') {
			$vars = '[峒洞]';
		} elsif ($ch eq '峡') {
			$vars = '[峡峽]';
		} elsif ($ch eq '峤') {
			$vars = '[峤嶠]';
		} elsif ($ch eq '峥') {
			$vars = '[峥崢]';
		} elsif ($ch eq '峦') {
			$vars = '[峦巒]';
		} elsif ($ch eq '峨') {
			$vars = '[峨峩]';
		} elsif ($ch eq '峩') {
			$vars = '[峩峨]';
		} elsif ($ch eq '峯') {
			$vars = '[峯峰]';
		} elsif ($ch eq '峰') {
			$vars = '[峰峯]';
		} elsif ($ch eq '峴') {
			$vars = '[峴岘]';
		} elsif ($ch eq '島') {
			$vars = '[島嶋岛]';
		} elsif ($ch eq '峺') {
			$vars = '[峺硬]';
		} elsif ($ch eq '峽') {
			$vars = '[峽峡]';
		} elsif ($ch eq '崂') {
			$vars = '[崂嶗]';
		} elsif ($ch eq '崃') {
			$vars = '[崃崍]';
		} elsif ($ch eq '崋') {
			$vars = '[崋華]';
		} elsif ($ch eq '崍') {
			$vars = '[崍崃]';
		} elsif ($ch eq '崎') {
			$vars = '[崎埼]';
		} elsif ($ch eq '崔') {
			$vars = '[崔磪]';
		} elsif ($ch eq '崕') {
			$vars = '[崕崖]';
		} elsif ($ch eq '崖') {
			$vars = '[崖厓]';
		} elsif ($ch eq '崗') {
			$vars = '[崗岗岡]';
		} elsif ($ch eq '崘') {
			$vars = '[崘崙]';
		} elsif ($ch eq '崙') {
			$vars = '[崙崘侖崙]';
		} elsif ($ch eq '崟') {
			$vars = '[崟嶔]';
		} elsif ($ch eq '崠') {
			$vars = '[崠岽]';
		} elsif ($ch eq '崢') {
			$vars = '[崢峥]';
		} elsif ($ch eq '崧') {
			$vars = '[崧嵩]';
		} elsif ($ch eq '崭') {
			$vars = '[崭嶄]';
		} elsif ($ch eq '嵐') {
			$vars = '[嵐岚嵐]';
		} elsif ($ch eq '嵘') {
			$vars = '[嵘嶸]';
		} elsif ($ch eq '嵜') {
			$vars = '[嵜崎]';
		} elsif ($ch eq '嵝') {
			$vars = '[嵝嶁]';
		} elsif ($ch eq '嵩') {
			$vars = '[嵩崧]';
		} elsif ($ch eq '嵯') {
			$vars = '[嵯嵳]';
		} elsif ($ch eq '嵳') {
			$vars = '[嵳嵯]';
		} elsif ($ch eq '嶁') {
			$vars = '[嶁嵝]';
		} elsif ($ch eq '嶄') {
			$vars = '[嶄崭巉]';
		} elsif ($ch eq '嶇') {
			$vars = '[嶇岖]';
		} elsif ($ch eq '嶋') {
			$vars = '[嶋島]';
		} elsif ($ch eq '嶌') {
			$vars = '[嶌島]';
		} elsif ($ch eq '嶔') {
			$vars = '[嶔崟]';
		} elsif ($ch eq '嶗') {
			$vars = '[嶗崂]';
		} elsif ($ch eq '嶝') {
			$vars = '[嶝磴]';
		} elsif ($ch eq '嶠') {
			$vars = '[嶠峤]';
		} elsif ($ch eq '嶧') {
			$vars = '[嶧峄]';
		} elsif ($ch eq '嶴') {
			$vars = '[嶴岙]';
		} elsif ($ch eq '嶸') {
			$vars = '[嶸嵘]';
		} elsif ($ch eq '嶺') {
			$vars = '[嶺嶺岭]';
		} elsif ($ch eq '嶼') {
			$vars = '[嶼屿]';
		} elsif ($ch eq '嶽') {
			$vars = '[嶽岳]';
		} elsif ($ch eq '巅') {
			$vars = '[巅巔]';
		} elsif ($ch eq '巉') {
			$vars = '[巉嶄]';
		} elsif ($ch eq '巋') {
			$vars = '[巋岿]';
		} elsif ($ch eq '巌') {
			$vars = '[巌巖]';
		} elsif ($ch eq '巍') {
			$vars = '[巍魏]';
		} elsif ($ch eq '巒') {
			$vars = '[巒峦]';
		} elsif ($ch eq '巔') {
			$vars = '[巔巅巓]';
		} elsif ($ch eq '巖') {
			$vars = '[巖巌岩]';
		} elsif ($ch eq '巛') {
			$vars = '[巛川]';
		} elsif ($ch eq '川') {
			$vars = '[川巛]';
		} elsif ($ch eq '巢') {
			$vars = '[巢巣]';
		} elsif ($ch eq '巣') {
			$vars = '[巣巢]';
		} elsif ($ch eq '巨') {
			$vars = '[巨鉅]';
		} elsif ($ch eq '巩') {
			$vars = '[巩鞏]';
		} elsif ($ch eq '巯') {
			$vars = '[巯巰]';
		} elsif ($ch eq '巰') {
			$vars = '[巰巯]';
		} elsif ($ch eq '巴') {
			$vars = '[巴笆]';
		} elsif ($ch eq '巵') {
			$vars = '[巵卮]';
		} elsif ($ch eq '巻') {
			$vars = '[巻捲]';
		} elsif ($ch eq '币') {
			$vars = '[币幣]';
		} elsif ($ch eq '布') {
			$vars = '[布佈]';
		} elsif ($ch eq '帅') {
			$vars = '[帅帥]';
		} elsif ($ch eq '帆') {
			$vars = '[帆拚]';
		} elsif ($ch eq '师') {
			$vars = '[师師]';
		} elsif ($ch eq '帋') {
			$vars = '[帋紙]';
		} elsif ($ch eq '希') {
			$vars = '[希稀]';
		} elsif ($ch eq '帏') {
			$vars = '[帏幃]';
		} elsif ($ch eq '帐') {
			$vars = '[帐帳]';
		} elsif ($ch eq '帘') {
			$vars = '[帘簾]';
		} elsif ($ch eq '帚') {
			$vars = '[帚菷箒]';
		} elsif ($ch eq '帜') {
			$vars = '[帜幟]';
		} elsif ($ch eq '帥') {
			$vars = '[帥帅]';
		} elsif ($ch eq '带') {
			$vars = '[带帶]';
		} elsif ($ch eq '帧') {
			$vars = '[帧幀]';
		} elsif ($ch eq '師') {
			$vars = '[師师]';
		} elsif ($ch eq '席') {
			$vars = '[席蓆]';
		} elsif ($ch eq '帮') {
			$vars = '[帮幇幫]';
		} elsif ($ch eq '帯') {
			$vars = '[帯帶]';
		} elsif ($ch eq '帰') {
			$vars = '[帰歸]';
		} elsif ($ch eq '帱') {
			$vars = '[帱幬]';
		} elsif ($ch eq '帳') {
			$vars = '[帳帐賬]';
		} elsif ($ch eq '帶') {
			$vars = '[帶帯带]';
		} elsif ($ch eq '帻') {
			$vars = '[帻幘]';
		} elsif ($ch eq '帼') {
			$vars = '[帼幗]';
		} elsif ($ch eq '幀') {
			$vars = '[幀帧]';
		} elsif ($ch eq '幂') {
			$vars = '[幂冪鼏]';
		} elsif ($ch eq '幃') {
			$vars = '[幃帏]';
		} elsif ($ch eq '幇') {
			$vars = '[幇幫帮]';
		} elsif ($ch eq '幕') {
			$vars = '[幕幙]';
		} elsif ($ch eq '幗') {
			$vars = '[幗帼]';
		} elsif ($ch eq '幘') {
			$vars = '[幘帻]';
		} elsif ($ch eq '幙') {
			$vars = '[幙幕]';
		} elsif ($ch eq '幞') {
			$vars = '[幞襮]';
		} elsif ($ch eq '幟') {
			$vars = '[幟帜]';
		} elsif ($ch eq '幡') {
			$vars = '[幡旛]';
		} elsif ($ch eq '幢') {
			$vars = '[幢橦]';
		} elsif ($ch eq '幣') {
			$vars = '[幣币]';
		} elsif ($ch eq '幤') {
			$vars = '[幤幣]';
		} elsif ($ch eq '幫') {
			$vars = '[幫幇帮]';
		} elsif ($ch eq '幬') {
			$vars = '[幬帱]';
		} elsif ($ch eq '干') {
			$vars = '[干幹乾]';
		} elsif ($ch eq '年') {
			$vars = '[年秊]';
		} elsif ($ch eq '幵') {
			$vars = '[幵开]';
		} elsif ($ch eq '并') {
			$vars = '[并幷併竝並]';
		} elsif ($ch eq '幷') {
			$vars = '[幷并竝並]';
		} elsif ($ch eq '幸') {
			$vars = '[幸囟倖]';
		} elsif ($ch eq '幹') {
			$vars = '[幹干]';
		} elsif ($ch eq '幺') {
			$vars = '[幺么]';
		} elsif ($ch eq '幽') {
			$vars = '[幽凼]';
		} elsif ($ch eq '幾') {
			$vars = '[幾几]';
		} elsif ($ch eq '广') {
			$vars = '[广廣]';
		} elsif ($ch eq '庁') {
			$vars = '[庁廳]';
		} elsif ($ch eq '広') {
			$vars = '[広廣]';
		} elsif ($ch eq '庄') {
			$vars = '[庄莊]';
		} elsif ($ch eq '庆') {
			$vars = '[庆慶]';
		} elsif ($ch eq '床') {
			$vars = '[床牀]';
		} elsif ($ch eq '庐') {
			$vars = '[庐廬]';
		} elsif ($ch eq '庑') {
			$vars = '[庑廡]';
		} elsif ($ch eq '库') {
			$vars = '[库庫]';
		} elsif ($ch eq '应') {
			$vars = '[应應]';
		} elsif ($ch eq '店') {
			$vars = '[店坫]';
		} elsif ($ch eq '庙') {
			$vars = '[庙廟]';
		} elsif ($ch eq '庞') {
			$vars = '[庞龐]';
		} elsif ($ch eq '废') {
			$vars = '[废廢]';
		} elsif ($ch eq '度') {
			$vars = '[度廓]';
		} elsif ($ch eq '座') {
			$vars = '[座坐]';
		} elsif ($ch eq '庫') {
			$vars = '[庫库]';
		} elsif ($ch eq '庬') {
			$vars = '[庬厖]';
		} elsif ($ch eq '庵') {
			$vars = '[庵菴]';
		} elsif ($ch eq '庾') {
			$vars = '[庾斞]';
		} elsif ($ch eq '廁') {
			$vars = '[廁厕厠]';
		} elsif ($ch eq '廂') {
			$vars = '[廂厢]';
		} elsif ($ch eq '廃') {
			$vars = '[廃廢]';
		} elsif ($ch eq '廄') {
			$vars = '[廄廐厩]';
		} elsif ($ch eq '廈') {
			$vars = '[廈厦]';
		} elsif ($ch eq '廉') {
			$vars = '[廉廉]';
		} elsif ($ch eq '廊') {
			$vars = '[廊廊]';
		} elsif ($ch eq '廌') {
			$vars = '[廌豸]';
		} elsif ($ch eq '廏') {
			$vars = '[廏廄]';
		} elsif ($ch eq '廐') {
			$vars = '[廐廄厩]';
		} elsif ($ch eq '廓') {
			$vars = '[廓廓]';
		} elsif ($ch eq '廕') {
			$vars = '[廕蔭]';
		} elsif ($ch eq '廚') {
			$vars = '[廚厨]';
		} elsif ($ch eq '廝') {
			$vars = '[廝厮]';
		} elsif ($ch eq '廟') {
			$vars = '[廟庙]';
		} elsif ($ch eq '廠') {
			$vars = '[廠厂厰]';
		} elsif ($ch eq '廡') {
			$vars = '[廡庑]';
		} elsif ($ch eq '廢') {
			$vars = '[廢废廃]';
		} elsif ($ch eq '廣') {
			$vars = '[廣广]';
		} elsif ($ch eq '廧') {
			$vars = '[廧牆墻]';
		} elsif ($ch eq '廩') {
			$vars = '[廩稟廪]';
		} elsif ($ch eq '廪') {
			$vars = '[廪稟廩]';
		} elsif ($ch eq '廬') {
			$vars = '[廬廬庐]';
		} elsif ($ch eq '廰') {
			$vars = '[廰廳]';
		} elsif ($ch eq '廱') {
			$vars = '[廱雝]';
		} elsif ($ch eq '廳') {
			$vars = '[廳厅廰]';
		} elsif ($ch eq '廸') {
			$vars = '[廸迪]';
		} elsif ($ch eq '廻') {
			$vars = '[廻迴回]';
		} elsif ($ch eq '廼') {
			$vars = '[廼乃迺]';
		} elsif ($ch eq '廾') {
			$vars = '[廾廿]';
		} elsif ($ch eq '廿') {
			$vars = '[廿廾卄]';
		} elsif ($ch eq '开') {
			$vars = '[开開幵]';
		} elsif ($ch eq '弁') {
			$vars = '[弁辨]';
		} elsif ($ch eq '异') {
			$vars = '[异異]';
		} elsif ($ch eq '弃') {
			$vars = '[弃棄]';
		} elsif ($ch eq '弄') {
			$vars = '[弄弄瘧]';
		} elsif ($ch eq '弈') {
			$vars = '[弈奕]';
		} elsif ($ch eq '弉') {
			$vars = '[弉奘]';
		} elsif ($ch eq '弌') {
			$vars = '[弌壹一搋]';
		} elsif ($ch eq '弍') {
			$vars = '[弍二貳]';
		} elsif ($ch eq '弑') {
			$vars = '[弑弒]';
		} elsif ($ch eq '弒') {
			$vars = '[弒弑]';
		} elsif ($ch eq '弔') {
			$vars = '[弔吊]';
		} elsif ($ch eq '张') {
			$vars = '[张張]';
		} elsif ($ch eq '弢') {
			$vars = '[弢韜]';
		} elsif ($ch eq '弥') {
			$vars = '[弥彌]';
		} elsif ($ch eq '弦') {
			$vars = '[弦絃]';
		} elsif ($ch eq '弪') {
			$vars = '[弪弳]';
		} elsif ($ch eq '弯') {
			$vars = '[弯彎]';
		} elsif ($ch eq '弳') {
			$vars = '[弳弪]';
		} elsif ($ch eq '張') {
			$vars = '[張张]';
		} elsif ($ch eq '強') {
			$vars = '[強强彊]';
		} elsif ($ch eq '弹') {
			$vars = '[弹彈]';
		} elsif ($ch eq '强') {
			$vars = '[强強彊]';
		} elsif ($ch eq '弾') {
			$vars = '[弾彈]';
		} elsif ($ch eq '彀') {
			$vars = '[彀夠够]';
		} elsif ($ch eq '彈') {
			$vars = '[彈弹]';
		} elsif ($ch eq '彊') {
			$vars = '[彊强強]';
		} elsif ($ch eq '彌') {
			$vars = '[彌弥]';
		} elsif ($ch eq '彎') {
			$vars = '[彎弯]';
		} elsif ($ch eq '彐') {
			$vars = '[彐彑]';
		} elsif ($ch eq '彑') {
			$vars = '[彑彐]';
		} elsif ($ch eq '归') {
			$vars = '[归歸]';
		} elsif ($ch eq '当') {
			$vars = '[当當噹]';
		} elsif ($ch eq '录') {
			$vars = '[录録錄]';
		} elsif ($ch eq '彗') {
			$vars = '[彗篲]';
		} elsif ($ch eq '彙') {
			$vars = '[彙汇]';
		} elsif ($ch eq '彛') {
			$vars = '[彛彝]';
		} elsif ($ch eq '彜') {
			$vars = '[彜彝]';
		} elsif ($ch eq '彝') {
			$vars = '[彝彛]';
		} elsif ($ch eq '彥') {
			$vars = '[彥彦]';
		} elsif ($ch eq '彦') {
			$vars = '[彦彥]';
		} elsif ($ch eq '彫') {
			$vars = '[彫鵰雕]';
		} elsif ($ch eq '彬') {
			$vars = '[彬斌份]';
		} elsif ($ch eq '彷') {
			$vars = '[彷仿髣徬]';
		} elsif ($ch eq '彸') {
			$vars = '[彸伀]';
		} elsif ($ch eq '彻') {
			$vars = '[彻徹]';
		} elsif ($ch eq '彿') {
			$vars = '[彿髴]';
		} elsif ($ch eq '往') {
			$vars = '[往徃]';
		} elsif ($ch eq '征') {
			$vars = '[征徵]';
		} elsif ($ch eq '徃') {
			$vars = '[徃往]';
		} elsif ($ch eq '径') {
			$vars = '[径徑]';
		} elsif ($ch eq '律') {
			$vars = '[律律]';
		} elsif ($ch eq '後') {
			$vars = '[後后]';
		} elsif ($ch eq '徑') {
			$vars = '[徑俓勁径]';
		} elsif ($ch eq '従') {
			$vars = '[従從]';
		} elsif ($ch eq '徕') {
			$vars = '[徕徠]';
		} elsif ($ch eq '從') {
			$vars = '[從従从]';
		} elsif ($ch eq '徠') {
			$vars = '[徠徕來]';
		} elsif ($ch eq '御') {
			$vars = '[御馭禦]';
		} elsif ($ch eq '徨') {
			$vars = '[徨遑]';
		} elsif ($ch eq '復') {
			$vars = '[復复覆]';
		} elsif ($ch eq '徬') {
			$vars = '[徬彷]';
		} elsif ($ch eq '徭') {
			$vars = '[徭傜]';
		} elsif ($ch eq '徳') {
			$vars = '[徳德]';
		} elsif ($ch eq '徴') {
			$vars = '[徴徵]';
		} elsif ($ch eq '徵') {
			$vars = '[徵征]';
		} elsif ($ch eq '德') {
			$vars = '[德悳]';
		} elsif ($ch eq '徹') {
			$vars = '[徹彻澈]';
		} elsif ($ch eq '心') {
			$vars = '[心忄]';
		} elsif ($ch eq '忄') {
			$vars = '[忄心]';
		} elsif ($ch eq '忆') {
			$vars = '[忆憶]';
		} elsif ($ch eq '忏') {
			$vars = '[忏懺]';
		} elsif ($ch eq '志') {
			$vars = '[志誌]';
		} elsif ($ch eq '応') {
			$vars = '[応應]';
		} elsif ($ch eq '忞') {
			$vars = '[忞暋]';
		} elsif ($ch eq '忤') {
			$vars = '[忤啎迕]';
		} elsif ($ch eq '忧') {
			$vars = '[忧憂]';
		} elsif ($ch eq '忰') {
			$vars = '[忰悴]';
		} elsif ($ch eq '念') {
			$vars = '[念念]';
		} elsif ($ch eq '忻') {
			$vars = '[忻欣]';
		} elsif ($ch eq '忾') {
			$vars = '[忾愾]';
		} elsif ($ch eq '怀') {
			$vars = '[怀懷]';
		} elsif ($ch eq '态') {
			$vars = '[态態]';
		} elsif ($ch eq '怂') {
			$vars = '[怂慫]';
		} elsif ($ch eq '怃') {
			$vars = '[怃憮]';
		} elsif ($ch eq '怄') {
			$vars = '[怄慪]';
		} elsif ($ch eq '怅') {
			$vars = '[怅悵]';
		} elsif ($ch eq '怆') {
			$vars = '[怆愴]';
		} elsif ($ch eq '怌') {
			$vars = '[怌懷]';
		} elsif ($ch eq '怒') {
			$vars = '[怒怒]';
		} elsif ($ch eq '怜') {
			$vars = '[怜憐]';
		} elsif ($ch eq '怪') {
			$vars = '[怪恠]';
		} elsif ($ch eq '怱') {
			$vars = '[怱匆悤]';
		} elsif ($ch eq '怳') {
			$vars = '[怳恍]';
		} elsif ($ch eq '总') {
			$vars = '[总總]';
		} elsif ($ch eq '怼') {
			$vars = '[怼懟]';
		} elsif ($ch eq '怿') {
			$vars = '[怿懌]';
		} elsif ($ch eq '恂') {
			$vars = '[恂悛]';
		} elsif ($ch eq '恆') {
			$vars = '[恆恒]';
		} elsif ($ch eq '恊') {
			$vars = '[恊協勰]';
		} elsif ($ch eq '恋') {
			$vars = '[恋戀]';
		} elsif ($ch eq '恍') {
			$vars = '[恍怳]';
		} elsif ($ch eq '恒') {
			$vars = '[恒恆]';
		} elsif ($ch eq '恠') {
			$vars = '[恠怪]';
		} elsif ($ch eq '恤') {
			$vars = '[恤卹]';
		} elsif ($ch eq '恥') {
			$vars = '[恥耻]';
		} elsif ($ch eq '恩') {
			$vars = '[恩摁]';
		} elsif ($ch eq '恳') {
			$vars = '[恳懇]';
		} elsif ($ch eq '恵') {
			$vars = '[恵惠]';
		} elsif ($ch eq '恶') {
			$vars = '[恶惡]';
		} elsif ($ch eq '恸') {
			$vars = '[恸慟]';
		} elsif ($ch eq '恹') {
			$vars = '[恹懨]';
		} elsif ($ch eq '恺') {
			$vars = '[恺愷]';
		} elsif ($ch eq '恻') {
			$vars = '[恻惻]';
		} elsif ($ch eq '恼') {
			$vars = '[恼惱]';
		} elsif ($ch eq '恽') {
			$vars = '[恽惲]';
		} elsif ($ch eq '恿') {
			$vars = '[恿慂]';
		} elsif ($ch eq '悁') {
			$vars = '[悁懁]';
		} elsif ($ch eq '悅') {
			$vars = '[悅悦]';
		} elsif ($ch eq '悊') {
			$vars = '[悊哲]';
		} elsif ($ch eq '悋') {
			$vars = '[悋吝]';
		} elsif ($ch eq '悐') {
			$vars = '[悐惕]';
		} elsif ($ch eq '悛') {
			$vars = '[悛恂]';
		} elsif ($ch eq '悤') {
			$vars = '[悤匆怱]';
		} elsif ($ch eq '悦') {
			$vars = '[悦悅]';
		} elsif ($ch eq '悪') {
			$vars = '[悪惡]';
		} elsif ($ch eq '悫') {
			$vars = '[悫慤愨]';
		} elsif ($ch eq '悬') {
			$vars = '[悬懸]';
		} elsif ($ch eq '悭') {
			$vars = '[悭慳]';
		} elsif ($ch eq '悯') {
			$vars = '[悯憫]';
		} elsif ($ch eq '悳') {
			$vars = '[悳德]';
		} elsif ($ch eq '悴') {
			$vars = '[悴忰]';
		} elsif ($ch eq '悵') {
			$vars = '[悵怅]';
		} elsif ($ch eq '悶') {
			$vars = '[悶闷懣]';
		} elsif ($ch eq '悽') {
			$vars = '[悽淒]';
		} elsif ($ch eq '惇') {
			$vars = '[惇敦]';
		} elsif ($ch eq '惊') {
			$vars = '[惊驚]';
		} elsif ($ch eq '惕') {
			$vars = '[惕悐]';
		} elsif ($ch eq '惠') {
			$vars = '[惠恵]';
		} elsif ($ch eq '惡') {
			$vars = '[惡惡恶]';
		} elsif ($ch eq '惧') {
			$vars = '[惧懼]';
		} elsif ($ch eq '惨') {
			$vars = '[惨慘]';
		} elsif ($ch eq '惩') {
			$vars = '[惩懲]';
		} elsif ($ch eq '惫') {
			$vars = '[惫憊]';
		} elsif ($ch eq '惬') {
			$vars = '[惬愜]';
		} elsif ($ch eq '惭') {
			$vars = '[惭慚]';
		} elsif ($ch eq '惮') {
			$vars = '[惮憚]';
		} elsif ($ch eq '惯') {
			$vars = '[惯慣]';
		} elsif ($ch eq '惱') {
			$vars = '[惱嬲恼]';
		} elsif ($ch eq '惲') {
			$vars = '[惲恽]';
		} elsif ($ch eq '惷') {
			$vars = '[惷蠢]';
		} elsif ($ch eq '惺') {
			$vars = '[惺醒]';
		} elsif ($ch eq '惻') {
			$vars = '[惻恻]';
		} elsif ($ch eq '愈') {
			$vars = '[愈瘉愉癒]';
		} elsif ($ch eq '愉') {
			$vars = '[愉愈]';
		} elsif ($ch eq '愍') {
			$vars = '[愍憫]';
		} elsif ($ch eq '愛') {
			$vars = '[愛爱]';
		} elsif ($ch eq '愜') {
			$vars = '[愜惬]';
		} elsif ($ch eq '愠') {
			$vars = '[愠慍]';
		} elsif ($ch eq '愤') {
			$vars = '[愤憤]';
		} elsif ($ch eq '愦') {
			$vars = '[愦憒]';
		} elsif ($ch eq '愧') {
			$vars = '[愧媿]';
		} elsif ($ch eq '愨') {
			$vars = '[愨慤悫]';
		} elsif ($ch eq '愬') {
			$vars = '[愬訴]';
		} elsif ($ch eq '愴') {
			$vars = '[愴怆]';
		} elsif ($ch eq '愷') {
			$vars = '[愷恺]';
		} elsif ($ch eq '愻') {
			$vars = '[愻遜]';
		} elsif ($ch eq '愽') {
			$vars = '[愽博]';
		} elsif ($ch eq '愾') {
			$vars = '[愾忾]';
		} elsif ($ch eq '愿') {
			$vars = '[愿願]';
		} elsif ($ch eq '慂') {
			$vars = '[慂恿]';
		} elsif ($ch eq '慄') {
			$vars = '[慄栗慄]';
		} elsif ($ch eq '態') {
			$vars = '[態态]';
		} elsif ($ch eq '慍') {
			$vars = '[慍愠]';
		} elsif ($ch eq '慎') {
			$vars = '[慎愼]';
		} elsif ($ch eq '慑') {
			$vars = '[慑懾]';
		} elsif ($ch eq '慘') {
			$vars = '[慘惨]';
		} elsif ($ch eq '慙') {
			$vars = '[慙慚]';
		} elsif ($ch eq '慚') {
			$vars = '[慚惭慙]';
		} elsif ($ch eq '慞') {
			$vars = '[慞傽]';
		} elsif ($ch eq '慟') {
			$vars = '[慟恸]';
		} elsif ($ch eq '慣') {
			$vars = '[慣惯]';
		} elsif ($ch eq '慤') {
			$vars = '[慤愨悫]';
		} elsif ($ch eq '慪') {
			$vars = '[慪嘔怄]';
		} elsif ($ch eq '慫') {
			$vars = '[慫怂]';
		} elsif ($ch eq '慮') {
			$vars = '[慮虑]';
		} elsif ($ch eq '慳') {
			$vars = '[慳悭]';
		} elsif ($ch eq '慶') {
			$vars = '[慶庆]';
		} elsif ($ch eq '慼') {
			$vars = '[慼慽]';
		} elsif ($ch eq '慽') {
			$vars = '[慽慼]';
		} elsif ($ch eq '慾') {
			$vars = '[慾欲]';
		} elsif ($ch eq '憂') {
			$vars = '[憂懮忧]';
		} elsif ($ch eq '憇') {
			$vars = '[憇憩]';
		} elsif ($ch eq '憊') {
			$vars = '[憊惫]';
		} elsif ($ch eq '憐') {
			$vars = '[憐憐怜]';
		} elsif ($ch eq '憑') {
			$vars = '[憑凭]';
		} elsif ($ch eq '憒') {
			$vars = '[憒愦]';
		} elsif ($ch eq '憙') {
			$vars = '[憙喜]';
		} elsif ($ch eq '憚') {
			$vars = '[憚惮]';
		} elsif ($ch eq '憝') {
			$vars = '[憝懟譈]';
		} elsif ($ch eq '憤') {
			$vars = '[憤愤]';
		} elsif ($ch eq '憩') {
			$vars = '[憩憇]';
		} elsif ($ch eq '憫') {
			$vars = '[憫愍悯]';
		} elsif ($ch eq '憮') {
			$vars = '[憮怃]';
		} elsif ($ch eq '憰') {
			$vars = '[憰譎]';
		} elsif ($ch eq '憲') {
			$vars = '[憲宪]';
		} elsif ($ch eq '憶') {
			$vars = '[憶忆]';
		} elsif ($ch eq '懁') {
			$vars = '[懁悁]';
		} elsif ($ch eq '懃') {
			$vars = '[懃勤]';
		} elsif ($ch eq '懇') {
			$vars = '[懇恳]';
		} elsif ($ch eq '應') {
			$vars = '[應应硬応]';
		} elsif ($ch eq '懌') {
			$vars = '[懌怿]';
		} elsif ($ch eq '懍') {
			$vars = '[懍懔]';
		} elsif ($ch eq '懐') {
			$vars = '[懐懷]';
		} elsif ($ch eq '懑') {
			$vars = '[懑懣]';
		} elsif ($ch eq '懒') {
			$vars = '[懒懶]';
		} elsif ($ch eq '懔') {
			$vars = '[懔懍凛]';
		} elsif ($ch eq '懞') {
			$vars = '[懞蒙]';
		} elsif ($ch eq '懟') {
			$vars = '[懟怼憝譈]';
		} elsif ($ch eq '懣') {
			$vars = '[懣悶懑]';
		} elsif ($ch eq '懥') {
			$vars = '[懥懫]';
		} elsif ($ch eq '懨') {
			$vars = '[懨恹]';
		} elsif ($ch eq '懫') {
			$vars = '[懫懥]';
		} elsif ($ch eq '懮') {
			$vars = '[懮憂]';
		} elsif ($ch eq '懲') {
			$vars = '[懲惩]';
		} elsif ($ch eq '懴') {
			$vars = '[懴懺]';
		} elsif ($ch eq '懶') {
			$vars = '[懶懒]';
		} elsif ($ch eq '懷') {
			$vars = '[懷怀怌]';
		} elsif ($ch eq '懸') {
			$vars = '[懸悬]';
		} elsif ($ch eq '懺') {
			$vars = '[懺忏懴]';
		} elsif ($ch eq '懼') {
			$vars = '[懼惧]';
		} elsif ($ch eq '懽') {
			$vars = '[懽欢歡]';
		} elsif ($ch eq '懾') {
			$vars = '[懾慑]';
		} elsif ($ch eq '戀') {
			$vars = '[戀戀恋]';
		} elsif ($ch eq '戆') {
			$vars = '[戆戇]';
		} elsif ($ch eq '戇') {
			$vars = '[戇戆]';
		} elsif ($ch eq '戉') {
			$vars = '[戉鉞]';
		} elsif ($ch eq '戋') {
			$vars = '[戋戔]';
		} elsif ($ch eq '戏') {
			$vars = '[戏戲]';
		} elsif ($ch eq '戔') {
			$vars = '[戔戋]';
		} elsif ($ch eq '戗') {
			$vars = '[戗戧]';
		} elsif ($ch eq '战') {
			$vars = '[战戰]';
		} elsif ($ch eq '戛') {
			$vars = '[戛戞]';
		} elsif ($ch eq '戝') {
			$vars = '[戝賊]';
		} elsif ($ch eq '戞') {
			$vars = '[戞戛]';
		} elsif ($ch eq '戦') {
			$vars = '[戦戰]';
		} elsif ($ch eq '戧') {
			$vars = '[戧戗創]';
		} elsif ($ch eq '戩') {
			$vars = '[戩戬]';
		} elsif ($ch eq '戬') {
			$vars = '[戬戩]';
		} elsif ($ch eq '戮') {
			$vars = '[戮戮]';
		} elsif ($ch eq '戯') {
			$vars = '[戯戱戲]';
		} elsif ($ch eq '戰') {
			$vars = '[戰戦战]';
		} elsif ($ch eq '戱') {
			$vars = '[戱戯戲]';
		} elsif ($ch eq '戲') {
			$vars = '[戲戱戯戏]';
		} elsif ($ch eq '戶') {
			$vars = '[戶戸户]';
		} elsif ($ch eq '户') {
			$vars = '[户戶]';
		} elsif ($ch eq '戸') {
			$vars = '[戸戶]';
		} elsif ($ch eq '戻') {
			$vars = '[戻戾]';
		} elsif ($ch eq '戾') {
			$vars = '[戾戻]';
		} elsif ($ch eq '扁') {
			$vars = '[扁艑碥]';
		} elsif ($ch eq '扇') {
			$vars = '[扇煽]';
		} elsif ($ch eq '手') {
			$vars = '[手扌]';
		} elsif ($ch eq '扌') {
			$vars = '[扌手]';
		} elsif ($ch eq '才') {
			$vars = '[才纔財]';
		} elsif ($ch eq '扎') {
			$vars = '[扎紮]';
		} elsif ($ch eq '扐') {
			$vars = '[扐朸]';
		} elsif ($ch eq '扑') {
			$vars = '[扑撲]';
		} elsif ($ch eq '払') {
			$vars = '[払拂]';
		} elsif ($ch eq '托') {
			$vars = '[托拓]';
		} elsif ($ch eq '扛') {
			$vars = '[扛摃]';
		} elsif ($ch eq '扞') {
			$vars = '[扞擀捍]';
		} elsif ($ch eq '扠') {
			$vars = '[扠搋]';
		} elsif ($ch eq '执') {
			$vars = '[执執]';
		} elsif ($ch eq '扩') {
			$vars = '[扩擴]';
		} elsif ($ch eq '扪') {
			$vars = '[扪捫]';
		} elsif ($ch eq '扫') {
			$vars = '[扫掃]';
		} elsif ($ch eq '扬') {
			$vars = '[扬揚]';
		} elsif ($ch eq '扯') {
			$vars = '[扯撦]';
		} elsif ($ch eq '扰') {
			$vars = '[扰擾]';
		} elsif ($ch eq '扱') {
			$vars = '[扱插]';
		} elsif ($ch eq '扳') {
			$vars = '[扳攀]';
		} elsif ($ch eq '扺') {
			$vars = '[扺抵]';
		} elsif ($ch eq '扼') {
			$vars = '[扼搤]';
		} elsif ($ch eq '抃') {
			$vars = '[抃拚]';
		} elsif ($ch eq '抉') {
			$vars = '[抉刔]';
		} elsif ($ch eq '抌') {
			$vars = '[抌舀]';
		} elsif ($ch eq '折') {
			$vars = '[折翼]';
		} elsif ($ch eq '抚') {
			$vars = '[抚撫]';
		} elsif ($ch eq '抛') {
			$vars = '[抛拋]';
		} elsif ($ch eq '抜') {
			$vars = '[抜拔]';
		} elsif ($ch eq '択') {
			$vars = '[択擇]';
		} elsif ($ch eq '抟') {
			$vars = '[抟摶]';
		} elsif ($ch eq '抠') {
			$vars = '[抠摳]';
		} elsif ($ch eq '抡') {
			$vars = '[抡掄]';
		} elsif ($ch eq '抢') {
			$vars = '[抢搶]';
		} elsif ($ch eq '护') {
			$vars = '[护護]';
		} elsif ($ch eq '报') {
			$vars = '[报報]';
		} elsif ($ch eq '抬') {
			$vars = '[抬擡]';
		} elsif ($ch eq '抱') {
			$vars = '[抱抔]';
		} elsif ($ch eq '抵') {
			$vars = '[抵扺]';
		} elsif ($ch eq '抻') {
			$vars = '[抻伸]';
		} elsif ($ch eq '拂') {
			$vars = '[拂払]';
		} elsif ($ch eq '担') {
			$vars = '[担擔]';
		} elsif ($ch eq '拆') {
			$vars = '[拆責]';
		} elsif ($ch eq '拈') {
			$vars = '[拈敁]';
		} elsif ($ch eq '拉') {
			$vars = '[拉拉]';
		} elsif ($ch eq '拊') {
			$vars = '[拊撫]';
		} elsif ($ch eq '拋') {
			$vars = '[拋抛]';
		} elsif ($ch eq '拏') {
			$vars = '[拏拏挐拿]';
		} elsif ($ch eq '拓') {
			$vars = '[拓托拓]';
		} elsif ($ch eq '拔') {
			$vars = '[拔抜]';
		} elsif ($ch eq '拚') {
			$vars = '[拚帆抃]';
		} elsif ($ch eq '拜') {
			$vars = '[拜拝]';
		} elsif ($ch eq '拝') {
			$vars = '[拝拜]';
		} elsif ($ch eq '拟') {
			$vars = '[拟擬]';
		} elsif ($ch eq '拡') {
			$vars = '[拡擴]';
		} elsif ($ch eq '拢') {
			$vars = '[拢攏]';
		} elsif ($ch eq '拣') {
			$vars = '[拣揀]';
		} elsif ($ch eq '拥') {
			$vars = '[拥擁]';
		} elsif ($ch eq '拦') {
			$vars = '[拦攔]';
		} elsif ($ch eq '拧') {
			$vars = '[拧擰]';
		} elsif ($ch eq '拨') {
			$vars = '[拨撥]';
		} elsif ($ch eq '择') {
			$vars = '[择擇]';
		} elsif ($ch eq '拯') {
			$vars = '[拯基]';
		} elsif ($ch eq '拴') {
			$vars = '[拴揎]';
		} elsif ($ch eq '拼') {
			$vars = '[拼秉摒]';
		} elsif ($ch eq '拽') {
			$vars = '[拽曳]';
		} elsif ($ch eq '拾') {
			$vars = '[拾十]';
		} elsif ($ch eq '拿') {
			$vars = '[拿拏拏挐]';
		} elsif ($ch eq '挂') {
			$vars = '[挂掛]';
		} elsif ($ch eq '按') {
			$vars = '[按搵]';
		} elsif ($ch eq '挐') {
			$vars = '[挐拏拿]';
		} elsif ($ch eq '挙') {
			$vars = '[挙舉]';
		} elsif ($ch eq '挚') {
			$vars = '[挚摯]';
		} elsif ($ch eq '挛') {
			$vars = '[挛攣]';
		} elsif ($ch eq '挝') {
			$vars = '[挝撾]';
		} elsif ($ch eq '挞') {
			$vars = '[挞撻]';
		} elsif ($ch eq '挟') {
			$vars = '[挟挾]';
		} elsif ($ch eq '挠') {
			$vars = '[挠撓]';
		} elsif ($ch eq '挡') {
			$vars = '[挡擋]';
		} elsif ($ch eq '挢') {
			$vars = '[挢撟]';
		} elsif ($ch eq '挣') {
			$vars = '[挣掙]';
		} elsif ($ch eq '挤') {
			$vars = '[挤擠]';
		} elsif ($ch eq '挥') {
			$vars = '[挥揮]';
		} elsif ($ch eq '挫') {
			$vars = '[挫繲]';
		} elsif ($ch eq '挭') {
			$vars = '[挭鯁骾]';
		} elsif ($ch eq '挼') {
			$vars = '[挼捼]';
		} elsif ($ch eq '挽') {
			$vars = '[挽掇輓]';
		} elsif ($ch eq '挾') {
			$vars = '[挾挟]';
		} elsif ($ch eq '捆') {
			$vars = '[捆綑]';
		} elsif ($ch eq '捉') {
			$vars = '[捉杓]';
		} elsif ($ch eq '捌') {
			$vars = '[捌八]';
		} elsif ($ch eq '捍') {
			$vars = '[捍扞]';
		} elsif ($ch eq '捜') {
			$vars = '[捜搜]';
		} elsif ($ch eq '捞') {
			$vars = '[捞撈]';
		} elsif ($ch eq '损') {
			$vars = '[损損]';
		} elsif ($ch eq '捡') {
			$vars = '[捡撿]';
		} elsif ($ch eq '换') {
			$vars = '[换換]';
		} elsif ($ch eq '捣') {
			$vars = '[捣搗]';
		} elsif ($ch eq '捨') {
			$vars = '[捨舍]';
		} elsif ($ch eq '捫') {
			$vars = '[捫扪]';
		} elsif ($ch eq '据') {
			$vars = '[据據]';
		} elsif ($ch eq '捲') {
			$vars = '[捲卷]';
		} elsif ($ch eq '捶') {
			$vars = '[捶搥箠]';
		} elsif ($ch eq '捻') {
			$vars = '[捻捻]';
		} elsif ($ch eq '捼') {
			$vars = '[捼挼]';
		} elsif ($ch eq '掂') {
			$vars = '[掂敁]';
		} elsif ($ch eq '掃') {
			$vars = '[掃扫埽]';
		} elsif ($ch eq '掄') {
			$vars = '[掄抡]';
		} elsif ($ch eq '掇') {
			$vars = '[掇挽]';
		} elsif ($ch eq '掉') {
			$vars = '[掉棹]';
		} elsif ($ch eq '掏') {
			$vars = '[掏搯]';
		} elsif ($ch eq '掘') {
			$vars = '[掘撅]';
		} elsif ($ch eq '掙') {
			$vars = '[掙挣]';
		} elsif ($ch eq '掛') {
			$vars = '[掛挂]';
		} elsif ($ch eq '掠') {
			$vars = '[掠掠]';
		} elsif ($ch eq '採') {
			$vars = '[採采]';
		} elsif ($ch eq '掩') {
			$vars = '[掩揞揜]';
		} elsif ($ch eq '掬') {
			$vars = '[掬匊]';
		} elsif ($ch eq '掲') {
			$vars = '[掲揭]';
		} elsif ($ch eq '掳') {
			$vars = '[掳擄]';
		} elsif ($ch eq '掴') {
			$vars = '[掴摑]';
		} elsif ($ch eq '掷') {
			$vars = '[掷擲]';
		} elsif ($ch eq '掸') {
			$vars = '[掸撣]';
		} elsif ($ch eq '掺') {
			$vars = '[掺摻]';
		} elsif ($ch eq '掻') {
			$vars = '[掻搔]';
		} elsif ($ch eq '掼') {
			$vars = '[掼摜]';
		} elsif ($ch eq '掽') {
			$vars = '[掽碰]';
		} elsif ($ch eq '揀') {
			$vars = '[揀拣]';
		} elsif ($ch eq '揅') {
			$vars = '[揅研]';
		} elsif ($ch eq '揎') {
			$vars = '[揎拴]';
		} elsif ($ch eq '插') {
			$vars = '[插扱]';
		} elsif ($ch eq '揚') {
			$vars = '[揚扬]';
		} elsif ($ch eq '換') {
			$vars = '[換换]';
		} elsif ($ch eq '揜') {
			$vars = '[揜掩]';
		} elsif ($ch eq '揝') {
			$vars = '[揝攢]';
		} elsif ($ch eq '揞') {
			$vars = '[揞掩]';
		} elsif ($ch eq '揪') {
			$vars = '[揪揫]';
		} elsif ($ch eq '揫') {
			$vars = '[揫揪]';
		} elsif ($ch eq '揭') {
			$vars = '[揭掲結]';
		} elsif ($ch eq '揮') {
			$vars = '[揮挥]';
		} elsif ($ch eq '揷') {
			$vars = '[揷插]';
		} elsif ($ch eq '揸') {
			$vars = '[揸楂]';
		} elsif ($ch eq '揺') {
			$vars = '[揺搖]';
		} elsif ($ch eq '揽') {
			$vars = '[揽攬]';
		} elsif ($ch eq '揿') {
			$vars = '[揿撳]';
		} elsif ($ch eq '搀') {
			$vars = '[搀攙]';
		} elsif ($ch eq '搁') {
			$vars = '[搁擱]';
		} elsif ($ch eq '搂') {
			$vars = '[搂摟]';
		} elsif ($ch eq '搅') {
			$vars = '[搅攪]';
		} elsif ($ch eq '搆') {
			$vars = '[搆構]';
		} elsif ($ch eq '損') {
			$vars = '[損损]';
		} elsif ($ch eq '搔') {
			$vars = '[搔掻]';
		} elsif ($ch eq '搖') {
			$vars = '[搖摇揺]';
		} elsif ($ch eq '搗') {
			$vars = '[搗擣捣]';
		} elsif ($ch eq '搜') {
			$vars = '[搜捜]';
		} elsif ($ch eq '搞') {
			$vars = '[搞攪]';
		} elsif ($ch eq '搤') {
			$vars = '[搤扼]';
		} elsif ($ch eq '搥') {
			$vars = '[搥捶]';
		} elsif ($ch eq '搧') {
			$vars = '[搧煽]';
		} elsif ($ch eq '搨') {
			$vars = '[搨搭]';
		} elsif ($ch eq '搫') {
			$vars = '[搫搬]';
		} elsif ($ch eq '搬') {
			$vars = '[搬搫]';
		} elsif ($ch eq '搭') {
			$vars = '[搭搨撘]';
		} elsif ($ch eq '搯') {
			$vars = '[搯掏]';
		} elsif ($ch eq '搵') {
			$vars = '[搵按]';
		} elsif ($ch eq '搶') {
			$vars = '[搶抢]';
		} elsif ($ch eq '携') {
			$vars = '[携攜]';
		} elsif ($ch eq '摁') {
			$vars = '[摁恩]';
		} elsif ($ch eq '摂') {
			$vars = '[摂攝]';
		} elsif ($ch eq '摃') {
			$vars = '[摃扛]';
		} elsif ($ch eq '摄') {
			$vars = '[摄攝]';
		} elsif ($ch eq '摅') {
			$vars = '[摅攄]';
		} elsif ($ch eq '摆') {
			$vars = '[摆擺]';
		} elsif ($ch eq '摇') {
			$vars = '[摇搖]';
		} elsif ($ch eq '摈') {
			$vars = '[摈擯]';
		} elsif ($ch eq '摊') {
			$vars = '[摊攤]';
		} elsif ($ch eq '摑') {
			$vars = '[摑掴]';
		} elsif ($ch eq '摒') {
			$vars = '[摒屏拼]';
		} elsif ($ch eq '摔') {
			$vars = '[摔甩]';
		} elsif ($ch eq '摜') {
			$vars = '[摜掼]';
		} elsif ($ch eq '摟') {
			$vars = '[摟搂]';
		} elsif ($ch eq '摠') {
			$vars = '[摠總]';
		} elsif ($ch eq '摡') {
			$vars = '[摡溉]';
		} elsif ($ch eq '摭') {
			$vars = '[摭拓]';
		} elsif ($ch eq '摯') {
			$vars = '[摯挚]';
		} elsif ($ch eq '摳') {
			$vars = '[摳抠]';
		} elsif ($ch eq '摴') {
			$vars = '[摴舒]';
		} elsif ($ch eq '摶') {
			$vars = '[摶抟]';
		} elsif ($ch eq '摻') {
			$vars = '[摻掺]';
		} elsif ($ch eq '撃') {
			$vars = '[撃擊]';
		} elsif ($ch eq '撄') {
			$vars = '[撄攖]';
		} elsif ($ch eq '撅') {
			$vars = '[撅掘]';
		} elsif ($ch eq '撈') {
			$vars = '[撈捞]';
		} elsif ($ch eq '撐') {
			$vars = '[撐撑]';
		} elsif ($ch eq '撑') {
			$vars = '[撑撐]';
		} elsif ($ch eq '撓') {
			$vars = '[撓挠]';
		} elsif ($ch eq '撘') {
			$vars = '[撘搭]';
		} elsif ($ch eq '撚') {
			$vars = '[撚撚]';
		} elsif ($ch eq '撟') {
			$vars = '[撟嬌挢]';
		} elsif ($ch eq '撢') {
			$vars = '[撢撣]';
		} elsif ($ch eq '撣') {
			$vars = '[撣撢掸]';
		} elsif ($ch eq '撥') {
			$vars = '[撥拨]';
		} elsif ($ch eq '撦') {
			$vars = '[撦扯]';
		} elsif ($ch eq '撫') {
			$vars = '[撫拊抚]';
		} elsif ($ch eq '撲') {
			$vars = '[撲攴扑]';
		} elsif ($ch eq '撳') {
			$vars = '[撳揿]';
		} elsif ($ch eq '撵') {
			$vars = '[撵攆]';
		} elsif ($ch eq '撷') {
			$vars = '[撷擷]';
		} elsif ($ch eq '撸') {
			$vars = '[撸擼]';
		} elsif ($ch eq '撹') {
			$vars = '[撹攪]';
		} elsif ($ch eq '撺') {
			$vars = '[撺攛]';
		} elsif ($ch eq '撻') {
			$vars = '[撻挞]';
		} elsif ($ch eq '撾') {
			$vars = '[撾挝]';
		} elsif ($ch eq '撿') {
			$vars = '[撿捡]';
		} elsif ($ch eq '擀') {
			$vars = '[擀扞]';
		} elsif ($ch eq '擁') {
			$vars = '[擁拥]';
		} elsif ($ch eq '擃') {
			$vars = '[擃攮]';
		} elsif ($ch eq '擄') {
			$vars = '[擄擄掳虜]';
		} elsif ($ch eq '擇') {
			$vars = '[擇择択]';
		} elsif ($ch eq '擊') {
			$vars = '[擊击撃]';
		} elsif ($ch eq '擋') {
			$vars = '[擋攩挡]';
		} elsif ($ch eq '擔') {
			$vars = '[擔担]';
		} elsif ($ch eq '擗') {
			$vars = '[擗劈]';
		} elsif ($ch eq '據') {
			$vars = '[據拠据]';
		} elsif ($ch eq '擞') {
			$vars = '[擞擻]';
		} elsif ($ch eq '擠') {
			$vars = '[擠挤]';
		} elsif ($ch eq '擡') {
			$vars = '[擡抬]';
		} elsif ($ch eq '擣') {
			$vars = '[擣搗]';
		} elsif ($ch eq '擥') {
			$vars = '[擥攬]';
		} elsif ($ch eq '擧') {
			$vars = '[擧舉]';
		} elsif ($ch eq '擬') {
			$vars = '[擬拟儗]';
		} elsif ($ch eq '擯') {
			$vars = '[擯摈]';
		} elsif ($ch eq '擰') {
			$vars = '[擰拧]';
		} elsif ($ch eq '擱') {
			$vars = '[擱搁]';
		} elsif ($ch eq '擲') {
			$vars = '[擲擿掷]';
		} elsif ($ch eq '擴') {
			$vars = '[擴扩]';
		} elsif ($ch eq '擷') {
			$vars = '[擷撷]';
		} elsif ($ch eq '擺') {
			$vars = '[擺摆]';
		} elsif ($ch eq '擻') {
			$vars = '[擻擞]';
		} elsif ($ch eq '擼') {
			$vars = '[擼撸]';
		} elsif ($ch eq '擾') {
			$vars = '[擾扰]';
		} elsif ($ch eq '擿') {
			$vars = '[擿擲]';
		} elsif ($ch eq '攀') {
			$vars = '[攀扳]';
		} elsif ($ch eq '攄') {
			$vars = '[攄摅]';
		} elsif ($ch eq '攅') {
			$vars = '[攅攢]';
		} elsif ($ch eq '攆') {
			$vars = '[攆撵]';
		} elsif ($ch eq '攏') {
			$vars = '[攏拢]';
		} elsif ($ch eq '攒') {
			$vars = '[攒攢]';
		} elsif ($ch eq '攔') {
			$vars = '[攔拦]';
		} elsif ($ch eq '攖') {
			$vars = '[攖撄]';
		} elsif ($ch eq '攙') {
			$vars = '[攙搀]';
		} elsif ($ch eq '攛') {
			$vars = '[攛撺]';
		} elsif ($ch eq '攜') {
			$vars = '[攜携]';
		} elsif ($ch eq '攝') {
			$vars = '[攝摂摄]';
		} elsif ($ch eq '攢') {
			$vars = '[攢揝攒攅]';
		} elsif ($ch eq '攣') {
			$vars = '[攣挛]';
		} elsif ($ch eq '攤') {
			$vars = '[攤摊]';
		} elsif ($ch eq '攩') {
			$vars = '[攩擋]';
		} elsif ($ch eq '攪') {
			$vars = '[攪搅搞]';
		} elsif ($ch eq '攬') {
			$vars = '[攬擥揽]';
		} elsif ($ch eq '攮') {
			$vars = '[攮擃]';
		} elsif ($ch eq '攴') {
			$vars = '[攴攵撲]';
		} elsif ($ch eq '攵') {
			$vars = '[攵攴夊]';
		} elsif ($ch eq '收') {
			$vars = '[收収]';
		} elsif ($ch eq '攷') {
			$vars = '[攷考]';
		} elsif ($ch eq '敁') {
			$vars = '[敁掂拈]';
		} elsif ($ch eq '敃') {
			$vars = '[敃暋]';
		} elsif ($ch eq '效') {
			$vars = '[效効]';
		} elsif ($ch eq '敌') {
			$vars = '[敌敵]';
		} elsif ($ch eq '敍') {
			$vars = '[敍敘叙]';
		} elsif ($ch eq '敎') {
			$vars = '[敎教]';
		} elsif ($ch eq '敕') {
			$vars = '[敕勅]';
		} elsif ($ch eq '敗') {
			$vars = '[敗败]';
		} elsif ($ch eq '敘') {
			$vars = '[敘叙敍]';
		} elsif ($ch eq '教') {
			$vars = '[教敎]';
		} elsif ($ch eq '敛') {
			$vars = '[敛斂]';
		} elsif ($ch eq '敦') {
			$vars = '[敦惇]';
		} elsif ($ch eq '数') {
			$vars = '[数數]';
		} elsif ($ch eq '敵') {
			$vars = '[敵敌]';
		} elsif ($ch eq '敷') {
			$vars = '[敷尃]';
		} elsif ($ch eq '數') {
			$vars = '[數数]';
		} elsif ($ch eq '敺') {
			$vars = '[敺驅]';
		} elsif ($ch eq '敻') {
			$vars = '[敻夐]';
		} elsif ($ch eq '斂') {
			$vars = '[斂敛]';
		} elsif ($ch eq '斃') {
			$vars = '[斃毙]';
		} elsif ($ch eq '文') {
			$vars = '[文穩]';
		} elsif ($ch eq '斈') {
			$vars = '[斈學]';
		} elsif ($ch eq '斉') {
			$vars = '[斉齊]';
		} elsif ($ch eq '斋') {
			$vars = '[斋齋齊]';
		} elsif ($ch eq '斌') {
			$vars = '[斌彬]';
		} elsif ($ch eq '斎') {
			$vars = '[斎齋]';
		} elsif ($ch eq '斓') {
			$vars = '[斓斕]';
		} elsif ($ch eq '斕') {
			$vars = '[斕斓]';
		} elsif ($ch eq '斗') {
			$vars = '[斗鬥]';
		} elsif ($ch eq '斝') {
			$vars = '[斝檟]';
		} elsif ($ch eq '斞') {
			$vars = '[斞庾]';
		} elsif ($ch eq '斤') {
			$vars = '[斤觔]';
		} elsif ($ch eq '斩') {
			$vars = '[斩斬]';
		} elsif ($ch eq '斬') {
			$vars = '[斬斩]';
		} elsif ($ch eq '断') {
			$vars = '[断斷]';
		} elsif ($ch eq '斷') {
			$vars = '[斷断]';
		} elsif ($ch eq '於') {
			$vars = '[於亏于]';
		} elsif ($ch eq '旁') {
			$vars = '[旁傍]';
		} elsif ($ch eq '旂') {
			$vars = '[旂旗]';
		} elsif ($ch eq '旅') {
			$vars = '[旅旅]';
		} elsif ($ch eq '旗') {
			$vars = '[旗旂]';
		} elsif ($ch eq '旛') {
			$vars = '[旛幡]';
		} elsif ($ch eq '无') {
			$vars = '[无無]';
		} elsif ($ch eq '既') {
			$vars = '[既旣]';
		} elsif ($ch eq '旦') {
			$vars = '[旦蛋]';
		} elsif ($ch eq '旧') {
			$vars = '[旧舊]';
		} elsif ($ch eq '旭') {
			$vars = '[旭旯]';
		} elsif ($ch eq '旮') {
			$vars = '[旮旭]';
		} elsif ($ch eq '旯') {
			$vars = '[旯旭]';
		} elsif ($ch eq '时') {
			$vars = '[时時]';
		} elsif ($ch eq '旷') {
			$vars = '[旷曠]';
		} elsif ($ch eq '昂') {
			$vars = '[昂昻]';
		} elsif ($ch eq '昇') {
			$vars = '[昇升]';
		} elsif ($ch eq '易') {
			$vars = '[易易]';
		} elsif ($ch eq '昙') {
			$vars = '[昙曇]';
		} elsif ($ch eq '昜') {
			$vars = '[昜陽]';
		} elsif ($ch eq '昝') {
			$vars = '[昝偺喒]';
		} elsif ($ch eq '映') {
			$vars = '[映暎]';
		} elsif ($ch eq '是') {
			$vars = '[是昰]';
		} elsif ($ch eq '昰') {
			$vars = '[昰是]';
		} elsif ($ch eq '昵') {
			$vars = '[昵暱]';
		} elsif ($ch eq '昶') {
			$vars = '[昶暢]';
		} elsif ($ch eq '昻') {
			$vars = '[昻昂]';
		} elsif ($ch eq '昼') {
			$vars = '[昼晝]';
		} elsif ($ch eq '显') {
			$vars = '[显顯]';
		} elsif ($ch eq '昿') {
			$vars = '[昿曠]';
		} elsif ($ch eq '晁') {
			$vars = '[晁朝]';
		} elsif ($ch eq '時') {
			$vars = '[時时]';
		} elsif ($ch eq '晃') {
			$vars = '[晃晄]';
		} elsif ($ch eq '晄') {
			$vars = '[晄晃]';
		} elsif ($ch eq '晅') {
			$vars = '[晅烜]';
		} elsif ($ch eq '晉') {
			$vars = '[晉晋]';
		} elsif ($ch eq '晋') {
			$vars = '[晋晉]';
		} elsif ($ch eq '晒') {
			$vars = '[晒曬]';
		} elsif ($ch eq '晓') {
			$vars = '[晓曉]';
		} elsif ($ch eq '晔') {
			$vars = '[晔曄]';
		} elsif ($ch eq '晕') {
			$vars = '[晕暈]';
		} elsif ($ch eq '晖') {
			$vars = '[晖暉]';
		} elsif ($ch eq '晚') {
			$vars = '[晚晩]';
		} elsif ($ch eq '晝') {
			$vars = '[晝昼]';
		} elsif ($ch eq '晢') {
			$vars = '[晢晰]';
		} elsif ($ch eq '晩') {
			$vars = '[晩晚]';
		} elsif ($ch eq '晰') {
			$vars = '[晰晳晢]';
		} elsif ($ch eq '晳') {
			$vars = '[晳晰]';
		} elsif ($ch eq '暁') {
			$vars = '[暁曉]';
		} elsif ($ch eq '暂') {
			$vars = '[暂暫]';
		} elsif ($ch eq '暈') {
			$vars = '[暈晕]';
		} elsif ($ch eq '暉') {
			$vars = '[暉晖]';
		} elsif ($ch eq '暋') {
			$vars = '[暋忞敃]';
		} elsif ($ch eq '暎') {
			$vars = '[暎映]';
		} elsif ($ch eq '暖') {
			$vars = '[暖煖娠]';
		} elsif ($ch eq '暗') {
			$vars = '[暗晻]';
		} elsif ($ch eq '暠') {
			$vars = '[暠皜]';
		} elsif ($ch eq '暢') {
			$vars = '[暢畅]';
		} elsif ($ch eq '暦') {
			$vars = '[暦曆]';
		} elsif ($ch eq '暧') {
			$vars = '[暧曖]';
		} elsif ($ch eq '暨') {
			$vars = '[暨曁]';
		} elsif ($ch eq '暫') {
			$vars = '[暫暂]';
		} elsif ($ch eq '暱') {
			$vars = '[暱昵]';
		} elsif ($ch eq '暴') {
			$vars = '[暴暴虣]';
		} elsif ($ch eq '暸') {
			$vars = '[暸瞭]';
		} elsif ($ch eq '曄') {
			$vars = '[曄晔]';
		} elsif ($ch eq '曆') {
			$vars = '[曆歴厤历歷]';
		} elsif ($ch eq '曇') {
			$vars = '[曇昙]';
		} elsif ($ch eq '曉') {
			$vars = '[曉暁晓]';
		} elsif ($ch eq '曏') {
			$vars = '[曏向]';
		} elsif ($ch eq '曖') {
			$vars = '[曖暧瞹]';
		} elsif ($ch eq '曜') {
			$vars = '[曜燿耀]';
		} elsif ($ch eq '曠') {
			$vars = '[曠旷昿]';
		} elsif ($ch eq '曬') {
			$vars = '[曬晒]';
		} elsif ($ch eq '曳') {
			$vars = '[曳曵拽]';
		} elsif ($ch eq '更') {
			$vars = '[更更]';
		} elsif ($ch eq '曵') {
			$vars = '[曵曳]';
		} elsif ($ch eq '書') {
			$vars = '[書书]';
		} elsif ($ch eq '曹') {
			$vars = '[曹曺]';
		} elsif ($ch eq '曽') {
			$vars = '[曽曾]';
		} elsif ($ch eq '曾') {
			$vars = '[曾曽]';
		} elsif ($ch eq '會') {
			$vars = '[會会]';
		} elsif ($ch eq '朐') {
			$vars = '[朐胊鴝]';
		} elsif ($ch eq '朖') {
			$vars = '[朖朗]';
		} elsif ($ch eq '朗') {
			$vars = '[朗朗]';
		} elsif ($ch eq '望') {
			$vars = '[望朢]';
		} elsif ($ch eq '朝') {
			$vars = '[朝晁]';
		} elsif ($ch eq '朞') {
			$vars = '[朞稘期]';
		} elsif ($ch eq '期') {
			$vars = '[期逞朞]';
		} elsif ($ch eq '朢') {
			$vars = '[朢望]';
		} elsif ($ch eq '朦') {
			$vars = '[朦蒙矇]';
		} elsif ($ch eq '朧') {
			$vars = '[朧胧矓]';
		} elsif ($ch eq '本') {
			$vars = '[本夲]';
		} elsif ($ch eq '札') {
			$vars = '[札箚]';
		} elsif ($ch eq '术') {
			$vars = '[术術]';
		} elsif ($ch eq '朳') {
			$vars = '[朳杷]';
		} elsif ($ch eq '朴') {
			$vars = '[朴樸]';
		} elsif ($ch eq '朵') {
			$vars = '[朵朶]';
		} elsif ($ch eq '朶') {
			$vars = '[朶朵]';
		} elsif ($ch eq '朸') {
			$vars = '[朸扐]';
		} elsif ($ch eq '机') {
			$vars = '[机機]';
		} elsif ($ch eq '朿') {
			$vars = '[朿莿]';
		} elsif ($ch eq '杀') {
			$vars = '[杀殺]';
		} elsif ($ch eq '杂') {
			$vars = '[杂雜]';
		} elsif ($ch eq '权') {
			$vars = '[权權]';
		} elsif ($ch eq '杆') {
			$vars = '[杆桿]';
		} elsif ($ch eq '杇') {
			$vars = '[杇圬]';
		} elsif ($ch eq '李') {
			$vars = '[李李]';
		} elsif ($ch eq '村') {
			$vars = '[村邨]';
		} elsif ($ch eq '杓') {
			$vars = '[杓捉]';
		} elsif ($ch eq '杝') {
			$vars = '[杝柂]';
		} elsif ($ch eq '杠') {
			$vars = '[杠槓]';
		} elsif ($ch eq '条') {
			$vars = '[条條]';
		} elsif ($ch eq '来') {
			$vars = '[来來]';
		} elsif ($ch eq '杨') {
			$vars = '[杨楊]';
		} elsif ($ch eq '杩') {
			$vars = '[杩榪]';
		} elsif ($ch eq '杯') {
			$vars = '[杯盃]';
		} elsif ($ch eq '杰') {
			$vars = '[杰傑]';
		} elsif ($ch eq '東') {
			$vars = '[東东]';
		} elsif ($ch eq '杴') {
			$vars = '[杴锨]';
		} elsif ($ch eq '杷') {
			$vars = '[杷朳]';
		} elsif ($ch eq '杸') {
			$vars = '[杸殳]';
		} elsif ($ch eq '松') {
			$vars = '[松枩鬆]';
		} elsif ($ch eq '板') {
			$vars = '[板版闆]';
		} elsif ($ch eq '极') {
			$vars = '[极極]';
		} elsif ($ch eq '构') {
			$vars = '[构構]';
		} elsif ($ch eq '枏') {
			$vars = '[枏楠]';
		} elsif ($ch eq '林') {
			$vars = '[林林]';
		} elsif ($ch eq '果') {
			$vars = '[果菓]';
		} elsif ($ch eq '枞') {
			$vars = '[枞樅]';
		} elsif ($ch eq '枢') {
			$vars = '[枢樞]';
		} elsif ($ch eq '枣') {
			$vars = '[枣棗]';
		} elsif ($ch eq '枥') {
			$vars = '[枥櫪]';
		} elsif ($ch eq '枨') {
			$vars = '[枨棖]';
		} elsif ($ch eq '枩') {
			$vars = '[枩松]';
		} elsif ($ch eq '枪') {
			$vars = '[枪槍]';
		} elsif ($ch eq '枫') {
			$vars = '[枫楓]';
		} elsif ($ch eq '枭') {
			$vars = '[枭梟]';
		} elsif ($ch eq '枴') {
			$vars = '[枴拐]';
		} elsif ($ch eq '枾') {
			$vars = '[枾柿]';
		} elsif ($ch eq '柁') {
			$vars = '[柁舵]';
		} elsif ($ch eq '柂') {
			$vars = '[柂杝]';
		} elsif ($ch eq '柄') {
			$vars = '[柄棅]';
		} elsif ($ch eq '柆') {
			$vars = '[柆拉]';
		} elsif ($ch eq '柏') {
			$vars = '[柏孛栢]';
		} elsif ($ch eq '某') {
			$vars = '[某厶]';
		} elsif ($ch eq '柒') {
			$vars = '[柒七漆]';
		} elsif ($ch eq '柜') {
			$vars = '[柜櫃]';
		} elsif ($ch eq '柠') {
			$vars = '[柠檸]';
		} elsif ($ch eq '查') {
			$vars = '[查査]';
		} elsif ($ch eq '柩') {
			$vars = '[柩柾]';
		} elsif ($ch eq '柰') {
			$vars = '[柰奈]';
		} elsif ($ch eq '柳') {
			$vars = '[柳檉]';
		} elsif ($ch eq '柴') {
			$vars = '[柴茈]';
		} elsif ($ch eq '柵') {
			$vars = '[柵栅]';
		} elsif ($ch eq '査') {
			$vars = '[査查]';
		} elsif ($ch eq '柽') {
			$vars = '[柽檉]';
		} elsif ($ch eq '柾') {
			$vars = '[柾柩]';
		} elsif ($ch eq '柿') {
			$vars = '[柿枾]';
		} elsif ($ch eq '栀') {
			$vars = '[栀梔]';
		} elsif ($ch eq '栄') {
			$vars = '[栄榮]';
		} elsif ($ch eq '栅') {
			$vars = '[栅柵]';
		} elsif ($ch eq '标') {
			$vars = '[标標檁]';
		} elsif ($ch eq '栈') {
			$vars = '[栈棧]';
		} elsif ($ch eq '栉') {
			$vars = '[栉櫛]';
		} elsif ($ch eq '栊') {
			$vars = '[栊櫳]';
		} elsif ($ch eq '栋') {
			$vars = '[栋棟]';
		} elsif ($ch eq '栌') {
			$vars = '[栌櫨]';
		} elsif ($ch eq '栎') {
			$vars = '[栎櫟]';
		} elsif ($ch eq '栏') {
			$vars = '[栏欄]';
		} elsif ($ch eq '树') {
			$vars = '[树樹]';
		} elsif ($ch eq '栒') {
			$vars = '[栒簨]';
		} elsif ($ch eq '栖') {
			$vars = '[栖棲]';
		} elsif ($ch eq '栗') {
			$vars = '[栗慄慄]';
		} elsif ($ch eq '栝') {
			$vars = '[栝檜]';
		} elsif ($ch eq '栢') {
			$vars = '[栢孛柏]';
		} elsif ($ch eq '样') {
			$vars = '[样樣]';
		} elsif ($ch eq '核') {
			$vars = '[核覈]';
		} elsif ($ch eq '栾') {
			$vars = '[栾欒]';
		} elsif ($ch eq '桁') {
			$vars = '[桁航]';
		} elsif ($ch eq '桌') {
			$vars = '[桌棹]';
		} elsif ($ch eq '桜') {
			$vars = '[桜櫻]';
		} elsif ($ch eq '桟') {
			$vars = '[桟棧]';
		} elsif ($ch eq '桠') {
			$vars = '[桠椏]';
		} elsif ($ch eq '桡') {
			$vars = '[桡橈]';
		} elsif ($ch eq '桢') {
			$vars = '[桢楨]';
		} elsif ($ch eq '档') {
			$vars = '[档檔]';
		} elsif ($ch eq '桤') {
			$vars = '[桤榿]';
		} elsif ($ch eq '桥') {
			$vars = '[桥橋]';
		} elsif ($ch eq '桦') {
			$vars = '[桦樺]';
		} elsif ($ch eq '桧') {
			$vars = '[桧檜]';
		} elsif ($ch eq '桨') {
			$vars = '[桨槳]';
		} elsif ($ch eq '桩') {
			$vars = '[桩樁]';
		} elsif ($ch eq '桮') {
			$vars = '[桮杯]';
		} elsif ($ch eq '桼') {
			$vars = '[桼漆]';
		} elsif ($ch eq '桿') {
			$vars = '[桿杆]';
		} elsif ($ch eq '梁') {
			$vars = '[梁樑梁]';
		} elsif ($ch eq '梅') {
			$vars = '[梅楳]';
		} elsif ($ch eq '梔') {
			$vars = '[梔栀]';
		} elsif ($ch eq '條') {
			$vars = '[條糶条]';
		} elsif ($ch eq '梟') {
			$vars = '[梟鴞枭]';
		} elsif ($ch eq '梦') {
			$vars = '[梦夢]';
		} elsif ($ch eq '梨') {
			$vars = '[梨梨]';
		} elsif ($ch eq '梲') {
			$vars = '[梲棳]';
		} elsif ($ch eq '梹') {
			$vars = '[梹檳]';
		} elsif ($ch eq '梼') {
			$vars = '[梼檮]';
		} elsif ($ch eq '检') {
			$vars = '[检檢]';
		} elsif ($ch eq '棂') {
			$vars = '[棂欞]';
		} elsif ($ch eq '棄') {
			$vars = '[棄弃]';
		} elsif ($ch eq '棅') {
			$vars = '[棅柄]';
		} elsif ($ch eq '棊') {
			$vars = '[棊棋碁]';
		} elsif ($ch eq '棋') {
			$vars = '[棋棊碁]';
		} elsif ($ch eq '棐') {
			$vars = '[棐榧]';
		} elsif ($ch eq '棕') {
			$vars = '[棕椶]';
		} elsif ($ch eq '棖') {
			$vars = '[棖枨]';
		} elsif ($ch eq '棗') {
			$vars = '[棗枣]';
		} elsif ($ch eq '棟') {
			$vars = '[棟栋]';
		} elsif ($ch eq '棧') {
			$vars = '[棧栈桟]';
		} elsif ($ch eq '棰') {
			$vars = '[棰槌]';
		} elsif ($ch eq '棱') {
			$vars = '[棱楞稜]';
		} elsif ($ch eq '棲') {
			$vars = '[棲栖]';
		} elsif ($ch eq '棳') {
			$vars = '[棳梲]';
		} elsif ($ch eq '棹') {
			$vars = '[棹桌卓櫂]';
		} elsif ($ch eq '椀') {
			$vars = '[椀碗]';
		} elsif ($ch eq '椁') {
			$vars = '[椁槨]';
		} elsif ($ch eq '椎') {
			$vars = '[椎槌]';
		} elsif ($ch eq '椏') {
			$vars = '[椏桠]';
		} elsif ($ch eq '椒') {
			$vars = '[椒茭]';
		} elsif ($ch eq '検') {
			$vars = '[検檢]';
		} elsif ($ch eq '椟') {
			$vars = '[椟櫝]';
		} elsif ($ch eq '椠') {
			$vars = '[椠槧]';
		} elsif ($ch eq '椤') {
			$vars = '[椤欏]';
		} elsif ($ch eq '椭') {
			$vars = '[椭橢]';
		} elsif ($ch eq '椶') {
			$vars = '[椶棕]';
		} elsif ($ch eq '椹') {
			$vars = '[椹葚]';
		} elsif ($ch eq '楂') {
			$vars = '[楂槎查揸]';
		} elsif ($ch eq '楊') {
			$vars = '[楊杨]';
		} elsif ($ch eq '楓') {
			$vars = '[楓枫]';
		} elsif ($ch eq '楕') {
			$vars = '[楕橢]';
		} elsif ($ch eq '楙') {
			$vars = '[楙茂]';
		} elsif ($ch eq '楜') {
			$vars = '[楜胡]';
		} elsif ($ch eq '楞') {
			$vars = '[楞棱稜]';
		} elsif ($ch eq '楠') {
			$vars = '[楠枏]';
		} elsif ($ch eq '楡') {
			$vars = '[楡榆]';
		} elsif ($ch eq '楥') {
			$vars = '[楥楦]';
		} elsif ($ch eq '楦') {
			$vars = '[楦楥]';
		} elsif ($ch eq '楨') {
			$vars = '[楨桢]';
		} elsif ($ch eq '業') {
			$vars = '[業业]';
		} elsif ($ch eq '楳') {
			$vars = '[楳梅]';
		} elsif ($ch eq '極') {
			$vars = '[極极]';
		} elsif ($ch eq '楼') {
			$vars = '[楼樓]';
		} elsif ($ch eq '楽') {
			$vars = '[楽樂]';
		} elsif ($ch eq '概') {
			$vars = '[概槪]';
		} elsif ($ch eq '榄') {
			$vars = '[榄欖]';
		} elsif ($ch eq '榆') {
			$vars = '[榆楡]';
		} elsif ($ch eq '榇') {
			$vars = '[榇櫬]';
		} elsif ($ch eq '榈') {
			$vars = '[榈櫚]';
		} elsif ($ch eq '榉') {
			$vars = '[榉櫸]';
		} elsif ($ch eq '榎') {
			$vars = '[榎檟]';
		} elsif ($ch eq '榘') {
			$vars = '[榘矩]';
		} elsif ($ch eq '榛') {
			$vars = '[榛亲]';
		} elsif ($ch eq '榦') {
			$vars = '[榦乾]';
		} elsif ($ch eq '榧') {
			$vars = '[榧棐]';
		} elsif ($ch eq '榨') {
			$vars = '[榨醡酢]';
		} elsif ($ch eq '榪') {
			$vars = '[榪杩]';
		} elsif ($ch eq '榮') {
			$vars = '[榮荣]';
		} elsif ($ch eq '榿') {
			$vars = '[榿桤]';
		} elsif ($ch eq '槇') {
			$vars = '[槇槙]';
		} elsif ($ch eq '槊') {
			$vars = '[槊鎙]';
		} elsif ($ch eq '構') {
			$vars = '[構构]';
		} elsif ($ch eq '槌') {
			$vars = '[槌椎棰]';
		} elsif ($ch eq '槍') {
			$vars = '[槍枪]';
		} elsif ($ch eq '槎') {
			$vars = '[槎楂]';
		} elsif ($ch eq '槓') {
			$vars = '[槓杠篢]';
		} elsif ($ch eq '様') {
			$vars = '[様樣]';
		} elsif ($ch eq '槙') {
			$vars = '[槙槇]';
		} elsif ($ch eq '槛') {
			$vars = '[槛檻]';
		} elsif ($ch eq '槟') {
			$vars = '[槟檳]';
		} elsif ($ch eq '槠') {
			$vars = '[槠櫧]';
		} elsif ($ch eq '槧') {
			$vars = '[槧椠]';
		} elsif ($ch eq '槨') {
			$vars = '[槨椁]';
		} elsif ($ch eq '槳') {
			$vars = '[槳桨]';
		} elsif ($ch eq '槻') {
			$vars = '[槻規]';
		} elsif ($ch eq '樁') {
			$vars = '[樁桩]';
		} elsif ($ch eq '樂') {
			$vars = '[樂樂乐]';
		} elsif ($ch eq '樅') {
			$vars = '[樅枞]';
		} elsif ($ch eq '樑') {
			$vars = '[樑梁]';
		} elsif ($ch eq '樓') {
			$vars = '[樓樓楼]';
		} elsif ($ch eq '標') {
			$vars = '[標标]';
		} elsif ($ch eq '樞') {
			$vars = '[樞枢]';
		} elsif ($ch eq '樣') {
			$vars = '[樣様样]';
		} elsif ($ch eq '権') {
			$vars = '[権權]';
		} elsif ($ch eq '横') {
			$vars = '[横橫]';
		} elsif ($ch eq '樯') {
			$vars = '[樯檣]';
		} elsif ($ch eq '樱') {
			$vars = '[樱櫻]';
		} elsif ($ch eq '樸') {
			$vars = '[樸朴]';
		} elsif ($ch eq '樹') {
			$vars = '[樹树]';
		} elsif ($ch eq '樺') {
			$vars = '[樺桦]';
		} elsif ($ch eq '樻') {
			$vars = '[樻匱櫃]';
		} elsif ($ch eq '樽') {
			$vars = '[樽墫]';
		} elsif ($ch eq '橆') {
			$vars = '[橆無]';
		} elsif ($ch eq '橇') {
			$vars = '[橇鞒]';
		} elsif ($ch eq '橈') {
			$vars = '[橈桡]';
		} elsif ($ch eq '橋') {
			$vars = '[橋桥]';
		} elsif ($ch eq '橓') {
			$vars = '[橓蕣]';
		} elsif ($ch eq '機') {
			$vars = '[機机]';
		} elsif ($ch eq '橢') {
			$vars = '[橢楕椭]';
		} elsif ($ch eq '橥') {
			$vars = '[橥櫫]';
		} elsif ($ch eq '橦') {
			$vars = '[橦幢]';
		} elsif ($ch eq '橫') {
			$vars = '[橫横]';
		} elsif ($ch eq '橱') {
			$vars = '[橱櫥]';
		} elsif ($ch eq '橹') {
			$vars = '[橹櫓]';
		} elsif ($ch eq '橼') {
			$vars = '[橼櫞]';
		} elsif ($ch eq '檁') {
			$vars = '[檁标檩]';
		} elsif ($ch eq '檉') {
			$vars = '[檉柳柽]';
		} elsif ($ch eq '檐') {
			$vars = '[檐簷]';
		} elsif ($ch eq '檔') {
			$vars = '[檔档欓]';
		} elsif ($ch eq '檛') {
			$vars = '[檛簻]';
		} elsif ($ch eq '檜') {
			$vars = '[檜栝桧]';
		} elsif ($ch eq '檟') {
			$vars = '[檟榎斝]';
		} elsif ($ch eq '檢') {
			$vars = '[檢検检]';
		} elsif ($ch eq '檣') {
			$vars = '[檣樯艢]';
		} elsif ($ch eq '檩') {
			$vars = '[檩檁]';
		} elsif ($ch eq '檮') {
			$vars = '[檮梼]';
		} elsif ($ch eq '檯') {
			$vars = '[檯台儓]';
		} elsif ($ch eq '檳') {
			$vars = '[檳槟梹]';
		} elsif ($ch eq '檴') {
			$vars = '[檴穫]';
		} elsif ($ch eq '檸') {
			$vars = '[檸柠]';
		} elsif ($ch eq '檻') {
			$vars = '[檻槛]';
		} elsif ($ch eq '櫂') {
			$vars = '[櫂棹掉]';
		} elsif ($ch eq '櫃') {
			$vars = '[櫃匱鐀樻饋柜]';
		} elsif ($ch eq '櫌') {
			$vars = '[櫌耰]';
		} elsif ($ch eq '櫓') {
			$vars = '[櫓櫓橹艪]';
		} elsif ($ch eq '櫚') {
			$vars = '[櫚榈]';
		} elsif ($ch eq '櫛') {
			$vars = '[櫛栉]';
		} elsif ($ch eq '櫝') {
			$vars = '[櫝椟]';
		} elsif ($ch eq '櫞') {
			$vars = '[櫞橼]';
		} elsif ($ch eq '櫟') {
			$vars = '[櫟栎]';
		} elsif ($ch eq '櫥') {
			$vars = '[櫥橱]';
		} elsif ($ch eq '櫧') {
			$vars = '[櫧槠]';
		} elsif ($ch eq '櫨') {
			$vars = '[櫨栌]';
		} elsif ($ch eq '櫪') {
			$vars = '[櫪枥]';
		} elsif ($ch eq '櫫') {
			$vars = '[櫫橥]';
		} elsif ($ch eq '櫬') {
			$vars = '[櫬榇]';
		} elsif ($ch eq '櫱') {
			$vars = '[櫱蘖]';
		} elsif ($ch eq '櫳') {
			$vars = '[櫳栊]';
		} elsif ($ch eq '櫸') {
			$vars = '[櫸榉]';
		} elsif ($ch eq '櫺') {
			$vars = '[櫺欞]';
		} elsif ($ch eq '櫻') {
			$vars = '[櫻樱]';
		} elsif ($ch eq '欄') {
			$vars = '[欄欄栏]';
		} elsif ($ch eq '權') {
			$vars = '[權権权]';
		} elsif ($ch eq '欏') {
			$vars = '[欏椤]';
		} elsif ($ch eq '欒') {
			$vars = '[欒灤栾]';
		} elsif ($ch eq '欓') {
			$vars = '[欓檔]';
		} elsif ($ch eq '欖') {
			$vars = '[欖榄]';
		} elsif ($ch eq '欝') {
			$vars = '[欝鬱]';
		} elsif ($ch eq '欞') {
			$vars = '[欞櫺棂]';
		} elsif ($ch eq '欠') {
			$vars = '[欠缺]';
		} elsif ($ch eq '欢') {
			$vars = '[欢懽歡]';
		} elsif ($ch eq '欣') {
			$vars = '[欣忻]';
		} elsif ($ch eq '欤') {
			$vars = '[欤歟]';
		} elsif ($ch eq '欧') {
			$vars = '[欧歐]';
		} elsif ($ch eq '欬') {
			$vars = '[欬咳]';
		} elsif ($ch eq '欲') {
			$vars = '[欲慾]';
		} elsif ($ch eq '欸') {
			$vars = '[欸唉]';
		} elsif ($ch eq '欹') {
			$vars = '[欹猗]';
		} elsif ($ch eq '欼') {
			$vars = '[欼啜歠]';
		} elsif ($ch eq '欽') {
			$vars = '[欽钦]';
		} elsif ($ch eq '歉') {
			$vars = '[歉欠]';
		} elsif ($ch eq '歌') {
			$vars = '[歌謌]';
		} elsif ($ch eq '歎') {
			$vars = '[歎嘆]';
		} elsif ($ch eq '歐') {
			$vars = '[歐欧]';
		} elsif ($ch eq '歓') {
			$vars = '[歓歡]';
		} elsif ($ch eq '歕') {
			$vars = '[歕呠噴]';
		} elsif ($ch eq '歛') {
			$vars = '[歛斂]';
		} elsif ($ch eq '歟') {
			$vars = '[歟欤]';
		} elsif ($ch eq '歠') {
			$vars = '[歠啜欼]';
		} elsif ($ch eq '歡') {
			$vars = '[歡懽欢驩]';
		} elsif ($ch eq '止') {
			$vars = '[止只]';
		} elsif ($ch eq '歧') {
			$vars = '[歧岐]';
		} elsif ($ch eq '歩') {
			$vars = '[歩步]';
		} elsif ($ch eq '歯') {
			$vars = '[歯齒]';
		} elsif ($ch eq '歲') {
			$vars = '[歲岁歳]';
		} elsif ($ch eq '歳') {
			$vars = '[歳歲]';
		} elsif ($ch eq '歴') {
			$vars = '[歴曆歷]';
		} elsif ($ch eq '歷') {
			$vars = '[歷歴曆历]';
		} elsif ($ch eq '歸') {
			$vars = '[歸归帰]';
		} elsif ($ch eq '歼') {
			$vars = '[歼殲]';
		} elsif ($ch eq '歿') {
			$vars = '[歿殁]';
		} elsif ($ch eq '殀') {
			$vars = '[殀夭]';
		} elsif ($ch eq '殁') {
			$vars = '[殁歿]';
		} elsif ($ch eq '殇') {
			$vars = '[殇殤]';
		} elsif ($ch eq '殉') {
			$vars = '[殉侚]';
		} elsif ($ch eq '残') {
			$vars = '[残殘]';
		} elsif ($ch eq '殍') {
			$vars = '[殍莩]';
		} elsif ($ch eq '殒') {
			$vars = '[殒殞隕]';
		} elsif ($ch eq '殓') {
			$vars = '[殓殮]';
		} elsif ($ch eq '殘') {
			$vars = '[殘残]';
		} elsif ($ch eq '殚') {
			$vars = '[殚殫]';
		} elsif ($ch eq '殞') {
			$vars = '[殞殒隕]';
		} elsif ($ch eq '殡') {
			$vars = '[殡殯]';
		} elsif ($ch eq '殤') {
			$vars = '[殤殇]';
		} elsif ($ch eq '殫') {
			$vars = '[殫殚]';
		} elsif ($ch eq '殮') {
			$vars = '[殮殓]';
		} elsif ($ch eq '殯') {
			$vars = '[殯殡]';
		} elsif ($ch eq '殱') {
			$vars = '[殱殲]';
		} elsif ($ch eq '殲') {
			$vars = '[殲歼]';
		} elsif ($ch eq '殳') {
			$vars = '[殳杸]';
		} elsif ($ch eq '殴') {
			$vars = '[殴毆]';
		} elsif ($ch eq '殺') {
			$vars = '[殺殺杀]';
		} elsif ($ch eq '殻') {
			$vars = '[殻壳殼]';
		} elsif ($ch eq '殼') {
			$vars = '[殼壳殻]';
		} elsif ($ch eq '殽') {
			$vars = '[殽淆]';
		} elsif ($ch eq '毀') {
			$vars = '[毀毁]';
		} elsif ($ch eq '毁') {
			$vars = '[毁毀]';
		} elsif ($ch eq '毂') {
			$vars = '[毂轂]';
		} elsif ($ch eq '毆') {
			$vars = '[毆殴]';
		} elsif ($ch eq '毎') {
			$vars = '[毎每]';
		} elsif ($ch eq '每') {
			$vars = '[每毎]';
		} elsif ($ch eq '毓') {
			$vars = '[毓育]';
		} elsif ($ch eq '毕') {
			$vars = '[毕畢]';
		} elsif ($ch eq '毗') {
			$vars = '[毗毘]';
		} elsif ($ch eq '毘') {
			$vars = '[毘毗]';
		} elsif ($ch eq '毙') {
			$vars = '[毙斃]';
		} elsif ($ch eq '毡') {
			$vars = '[毡氈]';
		} elsif ($ch eq '毬') {
			$vars = '[毬球]';
		} elsif ($ch eq '毵') {
			$vars = '[毵毿]';
		} elsif ($ch eq '毿') {
			$vars = '[毿毵]';
		} elsif ($ch eq '氂') {
			$vars = '[氂犛牦]';
		} elsif ($ch eq '氅') {
			$vars = '[氅鷩]';
		} elsif ($ch eq '氇') {
			$vars = '[氇氌]';
		} elsif ($ch eq '氈') {
			$vars = '[氈毡]';
		} elsif ($ch eq '氌') {
			$vars = '[氌氇]';
		} elsif ($ch eq '氓') {
			$vars = '[氓甿]';
		} elsif ($ch eq '气') {
			$vars = '[气氣]';
		} elsif ($ch eq '気') {
			$vars = '[気氣]';
		} elsif ($ch eq '氢') {
			$vars = '[氢氫]';
		} elsif ($ch eq '氣') {
			$vars = '[氣气気]';
		} elsif ($ch eq '氤') {
			$vars = '[氤絪]';
		} elsif ($ch eq '氩') {
			$vars = '[氩氬]';
		} elsif ($ch eq '氫') {
			$vars = '[氫氢]';
		} elsif ($ch eq '氬') {
			$vars = '[氬氩]';
		} elsif ($ch eq '氯') {
			$vars = '[氯綠]';
		} elsif ($ch eq '氲') {
			$vars = '[氲氳]';
		} elsif ($ch eq '氳') {
			$vars = '[氳氲]';
		} elsif ($ch eq '水') {
			$vars = '[水氵]';
		} elsif ($ch eq '氵') {
			$vars = '[氵水]';
		} elsif ($ch eq '氷') {
			$vars = '[氷冰冫]';
		} elsif ($ch eq '氽') {
			$vars = '[氽尿]';
		} elsif ($ch eq '氾') {
			$vars = '[氾泛]';
		} elsif ($ch eq '汇') {
			$vars = '[汇彙匯]';
		} elsif ($ch eq '汉') {
			$vars = '[汉漢]';
		} elsif ($ch eq '汎') {
			$vars = '[汎泛]';
		} elsif ($ch eq '汙') {
			$vars = '[汙污汚洿]';
		} elsif ($ch eq '汚') {
			$vars = '[汚洿汙]';
		} elsif ($ch eq '污') {
			$vars = '[污汙]';
		} elsif ($ch eq '汤') {
			$vars = '[汤湯]';
		} elsif ($ch eq '汨') {
			$vars = '[汨汩]';
		} elsif ($ch eq '汩') {
			$vars = '[汩汨]';
		} elsif ($ch eq '汹') {
			$vars = '[汹洶]';
		} elsif ($ch eq '決') {
			$vars = '[決决]';
		} elsif ($ch eq '沅') {
			$vars = '[沅源]';
		} elsif ($ch eq '沈') {
			$vars = '[沈沉瀋]';
		} elsif ($ch eq '沉') {
			$vars = '[沉瀋沈]';
		} elsif ($ch eq '沍') {
			$vars = '[沍冱]';
		} elsif ($ch eq '沒') {
			$vars = '[沒没]';
		} elsif ($ch eq '沖') {
			$vars = '[沖盅冲]';
		} elsif ($ch eq '沟') {
			$vars = '[沟溝]';
		} elsif ($ch eq '没') {
			$vars = '[没沒]';
		} elsif ($ch eq '沢') {
			$vars = '[沢澤]';
		} elsif ($ch eq '沣') {
			$vars = '[沣灃]';
		} elsif ($ch eq '沤') {
			$vars = '[沤漚]';
		} elsif ($ch eq '沥') {
			$vars = '[沥瀝]';
		} elsif ($ch eq '沦') {
			$vars = '[沦淪]';
		} elsif ($ch eq '沧') {
			$vars = '[沧滄]';
		} elsif ($ch eq '沩') {
			$vars = '[沩溈]';
		} elsif ($ch eq '沪') {
			$vars = '[沪滬冱]';
		} elsif ($ch eq '沱') {
			$vars = '[沱沲]';
		} elsif ($ch eq '沲') {
			$vars = '[沲沱]';
		} elsif ($ch eq '況') {
			$vars = '[況况]';
		} elsif ($ch eq '泄') {
			$vars = '[泄洩渫]';
		} elsif ($ch eq '泊') {
			$vars = '[泊泺]';
		} elsif ($ch eq '泖') {
			$vars = '[泖茅]';
		} elsif ($ch eq '泙') {
			$vars = '[泙洴]';
		} elsif ($ch eq '泛') {
			$vars = '[泛汎]';
		} elsif ($ch eq '泝') {
			$vars = '[泝溯遡]';
		} elsif ($ch eq '泞') {
			$vars = '[泞濘]';
		} elsif ($ch eq '泡') {
			$vars = '[泡箔]';
		} elsif ($ch eq '泥') {
			$vars = '[泥泥坭]';
		} elsif ($ch eq '注') {
			$vars = '[注註]';
		} elsif ($ch eq '泪') {
			$vars = '[泪淚]';
		} elsif ($ch eq '泶') {
			$vars = '[泶澩]';
		} elsif ($ch eq '泷') {
			$vars = '[泷瀧]';
		} elsif ($ch eq '泸') {
			$vars = '[泸瀘]';
		} elsif ($ch eq '泺') {
			$vars = '[泺濼]';
		} elsif ($ch eq '泻') {
			$vars = '[泻瀉]';
		} elsif ($ch eq '泼') {
			$vars = '[泼潑]';
		} elsif ($ch eq '泽') {
			$vars = '[泽澤]';
		} elsif ($ch eq '泾') {
			$vars = '[泾涇]';
		} elsif ($ch eq '洁') {
			$vars = '[洁潔]';
		} elsif ($ch eq '洌') {
			$vars = '[洌冽]';
		} elsif ($ch eq '洒') {
			$vars = '[洒灑]';
		} elsif ($ch eq '洚') {
			$vars = '[洚洪]';
		} elsif ($ch eq '洛') {
			$vars = '[洛洛]';
		} elsif ($ch eq '洞') {
			$vars = '[洞峒]';
		} elsif ($ch eq '洟') {
			$vars = '[洟涕]';
		} elsif ($ch eq '洩') {
			$vars = '[洩泄渫]';
		} elsif ($ch eq '洪') {
			$vars = '[洪洚]';
		} elsif ($ch eq '洴') {
			$vars = '[洴泙]';
		} elsif ($ch eq '洶') {
			$vars = '[洶汹]';
		} elsif ($ch eq '洼') {
			$vars = '[洼窪]';
		} elsif ($ch eq '洿') {
			$vars = '[洿汚汙]';
		} elsif ($ch eq '流') {
			$vars = '[流流]';
		} elsif ($ch eq '浃') {
			$vars = '[浃浹]';
		} elsif ($ch eq '浄') {
			$vars = '[浄淨]';
		} elsif ($ch eq '浅') {
			$vars = '[浅淺]';
		} elsif ($ch eq '浆') {
			$vars = '[浆漿]';
		} elsif ($ch eq '浇') {
			$vars = '[浇澆]';
		} elsif ($ch eq '浈') {
			$vars = '[浈湞]';
		} elsif ($ch eq '浊') {
			$vars = '[浊濁]';
		} elsif ($ch eq '测') {
			$vars = '[测測]';
		} elsif ($ch eq '浍') {
			$vars = '[浍澮]';
		} elsif ($ch eq '济') {
			$vars = '[济濟]';
		} elsif ($ch eq '浏') {
			$vars = '[浏瀏]';
		} elsif ($ch eq '浑') {
			$vars = '[浑渾]';
		} elsif ($ch eq '浒') {
			$vars = '[浒滸]';
		} elsif ($ch eq '浓') {
			$vars = '[浓濃]';
		} elsif ($ch eq '浔') {
			$vars = '[浔潯]';
		} elsif ($ch eq '浚') {
			$vars = '[浚濬]';
		} elsif ($ch eq '浜') {
			$vars = '[浜濱]';
		} elsif ($ch eq '浣') {
			$vars = '[浣澣]';
		} elsif ($ch eq '浩') {
			$vars = '[浩澔]';
		} elsif ($ch eq '浪') {
			$vars = '[浪浪]';
		} elsif ($ch eq '浹') {
			$vars = '[浹浃]';
		} elsif ($ch eq '涂') {
			$vars = '[涂塗]';
		} elsif ($ch eq '涇') {
			$vars = '[涇泾]';
		} elsif ($ch eq '涉') {
			$vars = '[涉渉]';
		} elsif ($ch eq '涌') {
			$vars = '[涌湧]';
		} elsif ($ch eq '涕') {
			$vars = '[涕洟]';
		} elsif ($ch eq '涙') {
			$vars = '[涙淚]';
		} elsif ($ch eq '涛') {
			$vars = '[涛濤]';
		} elsif ($ch eq '涜') {
			$vars = '[涜瀆]';
		} elsif ($ch eq '涝') {
			$vars = '[涝澇]';
		} elsif ($ch eq '涞') {
			$vars = '[涞淶]';
		} elsif ($ch eq '涟') {
			$vars = '[涟漣]';
		} elsif ($ch eq '涠') {
			$vars = '[涠潿]';
		} elsif ($ch eq '涡') {
			$vars = '[涡渦]';
		} elsif ($ch eq '涣') {
			$vars = '[涣渙]';
		} elsif ($ch eq '涤') {
			$vars = '[涤滌]';
		} elsif ($ch eq '润') {
			$vars = '[润潤]';
		} elsif ($ch eq '涧') {
			$vars = '[涧澗]';
		} elsif ($ch eq '涨') {
			$vars = '[涨漲]';
		} elsif ($ch eq '涩') {
			$vars = '[涩澀]';
		} elsif ($ch eq '涸') {
			$vars = '[涸凅]';
		} elsif ($ch eq '涼') {
			$vars = '[涼凉凉]';
		} elsif ($ch eq '淀') {
			$vars = '[淀澱]';
		} elsif ($ch eq '淆') {
			$vars = '[淆殽]';
		} elsif ($ch eq '淋') {
			$vars = '[淋淋]';
		} elsif ($ch eq '淒') {
			$vars = '[淒凄]';
		} elsif ($ch eq '淚') {
			$vars = '[淚泪淚]';
		} elsif ($ch eq '淜') {
			$vars = '[淜漰]';
		} elsif ($ch eq '淡') {
			$vars = '[淡澹]';
		} elsif ($ch eq '淥') {
			$vars = '[淥渌]';
		} elsif ($ch eq '淨') {
			$vars = '[淨凈]';
		} elsif ($ch eq '淪') {
			$vars = '[淪沦]';
		} elsif ($ch eq '淫') {
			$vars = '[淫婬]';
		} elsif ($ch eq '淵') {
			$vars = '[淵渊]';
		} elsif ($ch eq '淶') {
			$vars = '[淶涞]';
		} elsif ($ch eq '淸') {
			$vars = '[淸清]';
		} elsif ($ch eq '淹') {
			$vars = '[淹渰]';
		} elsif ($ch eq '淺') {
			$vars = '[淺浅]';
		} elsif ($ch eq '清') {
			$vars = '[清淸]';
		} elsif ($ch eq '渇') {
			$vars = '[渇渴]';
		} elsif ($ch eq '済') {
			$vars = '[済濟]';
		} elsif ($ch eq '渉') {
			$vars = '[渉涉]';
		} elsif ($ch eq '渊') {
			$vars = '[渊淵]';
		} elsif ($ch eq '渋') {
			$vars = '[渋澀]';
		} elsif ($ch eq '渌') {
			$vars = '[渌淥]';
		} elsif ($ch eq '渍') {
			$vars = '[渍漬]';
		} elsif ($ch eq '渎') {
			$vars = '[渎瀆]';
		} elsif ($ch eq '渐') {
			$vars = '[渐漸]';
		} elsif ($ch eq '渑') {
			$vars = '[渑澠]';
		} elsif ($ch eq '渓') {
			$vars = '[渓溪]';
		} elsif ($ch eq '渔') {
			$vars = '[渔漁]';
		} elsif ($ch eq '渕') {
			$vars = '[渕淵]';
		} elsif ($ch eq '渖') {
			$vars = '[渖瀋]';
		} elsif ($ch eq '渗') {
			$vars = '[渗滲]';
		} elsif ($ch eq '渙') {
			$vars = '[渙涣]';
		} elsif ($ch eq '渚') {
			$vars = '[渚陼]';
		} elsif ($ch eq '減') {
			$vars = '[減减]';
		} elsif ($ch eq '渦') {
			$vars = '[渦涡]';
		} elsif ($ch eq '渨') {
			$vars = '[渨偎隈]';
		} elsif ($ch eq '温') {
			$vars = '[温溫]';
		} elsif ($ch eq '渫') {
			$vars = '[渫泄洩]';
		} elsif ($ch eq '測') {
			$vars = '[測测]';
		} elsif ($ch eq '渰') {
			$vars = '[渰淹]';
		} elsif ($ch eq '渴') {
			$vars = '[渴渇]';
		} elsif ($ch eq '渹') {
			$vars = '[渹訇]';
		} elsif ($ch eq '渾') {
			$vars = '[渾浑]';
		} elsif ($ch eq '湊') {
			$vars = '[湊凑]';
		} elsif ($ch eq '湑') {
			$vars = '[湑醑]';
		} elsif ($ch eq '湞') {
			$vars = '[湞浈]';
		} elsif ($ch eq '湟') {
			$vars = '[湟況]';
		} elsif ($ch eq '湧') {
			$vars = '[湧涌]';
		} elsif ($ch eq '湯') {
			$vars = '[湯汤]';
		} elsif ($ch eq '湾') {
			$vars = '[湾灣]';
		} elsif ($ch eq '湿') {
			$vars = '[湿溼濕]';
		} elsif ($ch eq '満') {
			$vars = '[満滿]';
		} elsif ($ch eq '溃') {
			$vars = '[溃潰]';
		} elsif ($ch eq '溅') {
			$vars = '[溅濺]';
		} elsif ($ch eq '溆') {
			$vars = '[溆漵]';
		} elsif ($ch eq '溈') {
			$vars = '[溈沩]';
		} elsif ($ch eq '溉') {
			$vars = '[溉漑摡]';
		} elsif ($ch eq '溌') {
			$vars = '[溌潑]';
		} elsif ($ch eq '準') {
			$vars = '[準准凖]';
		} elsif ($ch eq '溜') {
			$vars = '[溜溜]';
		} elsif ($ch eq '溝') {
			$vars = '[溝沟]';
		} elsif ($ch eq '溪') {
			$vars = '[溪渓]';
		} elsif ($ch eq '溫') {
			$vars = '[溫温]';
		} elsif ($ch eq '溯') {
			$vars = '[溯泝遡]';
		} elsif ($ch eq '溺') {
			$vars = '[溺尿]';
		} elsif ($ch eq '溻') {
			$vars = '[溻褟]';
		} elsif ($ch eq '溼') {
			$vars = '[溼濕]';
		} elsif ($ch eq '溽') {
			$vars = '[溽縟]';
		} elsif ($ch eq '滄') {
			$vars = '[滄沧]';
		} elsif ($ch eq '滅') {
			$vars = '[滅灭]';
		} elsif ($ch eq '滌') {
			$vars = '[滌涤]';
		} elsif ($ch eq '滎') {
			$vars = '[滎荥]';
		} elsif ($ch eq '滑') {
			$vars = '[滑磆]';
		} elsif ($ch eq '滗') {
			$vars = '[滗潷]';
		} elsif ($ch eq '滚') {
			$vars = '[滚滾]';
		} elsif ($ch eq '滞') {
			$vars = '[滞滯]';
		} elsif ($ch eq '滠') {
			$vars = '[滠灄]';
		} elsif ($ch eq '满') {
			$vars = '[满滿]';
		} elsif ($ch eq '滢') {
			$vars = '[滢瀅]';
		} elsif ($ch eq '滤') {
			$vars = '[滤濾]';
		} elsif ($ch eq '滥') {
			$vars = '[滥濫]';
		} elsif ($ch eq '滦') {
			$vars = '[滦灤]';
		} elsif ($ch eq '滨') {
			$vars = '[滨濱]';
		} elsif ($ch eq '滩') {
			$vars = '[滩灘]';
		} elsif ($ch eq '滬') {
			$vars = '[滬沪]';
		} elsif ($ch eq '滯') {
			$vars = '[滯滞]';
		} elsif ($ch eq '滲') {
			$vars = '[滲渗]';
		} elsif ($ch eq '滷') {
			$vars = '[滷卤]';
		} elsif ($ch eq '滸') {
			$vars = '[滸浒]';
		} elsif ($ch eq '滾') {
			$vars = '[滾菌滚]';
		} elsif ($ch eq '滿') {
			$vars = '[滿满]';
		} elsif ($ch eq '漁') {
			$vars = '[漁渔]';
		} elsif ($ch eq '漆') {
			$vars = '[漆柒桼]';
		} elsif ($ch eq '漏') {
			$vars = '[漏漏]';
		} elsif ($ch eq '漑') {
			$vars = '[漑溉]';
		} elsif ($ch eq '漓') {
			$vars = '[漓灕]';
		} elsif ($ch eq '漚') {
			$vars = '[漚沤]';
		} elsif ($ch eq '漢') {
			$vars = '[漢汉]';
		} elsif ($ch eq '漣') {
			$vars = '[漣涟]';
		} elsif ($ch eq '漤') {
			$vars = '[漤灠]';
		} elsif ($ch eq '漬') {
			$vars = '[漬渍]';
		} elsif ($ch eq '漰') {
			$vars = '[漰淜]';
		} elsif ($ch eq '漲') {
			$vars = '[漲涨]';
		} elsif ($ch eq '漵') {
			$vars = '[漵溆]';
		} elsif ($ch eq '漸') {
			$vars = '[漸渐]';
		} elsif ($ch eq '漾') {
			$vars = '[漾瀁]';
		} elsif ($ch eq '漿') {
			$vars = '[漿浆]';
		} elsif ($ch eq '潁') {
			$vars = '[潁颍]';
		} elsif ($ch eq '潅') {
			$vars = '[潅灌]';
		} elsif ($ch eq '潆') {
			$vars = '[潆瀠]';
		} elsif ($ch eq '潇') {
			$vars = '[潇瀟]';
		} elsif ($ch eq '潋') {
			$vars = '[潋瀲]';
		} elsif ($ch eq '潍') {
			$vars = '[潍濰]';
		} elsif ($ch eq '潑') {
			$vars = '[潑泼溌]';
		} elsif ($ch eq '潔') {
			$vars = '[潔洁]';
		} elsif ($ch eq '潛') {
			$vars = '[潛潜]';
		} elsif ($ch eq '潜') {
			$vars = '[潜潛]';
		} elsif ($ch eq '潤') {
			$vars = '[潤润]';
		} elsif ($ch eq '潦') {
			$vars = '[潦澇]';
		} elsif ($ch eq '潬') {
			$vars = '[潬灘]';
		} elsif ($ch eq '潯') {
			$vars = '[潯浔]';
		} elsif ($ch eq '潰') {
			$vars = '[潰溃]';
		} elsif ($ch eq '潴') {
			$vars = '[潴瀦]';
		} elsif ($ch eq '潷') {
			$vars = '[潷滗]';
		} elsif ($ch eq '潿') {
			$vars = '[潿涠]';
		} elsif ($ch eq '澀') {
			$vars = '[澀澁涩濇]';
		} elsif ($ch eq '澁') {
			$vars = '[澁澀濇]';
		} elsif ($ch eq '澄') {
			$vars = '[澄澂]';
		} elsif ($ch eq '澆') {
			$vars = '[澆浇]';
		} elsif ($ch eq '澇') {
			$vars = '[澇潦涝]';
		} elsif ($ch eq '澈') {
			$vars = '[澈徹]';
		} elsif ($ch eq '澑') {
			$vars = '[澑溜]';
		} elsif ($ch eq '澔') {
			$vars = '[澔浩]';
		} elsif ($ch eq '澗') {
			$vars = '[澗磵涧]';
		} elsif ($ch eq '澜') {
			$vars = '[澜瀾]';
		} elsif ($ch eq '澠') {
			$vars = '[澠渑]';
		} elsif ($ch eq '澣') {
			$vars = '[澣浣]';
		} elsif ($ch eq '澤') {
			$vars = '[澤沢泽]';
		} elsif ($ch eq '澩') {
			$vars = '[澩泶]';
		} elsif ($ch eq '澮') {
			$vars = '[澮浍]';
		} elsif ($ch eq '澱') {
			$vars = '[澱淀]';
		} elsif ($ch eq '澳') {
			$vars = '[澳襖]';
		} elsif ($ch eq '澹') {
			$vars = '[澹淡]';
		} elsif ($ch eq '濁') {
			$vars = '[濁浊]';
		} elsif ($ch eq '濃') {
			$vars = '[濃浓]';
		} elsif ($ch eq '濇') {
			$vars = '[濇澀澁]';
		} elsif ($ch eq '濑') {
			$vars = '[濑瀨]';
		} elsif ($ch eq '濒') {
			$vars = '[濒瀕]';
		} elsif ($ch eq '濕') {
			$vars = '[濕溼湿]';
		} elsif ($ch eq '濘') {
			$vars = '[濘泞]';
		} elsif ($ch eq '濛') {
			$vars = '[濛霥]';
		} elsif ($ch eq '濟') {
			$vars = '[濟济]';
		} elsif ($ch eq '濤') {
			$vars = '[濤涛]';
		} elsif ($ch eq '濫') {
			$vars = '[濫滥]';
		} elsif ($ch eq '濬') {
			$vars = '[濬浚]';
		} elsif ($ch eq '濰') {
			$vars = '[濰潍]';
		} elsif ($ch eq '濱') {
			$vars = '[濱滨瀕]';
		} elsif ($ch eq '濳') {
			$vars = '[濳潛]';
		} elsif ($ch eq '濶') {
			$vars = '[濶闊]';
		} elsif ($ch eq '濺') {
			$vars = '[濺溅]';
		} elsif ($ch eq '濼') {
			$vars = '[濼泊泺]';
		} elsif ($ch eq '濾') {
			$vars = '[濾濾滤]';
		} elsif ($ch eq '濿') {
			$vars = '[濿砅]';
		} elsif ($ch eq '瀁') {
			$vars = '[瀁漾]';
		} elsif ($ch eq '瀅') {
			$vars = '[瀅滢]';
		} elsif ($ch eq '瀆') {
			$vars = '[瀆渎]';
		} elsif ($ch eq '瀉') {
			$vars = '[瀉泻]';
		} elsif ($ch eq '瀋') {
			$vars = '[瀋渖沈]';
		} elsif ($ch eq '瀏') {
			$vars = '[瀏浏]';
		} elsif ($ch eq '瀕') {
			$vars = '[瀕濱濒]';
		} elsif ($ch eq '瀘') {
			$vars = '[瀘泸]';
		} elsif ($ch eq '瀝') {
			$vars = '[瀝沥]';
		} elsif ($ch eq '瀟') {
			$vars = '[瀟潇]';
		} elsif ($ch eq '瀠') {
			$vars = '[瀠潆]';
		} elsif ($ch eq '瀦') {
			$vars = '[瀦潴]';
		} elsif ($ch eq '瀧') {
			$vars = '[瀧泷]';
		} elsif ($ch eq '瀨') {
			$vars = '[瀨濑瀬]';
		} elsif ($ch eq '瀬') {
			$vars = '[瀬瀨]';
		} elsif ($ch eq '瀰') {
			$vars = '[瀰彌]';
		} elsif ($ch eq '瀲') {
			$vars = '[瀲潋]';
		} elsif ($ch eq '瀾') {
			$vars = '[瀾澜]';
		} elsif ($ch eq '灃') {
			$vars = '[灃沣]';
		} elsif ($ch eq '灄') {
			$vars = '[灄滠]';
		} elsif ($ch eq '灌') {
			$vars = '[灌潅]';
		} elsif ($ch eq '灏') {
			$vars = '[灏灝]';
		} elsif ($ch eq '灑') {
			$vars = '[灑洒]';
		} elsif ($ch eq '灕') {
			$vars = '[灕漓]';
		} elsif ($ch eq '灘') {
			$vars = '[灘潬滩]';
		} elsif ($ch eq '灝') {
			$vars = '[灝灏]';
		} elsif ($ch eq '灠') {
			$vars = '[灠漤]';
		} elsif ($ch eq '灣') {
			$vars = '[灣湾]';
		} elsif ($ch eq '灤') {
			$vars = '[灤滦]';
		} elsif ($ch eq '火') {
			$vars = '[火灬]';
		} elsif ($ch eq '灬') {
			$vars = '[灬火]';
		} elsif ($ch eq '灭') {
			$vars = '[灭滅]';
		} elsif ($ch eq '灯') {
			$vars = '[灯燈]';
		} elsif ($ch eq '灴') {
			$vars = '[灴烘]';
		} elsif ($ch eq '灵') {
			$vars = '[灵靈]';
		} elsif ($ch eq '灶') {
			$vars = '[灶竈]';
		} elsif ($ch eq '災') {
			$vars = '[災灾菑]';
		} elsif ($ch eq '灾') {
			$vars = '[灾災菑]';
		} elsif ($ch eq '灿') {
			$vars = '[灿燦]';
		} elsif ($ch eq '炀') {
			$vars = '[炀煬]';
		} elsif ($ch eq '炅') {
			$vars = '[炅耿]';
		} elsif ($ch eq '炉') {
			$vars = '[炉爐]';
		} elsif ($ch eq '炔') {
			$vars = '[炔耿]';
		} elsif ($ch eq '炖') {
			$vars = '[炖燉]';
		} elsif ($ch eq '炙') {
			$vars = '[炙炙]';
		} elsif ($ch eq '炜') {
			$vars = '[炜煒]';
		} elsif ($ch eq '炝') {
			$vars = '[炝熗]';
		} elsif ($ch eq '炤') {
			$vars = '[炤照]';
		} elsif ($ch eq '炫') {
			$vars = '[炫衒]';
		} elsif ($ch eq '炮') {
			$vars = '[炮砲炰]';
		} elsif ($ch eq '炯') {
			$vars = '[炯烱]';
		} elsif ($ch eq '炰') {
			$vars = '[炰炮]';
		} elsif ($ch eq '炸') {
			$vars = '[炸煠]';
		} elsif ($ch eq '点') {
			$vars = '[点點]';
		} elsif ($ch eq '為') {
			$vars = '[為为爲]';
		} elsif ($ch eq '炼') {
			$vars = '[炼煉]';
		} elsif ($ch eq '炽') {
			$vars = '[炽熾]';
		} elsif ($ch eq '烁') {
			$vars = '[烁爍]';
		} elsif ($ch eq '烂') {
			$vars = '[烂爛]';
		} elsif ($ch eq '烃') {
			$vars = '[烃烴]';
		} elsif ($ch eq '烊') {
			$vars = '[烊煬]';
		} elsif ($ch eq '烏') {
			$vars = '[烏乌]';
		} elsif ($ch eq '烘') {
			$vars = '[烘灴]';
		} elsif ($ch eq '烙') {
			$vars = '[烙烙]';
		} elsif ($ch eq '烛') {
			$vars = '[烛燭]';
		} elsif ($ch eq '烜') {
			$vars = '[烜晅]';
		} elsif ($ch eq '烝') {
			$vars = '[烝蒸]';
		} elsif ($ch eq '烟') {
			$vars = '[烟煙完菸]';
		} elsif ($ch eq '烦') {
			$vars = '[烦煩]';
		} elsif ($ch eq '烧') {
			$vars = '[烧燒]';
		} elsif ($ch eq '烨') {
			$vars = '[烨燁]';
		} elsif ($ch eq '烩') {
			$vars = '[烩燴]';
		} elsif ($ch eq '烫') {
			$vars = '[烫燙]';
		} elsif ($ch eq '烬') {
			$vars = '[烬燼]';
		} elsif ($ch eq '热') {
			$vars = '[热熱]';
		} elsif ($ch eq '烱') {
			$vars = '[烱炯]';
		} elsif ($ch eq '烴') {
			$vars = '[烴烃]';
		} elsif ($ch eq '焔') {
			$vars = '[焔焰]';
		} elsif ($ch eq '焕') {
			$vars = '[焕煥]';
		} elsif ($ch eq '焖') {
			$vars = '[焖燜]';
		} elsif ($ch eq '焘') {
			$vars = '[焘燾]';
		} elsif ($ch eq '無') {
			$vars = '[無橆无]';
		} elsif ($ch eq '焰') {
			$vars = '[焰燄焔]';
		} elsif ($ch eq '焼') {
			$vars = '[焼燒]';
		} elsif ($ch eq '煅') {
			$vars = '[煅鍛]';
		} elsif ($ch eq '煆') {
			$vars = '[煆鍜]';
		} elsif ($ch eq '煇') {
			$vars = '[煇輝]';
		} elsif ($ch eq '煉') {
			$vars = '[煉炼煉]';
		} elsif ($ch eq '煒') {
			$vars = '[煒炜]';
		} elsif ($ch eq '煕') {
			$vars = '[煕熙]';
		} elsif ($ch eq '煖') {
			$vars = '[煖娠暖]';
		} elsif ($ch eq '煙') {
			$vars = '[煙烟完菸]';
		} elsif ($ch eq '煠') {
			$vars = '[煠炸]';
		} elsif ($ch eq '煢') {
			$vars = '[煢茕]';
		} elsif ($ch eq '煥') {
			$vars = '[煥焕]';
		} elsif ($ch eq '照') {
			$vars = '[照炤]';
		} elsif ($ch eq '煩') {
			$vars = '[煩烦]';
		} elsif ($ch eq '煬') {
			$vars = '[煬烊炀]';
		} elsif ($ch eq '煽') {
			$vars = '[煽搧]';
		} elsif ($ch eq '熈') {
			$vars = '[熈熙]';
		} elsif ($ch eq '熏') {
			$vars = '[熏燻]';
		} elsif ($ch eq '熒') {
			$vars = '[熒荧]';
		} elsif ($ch eq '熔') {
			$vars = '[熔鎔]';
		} elsif ($ch eq '熗') {
			$vars = '[熗炝]';
		} elsif ($ch eq '熙') {
			$vars = '[熙煕熈]';
		} elsif ($ch eq '熨') {
			$vars = '[熨尉]';
		} elsif ($ch eq '熱') {
			$vars = '[熱热]';
		} elsif ($ch eq '熹') {
			$vars = '[熹熺]';
		} elsif ($ch eq '熺') {
			$vars = '[熺熹]';
		} elsif ($ch eq '熾') {
			$vars = '[熾炽]';
		} elsif ($ch eq '燁') {
			$vars = '[燁烨]';
		} elsif ($ch eq '燄') {
			$vars = '[燄焰]';
		} elsif ($ch eq '燈') {
			$vars = '[燈灯]';
		} elsif ($ch eq '燉') {
			$vars = '[燉炖]';
		} elsif ($ch eq '燎') {
			$vars = '[燎燎]';
		} elsif ($ch eq '燐') {
			$vars = '[燐燐]';
		} elsif ($ch eq '燒') {
			$vars = '[燒烧簫]';
		} elsif ($ch eq '燕') {
			$vars = '[燕鷰]';
		} elsif ($ch eq '燗') {
			$vars = '[燗爛]';
		} elsif ($ch eq '燙') {
			$vars = '[燙烫]';
		} elsif ($ch eq '燜') {
			$vars = '[燜焖]';
		} elsif ($ch eq '營') {
			$vars = '[營营]';
		} elsif ($ch eq '燦') {
			$vars = '[燦灿]';
		} elsif ($ch eq '燭') {
			$vars = '[燭烛]';
		} elsif ($ch eq '燴') {
			$vars = '[燴烩]';
		} elsif ($ch eq '燻') {
			$vars = '[燻熏]';
		} elsif ($ch eq '燼') {
			$vars = '[燼烬]';
		} elsif ($ch eq '燾') {
			$vars = '[燾焘]';
		} elsif ($ch eq '燿') {
			$vars = '[燿耀曜]';
		} elsif ($ch eq '爍') {
			$vars = '[爍烁]';
		} elsif ($ch eq '爐') {
			$vars = '[爐爐炉]';
		} elsif ($ch eq '爛') {
			$vars = '[爛烂]';
		} elsif ($ch eq '爭') {
			$vars = '[爭争]';
		} elsif ($ch eq '爱') {
			$vars = '[爱愛]';
		} elsif ($ch eq '爲') {
			$vars = '[爲为為]';
		} elsif ($ch eq '爷') {
			$vars = '[爷爺]';
		} elsif ($ch eq '爺') {
			$vars = '[爺爷]';
		} elsif ($ch eq '爼') {
			$vars = '[爼俎]';
		} elsif ($ch eq '爾') {
			$vars = '[爾尔尒]';
		} elsif ($ch eq '牀') {
			$vars = '[牀床]';
		} elsif ($ch eq '牄') {
			$vars = '[牄蹌]';
		} elsif ($ch eq '牆') {
			$vars = '[牆廧墙墻]';
		} elsif ($ch eq '版') {
			$vars = '[版板]';
		} elsif ($ch eq '牋') {
			$vars = '[牋箋]';
		} elsif ($ch eq '牍') {
			$vars = '[牍牘]';
		} elsif ($ch eq '牘') {
			$vars = '[牘牍]';
		} elsif ($ch eq '牟') {
			$vars = '[牟麰]';
		} elsif ($ch eq '牠') {
			$vars = '[牠它他]';
		} elsif ($ch eq '牢') {
			$vars = '[牢牢]';
		} elsif ($ch eq '牦') {
			$vars = '[牦氂犛]';
		} elsif ($ch eq '牴') {
			$vars = '[牴觝]';
		} elsif ($ch eq '牵') {
			$vars = '[牵牽]';
		} elsif ($ch eq '牺') {
			$vars = '[牺犧]';
		} elsif ($ch eq '牽') {
			$vars = '[牽牵]';
		} elsif ($ch eq '犁') {
			$vars = '[犁犂]';
		} elsif ($ch eq '犂') {
			$vars = '[犂犁]';
		} elsif ($ch eq '犄') {
			$vars = '[犄踦]';
		} elsif ($ch eq '犇') {
			$vars = '[犇奔]';
		} elsif ($ch eq '犊') {
			$vars = '[犊犢]';
		} elsif ($ch eq '犖') {
			$vars = '[犖荦]';
		} elsif ($ch eq '犛') {
			$vars = '[犛髦]';
		} elsif ($ch eq '犠') {
			$vars = '[犠犧]';
		} elsif ($ch eq '犢') {
			$vars = '[犢犊]';
		} elsif ($ch eq '犧') {
			$vars = '[犧牺]';
		} elsif ($ch eq '犬') {
			$vars = '[犬犭]';
		} elsif ($ch eq '犭') {
			$vars = '[犭犬]';
		} elsif ($ch eq '犲') {
			$vars = '[犲豺]';
		} elsif ($ch eq '犴') {
			$vars = '[犴豻]';
		} elsif ($ch eq '状') {
			$vars = '[状狀]';
		} elsif ($ch eq '犷') {
			$vars = '[犷獷]';
		} elsif ($ch eq '犹') {
			$vars = '[犹猶]';
		} elsif ($ch eq '狀') {
			$vars = '[狀状]';
		} elsif ($ch eq '狈') {
			$vars = '[狈狽]';
		} elsif ($ch eq '狞') {
			$vars = '[狞獰]';
		} elsif ($ch eq '狢') {
			$vars = '[狢貉]';
		} elsif ($ch eq '独') {
			$vars = '[独獨]';
		} elsif ($ch eq '狭') {
			$vars = '[狭狹]';
		} elsif ($ch eq '狮') {
			$vars = '[狮獅]';
		} elsif ($ch eq '狯') {
			$vars = '[狯獪]';
		} elsif ($ch eq '狰') {
			$vars = '[狰猙]';
		} elsif ($ch eq '狱') {
			$vars = '[狱獄]';
		} elsif ($ch eq '狲') {
			$vars = '[狲猻]';
		} elsif ($ch eq '狷') {
			$vars = '[狷獧]';
		} elsif ($ch eq '狸') {
			$vars = '[狸貍]';
		} elsif ($ch eq '狹') {
			$vars = '[狹狭陜]';
		} elsif ($ch eq '狼') {
			$vars = '[狼狼]';
		} elsif ($ch eq '狽') {
			$vars = '[狽狈]';
		} elsif ($ch eq '猃') {
			$vars = '[猃獫]';
		} elsif ($ch eq '猇') {
			$vars = '[猇唬虓]';
		} elsif ($ch eq '猋') {
			$vars = '[猋颮飇]';
		} elsif ($ch eq '猎') {
			$vars = '[猎獵]';
		} elsif ($ch eq '猕') {
			$vars = '[猕獼]';
		} elsif ($ch eq '猗') {
			$vars = '[猗欹]';
		} elsif ($ch eq '猙') {
			$vars = '[猙狰]';
		} elsif ($ch eq '猟') {
			$vars = '[猟獵]';
		} elsif ($ch eq '猡') {
			$vars = '[猡玀]';
		} elsif ($ch eq '猪') {
			$vars = '[猪豬]';
		} elsif ($ch eq '猫') {
			$vars = '[猫貓]';
		} elsif ($ch eq '猬') {
			$vars = '[猬蝟]';
		} elsif ($ch eq '献') {
			$vars = '[献獻]';
		} elsif ($ch eq '猶') {
			$vars = '[猶犹]';
		} elsif ($ch eq '猻') {
			$vars = '[猻狲]';
		} elsif ($ch eq '猾') {
			$vars = '[猾獪]';
		} elsif ($ch eq '猿') {
			$vars = '[猿蝯]';
		} elsif ($ch eq '獃') {
			$vars = '[獃呆]';
		} elsif ($ch eq '獄') {
			$vars = '[獄狱]';
		} elsif ($ch eq '獅') {
			$vars = '[獅狮]';
		} elsif ($ch eq '獎') {
			$vars = '[獎奖奬]';
		} elsif ($ch eq '獣') {
			$vars = '[獣獸]';
		} elsif ($ch eq '獧') {
			$vars = '[獧狷]';
		} elsif ($ch eq '獨') {
			$vars = '[獨独]';
		} elsif ($ch eq '獪') {
			$vars = '[獪狯猾]';
		} elsif ($ch eq '獫') {
			$vars = '[獫玁猃]';
		} elsif ($ch eq '獭') {
			$vars = '[獭獺]';
		} elsif ($ch eq '獰') {
			$vars = '[獰狞]';
		} elsif ($ch eq '獲') {
			$vars = '[獲获]';
		} elsif ($ch eq '獵') {
			$vars = '[獵猎獵]';
		} elsif ($ch eq '獷') {
			$vars = '[獷犷]';
		} elsif ($ch eq '獸') {
			$vars = '[獸兽]';
		} elsif ($ch eq '獺') {
			$vars = '[獺獭]';
		} elsif ($ch eq '獻') {
			$vars = '[獻献]';
		} elsif ($ch eq '獼') {
			$vars = '[獼猕]';
		} elsif ($ch eq '玀') {
			$vars = '[玀猡]';
		} elsif ($ch eq '玁') {
			$vars = '[玁獫]';
		} elsif ($ch eq '玄') {
			$vars = '[玄伭]';
		} elsif ($ch eq '玅') {
			$vars = '[玅妙]';
		} elsif ($ch eq '玆') {
			$vars = '[玆茲兹]';
		} elsif ($ch eq '率') {
			$vars = '[率率]';
		} elsif ($ch eq '玑') {
			$vars = '[玑璣]';
		} elsif ($ch eq '玖') {
			$vars = '[玖九]';
		} elsif ($ch eq '玛') {
			$vars = '[玛瑪]';
		} elsif ($ch eq '玟') {
			$vars = '[玟珉玫]';
		} elsif ($ch eq '玫') {
			$vars = '[玫玟]';
		} elsif ($ch eq '玮') {
			$vars = '[玮瑋]';
		} elsif ($ch eq '环') {
			$vars = '[环環]';
		} elsif ($ch eq '现') {
			$vars = '[现現]';
		} elsif ($ch eq '玲') {
			$vars = '[玲玲]';
		} elsif ($ch eq '玺') {
			$vars = '[玺璽]';
		} elsif ($ch eq '珉') {
			$vars = '[珉玟]';
		} elsif ($ch eq '珍') {
			$vars = '[珍珎]';
		} elsif ($ch eq '珎') {
			$vars = '[珎珍]';
		} elsif ($ch eq '珐') {
			$vars = '[珐琺]';
		} elsif ($ch eq '珑') {
			$vars = '[珑瓏]';
		} elsif ($ch eq '珞') {
			$vars = '[珞珞]';
		} elsif ($ch eq '珪') {
			$vars = '[珪圭]';
		} elsif ($ch eq '珲') {
			$vars = '[珲琿]';
		} elsif ($ch eq '珷') {
			$vars = '[珷碔]';
		} elsif ($ch eq '現') {
			$vars = '[現现]';
		} elsif ($ch eq '琄') {
			$vars = '[琄鞙]';
		} elsif ($ch eq '琅') {
			$vars = '[琅瑯]';
		} elsif ($ch eq '理') {
			$vars = '[理理]';
		} elsif ($ch eq '琉') {
			$vars = '[琉琉瑠]';
		} elsif ($ch eq '琏') {
			$vars = '[琏璉]';
		} elsif ($ch eq '琐') {
			$vars = '[琐瑣]';
		} elsif ($ch eq '琱') {
			$vars = '[琱雕]';
		} elsif ($ch eq '琺') {
			$vars = '[琺珐]';
		} elsif ($ch eq '琼') {
			$vars = '[琼瓊]';
		} elsif ($ch eq '琿') {
			$vars = '[琿珲]';
		} elsif ($ch eq '瑋') {
			$vars = '[瑋玮]';
		} elsif ($ch eq '瑙') {
			$vars = '[瑙碯]';
		} elsif ($ch eq '瑠') {
			$vars = '[瑠琉]';
		} elsif ($ch eq '瑣') {
			$vars = '[瑣琐]';
		} elsif ($ch eq '瑤') {
			$vars = '[瑤瑶]';
		} elsif ($ch eq '瑩') {
			$vars = '[瑩莹瑩]';
		} elsif ($ch eq '瑪') {
			$vars = '[瑪玛]';
		} elsif ($ch eq '瑯') {
			$vars = '[瑯琅]';
		} elsif ($ch eq '瑶') {
			$vars = '[瑶瑤]';
		} elsif ($ch eq '瑷') {
			$vars = '[瑷璦]';
		} elsif ($ch eq '瑽') {
			$vars = '[瑽璁]';
		} elsif ($ch eq '璁') {
			$vars = '[璁瑽]';
		} elsif ($ch eq '璇') {
			$vars = '[璇璿]';
		} elsif ($ch eq '璉') {
			$vars = '[璉琏]';
		} elsif ($ch eq '璎') {
			$vars = '[璎瓔]';
		} elsif ($ch eq '璘') {
			$vars = '[璘璘]';
		} elsif ($ch eq '璢') {
			$vars = '[璢琉]';
		} elsif ($ch eq '璣') {
			$vars = '[璣玑]';
		} elsif ($ch eq '璦') {
			$vars = '[璦瑷]';
		} elsif ($ch eq '環') {
			$vars = '[環环]';
		} elsif ($ch eq '璽') {
			$vars = '[璽玺]';
		} elsif ($ch eq '璿') {
			$vars = '[璿璇]';
		} elsif ($ch eq '瓊') {
			$vars = '[瓊琼]';
		} elsif ($ch eq '瓏') {
			$vars = '[瓏珑]';
		} elsif ($ch eq '瓒') {
			$vars = '[瓒瓚]';
		} elsif ($ch eq '瓔') {
			$vars = '[瓔璎]';
		} elsif ($ch eq '瓚') {
			$vars = '[瓚瓒]';
		} elsif ($ch eq '瓟') {
			$vars = '[瓟匏]';
		} elsif ($ch eq '瓮') {
			$vars = '[瓮甕罋]';
		} elsif ($ch eq '瓯') {
			$vars = '[瓯甌]';
		} elsif ($ch eq '瓶') {
			$vars = '[瓶缾]';
		} elsif ($ch eq '瓷') {
			$vars = '[瓷磁]';
		} elsif ($ch eq '甁') {
			$vars = '[甁瓶]';
		} elsif ($ch eq '甌') {
			$vars = '[甌瓯]';
		} elsif ($ch eq '甎') {
			$vars = '[甎磚]';
		} elsif ($ch eq '甕') {
			$vars = '[甕罋瓮]';
		} elsif ($ch eq '甖') {
			$vars = '[甖罌罃]';
		} elsif ($ch eq '甚') {
			$vars = '[甚什]';
		} elsif ($ch eq '甜') {
			$vars = '[甜甛]';
		} elsif ($ch eq '甞') {
			$vars = '[甞嘗]';
		} elsif ($ch eq '產') {
			$vars = '[產产]';
		} elsif ($ch eq '産') {
			$vars = '[産产產]';
		} elsif ($ch eq '甦') {
			$vars = '[甦穌]';
		} elsif ($ch eq '甩') {
			$vars = '[甩摔]';
		} elsif ($ch eq '甪') {
			$vars = '[甪角]';
		} elsif ($ch eq '甬') {
			$vars = '[甬埇]';
		} elsif ($ch eq '甯') {
			$vars = '[甯寗]';
		} elsif ($ch eq '电') {
			$vars = '[电電]';
		} elsif ($ch eq '町') {
			$vars = '[町圢]';
		} elsif ($ch eq '画') {
			$vars = '[画畫]';
		} elsif ($ch eq '甽') {
			$vars = '[甽畎]';
		} elsif ($ch eq '甾') {
			$vars = '[甾菑]';
		} elsif ($ch eq '甿') {
			$vars = '[甿氓]';
		} elsif ($ch eq '畄') {
			$vars = '[畄留]';
		} elsif ($ch eq '畅') {
			$vars = '[畅暢]';
		} elsif ($ch eq '畆') {
			$vars = '[畆畝]';
		} elsif ($ch eq '畊') {
			$vars = '[畊耕]';
		} elsif ($ch eq '界') {
			$vars = '[界畍]';
		} elsif ($ch eq '畍') {
			$vars = '[畍界]';
		} elsif ($ch eq '畎') {
			$vars = '[畎甽]';
		} elsif ($ch eq '留') {
			$vars = '[留畄]';
		} elsif ($ch eq '畝') {
			$vars = '[畝畆亩]';
		} elsif ($ch eq '畢') {
			$vars = '[畢毕]';
		} elsif ($ch eq '略') {
			$vars = '[略畧]';
		} elsif ($ch eq '畧') {
			$vars = '[畧略]';
		} elsif ($ch eq '番') {
			$vars = '[番蹯]';
		} elsif ($ch eq '畫') {
			$vars = '[畫划畵画]';
		} elsif ($ch eq '畬') {
			$vars = '[畬畭]';
		} elsif ($ch eq '畭') {
			$vars = '[畭畬]';
		} elsif ($ch eq '異') {
			$vars = '[異異异]';
		} elsif ($ch eq '畲') {
			$vars = '[畲畬]';
		} elsif ($ch eq '畳') {
			$vars = '[畳疊]';
		} elsif ($ch eq '畴') {
			$vars = '[畴疇]';
		} elsif ($ch eq '畵') {
			$vars = '[畵畫]';
		} elsif ($ch eq '當') {
			$vars = '[當当]';
		} elsif ($ch eq '畺') {
			$vars = '[畺將疆]';
		} elsif ($ch eq '畽') {
			$vars = '[畽疃]';
		} elsif ($ch eq '疃') {
			$vars = '[疃畽]';
		} elsif ($ch eq '疆') {
			$vars = '[疆將畺]';
		} elsif ($ch eq '疇') {
			$vars = '[疇畴]';
		} elsif ($ch eq '疉') {
			$vars = '[疉疊]';
		} elsif ($ch eq '疊') {
			$vars = '[疊叠]';
		} elsif ($ch eq '疋') {
			$vars = '[疋匹]';
		} elsif ($ch eq '疎') {
			$vars = '[疎疏]';
		} elsif ($ch eq '疏') {
			$vars = '[疏疎]';
		} elsif ($ch eq '疖') {
			$vars = '[疖癤]';
		} elsif ($ch eq '疗') {
			$vars = '[疗療]';
		} elsif ($ch eq '疟') {
			$vars = '[疟瘧]';
		} elsif ($ch eq '疠') {
			$vars = '[疠癘]';
		} elsif ($ch eq '疡') {
			$vars = '[疡瘍]';
		} elsif ($ch eq '疣') {
			$vars = '[疣肬]';
		} elsif ($ch eq '疬') {
			$vars = '[疬癧]';
		} elsif ($ch eq '疮') {
			$vars = '[疮瘡]';
		} elsif ($ch eq '疯') {
			$vars = '[疯瘋]';
		} elsif ($ch eq '疱') {
			$vars = '[疱皰]';
		} elsif ($ch eq '疴') {
			$vars = '[疴痾]';
		} elsif ($ch eq '疸') {
			$vars = '[疸癉]';
		} elsif ($ch eq '疹') {
			$vars = '[疹胗]';
		} elsif ($ch eq '症') {
			$vars = '[症癥]';
		} elsif ($ch eq '痈') {
			$vars = '[痈癰]';
		} elsif ($ch eq '痉') {
			$vars = '[痉痙]';
		} elsif ($ch eq '痐') {
			$vars = '[痐蚘]';
		} elsif ($ch eq '痒') {
			$vars = '[痒癢]';
		} elsif ($ch eq '痙') {
			$vars = '[痙痉]';
		} elsif ($ch eq '痢') {
			$vars = '[痢痢]';
		} elsif ($ch eq '痨') {
			$vars = '[痨癆]';
		} elsif ($ch eq '痩') {
			$vars = '[痩瘦]';
		} elsif ($ch eq '痪') {
			$vars = '[痪瘓]';
		} elsif ($ch eq '痫') {
			$vars = '[痫癇]';
		} elsif ($ch eq '痲') {
			$vars = '[痲痳]';
		} elsif ($ch eq '痳') {
			$vars = '[痳痲]';
		} elsif ($ch eq '痴') {
			$vars = '[痴癡]';
		} elsif ($ch eq '痹') {
			$vars = '[痹痺]';
		} elsif ($ch eq '痺') {
			$vars = '[痺痹]';
		} elsif ($ch eq '痾') {
			$vars = '[痾疴]';
		} elsif ($ch eq '瘅') {
			$vars = '[瘅癉]';
		} elsif ($ch eq '瘉') {
			$vars = '[瘉愈癒]';
		} elsif ($ch eq '瘋') {
			$vars = '[瘋疯]';
		} elsif ($ch eq '瘍') {
			$vars = '[瘍疡]';
		} elsif ($ch eq '瘓') {
			$vars = '[瘓痪]';
		} elsif ($ch eq '瘗') {
			$vars = '[瘗瘞]';
		} elsif ($ch eq '瘘') {
			$vars = '[瘘瘺瘻]';
		} elsif ($ch eq '瘞') {
			$vars = '[瘞瘗]';
		} elsif ($ch eq '瘡') {
			$vars = '[瘡疮]';
		} elsif ($ch eq '瘦') {
			$vars = '[瘦痩]';
		} elsif ($ch eq '瘧') {
			$vars = '[瘧疟弄]';
		} elsif ($ch eq '瘨') {
			$vars = '[瘨癲]';
		} elsif ($ch eq '瘪') {
			$vars = '[瘪癟]';
		} elsif ($ch eq '瘫') {
			$vars = '[瘫癱]';
		} elsif ($ch eq '瘺') {
			$vars = '[瘺瘻瘘]';
		} elsif ($ch eq '瘻') {
			$vars = '[瘻瘺瘘]';
		} elsif ($ch eq '瘾') {
			$vars = '[瘾癮]';
		} elsif ($ch eq '瘿') {
			$vars = '[瘿癭]';
		} elsif ($ch eq '療') {
			$vars = '[療疗]';
		} elsif ($ch eq '癆') {
			$vars = '[癆痨]';
		} elsif ($ch eq '癇') {
			$vars = '[癇痫]';
		} elsif ($ch eq '癉') {
			$vars = '[癉疸瘅]';
		} elsif ($ch eq '癒') {
			$vars = '[癒瘉愈]';
		} elsif ($ch eq '癘') {
			$vars = '[癘疠]';
		} elsif ($ch eq '癞') {
			$vars = '[癞癩]';
		} elsif ($ch eq '癟') {
			$vars = '[癟瘪]';
		} elsif ($ch eq '癡') {
			$vars = '[癡痴]';
		} elsif ($ch eq '癢') {
			$vars = '[癢痒]';
		} elsif ($ch eq '癣') {
			$vars = '[癣癬]';
		} elsif ($ch eq '癤') {
			$vars = '[癤疖]';
		} elsif ($ch eq '癥') {
			$vars = '[癥症]';
		} elsif ($ch eq '癧') {
			$vars = '[癧疬]';
		} elsif ($ch eq '癨') {
			$vars = '[癨霍]';
		} elsif ($ch eq '癩') {
			$vars = '[癩癞癩]';
		} elsif ($ch eq '癫') {
			$vars = '[癫癲]';
		} elsif ($ch eq '癬') {
			$vars = '[癬癣]';
		} elsif ($ch eq '癭') {
			$vars = '[癭瘿]';
		} elsif ($ch eq '癮') {
			$vars = '[癮瘾]';
		} elsif ($ch eq '癯') {
			$vars = '[癯臞]';
		} elsif ($ch eq '癰') {
			$vars = '[癰痈]';
		} elsif ($ch eq '癱') {
			$vars = '[癱瘫]';
		} elsif ($ch eq '癲') {
			$vars = '[癲癫瘨]';
		} elsif ($ch eq '発') {
			$vars = '[発發]';
		} elsif ($ch eq '登') {
			$vars = '[登豋]';
		} elsif ($ch eq '發') {
			$vars = '[發発发]';
		} elsif ($ch eq '百') {
			$vars = '[百佰]';
		} elsif ($ch eq '皁') {
			$vars = '[皁皂]';
		} elsif ($ch eq '皂') {
			$vars = '[皂皁]';
		} elsif ($ch eq '皃') {
			$vars = '[皃貌貎]';
		} elsif ($ch eq '皈') {
			$vars = '[皈歸]';
		} elsif ($ch eq '皋') {
			$vars = '[皋睾皐]';
		} elsif ($ch eq '皎') {
			$vars = '[皎皦]';
		} elsif ($ch eq '皐') {
			$vars = '[皐皋]';
		} elsif ($ch eq '皑') {
			$vars = '[皑皚]';
		} elsif ($ch eq '皓') {
			$vars = '[皓顥皝]';
		} elsif ($ch eq '皚') {
			$vars = '[皚皑]';
		} elsif ($ch eq '皜') {
			$vars = '[皜暠]';
		} elsif ($ch eq '皝') {
			$vars = '[皝顥皓]';
		} elsif ($ch eq '皦') {
			$vars = '[皦皎]';
		} elsif ($ch eq '皰') {
			$vars = '[皰疱]';
		} elsif ($ch eq '皱') {
			$vars = '[皱皺]';
		} elsif ($ch eq '皲') {
			$vars = '[皲皸]';
		} elsif ($ch eq '皷') {
			$vars = '[皷鼓]';
		} elsif ($ch eq '皸') {
			$vars = '[皸皲]';
		} elsif ($ch eq '皺') {
			$vars = '[皺縐皱]';
		} elsif ($ch eq '盃') {
			$vars = '[盃杯]';
		} elsif ($ch eq '盅') {
			$vars = '[盅沖]';
		} elsif ($ch eq '盏') {
			$vars = '[盏盞]';
		} elsif ($ch eq '盐') {
			$vars = '[盐鹽]';
		} elsif ($ch eq '监') {
			$vars = '[监監]';
		} elsif ($ch eq '盖') {
			$vars = '[盖蓋葢]';
		} elsif ($ch eq '盗') {
			$vars = '[盗盜]';
		} elsif ($ch eq '盘') {
			$vars = '[盘盤]';
		} elsif ($ch eq '盜') {
			$vars = '[盜盗]';
		} elsif ($ch eq '盞') {
			$vars = '[盞盏]';
		} elsif ($ch eq '盡') {
			$vars = '[盡尽]';
		} elsif ($ch eq '監') {
			$vars = '[監监]';
		} elsif ($ch eq '盤') {
			$vars = '[盤盘]';
		} elsif ($ch eq '盧') {
			$vars = '[盧卢]';
		} elsif ($ch eq '盩') {
			$vars = '[盩盭]';
		} elsif ($ch eq '盪') {
			$vars = '[盪逿荡蘯蕩]';
		} elsif ($ch eq '盭') {
			$vars = '[盭盩]';
		} elsif ($ch eq '省') {
			$vars = '[省省]';
		} elsif ($ch eq '眇') {
			$vars = '[眇緲]';
		} elsif ($ch eq '眙') {
			$vars = '[眙瞪]';
		} elsif ($ch eq '眞') {
			$vars = '[眞真]';
		} elsif ($ch eq '真') {
			$vars = '[真眞]';
		} elsif ($ch eq '眠') {
			$vars = '[眠緡]';
		} elsif ($ch eq '眥') {
			$vars = '[眥眦]';
		} elsif ($ch eq '眦') {
			$vars = '[眦眥]';
		} elsif ($ch eq '眾') {
			$vars = '[眾众衆]';
		} elsif ($ch eq '着') {
			$vars = '[着著]';
		} elsif ($ch eq '睁') {
			$vars = '[睁睜]';
		} elsif ($ch eq '睏') {
			$vars = '[睏困]';
		} elsif ($ch eq '睐') {
			$vars = '[睐睞]';
		} elsif ($ch eq '睑') {
			$vars = '[睑瞼]';
		} elsif ($ch eq '睜') {
			$vars = '[睜睁]';
		} elsif ($ch eq '睞') {
			$vars = '[睞睐]';
		} elsif ($ch eq '睹') {
			$vars = '[睹覩]';
		} elsif ($ch eq '睾') {
			$vars = '[睾皋]';
		} elsif ($ch eq '睿') {
			$vars = '[睿叡]';
		} elsif ($ch eq '瞒') {
			$vars = '[瞒瞞]';
		} elsif ($ch eq '瞞') {
			$vars = '[瞞瞒]';
		} elsif ($ch eq '瞠') {
			$vars = '[瞠瞪]';
		} elsif ($ch eq '瞥') {
			$vars = '[瞥苤]';
		} elsif ($ch eq '瞩') {
			$vars = '[瞩矚]';
		} elsif ($ch eq '瞪') {
			$vars = '[瞪瞠眙]';
		} elsif ($ch eq '瞭') {
			$vars = '[瞭了]';
		} elsif ($ch eq '瞰') {
			$vars = '[瞰矙]';
		} elsif ($ch eq '瞹') {
			$vars = '[瞹曖]';
		} elsif ($ch eq '瞼') {
			$vars = '[瞼睑]';
		} elsif ($ch eq '矇') {
			$vars = '[矇朦蒙]';
		} elsif ($ch eq '矓') {
			$vars = '[矓朧]';
		} elsif ($ch eq '矙') {
			$vars = '[矙瞰]';
		} elsif ($ch eq '矚') {
			$vars = '[矚瞩]';
		} elsif ($ch eq '矢') {
			$vars = '[矢笶]';
		} elsif ($ch eq '矩') {
			$vars = '[矩榘]';
		} elsif ($ch eq '矫') {
			$vars = '[矫矯]';
		} elsif ($ch eq '矯') {
			$vars = '[矯矫]';
		} elsif ($ch eq '矰') {
			$vars = '[矰蹭]';
		} elsif ($ch eq '矶') {
			$vars = '[矶磯]';
		} elsif ($ch eq '矾') {
			$vars = '[矾礬]';
		} elsif ($ch eq '矿') {
			$vars = '[矿礦]';
		} elsif ($ch eq '砀') {
			$vars = '[砀碭]';
		} elsif ($ch eq '码') {
			$vars = '[码碼]';
		} elsif ($ch eq '砅') {
			$vars = '[砅濿]';
		} elsif ($ch eq '砌') {
			$vars = '[砌纖]';
		} elsif ($ch eq '研') {
			$vars = '[研硎揅]';
		} elsif ($ch eq '砕') {
			$vars = '[砕碎]';
		} elsif ($ch eq '砖') {
			$vars = '[砖磚]';
		} elsif ($ch eq '砗') {
			$vars = '[砗硨]';
		} elsif ($ch eq '砚') {
			$vars = '[砚硯]';
		} elsif ($ch eq '砠') {
			$vars = '[砠岨]';
		} elsif ($ch eq '砣') {
			$vars = '[砣鉈]';
		} elsif ($ch eq '砥') {
			$vars = '[砥厎]';
		} elsif ($ch eq '砦') {
			$vars = '[砦寨]';
		} elsif ($ch eq '砧') {
			$vars = '[砧碪]';
		} elsif ($ch eq '砲') {
			$vars = '[砲炮]';
		} elsif ($ch eq '砺') {
			$vars = '[砺礪]';
		} elsif ($ch eq '砻') {
			$vars = '[砻礱]';
		} elsif ($ch eq '砾') {
			$vars = '[砾礫]';
		} elsif ($ch eq '砿') {
			$vars = '[砿礦]';
		} elsif ($ch eq '础') {
			$vars = '[础礎]';
		} elsif ($ch eq '硎') {
			$vars = '[硎研]';
		} elsif ($ch eq '硕') {
			$vars = '[硕碩]';
		} elsif ($ch eq '硖') {
			$vars = '[硖硤]';
		} elsif ($ch eq '硗') {
			$vars = '[硗磽]';
		} elsif ($ch eq '硤') {
			$vars = '[硤硖唊]';
		} elsif ($ch eq '硨') {
			$vars = '[硨砗]';
		} elsif ($ch eq '硫') {
			$vars = '[硫硫]';
		} elsif ($ch eq '硬') {
			$vars = '[硬峺應]';
		} elsif ($ch eq '确') {
			$vars = '[确確]';
		} elsif ($ch eq '硯') {
			$vars = '[硯砚]';
		} elsif ($ch eq '硷') {
			$vars = '[硷鹼]';
		} elsif ($ch eq '碁') {
			$vars = '[碁棋棊]';
		} elsif ($ch eq '碌') {
			$vars = '[碌碌]';
		} elsif ($ch eq '碍') {
			$vars = '[碍礙]';
		} elsif ($ch eq '碎') {
			$vars = '[碎砕]';
		} elsif ($ch eq '碔') {
			$vars = '[碔珷]';
		} elsif ($ch eq '碕') {
			$vars = '[碕崎]';
		} elsif ($ch eq '碗') {
			$vars = '[碗椀]';
		} elsif ($ch eq '碛') {
			$vars = '[碛磧]';
		} elsif ($ch eq '碜') {
			$vars = '[碜磣]';
		} elsif ($ch eq '碥') {
			$vars = '[碥扁]';
		} elsif ($ch eq '碩') {
			$vars = '[碩硕]';
		} elsif ($ch eq '碪') {
			$vars = '[碪砧]';
		} elsif ($ch eq '碭') {
			$vars = '[碭砀]';
		} elsif ($ch eq '碯') {
			$vars = '[碯瑙]';
		} elsif ($ch eq '碰') {
			$vars = '[碰掽]';
		} elsif ($ch eq '碱') {
			$vars = '[碱鹼]';
		} elsif ($ch eq '確') {
			$vars = '[確确]';
		} elsif ($ch eq '碼') {
			$vars = '[碼码]';
		} elsif ($ch eq '磁') {
			$vars = '[磁瓷]';
		} elsif ($ch eq '磆') {
			$vars = '[磆滑]';
		} elsif ($ch eq '磊') {
			$vars = '[磊磥磊]';
		} elsif ($ch eq '磚') {
			$vars = '[磚砖甎]';
		} elsif ($ch eq '磡') {
			$vars = '[磡墈]';
		} elsif ($ch eq '磣') {
			$vars = '[磣碜]';
		} elsif ($ch eq '磥') {
			$vars = '[磥磊]';
		} elsif ($ch eq '磧') {
			$vars = '[磧碛]';
		} elsif ($ch eq '磪') {
			$vars = '[磪崔]';
		} elsif ($ch eq '磯') {
			$vars = '[磯矶]';
		} elsif ($ch eq '磴') {
			$vars = '[磴嶝]';
		} elsif ($ch eq '磵') {
			$vars = '[磵澗]';
		} elsif ($ch eq '磻') {
			$vars = '[磻磻]';
		} elsif ($ch eq '磽') {
			$vars = '[磽硗墝]';
		} elsif ($ch eq '礎') {
			$vars = '[礎础]';
		} elsif ($ch eq '礙') {
			$vars = '[礙碍]';
		} elsif ($ch eq '礡') {
			$vars = '[礡礴]';
		} elsif ($ch eq '礦') {
			$vars = '[礦鑛矿]';
		} elsif ($ch eq '礪') {
			$vars = '[礪砺礪]';
		} elsif ($ch eq '礫') {
			$vars = '[礫砾]';
		} elsif ($ch eq '礬') {
			$vars = '[礬矾]';
		} elsif ($ch eq '礱') {
			$vars = '[礱砻]';
		} elsif ($ch eq '礴') {
			$vars = '[礴礡]';
		} elsif ($ch eq '示') {
			$vars = '[示礻]';
		} elsif ($ch eq '礻') {
			$vars = '[礻示]';
		} elsif ($ch eq '礼') {
			$vars = '[礼禮]';
		} elsif ($ch eq '礿') {
			$vars = '[礿禴]';
		} elsif ($ch eq '祇') {
			$vars = '[祇只]';
		} elsif ($ch eq '祐') {
			$vars = '[祐佑]';
		} elsif ($ch eq '祕') {
			$vars = '[祕秘]';
		} elsif ($ch eq '祗') {
			$vars = '[祗只]';
		} elsif ($ch eq '祢') {
			$vars = '[祢禰]';
		} elsif ($ch eq '祯') {
			$vars = '[祯禎]';
		} elsif ($ch eq '祷') {
			$vars = '[祷禱]';
		} elsif ($ch eq '祸') {
			$vars = '[祸禍]';
		} elsif ($ch eq '祿') {
			$vars = '[祿禄祿]';
		} elsif ($ch eq '禀') {
			$vars = '[禀稟]';
		} elsif ($ch eq '禂') {
			$vars = '[禂禱]';
		} elsif ($ch eq '禄') {
			$vars = '[禄祿]';
		} elsif ($ch eq '禅') {
			$vars = '[禅禪]';
		} elsif ($ch eq '禍') {
			$vars = '[禍祸]';
		} elsif ($ch eq '禎') {
			$vars = '[禎祯]';
		} elsif ($ch eq '禦') {
			$vars = '[禦御]';
		} elsif ($ch eq '禪') {
			$vars = '[禪禅]';
		} elsif ($ch eq '禮') {
			$vars = '[禮禮礼]';
		} elsif ($ch eq '禰') {
			$vars = '[禰祢]';
		} elsif ($ch eq '禱') {
			$vars = '[禱祷禂]';
		} elsif ($ch eq '禴') {
			$vars = '[禴礿]';
		} elsif ($ch eq '离') {
			$vars = '[离離]';
		} elsif ($ch eq '禿') {
			$vars = '[禿秃]';
		} elsif ($ch eq '私') {
			$vars = '[私厶]';
		} elsif ($ch eq '秃') {
			$vars = '[秃禿]';
		} elsif ($ch eq '秆') {
			$vars = '[秆稈]';
		} elsif ($ch eq '秈') {
			$vars = '[秈籼]';
		} elsif ($ch eq '秉') {
			$vars = '[秉拼]';
		} elsif ($ch eq '秊') {
			$vars = '[秊秊]';
		} elsif ($ch eq '秋') {
			$vars = '[秋龝]';
		} elsif ($ch eq '种') {
			$vars = '[种種]';
		} elsif ($ch eq '秏') {
			$vars = '[秏耗]';
		} elsif ($ch eq '秕') {
			$vars = '[秕粃]';
		} elsif ($ch eq '秘') {
			$vars = '[秘祕]';
		} elsif ($ch eq '秤') {
			$vars = '[秤稱]';
		} elsif ($ch eq '积') {
			$vars = '[积積]';
		} elsif ($ch eq '称') {
			$vars = '[称稱]';
		} elsif ($ch eq '移') {
			$vars = '[移迻]';
		} elsif ($ch eq '秽') {
			$vars = '[秽穢]';
		} elsif ($ch eq '稀') {
			$vars = '[稀希]';
		} elsif ($ch eq '稅') {
			$vars = '[稅税]';
		} elsif ($ch eq '稆') {
			$vars = '[稆穭]';
		} elsif ($ch eq '稈') {
			$vars = '[稈秆]';
		} elsif ($ch eq '税') {
			$vars = '[税稅]';
		} elsif ($ch eq '稘') {
			$vars = '[稘朞]';
		} elsif ($ch eq '稚') {
			$vars = '[稚穉]';
		} elsif ($ch eq '稜') {
			$vars = '[稜楞棱稜]';
		} elsif ($ch eq '稟') {
			$vars = '[稟禀廪]';
		} elsif ($ch eq '稣') {
			$vars = '[稣穌]';
		} elsif ($ch eq '種') {
			$vars = '[種种]';
		} elsif ($ch eq '稱') {
			$vars = '[稱偁称秤]';
		} elsif ($ch eq '稲') {
			$vars = '[稲稻]';
		} elsif ($ch eq '稳') {
			$vars = '[稳穩]';
		} elsif ($ch eq '稻') {
			$vars = '[稻稲]';
		} elsif ($ch eq '稽') {
			$vars = '[稽乩]';
		} elsif ($ch eq '稾') {
			$vars = '[稾稿]';
		} elsif ($ch eq '稿') {
			$vars = '[稿稾]';
		} elsif ($ch eq '穀') {
			$vars = '[穀谷]';
		} elsif ($ch eq '穂') {
			$vars = '[穂穗]';
		} elsif ($ch eq '穉') {
			$vars = '[穉稚]';
		} elsif ($ch eq '穌') {
			$vars = '[穌甦稣]';
		} elsif ($ch eq '積') {
			$vars = '[積积]';
		} elsif ($ch eq '穎') {
			$vars = '[穎颖頴署]';
		} elsif ($ch eq '穐') {
			$vars = '[穐秋]';
		} elsif ($ch eq '穑') {
			$vars = '[穑穡]';
		} elsif ($ch eq '穗') {
			$vars = '[穗穂]';
		} elsif ($ch eq '穡') {
			$vars = '[穡穑]';
		} elsif ($ch eq '穢') {
			$vars = '[穢秽]';
		} elsif ($ch eq '穣') {
			$vars = '[穣穰]';
		} elsif ($ch eq '穩') {
			$vars = '[穩稳文]';
		} elsif ($ch eq '穫') {
			$vars = '[穫获檴]';
		} elsif ($ch eq '穭') {
			$vars = '[穭稆]';
		} elsif ($ch eq '穰') {
			$vars = '[穰穣]';
		} elsif ($ch eq '穷') {
			$vars = '[穷窮]';
		} elsif ($ch eq '穽') {
			$vars = '[穽阱]';
		} elsif ($ch eq '窃') {
			$vars = '[窃竊]';
		} elsif ($ch eq '窌') {
			$vars = '[窌窖]';
		} elsif ($ch eq '窍') {
			$vars = '[窍竅]';
		} elsif ($ch eq '窑') {
			$vars = '[窑窯]';
		} elsif ($ch eq '窓') {
			$vars = '[窓窗]';
		} elsif ($ch eq '窕') {
			$vars = '[窕阿]';
		} elsif ($ch eq '窖') {
			$vars = '[窖窌]';
		} elsif ($ch eq '窗') {
			$vars = '[窗窓]';
		} elsif ($ch eq '窜') {
			$vars = '[窜竄]';
		} elsif ($ch eq '窝') {
			$vars = '[窝窩]';
		} elsif ($ch eq '窥') {
			$vars = '[窥窺]';
		} elsif ($ch eq '窦') {
			$vars = '[窦竇]';
		} elsif ($ch eq '窩') {
			$vars = '[窩窝]';
		} elsif ($ch eq '窪') {
			$vars = '[窪洼]';
		} elsif ($ch eq '窭') {
			$vars = '[窭窶]';
		} elsif ($ch eq '窮') {
			$vars = '[窮穷]';
		} elsif ($ch eq '窯') {
			$vars = '[窯窰窑]';
		} elsif ($ch eq '窰') {
			$vars = '[窰窯]';
		} elsif ($ch eq '窴') {
			$vars = '[窴塡]';
		} elsif ($ch eq '窶') {
			$vars = '[窶寠窭]';
		} elsif ($ch eq '窺') {
			$vars = '[窺窥]';
		} elsif ($ch eq '竃') {
			$vars = '[竃灶]';
		} elsif ($ch eq '竄') {
			$vars = '[竄窜]';
		} elsif ($ch eq '竅') {
			$vars = '[竅窍]';
		} elsif ($ch eq '竇') {
			$vars = '[竇窦]';
		} elsif ($ch eq '竈') {
			$vars = '[竈灶]';
		} elsif ($ch eq '竊') {
			$vars = '[竊窃]';
		} elsif ($ch eq '立') {
			$vars = '[立立]';
		} elsif ($ch eq '竒') {
			$vars = '[竒奇]';
		} elsif ($ch eq '竖') {
			$vars = '[竖豎竪]';
		} elsif ($ch eq '竚') {
			$vars = '[竚佇]';
		} elsif ($ch eq '竜') {
			$vars = '[竜龍]';
		} elsif ($ch eq '竝') {
			$vars = '[竝幷并並]';
		} elsif ($ch eq '竞') {
			$vars = '[竞競]';
		} elsif ($ch eq '竢') {
			$vars = '[竢俟]';
		} elsif ($ch eq '竪') {
			$vars = '[竪豎竖]';
		} elsif ($ch eq '競') {
			$vars = '[競竞竸]';
		} elsif ($ch eq '竸') {
			$vars = '[竸競]';
		} elsif ($ch eq '笃') {
			$vars = '[笃篤]';
		} elsif ($ch eq '笆') {
			$vars = '[笆巴]';
		} elsif ($ch eq '笋') {
			$vars = '[笋筍]';
		} elsif ($ch eq '笑') {
			$vars = '[笑咲]';
		} elsif ($ch eq '笓') {
			$vars = '[笓篦]';
		} elsif ($ch eq '笔') {
			$vars = '[笔筆]';
		} elsif ($ch eq '笕') {
			$vars = '[笕筧]';
		} elsif ($ch eq '笛') {
			$vars = '[笛篴]';
		} elsif ($ch eq '笠') {
			$vars = '[笠笠]';
		} elsif ($ch eq '笺') {
			$vars = '[笺箋]';
		} elsif ($ch eq '笻') {
			$vars = '[笻筇]';
		} elsif ($ch eq '笼') {
			$vars = '[笼籠]';
		} elsif ($ch eq '笾') {
			$vars = '[笾籩]';
		} elsif ($ch eq '筆') {
			$vars = '[筆笔]';
		} elsif ($ch eq '筇') {
			$vars = '[筇笻]';
		} elsif ($ch eq '筋') {
			$vars = '[筋觔]';
		} elsif ($ch eq '筍') {
			$vars = '[筍笋]';
		} elsif ($ch eq '筐') {
			$vars = '[筐筺]';
		} elsif ($ch eq '筑') {
			$vars = '[筑築]';
		} elsif ($ch eq '答') {
			$vars = '[答荅]';
		} elsif ($ch eq '筚') {
			$vars = '[筚篳]';
		} elsif ($ch eq '筛') {
			$vars = '[筛篩]';
		} elsif ($ch eq '筝') {
			$vars = '[筝箏]';
		} elsif ($ch eq '筦') {
			$vars = '[筦管]';
		} elsif ($ch eq '筧') {
			$vars = '[筧笕]';
		} elsif ($ch eq '筭') {
			$vars = '[筭算]';
		} elsif ($ch eq '筱') {
			$vars = '[筱篠]';
		} elsif ($ch eq '筹') {
			$vars = '[筹籌]';
		} elsif ($ch eq '签') {
			$vars = '[签籤簽]';
		} elsif ($ch eq '简') {
			$vars = '[简簡]';
		} elsif ($ch eq '箇') {
			$vars = '[箇个個]';
		} elsif ($ch eq '箋') {
			$vars = '[箋笺牋]';
		} elsif ($ch eq '箍') {
			$vars = '[箍箛]';
		} elsif ($ch eq '箎') {
			$vars = '[箎篪]';
		} elsif ($ch eq '箏') {
			$vars = '[箏筝]';
		} elsif ($ch eq '箒') {
			$vars = '[箒帚]';
		} elsif ($ch eq '箔') {
			$vars = '[箔泡]';
		} elsif ($ch eq '箖') {
			$vars = '[箖籃]';
		} elsif ($ch eq '算') {
			$vars = '[算筭]';
		} elsif ($ch eq '箚') {
			$vars = '[箚剳]';
		} elsif ($ch eq '箛') {
			$vars = '[箛箍]';
		} elsif ($ch eq '箝') {
			$vars = '[箝钳]';
		} elsif ($ch eq '箠') {
			$vars = '[箠捶]';
		} elsif ($ch eq '管') {
			$vars = '[管筦]';
		} elsif ($ch eq '箦') {
			$vars = '[箦簀]';
		} elsif ($ch eq '箧') {
			$vars = '[箧篋]';
		} elsif ($ch eq '箨') {
			$vars = '[箨籜]';
		} elsif ($ch eq '箩') {
			$vars = '[箩籮]';
		} elsif ($ch eq '箪') {
			$vars = '[箪簞]';
		} elsif ($ch eq '箫') {
			$vars = '[箫簫]';
		} elsif ($ch eq '箬') {
			$vars = '[箬篛]';
		} elsif ($ch eq '箴') {
			$vars = '[箴鍼針]';
		} elsif ($ch eq '箾') {
			$vars = '[箾簫]';
		} elsif ($ch eq '節') {
			$vars = '[節节卩]';
		} elsif ($ch eq '範') {
			$vars = '[範范]';
		} elsif ($ch eq '築') {
			$vars = '[築筑]';
		} elsif ($ch eq '篋') {
			$vars = '[篋箧]';
		} elsif ($ch eq '篑') {
			$vars = '[篑簣]';
		} elsif ($ch eq '篓') {
			$vars = '[篓簍]';
		} elsif ($ch eq '篛') {
			$vars = '[篛箬]';
		} elsif ($ch eq '篠') {
			$vars = '[篠筱]';
		} elsif ($ch eq '篡') {
			$vars = '[篡簒]';
		} elsif ($ch eq '篢') {
			$vars = '[篢槓]';
		} elsif ($ch eq '篤') {
			$vars = '[篤笃]';
		} elsif ($ch eq '篦') {
			$vars = '[篦笓]';
		} elsif ($ch eq '篩') {
			$vars = '[篩簁筛]';
		} elsif ($ch eq '篪') {
			$vars = '[篪箎]';
		} elsif ($ch eq '篭') {
			$vars = '[篭籠]';
		} elsif ($ch eq '篮') {
			$vars = '[篮籃]';
		} elsif ($ch eq '篱') {
			$vars = '[篱籬]';
		} elsif ($ch eq '篲') {
			$vars = '[篲彗]';
		} elsif ($ch eq '篳') {
			$vars = '[篳筚]';
		} elsif ($ch eq '篴') {
			$vars = '[篴笛]';
		} elsif ($ch eq '簀') {
			$vars = '[簀箦]';
		} elsif ($ch eq '簁') {
			$vars = '[簁篩]';
		} elsif ($ch eq '簍') {
			$vars = '[簍篓]';
		} elsif ($ch eq '簑') {
			$vars = '[簑蓑]';
		} elsif ($ch eq '簒') {
			$vars = '[簒篡]';
		} elsif ($ch eq '簔') {
			$vars = '[簔簑]';
		} elsif ($ch eq '簖') {
			$vars = '[簖籪]';
		} elsif ($ch eq '簞') {
			$vars = '[簞箪]';
		} elsif ($ch eq '簡') {
			$vars = '[簡简耕]';
		} elsif ($ch eq '簣') {
			$vars = '[簣篑蕢]';
		} elsif ($ch eq '簨') {
			$vars = '[簨栒]';
		} elsif ($ch eq '簫') {
			$vars = '[簫燒箫箾]';
		} elsif ($ch eq '簷') {
			$vars = '[簷檐]';
		} elsif ($ch eq '簻') {
			$vars = '[簻檛]';
		} elsif ($ch eq '簽') {
			$vars = '[簽签]';
		} elsif ($ch eq '簾') {
			$vars = '[簾帘簾]';
		} elsif ($ch eq '籁') {
			$vars = '[籁籟]';
		} elsif ($ch eq '籃') {
			$vars = '[籃箖篮]';
		} elsif ($ch eq '籌') {
			$vars = '[籌筹]';
		} elsif ($ch eq '籐') {
			$vars = '[籐藤籘]';
		} elsif ($ch eq '籔') {
			$vars = '[籔藪]';
		} elsif ($ch eq '籖') {
			$vars = '[籖籤]';
		} elsif ($ch eq '籘') {
			$vars = '[籘籐]';
		} elsif ($ch eq '籜') {
			$vars = '[籜箨]';
		} elsif ($ch eq '籟') {
			$vars = '[籟籁]';
		} elsif ($ch eq '籠') {
			$vars = '[籠笼籠]';
		} elsif ($ch eq '籤') {
			$vars = '[籤籖]';
		} elsif ($ch eq '籥') {
			$vars = '[籥龠]';
		} elsif ($ch eq '籩') {
			$vars = '[籩笾]';
		} elsif ($ch eq '籪') {
			$vars = '[籪簖]';
		} elsif ($ch eq '籬') {
			$vars = '[籬篱]';
		} elsif ($ch eq '籮') {
			$vars = '[籮箩]';
		} elsif ($ch eq '籴') {
			$vars = '[籴糴]';
		} elsif ($ch eq '类') {
			$vars = '[类類]';
		} elsif ($ch eq '籼') {
			$vars = '[籼秈]';
		} elsif ($ch eq '粃') {
			$vars = '[粃秕]';
		} elsif ($ch eq '粋') {
			$vars = '[粋粹]';
		} elsif ($ch eq '粒') {
			$vars = '[粒粒]';
		} elsif ($ch eq '粗') {
			$vars = '[粗觕麤]';
		} elsif ($ch eq '粘') {
			$vars = '[粘黏]';
		} elsif ($ch eq '粛') {
			$vars = '[粛肅]';
		} elsif ($ch eq '粜') {
			$vars = '[粜糶]';
		} elsif ($ch eq '粝') {
			$vars = '[粝糲]';
		} elsif ($ch eq '粤') {
			$vars = '[粤粵]';
		} elsif ($ch eq '粥') {
			$vars = '[粥鬻]';
		} elsif ($ch eq '粧') {
			$vars = '[粧妝]';
		} elsif ($ch eq '粪') {
			$vars = '[粪糞]';
		} elsif ($ch eq '粫') {
			$vars = '[粫糯]';
		} elsif ($ch eq '粮') {
			$vars = '[粮糧]';
		} elsif ($ch eq '粵') {
			$vars = '[粵粤]';
		} elsif ($ch eq '粹') {
			$vars = '[粹粋]';
		} elsif ($ch eq '糁') {
			$vars = '[糁糝]';
		} elsif ($ch eq '糇') {
			$vars = '[糇餱]';
		} elsif ($ch eq '糊') {
			$vars = '[糊胡]';
		} elsif ($ch eq '糖') {
			$vars = '[糖糖]';
		} elsif ($ch eq '糝') {
			$vars = '[糝糁]';
		} elsif ($ch eq '糞') {
			$vars = '[糞粪]';
		} elsif ($ch eq '糧') {
			$vars = '[糧粮]';
		} elsif ($ch eq '糯') {
			$vars = '[糯粫]';
		} elsif ($ch eq '糲') {
			$vars = '[糲粝]';
		} elsif ($ch eq '糴') {
			$vars = '[糴籴]';
		} elsif ($ch eq '糶') {
			$vars = '[糶條粜]';
		} elsif ($ch eq '糸') {
			$vars = '[糸絲]';
		} elsif ($ch eq '糺') {
			$vars = '[糺糾]';
		} elsif ($ch eq '系') {
			$vars = '[系繫係]';
		} elsif ($ch eq '糾') {
			$vars = '[糾纠糺]';
		} elsif ($ch eq '紀') {
			$vars = '[紀纪]';
		} elsif ($ch eq '紂') {
			$vars = '[紂纣]';
		} elsif ($ch eq '約') {
			$vars = '[約约]';
		} elsif ($ch eq '紅') {
			$vars = '[紅红]';
		} elsif ($ch eq '紆') {
			$vars = '[紆纡]';
		} elsif ($ch eq '紇') {
			$vars = '[紇纥]';
		} elsif ($ch eq '紈') {
			$vars = '[紈纨]';
		} elsif ($ch eq '紉') {
			$vars = '[紉纫]';
		} elsif ($ch eq '紋') {
			$vars = '[紋纹]';
		} elsif ($ch eq '納') {
			$vars = '[納纳]';
		} elsif ($ch eq '紐') {
			$vars = '[紐紐纽]';
		} elsif ($ch eq '紓') {
			$vars = '[紓纾]';
		} elsif ($ch eq '純') {
			$vars = '[純纯]';
		} elsif ($ch eq '紕') {
			$vars = '[紕纰]';
		} elsif ($ch eq '紗') {
			$vars = '[紗纱]';
		} elsif ($ch eq '紙') {
			$vars = '[紙纸帋]';
		} elsif ($ch eq '級') {
			$vars = '[級级]';
		} elsif ($ch eq '紛') {
			$vars = '[紛纷]';
		} elsif ($ch eq '紜') {
			$vars = '[紜纭]';
		} elsif ($ch eq '紟') {
			$vars = '[紟衿]';
		} elsif ($ch eq '紡') {
			$vars = '[紡纺]';
		} elsif ($ch eq '索') {
			$vars = '[索索]';
		} elsif ($ch eq '紧') {
			$vars = '[紧緊]';
		} elsif ($ch eq '紬') {
			$vars = '[紬綢]';
		} elsif ($ch eq '紮') {
			$vars = '[紮扎]';
		} elsif ($ch eq '累') {
			$vars = '[累纍]';
		} elsif ($ch eq '細') {
			$vars = '[細细]';
		} elsif ($ch eq '紱') {
			$vars = '[紱绂]';
		} elsif ($ch eq '紲') {
			$vars = '[紲绁緤]';
		} elsif ($ch eq '紳') {
			$vars = '[紳绅]';
		} elsif ($ch eq '紹') {
			$vars = '[紹绍]';
		} elsif ($ch eq '紺') {
			$vars = '[紺绀]';
		} elsif ($ch eq '紼') {
			$vars = '[紼绋]';
		} elsif ($ch eq '紿') {
			$vars = '[紿绐]';
		} elsif ($ch eq '絀') {
			$vars = '[絀绌]';
		} elsif ($ch eq '終') {
			$vars = '[終终]';
		} elsif ($ch eq '絃') {
			$vars = '[絃弦]';
		} elsif ($ch eq '組') {
			$vars = '[組组]';
		} elsif ($ch eq '絅') {
			$vars = '[絅褧]';
		} elsif ($ch eq '絆') {
			$vars = '[絆绊]';
		} elsif ($ch eq '絋') {
			$vars = '[絋纊]';
		} elsif ($ch eq '経') {
			$vars = '[経經]';
		} elsif ($ch eq '絎') {
			$vars = '[絎绗]';
		} elsif ($ch eq '絏') {
			$vars = '[絏紲]';
		} elsif ($ch eq '結') {
			$vars = '[結结揭]';
		} elsif ($ch eq '絕') {
			$vars = '[絕绝]';
		} elsif ($ch eq '絖') {
			$vars = '[絖纊]';
		} elsif ($ch eq '絛') {
			$vars = '[絛縚绦]';
		} elsif ($ch eq '絞') {
			$vars = '[絞绞]';
		} elsif ($ch eq '絡') {
			$vars = '[絡络]';
		} elsif ($ch eq '絢') {
			$vars = '[絢绚]';
		} elsif ($ch eq '絣') {
			$vars = '[絣背]';
		} elsif ($ch eq '給') {
			$vars = '[給给]';
		} elsif ($ch eq '絨') {
			$vars = '[絨绒]';
		} elsif ($ch eq '絪') {
			$vars = '[絪氤]';
		} elsif ($ch eq '統') {
			$vars = '[統统]';
		} elsif ($ch eq '絲') {
			$vars = '[絲纟丝]';
		} elsif ($ch eq '絳') {
			$vars = '[絳绛]';
		} elsif ($ch eq '絵') {
			$vars = '[絵繪]';
		} elsif ($ch eq '絶') {
			$vars = '[絶絕绝]';
		} elsif ($ch eq '絷') {
			$vars = '[絷縶]';
		} elsif ($ch eq '絹') {
			$vars = '[絹绢]';
		} elsif ($ch eq '綁') {
			$vars = '[綁绑]';
		} elsif ($ch eq '綃') {
			$vars = '[綃绡]';
		} elsif ($ch eq '綆') {
			$vars = '[綆绠]';
		} elsif ($ch eq '綈') {
			$vars = '[綈绨]';
		} elsif ($ch eq '綉') {
			$vars = '[綉繡绣]';
		} elsif ($ch eq '綏') {
			$vars = '[綏绥]';
		} elsif ($ch eq '綑') {
			$vars = '[綑捆]';
		} elsif ($ch eq '經') {
			$vars = '[經经経]';
		} elsif ($ch eq '継') {
			$vars = '[継繼]';
		} elsif ($ch eq '続') {
			$vars = '[続續]';
		} elsif ($ch eq '綜') {
			$vars = '[綜综]';
		} elsif ($ch eq '綞') {
			$vars = '[綞缍]';
		} elsif ($ch eq '綠') {
			$vars = '[綠绿氯綠]';
		} elsif ($ch eq '綢') {
			$vars = '[綢绸紬]';
		} elsif ($ch eq '綣') {
			$vars = '[綣绻]';
		} elsif ($ch eq '綫') {
			$vars = '[綫线線]';
		} elsif ($ch eq '綬') {
			$vars = '[綬绶]';
		} elsif ($ch eq '維') {
			$vars = '[維维]';
		} elsif ($ch eq '綰') {
			$vars = '[綰绾]';
		} elsif ($ch eq '綱') {
			$vars = '[綱纲]';
		} elsif ($ch eq '網') {
			$vars = '[網网]';
		} elsif ($ch eq '綴') {
			$vars = '[綴缀]';
		} elsif ($ch eq '綸') {
			$vars = '[綸纶]';
		} elsif ($ch eq '綹') {
			$vars = '[綹绺]';
		} elsif ($ch eq '綺') {
			$vars = '[綺绮]';
		} elsif ($ch eq '綻') {
			$vars = '[綻绽]';
		} elsif ($ch eq '綽') {
			$vars = '[綽绰]';
		} elsif ($ch eq '綾') {
			$vars = '[綾绫]';
		} elsif ($ch eq '綿') {
			$vars = '[綿绵緜]';
		} elsif ($ch eq '緄') {
			$vars = '[緄绲]';
		} elsif ($ch eq '緇') {
			$vars = '[緇缁]';
		} elsif ($ch eq '緊') {
			$vars = '[緊紧]';
		} elsif ($ch eq '緋') {
			$vars = '[緋绯]';
		} elsif ($ch eq '総') {
			$vars = '[総總]';
		} elsif ($ch eq '緑') {
			$vars = '[緑绿綠]';
		} elsif ($ch eq '緒') {
			$vars = '[緒緖绪]';
		} elsif ($ch eq '緖') {
			$vars = '[緖緒]';
		} elsif ($ch eq '緗') {
			$vars = '[緗缃]';
		} elsif ($ch eq '緘') {
			$vars = '[緘缄]';
		} elsif ($ch eq '緙') {
			$vars = '[緙缂]';
		} elsif ($ch eq '線') {
			$vars = '[線线綫]';
		} elsif ($ch eq '緜') {
			$vars = '[緜綿]';
		} elsif ($ch eq '緝') {
			$vars = '[緝缉]';
		} elsif ($ch eq '緞') {
			$vars = '[緞缎]';
		} elsif ($ch eq '締') {
			$vars = '[締缔]';
		} elsif ($ch eq '緡') {
			$vars = '[緡眠缗]';
		} elsif ($ch eq '緣') {
			$vars = '[緣缘縁]';
		} elsif ($ch eq '緤') {
			$vars = '[緤紲]';
		} elsif ($ch eq '緦') {
			$vars = '[緦缌]';
		} elsif ($ch eq '編') {
			$vars = '[編编]';
		} elsif ($ch eq '緩') {
			$vars = '[緩缓]';
		} elsif ($ch eq '緬') {
			$vars = '[緬缅]';
		} elsif ($ch eq '緯') {
			$vars = '[緯纬]';
		} elsif ($ch eq '緱') {
			$vars = '[緱缑]';
		} elsif ($ch eq '緲') {
			$vars = '[緲缈眇]';
		} elsif ($ch eq '練') {
			$vars = '[練练]';
		} elsif ($ch eq '緶') {
			$vars = '[緶缏]';
		} elsif ($ch eq '緹') {
			$vars = '[緹缇]';
		} elsif ($ch eq '緻') {
			$vars = '[緻致]';
		} elsif ($ch eq '縁') {
			$vars = '[縁緣]';
		} elsif ($ch eq '縄') {
			$vars = '[縄繩]';
		} elsif ($ch eq '縈') {
			$vars = '[縈萦]';
		} elsif ($ch eq '縉') {
			$vars = '[縉缙]';
		} elsif ($ch eq '縊') {
			$vars = '[縊缢]';
		} elsif ($ch eq '縋') {
			$vars = '[縋缒]';
		} elsif ($ch eq '縐') {
			$vars = '[縐皺绉]';
		} elsif ($ch eq '縑') {
			$vars = '[縑缣]';
		} elsif ($ch eq '縕') {
			$vars = '[縕韞]';
		} elsif ($ch eq '縚') {
			$vars = '[縚絛]';
		} elsif ($ch eq '縛') {
			$vars = '[縛缚]';
		} elsif ($ch eq '縝') {
			$vars = '[縝缜]';
		} elsif ($ch eq '縞') {
			$vars = '[縞缟]';
		} elsif ($ch eq '縟') {
			$vars = '[縟缛溽]';
		} elsif ($ch eq '縣') {
			$vars = '[縣县]';
		} elsif ($ch eq '縦') {
			$vars = '[縦縱]';
		} elsif ($ch eq '縫') {
			$vars = '[縫缝]';
		} elsif ($ch eq '縭') {
			$vars = '[縭褵缡]';
		} elsif ($ch eq '縮') {
			$vars = '[縮缩]';
		} elsif ($ch eq '縱') {
			$vars = '[縱纵]';
		} elsif ($ch eq '縲') {
			$vars = '[縲缧]';
		} elsif ($ch eq '縴') {
			$vars = '[縴纤]';
		} elsif ($ch eq '縵') {
			$vars = '[縵缦]';
		} elsif ($ch eq '縶') {
			$vars = '[縶絷]';
		} elsif ($ch eq '縷') {
			$vars = '[縷缕]';
		} elsif ($ch eq '縹') {
			$vars = '[縹缥]';
		} elsif ($ch eq '總') {
			$vars = '[總摠総总]';
		} elsif ($ch eq '績') {
			$vars = '[績绩]';
		} elsif ($ch eq '繃') {
			$vars = '[繃绷]';
		} elsif ($ch eq '繅') {
			$vars = '[繅缫繰]';
		} elsif ($ch eq '繆') {
			$vars = '[繆缪]';
		} elsif ($ch eq '繈') {
			$vars = '[繈繦襁]';
		} elsif ($ch eq '繊') {
			$vars = '[繊纖]';
		} elsif ($ch eq '繋') {
			$vars = '[繋繫]';
		} elsif ($ch eq '繍') {
			$vars = '[繍繡]';
		} elsif ($ch eq '繒') {
			$vars = '[繒缯]';
		} elsif ($ch eq '織') {
			$vars = '[織织]';
		} elsif ($ch eq '繕') {
			$vars = '[繕缮]';
		} elsif ($ch eq '繖') {
			$vars = '[繖傘]';
		} elsif ($ch eq '繙') {
			$vars = '[繙翻]';
		} elsif ($ch eq '繚') {
			$vars = '[繚缭]';
		} elsif ($ch eq '繞') {
			$vars = '[繞绕遶]';
		} elsif ($ch eq '繡') {
			$vars = '[繡繍绣綉]';
		} elsif ($ch eq '繢') {
			$vars = '[繢缋繪]';
		} elsif ($ch eq '繦') {
			$vars = '[繦繈襁]';
		} elsif ($ch eq '繩') {
			$vars = '[繩绳縄]';
		} elsif ($ch eq '繪') {
			$vars = '[繪缋绘繢]';
		} elsif ($ch eq '繫') {
			$vars = '[繫系繋]';
		} elsif ($ch eq '繭') {
			$vars = '[繭茧]';
		} elsif ($ch eq '繯') {
			$vars = '[繯缳]';
		} elsif ($ch eq '繰') {
			$vars = '[繰缲繅]';
		} elsif ($ch eq '繲') {
			$vars = '[繲挫]';
		} elsif ($ch eq '繳') {
			$vars = '[繳缴]';
		} elsif ($ch eq '繹') {
			$vars = '[繹绎]';
		} elsif ($ch eq '繼') {
			$vars = '[繼继]';
		} elsif ($ch eq '繽') {
			$vars = '[繽缤]';
		} elsif ($ch eq '繾') {
			$vars = '[繾缱]';
		} elsif ($ch eq '繿') {
			$vars = '[繿襤]';
		} elsif ($ch eq '纂') {
			$vars = '[纂臇]';
		} elsif ($ch eq '纈') {
			$vars = '[纈缬]';
		} elsif ($ch eq '纉') {
			$vars = '[纉纘]';
		} elsif ($ch eq '纊') {
			$vars = '[纊絋纩絖]';
		} elsif ($ch eq '續') {
			$vars = '[續续]';
		} elsif ($ch eq '纍') {
			$vars = '[纍累]';
		} elsif ($ch eq '纎') {
			$vars = '[纎纖]';
		} elsif ($ch eq '纏') {
			$vars = '[纏缠]';
		} elsif ($ch eq '纒') {
			$vars = '[纒纏]';
		} elsif ($ch eq '纓') {
			$vars = '[纓缨]';
		} elsif ($ch eq '纔') {
			$vars = '[纔才]';
		} elsif ($ch eq '纖') {
			$vars = '[纖纎纤砌]';
		} elsif ($ch eq '纘') {
			$vars = '[纘缵纉]';
		} elsif ($ch eq '纜') {
			$vars = '[纜缆]';
		} elsif ($ch eq '纠') {
			$vars = '[纠糾]';
		} elsif ($ch eq '纡') {
			$vars = '[纡紆]';
		} elsif ($ch eq '红') {
			$vars = '[红紅]';
		} elsif ($ch eq '纣') {
			$vars = '[纣紂]';
		} elsif ($ch eq '纤') {
			$vars = '[纤縴纖]';
		} elsif ($ch eq '纥') {
			$vars = '[纥紇]';
		} elsif ($ch eq '约') {
			$vars = '[约約]';
		} elsif ($ch eq '级') {
			$vars = '[级級]';
		} elsif ($ch eq '纨') {
			$vars = '[纨紈]';
		} elsif ($ch eq '纩') {
			$vars = '[纩纊]';
		} elsif ($ch eq '纪') {
			$vars = '[纪紀]';
		} elsif ($ch eq '纫') {
			$vars = '[纫紉]';
		} elsif ($ch eq '纬') {
			$vars = '[纬緯]';
		} elsif ($ch eq '纭') {
			$vars = '[纭紜]';
		} elsif ($ch eq '纯') {
			$vars = '[纯純]';
		} elsif ($ch eq '纰') {
			$vars = '[纰紕]';
		} elsif ($ch eq '纱') {
			$vars = '[纱紗]';
		} elsif ($ch eq '纲') {
			$vars = '[纲綱]';
		} elsif ($ch eq '纳') {
			$vars = '[纳納]';
		} elsif ($ch eq '纵') {
			$vars = '[纵縱]';
		} elsif ($ch eq '纶') {
			$vars = '[纶綸]';
		} elsif ($ch eq '纷') {
			$vars = '[纷紛]';
		} elsif ($ch eq '纸') {
			$vars = '[纸紙]';
		} elsif ($ch eq '纹') {
			$vars = '[纹紋]';
		} elsif ($ch eq '纺') {
			$vars = '[纺紡]';
		} elsif ($ch eq '纽') {
			$vars = '[纽紐]';
		} elsif ($ch eq '纾') {
			$vars = '[纾紓]';
		} elsif ($ch eq '线') {
			$vars = '[线綫線]';
		} elsif ($ch eq '绀') {
			$vars = '[绀紺]';
		} elsif ($ch eq '绁') {
			$vars = '[绁紲]';
		} elsif ($ch eq '绂') {
			$vars = '[绂紱]';
		} elsif ($ch eq '练') {
			$vars = '[练練]';
		} elsif ($ch eq '组') {
			$vars = '[组組]';
		} elsif ($ch eq '绅') {
			$vars = '[绅紳]';
		} elsif ($ch eq '细') {
			$vars = '[细細]';
		} elsif ($ch eq '织') {
			$vars = '[织織]';
		} elsif ($ch eq '终') {
			$vars = '[终終]';
		} elsif ($ch eq '绉') {
			$vars = '[绉縐]';
		} elsif ($ch eq '绊') {
			$vars = '[绊絆]';
		} elsif ($ch eq '绋') {
			$vars = '[绋紼]';
		} elsif ($ch eq '绌') {
			$vars = '[绌絀]';
		} elsif ($ch eq '绍') {
			$vars = '[绍紹]';
		} elsif ($ch eq '绎') {
			$vars = '[绎繹]';
		} elsif ($ch eq '经') {
			$vars = '[经經]';
		} elsif ($ch eq '绐') {
			$vars = '[绐紿]';
		} elsif ($ch eq '绑') {
			$vars = '[绑綁]';
		} elsif ($ch eq '绒') {
			$vars = '[绒絨]';
		} elsif ($ch eq '结') {
			$vars = '[结結]';
		} elsif ($ch eq '绔') {
			$vars = '[绔褲]';
		} elsif ($ch eq '绕') {
			$vars = '[绕繞]';
		} elsif ($ch eq '绗') {
			$vars = '[绗絎]';
		} elsif ($ch eq '绘') {
			$vars = '[绘繪]';
		} elsif ($ch eq '给') {
			$vars = '[给給]';
		} elsif ($ch eq '绚') {
			$vars = '[绚絢]';
		} elsif ($ch eq '绛') {
			$vars = '[绛絳]';
		} elsif ($ch eq '络') {
			$vars = '[络絡]';
		} elsif ($ch eq '绝') {
			$vars = '[绝絕絶]';
		} elsif ($ch eq '绞') {
			$vars = '[绞絞]';
		} elsif ($ch eq '统') {
			$vars = '[统統]';
		} elsif ($ch eq '绠') {
			$vars = '[绠綆]';
		} elsif ($ch eq '绡') {
			$vars = '[绡綃]';
		} elsif ($ch eq '绢') {
			$vars = '[绢絹]';
		} elsif ($ch eq '绣') {
			$vars = '[绣繡綉]';
		} elsif ($ch eq '绥') {
			$vars = '[绥綏]';
		} elsif ($ch eq '绦') {
			$vars = '[绦絛]';
		} elsif ($ch eq '继') {
			$vars = '[继繼]';
		} elsif ($ch eq '绨') {
			$vars = '[绨綈]';
		} elsif ($ch eq '绩') {
			$vars = '[绩績]';
		} elsif ($ch eq '绪') {
			$vars = '[绪緒]';
		} elsif ($ch eq '绫') {
			$vars = '[绫綾]';
		} elsif ($ch eq '续') {
			$vars = '[续續]';
		} elsif ($ch eq '绮') {
			$vars = '[绮綺]';
		} elsif ($ch eq '绯') {
			$vars = '[绯緋]';
		} elsif ($ch eq '绰') {
			$vars = '[绰綽]';
		} elsif ($ch eq '绱') {
			$vars = '[绱鞝]';
		} elsif ($ch eq '绲') {
			$vars = '[绲緄]';
		} elsif ($ch eq '绳') {
			$vars = '[绳繩]';
		} elsif ($ch eq '维') {
			$vars = '[维維]';
		} elsif ($ch eq '绵') {
			$vars = '[绵綿]';
		} elsif ($ch eq '绶') {
			$vars = '[绶綬]';
		} elsif ($ch eq '绷') {
			$vars = '[绷繃]';
		} elsif ($ch eq '绸') {
			$vars = '[绸綢]';
		} elsif ($ch eq '绺') {
			$vars = '[绺綹]';
		} elsif ($ch eq '绻') {
			$vars = '[绻綣]';
		} elsif ($ch eq '综') {
			$vars = '[综綜]';
		} elsif ($ch eq '绽') {
			$vars = '[绽綻]';
		} elsif ($ch eq '绾') {
			$vars = '[绾綰]';
		} elsif ($ch eq '绿') {
			$vars = '[绿綠緑]';
		} elsif ($ch eq '缀') {
			$vars = '[缀綴]';
		} elsif ($ch eq '缁') {
			$vars = '[缁緇]';
		} elsif ($ch eq '缂') {
			$vars = '[缂緙]';
		} elsif ($ch eq '缃') {
			$vars = '[缃緗]';
		} elsif ($ch eq '缄') {
			$vars = '[缄緘]';
		} elsif ($ch eq '缅') {
			$vars = '[缅緬]';
		} elsif ($ch eq '缆') {
			$vars = '[缆纜]';
		} elsif ($ch eq '缇') {
			$vars = '[缇緹]';
		} elsif ($ch eq '缈') {
			$vars = '[缈緲]';
		} elsif ($ch eq '缉') {
			$vars = '[缉緝]';
		} elsif ($ch eq '缋') {
			$vars = '[缋繪繢]';
		} elsif ($ch eq '缌') {
			$vars = '[缌緦]';
		} elsif ($ch eq '缍') {
			$vars = '[缍綞]';
		} elsif ($ch eq '缎') {
			$vars = '[缎緞]';
		} elsif ($ch eq '缏') {
			$vars = '[缏緶]';
		} elsif ($ch eq '缑') {
			$vars = '[缑緱]';
		} elsif ($ch eq '缒') {
			$vars = '[缒縋]';
		} elsif ($ch eq '缓') {
			$vars = '[缓緩]';
		} elsif ($ch eq '缔') {
			$vars = '[缔締]';
		} elsif ($ch eq '缕') {
			$vars = '[缕縷]';
		} elsif ($ch eq '编') {
			$vars = '[编編]';
		} elsif ($ch eq '缗') {
			$vars = '[缗緡]';
		} elsif ($ch eq '缘') {
			$vars = '[缘緣]';
		} elsif ($ch eq '缙') {
			$vars = '[缙縉]';
		} elsif ($ch eq '缚') {
			$vars = '[缚縛]';
		} elsif ($ch eq '缛') {
			$vars = '[缛縟]';
		} elsif ($ch eq '缜') {
			$vars = '[缜縝]';
		} elsif ($ch eq '缝') {
			$vars = '[缝縫]';
		} elsif ($ch eq '缟') {
			$vars = '[缟縞]';
		} elsif ($ch eq '缠') {
			$vars = '[缠纏]';
		} elsif ($ch eq '缡') {
			$vars = '[缡縭]';
		} elsif ($ch eq '缢') {
			$vars = '[缢縊]';
		} elsif ($ch eq '缣') {
			$vars = '[缣縑]';
		} elsif ($ch eq '缤') {
			$vars = '[缤繽]';
		} elsif ($ch eq '缥') {
			$vars = '[缥縹]';
		} elsif ($ch eq '缦') {
			$vars = '[缦縵]';
		} elsif ($ch eq '缧') {
			$vars = '[缧縲]';
		} elsif ($ch eq '缨') {
			$vars = '[缨纓]';
		} elsif ($ch eq '缩') {
			$vars = '[缩縮]';
		} elsif ($ch eq '缪') {
			$vars = '[缪繆]';
		} elsif ($ch eq '缫') {
			$vars = '[缫繅]';
		} elsif ($ch eq '缬') {
			$vars = '[缬纈]';
		} elsif ($ch eq '缭') {
			$vars = '[缭繚]';
		} elsif ($ch eq '缮') {
			$vars = '[缮繕]';
		} elsif ($ch eq '缯') {
			$vars = '[缯繒]';
		} elsif ($ch eq '缰') {
			$vars = '[缰韁]';
		} elsif ($ch eq '缱') {
			$vars = '[缱繾]';
		} elsif ($ch eq '缲') {
			$vars = '[缲繰]';
		} elsif ($ch eq '缳') {
			$vars = '[缳繯]';
		} elsif ($ch eq '缴') {
			$vars = '[缴繳]';
		} elsif ($ch eq '缵') {
			$vars = '[缵纘]';
		} elsif ($ch eq '缶') {
			$vars = '[缶罐]';
		} elsif ($ch eq '缸') {
			$vars = '[缸堈]';
		} elsif ($ch eq '缺') {
			$vars = '[缺欠]';
		} elsif ($ch eq '缽') {
			$vars = '[缽鉢钵]';
		} elsif ($ch eq '缾') {
			$vars = '[缾瓶]';
		} elsif ($ch eq '罂') {
			$vars = '[罂罌]';
		} elsif ($ch eq '罃') {
			$vars = '[罃罌甖]';
		} elsif ($ch eq '罈') {
			$vars = '[罈坛壜]';
		} elsif ($ch eq '罋') {
			$vars = '[罋甕瓮]';
		} elsif ($ch eq '罌') {
			$vars = '[罌罂甖罃]';
		} elsif ($ch eq '罐') {
			$vars = '[罐缶]';
		} elsif ($ch eq '网') {
			$vars = '[网罔網]';
		} elsif ($ch eq '罔') {
			$vars = '[罔网]';
		} elsif ($ch eq '罗') {
			$vars = '[罗羅囉]';
		} elsif ($ch eq '罘') {
			$vars = '[罘罦]';
		} elsif ($ch eq '罚') {
			$vars = '[罚罰]';
		} elsif ($ch eq '罢') {
			$vars = '[罢罷]';
		} elsif ($ch eq '罥') {
			$vars = '[罥羂]';
		} elsif ($ch eq '置') {
			$vars = '[置寘]';
		} elsif ($ch eq '罰') {
			$vars = '[罰罸罚]';
		} elsif ($ch eq '署') {
			$vars = '[署穎]';
		} elsif ($ch eq '罴') {
			$vars = '[罴羆]';
		} elsif ($ch eq '罵') {
			$vars = '[罵傌骂]';
		} elsif ($ch eq '罷') {
			$vars = '[罷罢]';
		} elsif ($ch eq '罹') {
			$vars = '[罹罹]';
		} elsif ($ch eq '羁') {
			$vars = '[羁羈]';
		} elsif ($ch eq '羂') {
			$vars = '[羂罥]';
		} elsif ($ch eq '羃') {
			$vars = '[羃冪]';
		} elsif ($ch eq '羅') {
			$vars = '[羅羅罗]';
		} elsif ($ch eq '羆') {
			$vars = '[羆罴]';
		} elsif ($ch eq '羇') {
			$vars = '[羇羈]';
		} elsif ($ch eq '羈') {
			$vars = '[羈羁覊]';
		} elsif ($ch eq '羋') {
			$vars = '[羋芈]';
		} elsif ($ch eq '羚') {
			$vars = '[羚羚]';
		} elsif ($ch eq '羝') {
			$vars = '[羝牴]';
		} elsif ($ch eq '羟') {
			$vars = '[羟羥]';
		} elsif ($ch eq '羡') {
			$vars = '[羡羨]';
		} elsif ($ch eq '羣') {
			$vars = '[羣群]';
		} elsif ($ch eq '群') {
			$vars = '[群羣]';
		} elsif ($ch eq '羥') {
			$vars = '[羥羟]';
		} elsif ($ch eq '羨') {
			$vars = '[羨羡]';
		} elsif ($ch eq '義') {
			$vars = '[義义]';
		} elsif ($ch eq '羮') {
			$vars = '[羮羹]';
		} elsif ($ch eq '羶') {
			$vars = '[羶膻]';
		} elsif ($ch eq '羹') {
			$vars = '[羹羮]';
		} elsif ($ch eq '翆') {
			$vars = '[翆翠]';
		} elsif ($ch eq '習') {
			$vars = '[習习]';
		} elsif ($ch eq '翘') {
			$vars = '[翘翹]';
		} elsif ($ch eq '翠') {
			$vars = '[翠翆]';
		} elsif ($ch eq '翦') {
			$vars = '[翦剪]';
		} elsif ($ch eq '翹') {
			$vars = '[翹翘]';
		} elsif ($ch eq '翻') {
			$vars = '[翻繙]';
		} elsif ($ch eq '翼') {
			$vars = '[翼折]';
		} elsif ($ch eq '耀') {
			$vars = '[耀燿曜]';
		} elsif ($ch eq '考') {
			$vars = '[考攷]';
		} elsif ($ch eq '耏') {
			$vars = '[耏耐]';
		} elsif ($ch eq '耐') {
			$vars = '[耐耏]';
		} elsif ($ch eq '耑') {
			$vars = '[耑專]';
		} elsif ($ch eq '耒') {
			$vars = '[耒來]';
		} elsif ($ch eq '耕') {
			$vars = '[耕簡畊]';
		} elsif ($ch eq '耗') {
			$vars = '[耗秏]';
		} elsif ($ch eq '耙') {
			$vars = '[耙鈀]';
		} elsif ($ch eq '耡') {
			$vars = '[耡鋤]';
		} elsif ($ch eq '耤') {
			$vars = '[耤藉]';
		} elsif ($ch eq '耧') {
			$vars = '[耧耬]';
		} elsif ($ch eq '耨') {
			$vars = '[耨鎒]';
		} elsif ($ch eq '耬') {
			$vars = '[耬耧]';
		} elsif ($ch eq '耰') {
			$vars = '[耰櫌]';
		} elsif ($ch eq '耸') {
			$vars = '[耸聳]';
		} elsif ($ch eq '耻') {
			$vars = '[耻恥]';
		} elsif ($ch eq '耿') {
			$vars = '[耿炅]';
		} elsif ($ch eq '聂') {
			$vars = '[聂聶]';
		} elsif ($ch eq '聆') {
			$vars = '[聆聆]';
		} elsif ($ch eq '聋') {
			$vars = '[聋聾]';
		} elsif ($ch eq '职') {
			$vars = '[职職]';
		} elsif ($ch eq '聍') {
			$vars = '[聍聹]';
		} elsif ($ch eq '联') {
			$vars = '[联聯]';
		} elsif ($ch eq '聖') {
			$vars = '[聖堊圣]';
		} elsif ($ch eq '聝') {
			$vars = '[聝馘]';
		} elsif ($ch eq '聞') {
			$vars = '[聞闻]';
		} elsif ($ch eq '聟') {
			$vars = '[聟婿]';
		} elsif ($ch eq '聡') {
			$vars = '[聡聰]';
		} elsif ($ch eq '聨') {
			$vars = '[聨聯]';
		} elsif ($ch eq '聩') {
			$vars = '[聩聵]';
		} elsif ($ch eq '聪') {
			$vars = '[聪聰]';
		} elsif ($ch eq '聯') {
			$vars = '[聯聨联]';
		} elsif ($ch eq '聰') {
			$vars = '[聰聪聡]';
		} elsif ($ch eq '聲') {
			$vars = '[聲声]';
		} elsif ($ch eq '聳') {
			$vars = '[聳耸]';
		} elsif ($ch eq '聴') {
			$vars = '[聴聽]';
		} elsif ($ch eq '聵') {
			$vars = '[聵聩]';
		} elsif ($ch eq '聶') {
			$vars = '[聶聂]';
		} elsif ($ch eq '職') {
			$vars = '[職职]';
		} elsif ($ch eq '聹') {
			$vars = '[聹聍]';
		} elsif ($ch eq '聽') {
			$vars = '[聽听]';
		} elsif ($ch eq '聾') {
			$vars = '[聾聾聋]';
		} elsif ($ch eq '聿') {
			$vars = '[聿肀]';
		} elsif ($ch eq '肀') {
			$vars = '[肀聿]';
		} elsif ($ch eq '肃') {
			$vars = '[肃肅]';
		} elsif ($ch eq '肅') {
			$vars = '[肅粛肃]';
		} elsif ($ch eq '肆') {
			$vars = '[肆四]';
		} elsif ($ch eq '肉') {
			$vars = '[肉宍]';
		} elsif ($ch eq '肋') {
			$vars = '[肋肋]';
		} elsif ($ch eq '肐') {
			$vars = '[肐胳]';
		} elsif ($ch eq '肕') {
			$vars = '[肕韌]';
		} elsif ($ch eq '肠') {
			$vars = '[肠腸]';
		} elsif ($ch eq '肢') {
			$vars = '[肢胑]';
		} elsif ($ch eq '肤') {
			$vars = '[肤膚]';
		} elsif ($ch eq '肬') {
			$vars = '[肬疣]';
		} elsif ($ch eq '肮') {
			$vars = '[肮骯]';
		} elsif ($ch eq '育') {
			$vars = '[育毓]';
		} elsif ($ch eq '肴') {
			$vars = '[肴餚]';
		} elsif ($ch eq '肾') {
			$vars = '[肾腎]';
		} elsif ($ch eq '肿') {
			$vars = '[肿腫]';
		} elsif ($ch eq '胀') {
			$vars = '[胀脹]';
		} elsif ($ch eq '胁') {
			$vars = '[胁脅]';
		} elsif ($ch eq '胄') {
			$vars = '[胄冑]';
		} elsif ($ch eq '胆') {
			$vars = '[胆膽]';
		} elsif ($ch eq '胊') {
			$vars = '[胊朐]';
		} elsif ($ch eq '背') {
			$vars = '[背絣]';
		} elsif ($ch eq '胑') {
			$vars = '[胑肢]';
		} elsif ($ch eq '胔') {
			$vars = '[胔骴]';
		} elsif ($ch eq '胗') {
			$vars = '[胗疹]';
		} elsif ($ch eq '胜') {
			$vars = '[胜勝]';
		} elsif ($ch eq '胝') {
			$vars = '[胝郅]';
		} elsif ($ch eq '胞') {
			$vars = '[胞脬]';
		} elsif ($ch eq '胡') {
			$vars = '[胡楜鬍衚]';
		} elsif ($ch eq '胧') {
			$vars = '[胧朧]';
		} elsif ($ch eq '胪') {
			$vars = '[胪臚]';
		} elsif ($ch eq '胫') {
			$vars = '[胫脛]';
		} elsif ($ch eq '胭') {
			$vars = '[胭臙]';
		} elsif ($ch eq '胯') {
			$vars = '[胯骻]';
		} elsif ($ch eq '胳') {
			$vars = '[胳肐]';
		} elsif ($ch eq '胶') {
			$vars = '[胶膠]';
		} elsif ($ch eq '胸') {
			$vars = '[胸匈]';
		} elsif ($ch eq '脅') {
			$vars = '[脅脇胁勰]';
		} elsif ($ch eq '脇') {
			$vars = '[脇脅]';
		} elsif ($ch eq '脈') {
			$vars = '[脈脉]';
		} elsif ($ch eq '脉') {
			$vars = '[脉脈]';
		} elsif ($ch eq '脍') {
			$vars = '[脍膾]';
		} elsif ($ch eq '脏') {
			$vars = '[脏臟髒]';
		} elsif ($ch eq '脐') {
			$vars = '[脐臍]';
		} elsif ($ch eq '脑') {
			$vars = '[脑腦]';
		} elsif ($ch eq '脓') {
			$vars = '[脓膿]';
		} elsif ($ch eq '脔') {
			$vars = '[脔臠]';
		} elsif ($ch eq '脚') {
			$vars = '[脚腳]';
		} elsif ($ch eq '脛') {
			$vars = '[脛胫]';
		} elsif ($ch eq '脣') {
			$vars = '[脣唇]';
		} elsif ($ch eq '脧') {
			$vars = '[脧朘]';
		} elsif ($ch eq '脫') {
			$vars = '[脫脱]';
		} elsif ($ch eq '脬') {
			$vars = '[脬胞]';
		} elsif ($ch eq '脱') {
			$vars = '[脱脫]';
		} elsif ($ch eq '脲') {
			$vars = '[脲尿]';
		} elsif ($ch eq '脳') {
			$vars = '[脳腦]';
		} elsif ($ch eq '脶') {
			$vars = '[脶腡]';
		} elsif ($ch eq '脸') {
			$vars = '[脸臉]';
		} elsif ($ch eq '脹') {
			$vars = '[脹胀]';
		} elsif ($ch eq '腊') {
			$vars = '[腊臈臘]';
		} elsif ($ch eq '腌') {
			$vars = '[腌骯]';
		} elsif ($ch eq '腎') {
			$vars = '[腎肾]';
		} elsif ($ch eq '腟') {
			$vars = '[腟膣]';
		} elsif ($ch eq '腡') {
			$vars = '[腡脶]';
		} elsif ($ch eq '腦') {
			$vars = '[腦脑]';
		} elsif ($ch eq '腫') {
			$vars = '[腫肿尰]';
		} elsif ($ch eq '腭') {
			$vars = '[腭齶]';
		} elsif ($ch eq '腮') {
			$vars = '[腮顋]';
		} elsif ($ch eq '腳') {
			$vars = '[腳脚]';
		} elsif ($ch eq '腸') {
			$vars = '[腸肠膓]';
		} elsif ($ch eq '腻') {
			$vars = '[腻膩]';
		} elsif ($ch eq '腼') {
			$vars = '[腼靦]';
		} elsif ($ch eq '腽') {
			$vars = '[腽膃]';
		} elsif ($ch eq '腾') {
			$vars = '[腾騰]';
		} elsif ($ch eq '膃') {
			$vars = '[膃腽]';
		} elsif ($ch eq '膆') {
			$vars = '[膆嗉]';
		} elsif ($ch eq '膋') {
			$vars = '[膋膫]';
		} elsif ($ch eq '膑') {
			$vars = '[膑臏]';
		} elsif ($ch eq '膘') {
			$vars = '[膘臕]';
		} elsif ($ch eq '膚') {
			$vars = '[膚肤]';
		} elsif ($ch eq '膠') {
			$vars = '[膠胶]';
		} elsif ($ch eq '膣') {
			$vars = '[膣腟]';
		} elsif ($ch eq '膩') {
			$vars = '[膩腻]';
		} elsif ($ch eq '膫') {
			$vars = '[膫膋]';
		} elsif ($ch eq '膳') {
			$vars = '[膳饍]';
		} elsif ($ch eq '膸') {
			$vars = '[膸髓]';
		} elsif ($ch eq '膻') {
			$vars = '[膻羶]';
		} elsif ($ch eq '膽') {
			$vars = '[膽胆]';
		} elsif ($ch eq '膾') {
			$vars = '[膾鱠脍]';
		} elsif ($ch eq '膿') {
			$vars = '[膿脓]';
		} elsif ($ch eq '臇') {
			$vars = '[臇纂]';
		} elsif ($ch eq '臈') {
			$vars = '[臈臘腊]';
		} elsif ($ch eq '臉') {
			$vars = '[臉脸]';
		} elsif ($ch eq '臍') {
			$vars = '[臍脐]';
		} elsif ($ch eq '臏') {
			$vars = '[臏髕膑]';
		} elsif ($ch eq '臓') {
			$vars = '[臓臟]';
		} elsif ($ch eq '臕') {
			$vars = '[臕膘]';
		} elsif ($ch eq '臘') {
			$vars = '[臘臈腊]';
		} elsif ($ch eq '臙') {
			$vars = '[臙胭]';
		} elsif ($ch eq '臚') {
			$vars = '[臚胪]';
		} elsif ($ch eq '臞') {
			$vars = '[臞癯]';
		} elsif ($ch eq '臟') {
			$vars = '[臟脏]';
		} elsif ($ch eq '臠') {
			$vars = '[臠脔]';
		} elsif ($ch eq '臥') {
			$vars = '[臥卧]';
		} elsif ($ch eq '臨') {
			$vars = '[臨临臨]';
		} elsif ($ch eq '致') {
			$vars = '[致緻]';
		} elsif ($ch eq '臺') {
			$vars = '[臺台]';
		} elsif ($ch eq '舀') {
			$vars = '[舀外抌]';
		} elsif ($ch eq '舆') {
			$vars = '[舆輿]';
		} elsif ($ch eq '與') {
			$vars = '[與与]';
		} elsif ($ch eq '興') {
			$vars = '[興兴]';
		} elsif ($ch eq '舉') {
			$vars = '[舉举擧]';
		} elsif ($ch eq '舊') {
			$vars = '[舊旧]';
		} elsif ($ch eq '舍') {
			$vars = '[舍舎捨]';
		} elsif ($ch eq '舎') {
			$vars = '[舎舍]';
		} elsif ($ch eq '舒') {
			$vars = '[舒摴]';
		} elsif ($ch eq '舔') {
			$vars = '[舔餂]';
		} elsif ($ch eq '舖') {
			$vars = '[舖鋪]';
		} elsif ($ch eq '舗') {
			$vars = '[舗鋪]';
		} elsif ($ch eq '舘') {
			$vars = '[舘館]';
		} elsif ($ch eq '舡') {
			$vars = '[舡船]';
		} elsif ($ch eq '舣') {
			$vars = '[舣艤]';
		} elsif ($ch eq '舩') {
			$vars = '[舩船]';
		} elsif ($ch eq '舮') {
			$vars = '[舮櫓]';
		} elsif ($ch eq '舰') {
			$vars = '[舰艦]';
		} elsif ($ch eq '舱') {
			$vars = '[舱艙]';
		} elsif ($ch eq '舵') {
			$vars = '[舵柁]';
		} elsif ($ch eq '船') {
			$vars = '[船舩舡]';
		} elsif ($ch eq '舻') {
			$vars = '[舻櫓艫]';
		} elsif ($ch eq '艑') {
			$vars = '[艑扁]';
		} elsif ($ch eq '艙') {
			$vars = '[艙舱]';
		} elsif ($ch eq '艢') {
			$vars = '[艢檣]';
		} elsif ($ch eq '艣') {
			$vars = '[艣櫓]';
		} elsif ($ch eq '艤') {
			$vars = '[艤舣]';
		} elsif ($ch eq '艦') {
			$vars = '[艦舰]';
		} elsif ($ch eq '艪') {
			$vars = '[艪櫓]';
		} elsif ($ch eq '艫') {
			$vars = '[艫櫓舻]';
		} elsif ($ch eq '良') {
			$vars = '[良良]';
		} elsif ($ch eq '艰') {
			$vars = '[艰艱]';
		} elsif ($ch eq '艱') {
			$vars = '[艱艰]';
		} elsif ($ch eq '艳') {
			$vars = '[艳艷豔]';
		} elsif ($ch eq '艴') {
			$vars = '[艴勃]';
		} elsif ($ch eq '艶') {
			$vars = '[艶豔]';
		} elsif ($ch eq '艷') {
			$vars = '[艷艳豔]';
		} elsif ($ch eq '艸') {
			$vars = '[艸艹草]';
		} elsif ($ch eq '艹') {
			$vars = '[艹艸草]';
		} elsif ($ch eq '艺') {
			$vars = '[艺藝]';
		} elsif ($ch eq '艽') {
			$vars = '[艽韭]';
		} elsif ($ch eq '节') {
			$vars = '[节節]';
		} elsif ($ch eq '芈') {
			$vars = '[芈羋]';
		} elsif ($ch eq '芊') {
			$vars = '[芊茜]';
		} elsif ($ch eq '芔') {
			$vars = '[芔卉]';
		} elsif ($ch eq '芗') {
			$vars = '[芗薌]';
		} elsif ($ch eq '芘') {
			$vars = '[芘蔽]';
		} elsif ($ch eq '芜') {
			$vars = '[芜蕪]';
		} elsif ($ch eq '芦') {
			$vars = '[芦蘆]';
		} elsif ($ch eq '芭') {
			$vars = '[芭巴]';
		} elsif ($ch eq '花') {
			$vars = '[花蘤]';
		} elsif ($ch eq '芸') {
			$vars = '[芸藝蕓]';
		} elsif ($ch eq '芻') {
			$vars = '[芻刍蒭]';
		} elsif ($ch eq '苁') {
			$vars = '[苁蓯]';
		} elsif ($ch eq '苅') {
			$vars = '[苅刈]';
		} elsif ($ch eq '苇') {
			$vars = '[苇葦]';
		} elsif ($ch eq '苈') {
			$vars = '[苈藶]';
		} elsif ($ch eq '苋') {
			$vars = '[苋莧]';
		} elsif ($ch eq '苌') {
			$vars = '[苌萇]';
		} elsif ($ch eq '苍') {
			$vars = '[苍蒼]';
		} elsif ($ch eq '苎') {
			$vars = '[苎苧蒙]';
		} elsif ($ch eq '苏') {
			$vars = '[苏蘇]';
		} elsif ($ch eq '苑') {
			$vars = '[苑菀]';
		} elsif ($ch eq '苛') {
			$vars = '[苛哼]';
		} elsif ($ch eq '苟') {
			$vars = '[苟茍]';
		} elsif ($ch eq '苤') {
			$vars = '[苤瞥]';
		} elsif ($ch eq '若') {
			$vars = '[若若]';
		} elsif ($ch eq '苧') {
			$vars = '[苧薴苎]';
		} elsif ($ch eq '苹') {
			$vars = '[苹蘋]';
		} elsif ($ch eq '苺') {
			$vars = '[苺莓]';
		} elsif ($ch eq '苽') {
			$vars = '[苽菇]';
		} elsif ($ch eq '范') {
			$vars = '[范範]';
		} elsif ($ch eq '茅') {
			$vars = '[茅泖]';
		} elsif ($ch eq '茆') {
			$vars = '[茆茅]';
		} elsif ($ch eq '茈') {
			$vars = '[茈柴]';
		} elsif ($ch eq '茍') {
			$vars = '[茍苟]';
		} elsif ($ch eq '茎') {
			$vars = '[茎莖]';
		} elsif ($ch eq '茏') {
			$vars = '[茏蘢]';
		} elsif ($ch eq '茑') {
			$vars = '[茑蔦]';
		} elsif ($ch eq '茔') {
			$vars = '[茔塋]';
		} elsif ($ch eq '茕') {
			$vars = '[茕煢]';
		} elsif ($ch eq '茘') {
			$vars = '[茘荔]';
		} elsif ($ch eq '茠') {
			$vars = '[茠薅]';
		} elsif ($ch eq '茧') {
			$vars = '[茧繭]';
		} elsif ($ch eq '茭') {
			$vars = '[茭椒]';
		} elsif ($ch eq '茲') {
			$vars = '[茲玆兹]';
		} elsif ($ch eq '茶') {
			$vars = '[茶茶]';
		} elsif ($ch eq '荅') {
			$vars = '[荅答]';
		} elsif ($ch eq '荆') {
			$vars = '[荆荊]';
		} elsif ($ch eq '荇') {
			$vars = '[荇莕]';
		} elsif ($ch eq '草') {
			$vars = '[草艸艹]';
		} elsif ($ch eq '荊') {
			$vars = '[荊荆]';
		} elsif ($ch eq '荍') {
			$vars = '[荍蕎]';
		} elsif ($ch eq '荐') {
			$vars = '[荐薦]';
		} elsif ($ch eq '荘') {
			$vars = '[荘莊]';
		} elsif ($ch eq '荚') {
			$vars = '[荚莢]';
		} elsif ($ch eq '荛') {
			$vars = '[荛蕘]';
		} elsif ($ch eq '荜') {
			$vars = '[荜蓽]';
		} elsif ($ch eq '荞') {
			$vars = '[荞蕎]';
		} elsif ($ch eq '荟') {
			$vars = '[荟薈]';
		} elsif ($ch eq '荠') {
			$vars = '[荠薺]';
		} elsif ($ch eq '荡') {
			$vars = '[荡盪蕩]';
		} elsif ($ch eq '荣') {
			$vars = '[荣榮]';
		} elsif ($ch eq '荤') {
			$vars = '[荤葷]';
		} elsif ($ch eq '荥') {
			$vars = '[荥滎]';
		} elsif ($ch eq '荦') {
			$vars = '[荦犖]';
		} elsif ($ch eq '荧') {
			$vars = '[荧熒]';
		} elsif ($ch eq '荨') {
			$vars = '[荨蕁]';
		} elsif ($ch eq '荩') {
			$vars = '[荩藎]';
		} elsif ($ch eq '荪') {
			$vars = '[荪蓀]';
		} elsif ($ch eq '荫') {
			$vars = '[荫蔭]';
		} elsif ($ch eq '荭') {
			$vars = '[荭葒]';
		} elsif ($ch eq '药') {
			$vars = '[药藥葯]';
		} elsif ($ch eq '荳') {
			$vars = '[荳豆]';
		} elsif ($ch eq '荽') {
			$vars = '[荽萎]';
		} elsif ($ch eq '莅') {
			$vars = '[莅蒞]';
		} elsif ($ch eq '莆') {
			$vars = '[莆蒲]';
		} elsif ($ch eq '莊') {
			$vars = '[莊荘庄]';
		} elsif ($ch eq '莓') {
			$vars = '[莓苺]';
		} elsif ($ch eq '莕') {
			$vars = '[莕荇]';
		} elsif ($ch eq '莖') {
			$vars = '[莖茎]';
		} elsif ($ch eq '莜') {
			$vars = '[莜蓧]';
		} elsif ($ch eq '莢') {
			$vars = '[莢荚]';
		} elsif ($ch eq '莧') {
			$vars = '[莧苋]';
		} elsif ($ch eq '莩') {
			$vars = '[莩殍]';
		} elsif ($ch eq '莱') {
			$vars = '[莱萊]';
		} elsif ($ch eq '莲') {
			$vars = '[莲蓮]';
		} elsif ($ch eq '莳') {
			$vars = '[莳蒔]';
		} elsif ($ch eq '莴') {
			$vars = '[莴萵]';
		} elsif ($ch eq '莵') {
			$vars = '[莵菟]';
		} elsif ($ch eq '莶') {
			$vars = '[莶薟]';
		} elsif ($ch eq '获') {
			$vars = '[获穫獲]';
		} elsif ($ch eq '莸') {
			$vars = '[莸蕕]';
		} elsif ($ch eq '莹') {
			$vars = '[莹瑩]';
		} elsif ($ch eq '莺') {
			$vars = '[莺鶯]';
		} elsif ($ch eq '莼') {
			$vars = '[莼蓴]';
		} elsif ($ch eq '莿') {
			$vars = '[莿朿刺]';
		} elsif ($ch eq '菀') {
			$vars = '[菀苑]';
		} elsif ($ch eq '菇') {
			$vars = '[菇苽菰]';
		} elsif ($ch eq '菌') {
			$vars = '[菌蕈滾]';
		} elsif ($ch eq '菑') {
			$vars = '[菑災甾灾]';
		} elsif ($ch eq '菓') {
			$vars = '[菓果]';
		} elsif ($ch eq '菔') {
			$vars = '[菔蔔]';
		} elsif ($ch eq '菝') {
			$vars = '[菝蔽]';
		} elsif ($ch eq '菟') {
			$vars = '[菟莵]';
		} elsif ($ch eq '菫') {
			$vars = '[菫堇]';
		} elsif ($ch eq '華') {
			$vars = '[華华崋]';
		} elsif ($ch eq '菰') {
			$vars = '[菰苽菇]';
		} elsif ($ch eq '菱') {
			$vars = '[菱菱]';
		} elsif ($ch eq '菴') {
			$vars = '[菴庵]';
		} elsif ($ch eq '菷') {
			$vars = '[菷帚]';
		} elsif ($ch eq '菸') {
			$vars = '[菸烟煙]';
		} elsif ($ch eq '菻') {
			$vars = '[菻麻]';
		} elsif ($ch eq '萆') {
			$vars = '[萆蓖蔽]';
		} elsif ($ch eq '萇') {
			$vars = '[萇苌]';
		} elsif ($ch eq '萊') {
			$vars = '[萊莱]';
		} elsif ($ch eq '萌') {
			$vars = '[萌萠]';
		} elsif ($ch eq '萎') {
			$vars = '[萎荽]';
		} elsif ($ch eq '萝') {
			$vars = '[萝蘿]';
		} elsif ($ch eq '萠') {
			$vars = '[萠萌]';
		} elsif ($ch eq '萤') {
			$vars = '[萤螢]';
		} elsif ($ch eq '营') {
			$vars = '[营營]';
		} elsif ($ch eq '萦') {
			$vars = '[萦縈]';
		} elsif ($ch eq '萧') {
			$vars = '[萧蕭]';
		} elsif ($ch eq '萨') {
			$vars = '[萨薩]';
		} elsif ($ch eq '萬') {
			$vars = '[萬卍万]';
		} elsif ($ch eq '萱') {
			$vars = '[萱萲]';
		} elsif ($ch eq '萲') {
			$vars = '[萲萱]';
		} elsif ($ch eq '萵') {
			$vars = '[萵莴]';
		} elsif ($ch eq '萼') {
			$vars = '[萼蕚]';
		} elsif ($ch eq '落') {
			$vars = '[落落]';
		} elsif ($ch eq '葉') {
			$vars = '[葉葉叶]';
		} elsif ($ch eq '葒') {
			$vars = '[葒荭]';
		} elsif ($ch eq '著') {
			$vars = '[著螫着]';
		} elsif ($ch eq '葚') {
			$vars = '[葚椹]';
		} elsif ($ch eq '葢') {
			$vars = '[葢蓋盖]';
		} elsif ($ch eq '葦') {
			$vars = '[葦苇]';
		} elsif ($ch eq '葫') {
			$vars = '[葫胡]';
		} elsif ($ch eq '葯') {
			$vars = '[葯药藥]';
		} elsif ($ch eq '葱') {
			$vars = '[葱蔥]';
		} elsif ($ch eq '葷') {
			$vars = '[葷荤]';
		} elsif ($ch eq '蒇') {
			$vars = '[蒇蕆]';
		} elsif ($ch eq '蒉') {
			$vars = '[蒉蕢]';
		} elsif ($ch eq '蒋') {
			$vars = '[蒋蔣]';
		} elsif ($ch eq '蒌') {
			$vars = '[蒌蔞]';
		} elsif ($ch eq '蒍') {
			$vars = '[蒍蔿]';
		} elsif ($ch eq '蒔') {
			$vars = '[蒔莳]';
		} elsif ($ch eq '蒙') {
			$vars = '[蒙懞]';
		} elsif ($ch eq '蒞') {
			$vars = '[蒞莅]';
		} elsif ($ch eq '蒭') {
			$vars = '[蒭芻]';
		} elsif ($ch eq '蒲') {
			$vars = '[蒲莆]';
		} elsif ($ch eq '蒸') {
			$vars = '[蒸烝]';
		} elsif ($ch eq '蒼') {
			$vars = '[蒼苍]';
		} elsif ($ch eq '蓀') {
			$vars = '[蓀荪]';
		} elsif ($ch eq '蓆') {
			$vars = '[蓆席]';
		} elsif ($ch eq '蓋') {
			$vars = '[蓋葢盖]';
		} elsif ($ch eq '蓖') {
			$vars = '[蓖芘萆]';
		} elsif ($ch eq '蓝') {
			$vars = '[蓝藍]';
		} elsif ($ch eq '蓟') {
			$vars = '[蓟薊]';
		} elsif ($ch eq '蓠') {
			$vars = '[蓠蘺]';
		} elsif ($ch eq '蓣') {
			$vars = '[蓣蕷]';
		} elsif ($ch eq '蓥') {
			$vars = '[蓥鎣]';
		} elsif ($ch eq '蓦') {
			$vars = '[蓦驀]';
		} elsif ($ch eq '蓧') {
			$vars = '[蓧莜]';
		} elsif ($ch eq '蓮') {
			$vars = '[蓮莲]';
		} elsif ($ch eq '蓯') {
			$vars = '[蓯苁]';
		} elsif ($ch eq '蓴') {
			$vars = '[蓴莼]';
		} elsif ($ch eq '蓺') {
			$vars = '[蓺藝埶]';
		} elsif ($ch eq '蓼') {
			$vars = '[蓼蓼]';
		} elsif ($ch eq '蓽') {
			$vars = '[蓽荜]';
		} elsif ($ch eq '蔂') {
			$vars = '[蔂虆]';
		} elsif ($ch eq '蔔') {
			$vars = '[蔔菔卜]';
		} elsif ($ch eq '蔞') {
			$vars = '[蔞褸蒌]';
		} elsif ($ch eq '蔣') {
			$vars = '[蔣蒋]';
		} elsif ($ch eq '蔥') {
			$vars = '[蔥葱]';
		} elsif ($ch eq '蔦') {
			$vars = '[蔦茑]';
		} elsif ($ch eq '蔭') {
			$vars = '[蔭廕荫]';
		} elsif ($ch eq '蔵') {
			$vars = '[蔵藏]';
		} elsif ($ch eq '蔷') {
			$vars = '[蔷薔]';
		} elsif ($ch eq '蔹') {
			$vars = '[蔹蘞]';
		} elsif ($ch eq '蔺') {
			$vars = '[蔺藺]';
		} elsif ($ch eq '蔼') {
			$vars = '[蔼藹]';
		} elsif ($ch eq '蔽') {
			$vars = '[蔽芘]';
		} elsif ($ch eq '蔿') {
			$vars = '[蔿蒍]';
		} elsif ($ch eq '蕁') {
			$vars = '[蕁荨]';
		} elsif ($ch eq '蕆') {
			$vars = '[蕆蒇]';
		} elsif ($ch eq '蕈') {
			$vars = '[蕈菌]';
		} elsif ($ch eq '蕊') {
			$vars = '[蕊蘂蕋]';
		} elsif ($ch eq '蕋') {
			$vars = '[蕋蕊]';
		} elsif ($ch eq '蕎') {
			$vars = '[蕎荍荞]';
		} elsif ($ch eq '蕓') {
			$vars = '[蕓芸]';
		} elsif ($ch eq '蕕') {
			$vars = '[蕕莸]';
		} elsif ($ch eq '蕘') {
			$vars = '[蕘荛]';
		} elsif ($ch eq '蕚') {
			$vars = '[蕚萼]';
		} elsif ($ch eq '蕢') {
			$vars = '[蕢蒉簣]';
		} elsif ($ch eq '蕣') {
			$vars = '[蕣橓]';
		} elsif ($ch eq '蕩') {
			$vars = '[蕩荡盪蘯]';
		} elsif ($ch eq '蕪') {
			$vars = '[蕪芜]';
		} elsif ($ch eq '蕭') {
			$vars = '[蕭萧]';
		} elsif ($ch eq '蕲') {
			$vars = '[蕲蘄]';
		} elsif ($ch eq '蕴') {
			$vars = '[蕴蘊]';
		} elsif ($ch eq '蕷') {
			$vars = '[蕷蓣]';
		} elsif ($ch eq '薅') {
			$vars = '[薅茠]';
		} elsif ($ch eq '薈') {
			$vars = '[薈荟]';
		} elsif ($ch eq '薊') {
			$vars = '[薊蓟]';
		} elsif ($ch eq '薌') {
			$vars = '[薌芗]';
		} elsif ($ch eq '薑') {
			$vars = '[薑姜]';
		} elsif ($ch eq '薔') {
			$vars = '[薔蔷]';
		} elsif ($ch eq '薟') {
			$vars = '[薟莶蘞]';
		} elsif ($ch eq '薦') {
			$vars = '[薦荐]';
		} elsif ($ch eq '薩') {
			$vars = '[薩萨]';
		} elsif ($ch eq '薫') {
			$vars = '[薫薰]';
		} elsif ($ch eq '薬') {
			$vars = '[薬藥]';
		} elsif ($ch eq '薮') {
			$vars = '[薮藪]';
		} elsif ($ch eq '薯') {
			$vars = '[薯藷]';
		} elsif ($ch eq '薰') {
			$vars = '[薰薫]';
		} elsif ($ch eq '薴') {
			$vars = '[薴苧]';
		} elsif ($ch eq '薺') {
			$vars = '[薺荠]';
		} elsif ($ch eq '藉') {
			$vars = '[藉耤借]';
		} elsif ($ch eq '藍') {
			$vars = '[藍蓝]';
		} elsif ($ch eq '藎') {
			$vars = '[藎荩]';
		} elsif ($ch eq '藏') {
			$vars = '[藏蔵]';
		} elsif ($ch eq '藓') {
			$vars = '[藓蘚]';
		} elsif ($ch eq '藝') {
			$vars = '[藝艺埶蓺]';
		} elsif ($ch eq '藤') {
			$vars = '[藤籐]';
		} elsif ($ch eq '藥') {
			$vars = '[藥药薬葯]';
		} elsif ($ch eq '藦') {
			$vars = '[藦蘑]';
		} elsif ($ch eq '藪') {
			$vars = '[藪薮籔]';
		} elsif ($ch eq '藶') {
			$vars = '[藶苈]';
		} elsif ($ch eq '藷') {
			$vars = '[藷薯]';
		} elsif ($ch eq '藹') {
			$vars = '[藹蔼]';
		} elsif ($ch eq '藺') {
			$vars = '[藺蔺]';
		} elsif ($ch eq '蘂') {
			$vars = '[蘂蕊]';
		} elsif ($ch eq '蘄') {
			$vars = '[蘄蕲]';
		} elsif ($ch eq '蘆') {
			$vars = '[蘆蘆芦]';
		} elsif ($ch eq '蘇') {
			$vars = '[蘇苏]';
		} elsif ($ch eq '蘊') {
			$vars = '[蘊蕴]';
		} elsif ($ch eq '蘋') {
			$vars = '[蘋苹]';
		} elsif ($ch eq '蘑') {
			$vars = '[蘑藦]';
		} elsif ($ch eq '蘓') {
			$vars = '[蘓蘇]';
		} elsif ($ch eq '蘖') {
			$vars = '[蘖櫱蘗]';
		} elsif ($ch eq '蘚') {
			$vars = '[蘚藓]';
		} elsif ($ch eq '蘞') {
			$vars = '[蘞薟蔹]';
		} elsif ($ch eq '蘢') {
			$vars = '[蘢茏]';
		} elsif ($ch eq '蘤') {
			$vars = '[蘤花]';
		} elsif ($ch eq '蘭') {
			$vars = '[蘭兰]';
		} elsif ($ch eq '蘯') {
			$vars = '[蘯盪蕩]';
		} elsif ($ch eq '蘺') {
			$vars = '[蘺蓠]';
		} elsif ($ch eq '蘿') {
			$vars = '[蘿萝蘿]';
		} elsif ($ch eq '虆') {
			$vars = '[虆蔂]';
		} elsif ($ch eq '虎') {
			$vars = '[虎乕]';
		} elsif ($ch eq '虏') {
			$vars = '[虏虜]';
		} elsif ($ch eq '虐') {
			$vars = '[虐乇]';
		} elsif ($ch eq '虑') {
			$vars = '[虑慮]';
		} elsif ($ch eq '虓') {
			$vars = '[虓唬猇]';
		} elsif ($ch eq '處') {
			$vars = '[處处処]';
		} elsif ($ch eq '虖') {
			$vars = '[虖呼]';
		} elsif ($ch eq '虚') {
			$vars = '[虚虛]';
		} elsif ($ch eq '虛') {
			$vars = '[虛虚]';
		} elsif ($ch eq '虜') {
			$vars = '[虜虜擄虏]';
		} elsif ($ch eq '號') {
			$vars = '[號号]';
		} elsif ($ch eq '虣') {
			$vars = '[虣暴]';
		} elsif ($ch eq '虧') {
			$vars = '[虧亏]';
		} elsif ($ch eq '虫') {
			$vars = '[虫蟲]';
		} elsif ($ch eq '虬') {
			$vars = '[虬蚪虯]';
		} elsif ($ch eq '虮') {
			$vars = '[虮蟣]';
		} elsif ($ch eq '虯') {
			$vars = '[虯虬]';
		} elsif ($ch eq '虱') {
			$vars = '[虱蝨]';
		} elsif ($ch eq '虺') {
			$vars = '[虺蝰]';
		} elsif ($ch eq '虽') {
			$vars = '[虽雖]';
		} elsif ($ch eq '虾') {
			$vars = '[虾蝦]';
		} elsif ($ch eq '虿') {
			$vars = '[虿蠆]';
		} elsif ($ch eq '蚀') {
			$vars = '[蚀蝕]';
		} elsif ($ch eq '蚁') {
			$vars = '[蚁蟻]';
		} elsif ($ch eq '蚂') {
			$vars = '[蚂螞]';
		} elsif ($ch eq '蚓') {
			$vars = '[蚓螾]';
		} elsif ($ch eq '蚕') {
			$vars = '[蚕蠶]';
		} elsif ($ch eq '蚘') {
			$vars = '[蚘蛔痐]';
		} elsif ($ch eq '蚪') {
			$vars = '[蚪虬]';
		} elsif ($ch eq '蚬') {
			$vars = '[蚬蜆]';
		} elsif ($ch eq '蛄') {
			$vars = '[蛄蛌]';
		} elsif ($ch eq '蛊') {
			$vars = '[蛊蠱]';
		} elsif ($ch eq '蛋') {
			$vars = '[蛋蜑旦]';
		} elsif ($ch eq '蛌') {
			$vars = '[蛌蛄]';
		} elsif ($ch eq '蛍') {
			$vars = '[蛍螢]';
		} elsif ($ch eq '蛎') {
			$vars = '[蛎蠣]';
		} elsif ($ch eq '蛏') {
			$vars = '[蛏蟶]';
		} elsif ($ch eq '蛔') {
			$vars = '[蛔蚘]';
		} elsif ($ch eq '蛮') {
			$vars = '[蛮蠻]';
		} elsif ($ch eq '蛰') {
			$vars = '[蛰蟄]';
		} elsif ($ch eq '蛱') {
			$vars = '[蛱蛺]';
		} elsif ($ch eq '蛲') {
			$vars = '[蛲蟯]';
		} elsif ($ch eq '蛳') {
			$vars = '[蛳螄]';
		} elsif ($ch eq '蛴') {
			$vars = '[蛴蠐]';
		} elsif ($ch eq '蛺') {
			$vars = '[蛺蛱]';
		} elsif ($ch eq '蛻') {
			$vars = '[蛻蜕]';
		} elsif ($ch eq '蜆') {
			$vars = '[蜆蚬]';
		} elsif ($ch eq '蜋') {
			$vars = '[蜋螂]';
		} elsif ($ch eq '蜍') {
			$vars = '[蜍蠩]';
		} elsif ($ch eq '蜑') {
			$vars = '[蜑蛋]';
		} elsif ($ch eq '蜕') {
			$vars = '[蜕蛻]';
		} elsif ($ch eq '蜗') {
			$vars = '[蜗蝸]';
		} elsif ($ch eq '蜡') {
			$vars = '[蜡蠟]';
		} elsif ($ch eq '蜨') {
			$vars = '[蜨蝶]';
		} elsif ($ch eq '蜺') {
			$vars = '[蜺霓]';
		} elsif ($ch eq '蝃') {
			$vars = '[蝃螮]';
		} elsif ($ch eq '蝇') {
			$vars = '[蝇蠅]';
		} elsif ($ch eq '蝈') {
			$vars = '[蝈蟈]';
		} elsif ($ch eq '蝉') {
			$vars = '[蝉蟬]';
		} elsif ($ch eq '蝋') {
			$vars = '[蝋蠟]';
		} elsif ($ch eq '蝎') {
			$vars = '[蝎蠍]';
		} elsif ($ch eq '蝕') {
			$vars = '[蝕蚀]';
		} elsif ($ch eq '蝟') {
			$vars = '[蝟猬]';
		} elsif ($ch eq '蝥') {
			$vars = '[蝥蟊]';
		} elsif ($ch eq '蝦') {
			$vars = '[蝦鰕虾]';
		} elsif ($ch eq '蝨') {
			$vars = '[蝨虱]';
		} elsif ($ch eq '蝯') {
			$vars = '[蝯猿]';
		} elsif ($ch eq '蝴') {
			$vars = '[蝴胡]';
		} elsif ($ch eq '蝶') {
			$vars = '[蝶蜨]';
		} elsif ($ch eq '蝸') {
			$vars = '[蝸蜗]';
		} elsif ($ch eq '蝼') {
			$vars = '[蝼螻]';
		} elsif ($ch eq '蝾') {
			$vars = '[蝾蠑]';
		} elsif ($ch eq '蝿') {
			$vars = '[蝿蠅]';
		} elsif ($ch eq '螂') {
			$vars = '[螂蜋]';
		} elsif ($ch eq '螄') {
			$vars = '[螄蛳]';
		} elsif ($ch eq '螗') {
			$vars = '[螗螳]';
		} elsif ($ch eq '螘') {
			$vars = '[螘蟻]';
		} elsif ($ch eq '螞') {
			$vars = '[螞蚂]';
		} elsif ($ch eq '螢') {
			$vars = '[螢萤蛍]';
		} elsif ($ch eq '螫') {
			$vars = '[螫著]';
		} elsif ($ch eq '螮') {
			$vars = '[螮蝃]';
		} elsif ($ch eq '螳') {
			$vars = '[螳螗]';
		} elsif ($ch eq '螵') {
			$vars = '[螵蜱]';
		} elsif ($ch eq '螺') {
			$vars = '[螺螺蠃]';
		} elsif ($ch eq '螻') {
			$vars = '[螻蝼]';
		} elsif ($ch eq '螾') {
			$vars = '[螾蚓]';
		} elsif ($ch eq '蟄') {
			$vars = '[蟄蛰]';
		} elsif ($ch eq '蟇') {
			$vars = '[蟇蟆]';
		} elsif ($ch eq '蟈') {
			$vars = '[蟈蝈]';
		} elsif ($ch eq '蟊') {
			$vars = '[蟊蝥]';
		} elsif ($ch eq '蟒') {
			$vars = '[蟒蠎]';
		} elsif ($ch eq '蟣') {
			$vars = '[蟣虮]';
		} elsif ($ch eq '蟬') {
			$vars = '[蟬蝉]';
		} elsif ($ch eq '蟮') {
			$vars = '[蟮蟺]';
		} elsif ($ch eq '蟯') {
			$vars = '[蟯蛲]';
		} elsif ($ch eq '蟲') {
			$vars = '[蟲虫]';
		} elsif ($ch eq '蟶') {
			$vars = '[蟶蛏]';
		} elsif ($ch eq '蟹') {
			$vars = '[蟹蠏]';
		} elsif ($ch eq '蟺') {
			$vars = '[蟺蟮]';
		} elsif ($ch eq '蟻') {
			$vars = '[蟻蚁螘]';
		} elsif ($ch eq '蠃') {
			$vars = '[蠃螺]';
		} elsif ($ch eq '蠅') {
			$vars = '[蠅蝇]';
		} elsif ($ch eq '蠆') {
			$vars = '[蠆虿]';
		} elsif ($ch eq '蠍') {
			$vars = '[蠍蝎]';
		} elsif ($ch eq '蠎') {
			$vars = '[蠎蟒]';
		} elsif ($ch eq '蠏') {
			$vars = '[蠏蟹]';
		} elsif ($ch eq '蠐') {
			$vars = '[蠐蛴]';
		} elsif ($ch eq '蠑') {
			$vars = '[蠑蝾]';
		} elsif ($ch eq '蠟') {
			$vars = '[蠟蜡]';
		} elsif ($ch eq '蠢') {
			$vars = '[蠢惷]';
		} elsif ($ch eq '蠣') {
			$vars = '[蠣蛎]';
		} elsif ($ch eq '蠧') {
			$vars = '[蠧蠹]';
		} elsif ($ch eq '蠩') {
			$vars = '[蠩蜍]';
		} elsif ($ch eq '蠱') {
			$vars = '[蠱蛊]';
		} elsif ($ch eq '蠶') {
			$vars = '[蠶蚕]';
		} elsif ($ch eq '蠹') {
			$vars = '[蠹蠧]';
		} elsif ($ch eq '蠻') {
			$vars = '[蠻蛮]';
		} elsif ($ch eq '衂') {
			$vars = '[衂衄]';
		} elsif ($ch eq '衄') {
			$vars = '[衄衂]';
		} elsif ($ch eq '衅') {
			$vars = '[衅釁]';
		} elsif ($ch eq '衆') {
			$vars = '[衆眾众]';
		} elsif ($ch eq '行') {
			$vars = '[行行]';
		} elsif ($ch eq '衒') {
			$vars = '[衒炫]';
		} elsif ($ch eq '術') {
			$vars = '[術术]';
		} elsif ($ch eq '衔') {
			$vars = '[衔銜]';
		} elsif ($ch eq '衕') {
			$vars = '[衕同]';
		} elsif ($ch eq '街') {
			$vars = '[街亍]';
		} elsif ($ch eq '衚') {
			$vars = '[衚胡]';
		} elsif ($ch eq '衛') {
			$vars = '[衛衞卫]';
		} elsif ($ch eq '衝') {
			$vars = '[衝冲]';
		} elsif ($ch eq '衞') {
			$vars = '[衞衛]';
		} elsif ($ch eq '衣') {
			$vars = '[衣衤]';
		} elsif ($ch eq '衤') {
			$vars = '[衤衣]';
		} elsif ($ch eq '补') {
			$vars = '[补補]';
		} elsif ($ch eq '表') {
			$vars = '[表錶]';
		} elsif ($ch eq '衬') {
			$vars = '[衬襯]';
		} elsif ($ch eq '衮') {
			$vars = '[衮袞]';
		} elsif ($ch eq '衹') {
			$vars = '[衹只]';
		} elsif ($ch eq '衽') {
			$vars = '[衽袵]';
		} elsif ($ch eq '衿') {
			$vars = '[衿襟紟]';
		} elsif ($ch eq '袄') {
			$vars = '[袄襖]';
		} elsif ($ch eq '袅') {
			$vars = '[袅嬝裊]';
		} elsif ($ch eq '袒') {
			$vars = '[袒襢]';
		} elsif ($ch eq '袖') {
			$vars = '[袖褎]';
		} elsif ($ch eq '袜') {
			$vars = '[袜襪]';
		} elsif ($ch eq '袞') {
			$vars = '[袞衮]';
		} elsif ($ch eq '袭') {
			$vars = '[袭襲]';
		} elsif ($ch eq '袴') {
			$vars = '[袴褲]';
		} elsif ($ch eq '袵') {
			$vars = '[袵衽]';
		} elsif ($ch eq '袷') {
			$vars = '[袷裌]';
		} elsif ($ch eq '裂') {
			$vars = '[裂裂]';
		} elsif ($ch eq '装') {
			$vars = '[装裝]';
		} elsif ($ch eq '裆') {
			$vars = '[裆襠]';
		} elsif ($ch eq '裊') {
			$vars = '[裊嬝袅]';
		} elsif ($ch eq '裌') {
			$vars = '[裌袷]';
		} elsif ($ch eq '裏') {
			$vars = '[裏里裡里]';
		} elsif ($ch eq '裒') {
			$vars = '[裒鴄]';
		} elsif ($ch eq '補') {
			$vars = '[補补]';
		} elsif ($ch eq '裝') {
			$vars = '[裝装]';
		} elsif ($ch eq '裡') {
			$vars = '[裡里裏]';
		} elsif ($ch eq '裢') {
			$vars = '[裢褳]';
		} elsif ($ch eq '裣') {
			$vars = '[裣襝]';
		} elsif ($ch eq '裤') {
			$vars = '[裤褲]';
		} elsif ($ch eq '裴') {
			$vars = '[裴裵]';
		} elsif ($ch eq '裵') {
			$vars = '[裵裴]';
		} elsif ($ch eq '裸') {
			$vars = '[裸裸]';
		} elsif ($ch eq '製') {
			$vars = '[製制]';
		} elsif ($ch eq '複') {
			$vars = '[複复復]';
		} elsif ($ch eq '褒') {
			$vars = '[褒襃]';
		} elsif ($ch eq '褓') {
			$vars = '[褓褴]';
		} elsif ($ch eq '褛') {
			$vars = '[褛褸]';
		} elsif ($ch eq '褟') {
			$vars = '[褟溻]';
		} elsif ($ch eq '褢') {
			$vars = '[褢褱]';
		} elsif ($ch eq '褧') {
			$vars = '[褧絅]';
		} elsif ($ch eq '褱') {
			$vars = '[褱褢]';
		} elsif ($ch eq '褲') {
			$vars = '[褲綯裤袴]';
		} elsif ($ch eq '褳') {
			$vars = '[褳裢]';
		} elsif ($ch eq '褴') {
			$vars = '[褴襤褓]';
		} elsif ($ch eq '褵') {
			$vars = '[褵縭]';
		} elsif ($ch eq '褸') {
			$vars = '[褸褛蔞]';
		} elsif ($ch eq '褻') {
			$vars = '[褻亵]';
		} elsif ($ch eq '襁') {
			$vars = '[襁繦繈]';
		} elsif ($ch eq '襃') {
			$vars = '[襃褒]';
		} elsif ($ch eq '襍') {
			$vars = '[襍雜]';
		} elsif ($ch eq '襖') {
			$vars = '[襖澳袄]';
		} elsif ($ch eq '襜') {
			$vars = '[襜襝輦]';
		} elsif ($ch eq '襝') {
			$vars = '[襝裣襜]';
		} elsif ($ch eq '襟') {
			$vars = '[襟衿]';
		} elsif ($ch eq '襠') {
			$vars = '[襠裆]';
		} elsif ($ch eq '襢') {
			$vars = '[襢袒]';
		} elsif ($ch eq '襤') {
			$vars = '[襤襤褴]';
		} elsif ($ch eq '襪') {
			$vars = '[襪韈袜]';
		} elsif ($ch eq '襮') {
			$vars = '[襮幞]';
		} elsif ($ch eq '襯') {
			$vars = '[襯衬儭]';
		} elsif ($ch eq '襲') {
			$vars = '[襲袭]';
		} elsif ($ch eq '襾') {
			$vars = '[襾西]';
		} elsif ($ch eq '覆') {
			$vars = '[覆复復]';
		} elsif ($ch eq '覇') {
			$vars = '[覇霸]';
		} elsif ($ch eq '覈') {
			$vars = '[覈核]';
		} elsif ($ch eq '覊') {
			$vars = '[覊羈]';
		} elsif ($ch eq '見') {
			$vars = '[見见]';
		} elsif ($ch eq '規') {
			$vars = '[規规槻]';
		} elsif ($ch eq '覓') {
			$vars = '[覓觅]';
		} elsif ($ch eq '視') {
			$vars = '[視视]';
		} elsif ($ch eq '覘') {
			$vars = '[覘觇]';
		} elsif ($ch eq '覚') {
			$vars = '[覚覺]';
		} elsif ($ch eq '覡') {
			$vars = '[覡觋]';
		} elsif ($ch eq '覦') {
			$vars = '[覦觎]';
		} elsif ($ch eq '覩') {
			$vars = '[覩睹]';
		} elsif ($ch eq '親') {
			$vars = '[親亲]';
		} elsif ($ch eq '覬') {
			$vars = '[覬觊]';
		} elsif ($ch eq '覯') {
			$vars = '[覯觏]';
		} elsif ($ch eq '覲') {
			$vars = '[覲觐]';
		} elsif ($ch eq '観') {
			$vars = '[観觀]';
		} elsif ($ch eq '覷') {
			$vars = '[覷觑]';
		} elsif ($ch eq '覺') {
			$vars = '[覺覚觉]';
		} elsif ($ch eq '覽') {
			$vars = '[覽览覧]';
		} elsif ($ch eq '覿') {
			$vars = '[覿觌]';
		} elsif ($ch eq '觀') {
			$vars = '[觀观]';
		} elsif ($ch eq '见') {
			$vars = '[见見]';
		} elsif ($ch eq '观') {
			$vars = '[观觀]';
		} elsif ($ch eq '规') {
			$vars = '[规規]';
		} elsif ($ch eq '觅') {
			$vars = '[觅覓]';
		} elsif ($ch eq '视') {
			$vars = '[视視]';
		} elsif ($ch eq '觇') {
			$vars = '[觇覘]';
		} elsif ($ch eq '览') {
			$vars = '[览覽]';
		} elsif ($ch eq '觉') {
			$vars = '[觉覺]';
		} elsif ($ch eq '觊') {
			$vars = '[觊覬]';
		} elsif ($ch eq '觋') {
			$vars = '[觋覡]';
		} elsif ($ch eq '觌') {
			$vars = '[觌覿]';
		} elsif ($ch eq '觎') {
			$vars = '[觎覦]';
		} elsif ($ch eq '觏') {
			$vars = '[觏覯]';
		} elsif ($ch eq '觐') {
			$vars = '[觐覲]';
		} elsif ($ch eq '觑') {
			$vars = '[觑覷]';
		} elsif ($ch eq '角') {
			$vars = '[角甪]';
		} elsif ($ch eq '觔') {
			$vars = '[觔斤]';
		} elsif ($ch eq '觕') {
			$vars = '[觕麤粗]';
		} elsif ($ch eq '觜') {
			$vars = '[觜嘴咀]';
		} elsif ($ch eq '觝') {
			$vars = '[觝牴]';
		} elsif ($ch eq '觞') {
			$vars = '[觞觴]';
		} elsif ($ch eq '解') {
			$vars = '[解觧]';
		} elsif ($ch eq '触') {
			$vars = '[触觸]';
		} elsif ($ch eq '觧') {
			$vars = '[觧解]';
		} elsif ($ch eq '觯') {
			$vars = '[觯觶]';
		} elsif ($ch eq '觴') {
			$vars = '[觴觞]';
		} elsif ($ch eq '觶') {
			$vars = '[觶觯]';
		} elsif ($ch eq '觸') {
			$vars = '[觸触]';
		} elsif ($ch eq '訂') {
			$vars = '[訂订]';
		} elsif ($ch eq '訃') {
			$vars = '[訃讣]';
		} elsif ($ch eq '訇') {
			$vars = '[訇渹]';
		} elsif ($ch eq '計') {
			$vars = '[計计]';
		} elsif ($ch eq '訊') {
			$vars = '[訊讯]';
		} elsif ($ch eq '訌') {
			$vars = '[訌讧]';
		} elsif ($ch eq '討') {
			$vars = '[討讨]';
		} elsif ($ch eq '訐') {
			$vars = '[訐讦]';
		} elsif ($ch eq '訓') {
			$vars = '[訓训]';
		} elsif ($ch eq '訕') {
			$vars = '[訕讪]';
		} elsif ($ch eq '訖') {
			$vars = '[訖讫]';
		} elsif ($ch eq '託') {
			$vars = '[託侂]';
		} elsif ($ch eq '記') {
			$vars = '[記记]';
		} elsif ($ch eq '訛') {
			$vars = '[訛讹譌]';
		} elsif ($ch eq '訝') {
			$vars = '[訝讶]';
		} elsif ($ch eq '訟') {
			$vars = '[訟讼]';
		} elsif ($ch eq '訣') {
			$vars = '[訣诀]';
		} elsif ($ch eq '訥') {
			$vars = '[訥讷吶]';
		} elsif ($ch eq '訪') {
			$vars = '[訪访]';
		} elsif ($ch eq '設') {
			$vars = '[設设]';
		} elsif ($ch eq '許') {
			$vars = '[許许]';
		} elsif ($ch eq '訳') {
			$vars = '[訳譯]';
		} elsif ($ch eq '訴') {
			$vars = '[訴诉愬]';
		} elsif ($ch eq '訶') {
			$vars = '[訶呵诃]';
		} elsif ($ch eq '診') {
			$vars = '[診诊]';
		} elsif ($ch eq '註') {
			$vars = '[註注]';
		} elsif ($ch eq '証') {
			$vars = '[証證]';
		} elsif ($ch eq '詁') {
			$vars = '[詁诂]';
		} elsif ($ch eq '詆') {
			$vars = '[詆诋]';
		} elsif ($ch eq '詎') {
			$vars = '[詎讵]';
		} elsif ($ch eq '詐') {
			$vars = '[詐醡诈]';
		} elsif ($ch eq '詒') {
			$vars = '[詒诒]';
		} elsif ($ch eq '詔') {
			$vars = '[詔诏]';
		} elsif ($ch eq '評') {
			$vars = '[評评]';
		} elsif ($ch eq '詘') {
			$vars = '[詘诎]';
		} elsif ($ch eq '詛') {
			$vars = '[詛诅]';
		} elsif ($ch eq '詞') {
			$vars = '[詞词]';
		} elsif ($ch eq '詠') {
			$vars = '[詠咏]';
		} elsif ($ch eq '詡') {
			$vars = '[詡诩]';
		} elsif ($ch eq '詢') {
			$vars = '[詢询]';
		} elsif ($ch eq '詣') {
			$vars = '[詣诣]';
		} elsif ($ch eq '試') {
			$vars = '[試试]';
		} elsif ($ch eq '詩') {
			$vars = '[詩诗]';
		} elsif ($ch eq '詫') {
			$vars = '[詫诧]';
		} elsif ($ch eq '詬') {
			$vars = '[詬诟呴]';
		} elsif ($ch eq '詭') {
			$vars = '[詭诡]';
		} elsif ($ch eq '詮') {
			$vars = '[詮诠]';
		} elsif ($ch eq '詰') {
			$vars = '[詰诘]';
		} elsif ($ch eq '話') {
			$vars = '[話话]';
		} elsif ($ch eq '該') {
			$vars = '[該该]';
		} elsif ($ch eq '詳') {
			$vars = '[詳详]';
		} elsif ($ch eq '詵') {
			$vars = '[詵诜侁駪]';
		} elsif ($ch eq '詶') {
			$vars = '[詶酬]';
		} elsif ($ch eq '詻') {
			$vars = '[詻咯]';
		} elsif ($ch eq '詼') {
			$vars = '[詼诙]';
		} elsif ($ch eq '詿') {
			$vars = '[詿诖]';
		} elsif ($ch eq '誄') {
			$vars = '[誄诔]';
		} elsif ($ch eq '誅') {
			$vars = '[誅诛]';
		} elsif ($ch eq '誆') {
			$vars = '[誆诓]';
		} elsif ($ch eq '誇') {
			$vars = '[誇夸]';
		} elsif ($ch eq '誉') {
			$vars = '[誉譽]';
		} elsif ($ch eq '誊') {
			$vars = '[誊謄]';
		} elsif ($ch eq '誌') {
			$vars = '[誌志]';
		} elsif ($ch eq '認') {
			$vars = '[認认]';
		} elsif ($ch eq '誑') {
			$vars = '[誑诳]';
		} elsif ($ch eq '誒') {
			$vars = '[誒唉诶]';
		} elsif ($ch eq '誕') {
			$vars = '[誕诞]';
		} elsif ($ch eq '誘') {
			$vars = '[誘诱]';
		} elsif ($ch eq '誚') {
			$vars = '[誚譙诮]';
		} elsif ($ch eq '語') {
			$vars = '[語语]';
		} elsif ($ch eq '誠') {
			$vars = '[誠诚]';
		} elsif ($ch eq '誡') {
			$vars = '[誡诫]';
		} elsif ($ch eq '誣') {
			$vars = '[誣诬]';
		} elsif ($ch eq '誤') {
			$vars = '[誤误]';
		} elsif ($ch eq '誥') {
			$vars = '[誥诰]';
		} elsif ($ch eq '誦') {
			$vars = '[誦诵]';
		} elsif ($ch eq '誨') {
			$vars = '[誨诲]';
		} elsif ($ch eq '說') {
			$vars = '[說説说]';
		} elsif ($ch eq '説') {
			$vars = '[説說说]';
		} elsif ($ch eq '読') {
			$vars = '[読讀]';
		} elsif ($ch eq '誰') {
			$vars = '[誰谁]';
		} elsif ($ch eq '課') {
			$vars = '[課课]';
		} elsif ($ch eq '誶') {
			$vars = '[誶谇]';
		} elsif ($ch eq '誹') {
			$vars = '[誹诽]';
		} elsif ($ch eq '誼') {
			$vars = '[誼谊]';
		} elsif ($ch eq '調') {
			$vars = '[調调]';
		} elsif ($ch eq '諂') {
			$vars = '[諂谄]';
		} elsif ($ch eq '諄') {
			$vars = '[諄谆]';
		} elsif ($ch eq '談') {
			$vars = '[談譚谈]';
		} elsif ($ch eq '諉') {
			$vars = '[諉诿餵]';
		} elsif ($ch eq '請') {
			$vars = '[請请]';
		} elsif ($ch eq '諌') {
			$vars = '[諌諫]';
		} elsif ($ch eq '諍') {
			$vars = '[諍诤]';
		} elsif ($ch eq '諏') {
			$vars = '[諏诹]';
		} elsif ($ch eq '諑') {
			$vars = '[諑诼]';
		} elsif ($ch eq '諒') {
			$vars = '[諒谅]';
		} elsif ($ch eq '諕') {
			$vars = '[諕唬]';
		} elsif ($ch eq '論') {
			$vars = '[論论論]';
		} elsif ($ch eq '諗') {
			$vars = '[諗谂]';
		} elsif ($ch eq '諛') {
			$vars = '[諛谀]';
		} elsif ($ch eq '諜') {
			$vars = '[諜谍]';
		} elsif ($ch eq '諞') {
			$vars = '[諞谝]';
		} elsif ($ch eq '諠') {
			$vars = '[諠喧]';
		} elsif ($ch eq '諡') {
			$vars = '[諡謚]';
		} elsif ($ch eq '諢') {
			$vars = '[諢诨]';
		} elsif ($ch eq '諤') {
			$vars = '[諤谔囮]';
		} elsif ($ch eq '諦') {
			$vars = '[諦谛]';
		} elsif ($ch eq '諧') {
			$vars = '[諧谐龤]';
		} elsif ($ch eq '諫') {
			$vars = '[諫谏]';
		} elsif ($ch eq '諭') {
			$vars = '[諭谕]';
		} elsif ($ch eq '諮') {
			$vars = '[諮谘咨]';
		} elsif ($ch eq '諱') {
			$vars = '[諱讳]';
		} elsif ($ch eq '諳') {
			$vars = '[諳谙]';
		} elsif ($ch eq '諵') {
			$vars = '[諵喃]';
		} elsif ($ch eq '諶') {
			$vars = '[諶谌]';
		} elsif ($ch eq '諷') {
			$vars = '[諷讽]';
		} elsif ($ch eq '諸') {
			$vars = '[諸诸]';
		} elsif ($ch eq '諺') {
			$vars = '[諺谚]';
		} elsif ($ch eq '諼') {
			$vars = '[諼煖谖]';
		} elsif ($ch eq '諾') {
			$vars = '[諾诺]';
		} elsif ($ch eq '謀') {
			$vars = '[謀谋]';
		} elsif ($ch eq '謁') {
			$vars = '[謁谒]';
		} elsif ($ch eq '謂') {
			$vars = '[謂谓]';
		} elsif ($ch eq '謄') {
			$vars = '[謄誊]';
		} elsif ($ch eq '謅') {
			$vars = '[謅诌]';
		} elsif ($ch eq '謊') {
			$vars = '[謊谎]';
		} elsif ($ch eq '謌') {
			$vars = '[謌歌]';
		} elsif ($ch eq '謎') {
			$vars = '[謎谜]';
		} elsif ($ch eq '謐') {
			$vars = '[謐谧]';
		} elsif ($ch eq '謔') {
			$vars = '[謔谑]';
		} elsif ($ch eq '謖') {
			$vars = '[謖谡]';
		} elsif ($ch eq '謗') {
			$vars = '[謗谤]';
		} elsif ($ch eq '謙') {
			$vars = '[謙谦]';
		} elsif ($ch eq '謚') {
			$vars = '[謚諡谥]';
		} elsif ($ch eq '講') {
			$vars = '[講讲]';
		} elsif ($ch eq '謝') {
			$vars = '[謝谢]';
		} elsif ($ch eq '謠') {
			$vars = '[謠谣]';
		} elsif ($ch eq '謡') {
			$vars = '[謡谣謠]';
		} elsif ($ch eq '謨') {
			$vars = '[謨谟]';
		} elsif ($ch eq '謫') {
			$vars = '[謫谪]';
		} elsif ($ch eq '謬') {
			$vars = '[謬谬]';
		} elsif ($ch eq '謱') {
			$vars = '[謱嘍]';
		} elsif ($ch eq '謳') {
			$vars = '[謳讴]';
		} elsif ($ch eq '謹') {
			$vars = '[謹谨]';
		} elsif ($ch eq '謼') {
			$vars = '[謼呼]';
		} elsif ($ch eq '謾') {
			$vars = '[謾谩]';
		} elsif ($ch eq '譁') {
			$vars = '[譁嘩哗]';
		} elsif ($ch eq '譈') {
			$vars = '[譈懟憝]';
		} elsif ($ch eq '證') {
			$vars = '[證证証]';
		} elsif ($ch eq '譌') {
			$vars = '[譌訛]';
		} elsif ($ch eq '譎') {
			$vars = '[譎憰谲]';
		} elsif ($ch eq '譏') {
			$vars = '[譏讥]';
		} elsif ($ch eq '譐') {
			$vars = '[譐噂]';
		} elsif ($ch eq '譖') {
			$vars = '[譖谮]';
		} elsif ($ch eq '識') {
			$vars = '[識识]';
		} elsif ($ch eq '譙') {
			$vars = '[譙谯誚]';
		} elsif ($ch eq '譚') {
			$vars = '[譚談谭]';
		} elsif ($ch eq '譜') {
			$vars = '[譜谱]';
		} elsif ($ch eq '譟') {
			$vars = '[譟噪]';
		} elsif ($ch eq '警') {
			$vars = '[警儆]';
		} elsif ($ch eq '譫') {
			$vars = '[譫谵]';
		} elsif ($ch eq '譯') {
			$vars = '[譯訳译]';
		} elsif ($ch eq '議') {
			$vars = '[議议]';
		} elsif ($ch eq '譱') {
			$vars = '[譱善]';
		} elsif ($ch eq '譲') {
			$vars = '[譲讓]';
		} elsif ($ch eq '譴') {
			$vars = '[譴谴]';
		} elsif ($ch eq '護') {
			$vars = '[護护]';
		} elsif ($ch eq '譽') {
			$vars = '[譽域誉]';
		} elsif ($ch eq '譾') {
			$vars = '[譾谫]';
		} elsif ($ch eq '讀') {
			$vars = '[讀讀读]';
		} elsif ($ch eq '讃') {
			$vars = '[讃讚]';
		} elsif ($ch eq '變') {
			$vars = '[變変变]';
		} elsif ($ch eq '讌') {
			$vars = '[讌宴燕]';
		} elsif ($ch eq '讎') {
			$vars = '[讎讐仇雠]';
		} elsif ($ch eq '讐') {
			$vars = '[讐仇讎]';
		} elsif ($ch eq '讒') {
			$vars = '[讒谗]';
		} elsif ($ch eq '讓') {
			$vars = '[讓让]';
		} elsif ($ch eq '讕') {
			$vars = '[讕谰]';
		} elsif ($ch eq '讖') {
			$vars = '[讖谶]';
		} elsif ($ch eq '讘') {
			$vars = '[讘囁]';
		} elsif ($ch eq '讙') {
			$vars = '[讙歡]';
		} elsif ($ch eq '讚') {
			$vars = '[讚讃]';
		} elsif ($ch eq '讜') {
			$vars = '[讜谠]';
		} elsif ($ch eq '讞') {
			$vars = '[讞谳]';
		} elsif ($ch eq '讠') {
			$vars = '[讠言]';
		} elsif ($ch eq '计') {
			$vars = '[计計]';
		} elsif ($ch eq '订') {
			$vars = '[订訂]';
		} elsif ($ch eq '讣') {
			$vars = '[讣訃]';
		} elsif ($ch eq '认') {
			$vars = '[认認]';
		} elsif ($ch eq '讥') {
			$vars = '[讥譏]';
		} elsif ($ch eq '讦') {
			$vars = '[讦訐]';
		} elsif ($ch eq '讧') {
			$vars = '[讧訌]';
		} elsif ($ch eq '讨') {
			$vars = '[讨討]';
		} elsif ($ch eq '让') {
			$vars = '[让讓]';
		} elsif ($ch eq '讪') {
			$vars = '[讪訕]';
		} elsif ($ch eq '讫') {
			$vars = '[讫訖]';
		} elsif ($ch eq '训') {
			$vars = '[训訓]';
		} elsif ($ch eq '议') {
			$vars = '[议議]';
		} elsif ($ch eq '讯') {
			$vars = '[讯訊]';
		} elsif ($ch eq '记') {
			$vars = '[记記]';
		} elsif ($ch eq '讲') {
			$vars = '[讲講]';
		} elsif ($ch eq '讳') {
			$vars = '[讳諱]';
		} elsif ($ch eq '讴') {
			$vars = '[讴謳]';
		} elsif ($ch eq '讵') {
			$vars = '[讵詎]';
		} elsif ($ch eq '讶') {
			$vars = '[讶訝]';
		} elsif ($ch eq '讷') {
			$vars = '[讷訥]';
		} elsif ($ch eq '许') {
			$vars = '[许許]';
		} elsif ($ch eq '讹') {
			$vars = '[讹訛]';
		} elsif ($ch eq '论') {
			$vars = '[论論]';
		} elsif ($ch eq '讼') {
			$vars = '[讼訟]';
		} elsif ($ch eq '讽') {
			$vars = '[讽諷]';
		} elsif ($ch eq '设') {
			$vars = '[设設]';
		} elsif ($ch eq '访') {
			$vars = '[访訪]';
		} elsif ($ch eq '诀') {
			$vars = '[诀訣]';
		} elsif ($ch eq '证') {
			$vars = '[证證]';
		} elsif ($ch eq '诂') {
			$vars = '[诂詁]';
		} elsif ($ch eq '诃') {
			$vars = '[诃訶呵]';
		} elsif ($ch eq '评') {
			$vars = '[评評]';
		} elsif ($ch eq '诅') {
			$vars = '[诅詛]';
		} elsif ($ch eq '识') {
			$vars = '[识識]';
		} elsif ($ch eq '诈') {
			$vars = '[诈詐]';
		} elsif ($ch eq '诉') {
			$vars = '[诉訴]';
		} elsif ($ch eq '诊') {
			$vars = '[诊診]';
		} elsif ($ch eq '诋') {
			$vars = '[诋詆]';
		} elsif ($ch eq '诌') {
			$vars = '[诌謅]';
		} elsif ($ch eq '词') {
			$vars = '[词詞]';
		} elsif ($ch eq '诎') {
			$vars = '[诎詘]';
		} elsif ($ch eq '诏') {
			$vars = '[诏詔]';
		} elsif ($ch eq '译') {
			$vars = '[译譯]';
		} elsif ($ch eq '诒') {
			$vars = '[诒詒]';
		} elsif ($ch eq '诓') {
			$vars = '[诓誆]';
		} elsif ($ch eq '诔') {
			$vars = '[诔誄]';
		} elsif ($ch eq '试') {
			$vars = '[试試]';
		} elsif ($ch eq '诖') {
			$vars = '[诖詿]';
		} elsif ($ch eq '诗') {
			$vars = '[诗詩]';
		} elsif ($ch eq '诘') {
			$vars = '[诘詰]';
		} elsif ($ch eq '诙') {
			$vars = '[诙詼]';
		} elsif ($ch eq '诚') {
			$vars = '[诚誠]';
		} elsif ($ch eq '诛') {
			$vars = '[诛誅]';
		} elsif ($ch eq '诜') {
			$vars = '[诜詵]';
		} elsif ($ch eq '话') {
			$vars = '[话話]';
		} elsif ($ch eq '诞') {
			$vars = '[诞誕]';
		} elsif ($ch eq '诟') {
			$vars = '[诟詬]';
		} elsif ($ch eq '诠') {
			$vars = '[诠詮]';
		} elsif ($ch eq '诡') {
			$vars = '[诡詭]';
		} elsif ($ch eq '询') {
			$vars = '[询詢]';
		} elsif ($ch eq '诣') {
			$vars = '[诣詣]';
		} elsif ($ch eq '诤') {
			$vars = '[诤諍]';
		} elsif ($ch eq '该') {
			$vars = '[该該]';
		} elsif ($ch eq '详') {
			$vars = '[详詳]';
		} elsif ($ch eq '诧') {
			$vars = '[诧詫]';
		} elsif ($ch eq '诨') {
			$vars = '[诨諢]';
		} elsif ($ch eq '诩') {
			$vars = '[诩詡]';
		} elsif ($ch eq '诫') {
			$vars = '[诫誡]';
		} elsif ($ch eq '诬') {
			$vars = '[诬誣]';
		} elsif ($ch eq '语') {
			$vars = '[语語]';
		} elsif ($ch eq '诮') {
			$vars = '[诮誚]';
		} elsif ($ch eq '误') {
			$vars = '[误誤]';
		} elsif ($ch eq '诰') {
			$vars = '[诰誥]';
		} elsif ($ch eq '诱') {
			$vars = '[诱誘]';
		} elsif ($ch eq '诲') {
			$vars = '[诲誨]';
		} elsif ($ch eq '诳') {
			$vars = '[诳誑]';
		} elsif ($ch eq '说') {
			$vars = '[说説說]';
		} elsif ($ch eq '诵') {
			$vars = '[诵誦]';
		} elsif ($ch eq '诶') {
			$vars = '[诶唉誒]';
		} elsif ($ch eq '请') {
			$vars = '[请請]';
		} elsif ($ch eq '诸') {
			$vars = '[诸諸]';
		} elsif ($ch eq '诹') {
			$vars = '[诹諏]';
		} elsif ($ch eq '诺') {
			$vars = '[诺諾]';
		} elsif ($ch eq '读') {
			$vars = '[读讀]';
		} elsif ($ch eq '诼') {
			$vars = '[诼諑]';
		} elsif ($ch eq '诽') {
			$vars = '[诽誹]';
		} elsif ($ch eq '课') {
			$vars = '[课課]';
		} elsif ($ch eq '诿') {
			$vars = '[诿諉]';
		} elsif ($ch eq '谀') {
			$vars = '[谀諛]';
		} elsif ($ch eq '谁') {
			$vars = '[谁誰]';
		} elsif ($ch eq '谂') {
			$vars = '[谂諗]';
		} elsif ($ch eq '调') {
			$vars = '[调調]';
		} elsif ($ch eq '谄') {
			$vars = '[谄諂]';
		} elsif ($ch eq '谅') {
			$vars = '[谅諒]';
		} elsif ($ch eq '谆') {
			$vars = '[谆諄]';
		} elsif ($ch eq '谇') {
			$vars = '[谇誶]';
		} elsif ($ch eq '谈') {
			$vars = '[谈談]';
		} elsif ($ch eq '谊') {
			$vars = '[谊誼]';
		} elsif ($ch eq '谋') {
			$vars = '[谋謀]';
		} elsif ($ch eq '谌') {
			$vars = '[谌諶]';
		} elsif ($ch eq '谍') {
			$vars = '[谍諜]';
		} elsif ($ch eq '谎') {
			$vars = '[谎謊]';
		} elsif ($ch eq '谏') {
			$vars = '[谏諫]';
		} elsif ($ch eq '谐') {
			$vars = '[谐諧]';
		} elsif ($ch eq '谑') {
			$vars = '[谑謔]';
		} elsif ($ch eq '谒') {
			$vars = '[谒謁]';
		} elsif ($ch eq '谓') {
			$vars = '[谓謂]';
		} elsif ($ch eq '谔') {
			$vars = '[谔諤]';
		} elsif ($ch eq '谕') {
			$vars = '[谕諭]';
		} elsif ($ch eq '谖') {
			$vars = '[谖諼]';
		} elsif ($ch eq '谗') {
			$vars = '[谗讒]';
		} elsif ($ch eq '谘') {
			$vars = '[谘咨諮]';
		} elsif ($ch eq '谙') {
			$vars = '[谙諳]';
		} elsif ($ch eq '谚') {
			$vars = '[谚諺]';
		} elsif ($ch eq '谛') {
			$vars = '[谛諦]';
		} elsif ($ch eq '谜') {
			$vars = '[谜謎]';
		} elsif ($ch eq '谝') {
			$vars = '[谝諞]';
		} elsif ($ch eq '谟') {
			$vars = '[谟謨]';
		} elsif ($ch eq '谠') {
			$vars = '[谠讜]';
		} elsif ($ch eq '谡') {
			$vars = '[谡謖]';
		} elsif ($ch eq '谢') {
			$vars = '[谢謝]';
		} elsif ($ch eq '谣') {
			$vars = '[谣謠謡]';
		} elsif ($ch eq '谤') {
			$vars = '[谤謗]';
		} elsif ($ch eq '谥') {
			$vars = '[谥謚]';
		} elsif ($ch eq '谦') {
			$vars = '[谦謙]';
		} elsif ($ch eq '谧') {
			$vars = '[谧謐]';
		} elsif ($ch eq '谨') {
			$vars = '[谨謹]';
		} elsif ($ch eq '谩') {
			$vars = '[谩謾]';
		} elsif ($ch eq '谪') {
			$vars = '[谪謫]';
		} elsif ($ch eq '谫') {
			$vars = '[谫譾]';
		} elsif ($ch eq '谬') {
			$vars = '[谬謬]';
		} elsif ($ch eq '谭') {
			$vars = '[谭譚]';
		} elsif ($ch eq '谮') {
			$vars = '[谮譖]';
		} elsif ($ch eq '谯') {
			$vars = '[谯譙]';
		} elsif ($ch eq '谰') {
			$vars = '[谰讕]';
		} elsif ($ch eq '谱') {
			$vars = '[谱譜]';
		} elsif ($ch eq '谲') {
			$vars = '[谲譎]';
		} elsif ($ch eq '谳') {
			$vars = '[谳讞]';
		} elsif ($ch eq '谴') {
			$vars = '[谴譴]';
		} elsif ($ch eq '谵') {
			$vars = '[谵譫]';
		} elsif ($ch eq '谶') {
			$vars = '[谶讖]';
		} elsif ($ch eq '谷') {
			$vars = '[谷穀]';
		} elsif ($ch eq '豆') {
			$vars = '[豆荳]';
		} elsif ($ch eq '豈') {
			$vars = '[豈岂]';
		} elsif ($ch eq '豊') {
			$vars = '[豊豐]';
		} elsif ($ch eq '豋') {
			$vars = '[豋登]';
		} elsif ($ch eq '豎') {
			$vars = '[豎竖竪]';
		} elsif ($ch eq '豐') {
			$vars = '[豐丰豊]';
		} elsif ($ch eq '豔') {
			$vars = '[豔艶]';
		} elsif ($ch eq '豫') {
			$vars = '[豫預予]';
		} elsif ($ch eq '豬') {
			$vars = '[豬猪]';
		} elsif ($ch eq '豳') {
			$vars = '[豳邠]';
		} elsif ($ch eq '豸') {
			$vars = '[豸廌]';
		} elsif ($ch eq '豺') {
			$vars = '[豺犲]';
		} elsif ($ch eq '豻') {
			$vars = '[豻犴]';
		} elsif ($ch eq '貉') {
			$vars = '[貉狢]';
		} elsif ($ch eq '貊') {
			$vars = '[貊貘]';
		} elsif ($ch eq '貌') {
			$vars = '[貌皃]';
		} elsif ($ch eq '貍') {
			$vars = '[貍狸]';
		} elsif ($ch eq '貎') {
			$vars = '[貎皃]';
		} elsif ($ch eq '貓') {
			$vars = '[貓猫]';
		} elsif ($ch eq '貘') {
			$vars = '[貘貊]';
		} elsif ($ch eq '貝') {
			$vars = '[貝贝]';
		} elsif ($ch eq '貞') {
			$vars = '[貞贞]';
		} elsif ($ch eq '負') {
			$vars = '[負负]';
		} elsif ($ch eq '財') {
			$vars = '[財才财]';
		} elsif ($ch eq '貢') {
			$vars = '[貢贡]';
		} elsif ($ch eq '貧') {
			$vars = '[貧贫]';
		} elsif ($ch eq '貨') {
			$vars = '[貨货]';
		} elsif ($ch eq '販') {
			$vars = '[販贩]';
		} elsif ($ch eq '貪') {
			$vars = '[貪贪]';
		} elsif ($ch eq '貫') {
			$vars = '[貫贯]';
		} elsif ($ch eq '責') {
			$vars = '[責拆责]';
		} elsif ($ch eq '貭') {
			$vars = '[貭質]';
		} elsif ($ch eq '貮') {
			$vars = '[貮二]';
		} elsif ($ch eq '貯') {
			$vars = '[貯贮]';
		} elsif ($ch eq '貰') {
			$vars = '[貰贳]';
		} elsif ($ch eq '貲') {
			$vars = '[貲赀]';
		} elsif ($ch eq '貳') {
			$vars = '[貳二弍贰]';
		} elsif ($ch eq '貴') {
			$vars = '[貴贵]';
		} elsif ($ch eq '貶') {
			$vars = '[貶贬]';
		} elsif ($ch eq '買') {
			$vars = '[買买]';
		} elsif ($ch eq '貸') {
			$vars = '[貸贷]';
		} elsif ($ch eq '貺') {
			$vars = '[貺贶]';
		} elsif ($ch eq '費') {
			$vars = '[費费]';
		} elsif ($ch eq '貼') {
			$vars = '[貼贴]';
		} elsif ($ch eq '貽') {
			$vars = '[貽贻]';
		} elsif ($ch eq '貿') {
			$vars = '[貿贸]';
		} elsif ($ch eq '賀') {
			$vars = '[賀贺]';
		} elsif ($ch eq '賁') {
			$vars = '[賁贲]';
		} elsif ($ch eq '賂') {
			$vars = '[賂赂]';
		} elsif ($ch eq '賃') {
			$vars = '[賃赁]';
		} elsif ($ch eq '賄') {
			$vars = '[賄贿]';
		} elsif ($ch eq '賅') {
			$vars = '[賅赅侅]';
		} elsif ($ch eq '資') {
			$vars = '[資资]';
		} elsif ($ch eq '賈') {
			$vars = '[賈贾]';
		} elsif ($ch eq '賊') {
			$vars = '[賊戝贼]';
		} elsif ($ch eq '賍') {
			$vars = '[賍贓]';
		} elsif ($ch eq '賑') {
			$vars = '[賑赈]';
		} elsif ($ch eq '賒') {
			$vars = '[賒赊]';
		} elsif ($ch eq '賓') {
			$vars = '[賓宾]';
		} elsif ($ch eq '賕') {
			$vars = '[賕赇]';
		} elsif ($ch eq '賚') {
			$vars = '[賚赉]';
		} elsif ($ch eq '賛') {
			$vars = '[賛贊]';
		} elsif ($ch eq '賜') {
			$vars = '[賜赐]';
		} elsif ($ch eq '賞') {
			$vars = '[賞赏]';
		} elsif ($ch eq '賠') {
			$vars = '[賠赔]';
		} elsif ($ch eq '賡') {
			$vars = '[賡赓]';
		} elsif ($ch eq '賢') {
			$vars = '[賢贤]';
		} elsif ($ch eq '賣') {
			$vars = '[賣売卖]';
		} elsif ($ch eq '賤') {
			$vars = '[賤贱]';
		} elsif ($ch eq '賦') {
			$vars = '[賦赋]';
		} elsif ($ch eq '賧') {
			$vars = '[賧赕]';
		} elsif ($ch eq '質') {
			$vars = '[質质貭]';
		} elsif ($ch eq '賬') {
			$vars = '[賬账帳]';
		} elsif ($ch eq '賭') {
			$vars = '[賭赌]';
		} elsif ($ch eq '賮') {
			$vars = '[賮贐]';
		} elsif ($ch eq '賴') {
			$vars = '[賴頼赖]';
		} elsif ($ch eq '賸') {
			$vars = '[賸剩]';
		} elsif ($ch eq '賺') {
			$vars = '[賺赚]';
		} elsif ($ch eq '賻') {
			$vars = '[賻赙]';
		} elsif ($ch eq '購') {
			$vars = '[購购]';
		} elsif ($ch eq '賽') {
			$vars = '[賽赛]';
		} elsif ($ch eq '賾') {
			$vars = '[賾赜]';
		} elsif ($ch eq '贄') {
			$vars = '[贄贽]';
		} elsif ($ch eq '贅') {
			$vars = '[贅赘]';
		} elsif ($ch eq '贈') {
			$vars = '[贈赠]';
		} elsif ($ch eq '贊') {
			$vars = '[贊赞賛]';
		} elsif ($ch eq '贋') {
			$vars = '[贋赝贗偐]';
		} elsif ($ch eq '贍') {
			$vars = '[贍赡]';
		} elsif ($ch eq '贏') {
			$vars = '[贏赢]';
		} elsif ($ch eq '贐') {
			$vars = '[贐賮赆]';
		} elsif ($ch eq '贓') {
			$vars = '[贓賍赃]';
		} elsif ($ch eq '贖') {
			$vars = '[贖赎]';
		} elsif ($ch eq '贗') {
			$vars = '[贗赝贋偐]';
		} elsif ($ch eq '贛') {
			$vars = '[贛赣]';
		} elsif ($ch eq '贝') {
			$vars = '[贝貝]';
		} elsif ($ch eq '贞') {
			$vars = '[贞貞]';
		} elsif ($ch eq '负') {
			$vars = '[负負]';
		} elsif ($ch eq '贡') {
			$vars = '[贡貢]';
		} elsif ($ch eq '财') {
			$vars = '[财財]';
		} elsif ($ch eq '责') {
			$vars = '[责責]';
		} elsif ($ch eq '贤') {
			$vars = '[贤賢]';
		} elsif ($ch eq '败') {
			$vars = '[败敗]';
		} elsif ($ch eq '账') {
			$vars = '[账帳賬]';
		} elsif ($ch eq '货') {
			$vars = '[货貨]';
		} elsif ($ch eq '质') {
			$vars = '[质質]';
		} elsif ($ch eq '贩') {
			$vars = '[贩販]';
		} elsif ($ch eq '贪') {
			$vars = '[贪貪]';
		} elsif ($ch eq '贫') {
			$vars = '[贫貧]';
		} elsif ($ch eq '贬') {
			$vars = '[贬貶]';
		} elsif ($ch eq '购') {
			$vars = '[购購]';
		} elsif ($ch eq '贮') {
			$vars = '[贮貯]';
		} elsif ($ch eq '贯') {
			$vars = '[贯貫]';
		} elsif ($ch eq '贰') {
			$vars = '[贰二貳]';
		} elsif ($ch eq '贱') {
			$vars = '[贱賤]';
		} elsif ($ch eq '贲') {
			$vars = '[贲賁]';
		} elsif ($ch eq '贳') {
			$vars = '[贳貰]';
		} elsif ($ch eq '贴') {
			$vars = '[贴貼]';
		} elsif ($ch eq '贵') {
			$vars = '[贵貴]';
		} elsif ($ch eq '贶') {
			$vars = '[贶貺]';
		} elsif ($ch eq '贷') {
			$vars = '[贷貸]';
		} elsif ($ch eq '贸') {
			$vars = '[贸貿]';
		} elsif ($ch eq '费') {
			$vars = '[费費]';
		} elsif ($ch eq '贺') {
			$vars = '[贺賀]';
		} elsif ($ch eq '贻') {
			$vars = '[贻貽]';
		} elsif ($ch eq '贼') {
			$vars = '[贼賊]';
		} elsif ($ch eq '贽') {
			$vars = '[贽贄]';
		} elsif ($ch eq '贾') {
			$vars = '[贾賈]';
		} elsif ($ch eq '贿') {
			$vars = '[贿賄]';
		} elsif ($ch eq '赀') {
			$vars = '[赀貲]';
		} elsif ($ch eq '赁') {
			$vars = '[赁賃]';
		} elsif ($ch eq '赂') {
			$vars = '[赂賂]';
		} elsif ($ch eq '赃') {
			$vars = '[赃贓]';
		} elsif ($ch eq '资') {
			$vars = '[资資]';
		} elsif ($ch eq '赅') {
			$vars = '[赅賅]';
		} elsif ($ch eq '赆') {
			$vars = '[赆贐]';
		} elsif ($ch eq '赇') {
			$vars = '[赇賕]';
		} elsif ($ch eq '赈') {
			$vars = '[赈賑]';
		} elsif ($ch eq '赉') {
			$vars = '[赉賚]';
		} elsif ($ch eq '赊') {
			$vars = '[赊賒]';
		} elsif ($ch eq '赋') {
			$vars = '[赋賦]';
		} elsif ($ch eq '赌') {
			$vars = '[赌賭]';
		} elsif ($ch eq '赍') {
			$vars = '[赍齎]';
		} elsif ($ch eq '赎') {
			$vars = '[赎贖]';
		} elsif ($ch eq '赏') {
			$vars = '[赏賞]';
		} elsif ($ch eq '赐') {
			$vars = '[赐賜]';
		} elsif ($ch eq '赓') {
			$vars = '[赓賡]';
		} elsif ($ch eq '赔') {
			$vars = '[赔賠]';
		} elsif ($ch eq '赕') {
			$vars = '[赕賧]';
		} elsif ($ch eq '赖') {
			$vars = '[赖賴]';
		} elsif ($ch eq '赘') {
			$vars = '[赘贅]';
		} elsif ($ch eq '赙') {
			$vars = '[赙賻]';
		} elsif ($ch eq '赚') {
			$vars = '[赚賺]';
		} elsif ($ch eq '赛') {
			$vars = '[赛賽]';
		} elsif ($ch eq '赜') {
			$vars = '[赜賾]';
		} elsif ($ch eq '赝') {
			$vars = '[赝贗贋]';
		} elsif ($ch eq '赞') {
			$vars = '[赞贊]';
		} elsif ($ch eq '赠') {
			$vars = '[赠贈]';
		} elsif ($ch eq '赡') {
			$vars = '[赡贍]';
		} elsif ($ch eq '赢') {
			$vars = '[赢贏]';
		} elsif ($ch eq '赣') {
			$vars = '[赣贛]';
		} elsif ($ch eq '走') {
			$vars = '[走赱]';
		} elsif ($ch eq '赱') {
			$vars = '[赱走]';
		} elsif ($ch eq '赵') {
			$vars = '[赵趙]';
		} elsif ($ch eq '赶') {
			$vars = '[赶趕]';
		} elsif ($ch eq '趄') {
			$vars = '[趄跙]';
		} elsif ($ch eq '趋') {
			$vars = '[趋趨]';
		} elsif ($ch eq '趒') {
			$vars = '[趒跳]';
		} elsif ($ch eq '趕') {
			$vars = '[趕赶]';
		} elsif ($ch eq '趙') {
			$vars = '[趙赵]';
		} elsif ($ch eq '趨') {
			$vars = '[趨趋]';
		} elsif ($ch eq '趮') {
			$vars = '[趮躁]';
		} elsif ($ch eq '趯') {
			$vars = '[趯躍]';
		} elsif ($ch eq '趱') {
			$vars = '[趱趲]';
		} elsif ($ch eq '趲') {
			$vars = '[趲趱]';
		} elsif ($ch eq '趸') {
			$vars = '[趸躉]';
		} elsif ($ch eq '跃') {
			$vars = '[跃躍]';
		} elsif ($ch eq '跄') {
			$vars = '[跄蹌]';
		} elsif ($ch eq '跐') {
			$vars = '[跐跴]';
		} elsif ($ch eq '跖') {
			$vars = '[跖蹠]';
		} elsif ($ch eq '跙') {
			$vars = '[跙趄]';
		} elsif ($ch eq '跞') {
			$vars = '[跞躒]';
		} elsif ($ch eq '跡') {
			$vars = '[跡迹速蹟]';
		} elsif ($ch eq '路') {
			$vars = '[路路]';
		} elsif ($ch eq '跳') {
			$vars = '[跳趒]';
		} elsif ($ch eq '跴') {
			$vars = '[跴踹跐]';
		} elsif ($ch eq '践') {
			$vars = '[践踐]';
		} elsif ($ch eq '跷') {
			$vars = '[跷蹺]';
		} elsif ($ch eq '跸') {
			$vars = '[跸蹕]';
		} elsif ($ch eq '跹') {
			$vars = '[跹躚]';
		} elsif ($ch eq '跻') {
			$vars = '[跻躋]';
		} elsif ($ch eq '踊') {
			$vars = '[踊踴]';
		} elsif ($ch eq '踌') {
			$vars = '[踌躊]';
		} elsif ($ch eq '踏') {
			$vars = '[踏蹋]';
		} elsif ($ch eq '踐') {
			$vars = '[踐践]';
		} elsif ($ch eq '踦') {
			$vars = '[踦犄]';
		} elsif ($ch eq '踪') {
			$vars = '[踪蹤]';
		} elsif ($ch eq '踬') {
			$vars = '[踬躓]';
		} elsif ($ch eq '踯') {
			$vars = '[踯躑]';
		} elsif ($ch eq '踰') {
			$vars = '[踰逾]';
		} elsif ($ch eq '踴') {
			$vars = '[踴踊]';
		} elsif ($ch eq '踹') {
			$vars = '[踹跴]';
		} elsif ($ch eq '踽') {
			$vars = '[踽偊]';
		} elsif ($ch eq '蹋') {
			$vars = '[蹋踏]';
		} elsif ($ch eq '蹌') {
			$vars = '[蹌牄跄]';
		} elsif ($ch eq '蹑') {
			$vars = '[蹑躡]';
		} elsif ($ch eq '蹒') {
			$vars = '[蹒蹣]';
		} elsif ($ch eq '蹕') {
			$vars = '[蹕跸]';
		} elsif ($ch eq '蹝') {
			$vars = '[蹝屣]';
		} elsif ($ch eq '蹟') {
			$vars = '[蹟迹速跡]';
		} elsif ($ch eq '蹠') {
			$vars = '[蹠跖]';
		} elsif ($ch eq '蹣') {
			$vars = '[蹣蹒]';
		} elsif ($ch eq '蹤') {
			$vars = '[蹤踪]';
		} elsif ($ch eq '蹧') {
			$vars = '[蹧遭]';
		} elsif ($ch eq '蹭') {
			$vars = '[蹭矰]';
		} elsif ($ch eq '蹰') {
			$vars = '[蹰躕]';
		} elsif ($ch eq '蹺') {
			$vars = '[蹺蹻跷]';
		} elsif ($ch eq '蹻') {
			$vars = '[蹻蹺]';
		} elsif ($ch eq '蹿') {
			$vars = '[蹿躥]';
		} elsif ($ch eq '躁') {
			$vars = '[躁趮]';
		} elsif ($ch eq '躉') {
			$vars = '[躉趸]';
		} elsif ($ch eq '躊') {
			$vars = '[躊踌]';
		} elsif ($ch eq '躋') {
			$vars = '[躋隮跻]';
		} elsif ($ch eq '躍') {
			$vars = '[躍跃趯]';
		} elsif ($ch eq '躏') {
			$vars = '[躏躪]';
		} elsif ($ch eq '躑') {
			$vars = '[躑踯]';
		} elsif ($ch eq '躒') {
			$vars = '[躒跞]';
		} elsif ($ch eq '躓') {
			$vars = '[躓踬]';
		} elsif ($ch eq '躕') {
			$vars = '[躕蹰]';
		} elsif ($ch eq '躚') {
			$vars = '[躚跹]';
		} elsif ($ch eq '躜') {
			$vars = '[躜躦]';
		} elsif ($ch eq '躡') {
			$vars = '[躡蹑]';
		} elsif ($ch eq '躥') {
			$vars = '[躥蹿]';
		} elsif ($ch eq '躦') {
			$vars = '[躦躜]';
		} elsif ($ch eq '躪') {
			$vars = '[躪躏]';
		} elsif ($ch eq '躯') {
			$vars = '[躯軀]';
		} elsif ($ch eq '躰') {
			$vars = '[躰體]';
		} elsif ($ch eq '躱') {
			$vars = '[躱躲]';
		} elsif ($ch eq '躲') {
			$vars = '[躲躱]';
		} elsif ($ch eq '軀') {
			$vars = '[軀躯]';
		} elsif ($ch eq '軆') {
			$vars = '[軆体體]';
		} elsif ($ch eq '車') {
			$vars = '[車车]';
		} elsif ($ch eq '軋') {
			$vars = '[軋轧]';
		} elsif ($ch eq '軌') {
			$vars = '[軌轨]';
		} elsif ($ch eq '軍') {
			$vars = '[軍军]';
		} elsif ($ch eq '軒') {
			$vars = '[軒轩]';
		} elsif ($ch eq '軔') {
			$vars = '[軔轫]';
		} elsif ($ch eq '軛') {
			$vars = '[軛轭]';
		} elsif ($ch eq '軟') {
			$vars = '[軟软]';
		} elsif ($ch eq '転') {
			$vars = '[転轉]';
		} elsif ($ch eq '軣') {
			$vars = '[軣轟]';
		} elsif ($ch eq '軫') {
			$vars = '[軫轸]';
		} elsif ($ch eq '軸') {
			$vars = '[軸轴]';
		} elsif ($ch eq '軹') {
			$vars = '[軹轵]';
		} elsif ($ch eq '軺') {
			$vars = '[軺轺]';
		} elsif ($ch eq '軻') {
			$vars = '[軻轲]';
		} elsif ($ch eq '軼') {
			$vars = '[軼轶]';
		} elsif ($ch eq '軽') {
			$vars = '[軽輕]';
		} elsif ($ch eq '軾') {
			$vars = '[軾轼]';
		} elsif ($ch eq '軿') {
			$vars = '[軿輧]';
		} elsif ($ch eq '較') {
			$vars = '[較较]';
		} elsif ($ch eq '輅') {
			$vars = '[輅辂]';
		} elsif ($ch eq '輇') {
			$vars = '[輇辁]';
		} elsif ($ch eq '載') {
			$vars = '[載载]';
		} elsif ($ch eq '輊') {
			$vars = '[輊轾]';
		} elsif ($ch eq '輌') {
			$vars = '[輌輛]';
		} elsif ($ch eq '輒') {
			$vars = '[輒辄輙]';
		} elsif ($ch eq '輓') {
			$vars = '[輓挽]';
		} elsif ($ch eq '輔') {
			$vars = '[輔辅]';
		} elsif ($ch eq '輕') {
			$vars = '[輕轻]';
		} elsif ($ch eq '輙') {
			$vars = '[輙輒]';
		} elsif ($ch eq '輛') {
			$vars = '[輛輌辆]';
		} elsif ($ch eq '輜') {
			$vars = '[輜辎]';
		} elsif ($ch eq '輝') {
			$vars = '[輝煇辉]';
		} elsif ($ch eq '輞') {
			$vars = '[輞辋]';
		} elsif ($ch eq '輟') {
			$vars = '[輟辍]';
		} elsif ($ch eq '輥') {
			$vars = '[輥辊]';
		} elsif ($ch eq '輦') {
			$vars = '[輦襜辇輦]';
		} elsif ($ch eq '輧') {
			$vars = '[輧軿]';
		} elsif ($ch eq '輩') {
			$vars = '[輩辈]';
		} elsif ($ch eq '輪') {
			$vars = '[輪輪轮]';
		} elsif ($ch eq '輯') {
			$vars = '[輯辑]';
		} elsif ($ch eq '輳') {
			$vars = '[輳辏]';
		} elsif ($ch eq '輵') {
			$vars = '[輵轕]';
		} elsif ($ch eq '輸') {
			$vars = '[輸输]';
		} elsif ($ch eq '輻') {
			$vars = '[輻輻辐]';
		} elsif ($ch eq '輾') {
			$vars = '[輾辗]';
		} elsif ($ch eq '輿') {
			$vars = '[輿舆轝]';
		} elsif ($ch eq '轂') {
			$vars = '[轂毂]';
		} elsif ($ch eq '轄') {
			$vars = '[轄辖]';
		} elsif ($ch eq '轅') {
			$vars = '[轅辕]';
		} elsif ($ch eq '轆') {
			$vars = '[轆辘]';
		} elsif ($ch eq '轉') {
			$vars = '[轉転转]';
		} elsif ($ch eq '轍') {
			$vars = '[轍辙]';
		} elsif ($ch eq '轎') {
			$vars = '[轎轿]';
		} elsif ($ch eq '轔') {
			$vars = '[轔辚]';
		} elsif ($ch eq '轕') {
			$vars = '[轕輵]';
		} elsif ($ch eq '轝') {
			$vars = '[轝輿]';
		} elsif ($ch eq '轟') {
			$vars = '[轟轰]';
		} elsif ($ch eq '轡') {
			$vars = '[轡辔]';
		} elsif ($ch eq '轢') {
			$vars = '[轢轢轹]';
		} elsif ($ch eq '轤') {
			$vars = '[轤轳]';
		} elsif ($ch eq '车') {
			$vars = '[车車]';
		} elsif ($ch eq '轧') {
			$vars = '[轧軋]';
		} elsif ($ch eq '轨') {
			$vars = '[轨軌]';
		} elsif ($ch eq '轩') {
			$vars = '[轩軒]';
		} elsif ($ch eq '轫') {
			$vars = '[轫軔]';
		} elsif ($ch eq '转') {
			$vars = '[转轉]';
		} elsif ($ch eq '轭') {
			$vars = '[轭軛]';
		} elsif ($ch eq '轮') {
			$vars = '[轮輪]';
		} elsif ($ch eq '软') {
			$vars = '[软軟]';
		} elsif ($ch eq '轰') {
			$vars = '[轰轟]';
		} elsif ($ch eq '轲') {
			$vars = '[轲軻]';
		} elsif ($ch eq '轳') {
			$vars = '[轳轤]';
		} elsif ($ch eq '轴') {
			$vars = '[轴軸]';
		} elsif ($ch eq '轵') {
			$vars = '[轵軹]';
		} elsif ($ch eq '轶') {
			$vars = '[轶軼]';
		} elsif ($ch eq '轸') {
			$vars = '[轸軫]';
		} elsif ($ch eq '轹') {
			$vars = '[轹轢]';
		} elsif ($ch eq '轺') {
			$vars = '[轺軺]';
		} elsif ($ch eq '轻') {
			$vars = '[轻輕]';
		} elsif ($ch eq '轼') {
			$vars = '[轼軾]';
		} elsif ($ch eq '载') {
			$vars = '[载載]';
		} elsif ($ch eq '轾') {
			$vars = '[轾輊]';
		} elsif ($ch eq '轿') {
			$vars = '[轿轎]';
		} elsif ($ch eq '辁') {
			$vars = '[辁輇]';
		} elsif ($ch eq '辂') {
			$vars = '[辂輅]';
		} elsif ($ch eq '较') {
			$vars = '[较較]';
		} elsif ($ch eq '辄') {
			$vars = '[辄輒]';
		} elsif ($ch eq '辅') {
			$vars = '[辅輔]';
		} elsif ($ch eq '辆') {
			$vars = '[辆輛]';
		} elsif ($ch eq '辇') {
			$vars = '[辇輦]';
		} elsif ($ch eq '辈') {
			$vars = '[辈輩]';
		} elsif ($ch eq '辉') {
			$vars = '[辉輝]';
		} elsif ($ch eq '辊') {
			$vars = '[辊輥]';
		} elsif ($ch eq '辋') {
			$vars = '[辋輞]';
		} elsif ($ch eq '辍') {
			$vars = '[辍輟]';
		} elsif ($ch eq '辎') {
			$vars = '[辎輜]';
		} elsif ($ch eq '辏') {
			$vars = '[辏輳]';
		} elsif ($ch eq '辐') {
			$vars = '[辐輻]';
		} elsif ($ch eq '辑') {
			$vars = '[辑輯]';
		} elsif ($ch eq '输') {
			$vars = '[输輸]';
		} elsif ($ch eq '辔') {
			$vars = '[辔轡]';
		} elsif ($ch eq '辕') {
			$vars = '[辕轅]';
		} elsif ($ch eq '辖') {
			$vars = '[辖轄]';
		} elsif ($ch eq '辗') {
			$vars = '[辗輾]';
		} elsif ($ch eq '辘') {
			$vars = '[辘轆]';
		} elsif ($ch eq '辙') {
			$vars = '[辙轍]';
		} elsif ($ch eq '辚') {
			$vars = '[辚轔]';
		} elsif ($ch eq '辞') {
			$vars = '[辞辭]';
		} elsif ($ch eq '辟') {
			$vars = '[辟避]';
		} elsif ($ch eq '辦') {
			$vars = '[辦办]';
		} elsif ($ch eq '辧') {
			$vars = '[辧辨]';
		} elsif ($ch eq '辨') {
			$vars = '[辨弁辯]';
		} elsif ($ch eq '辩') {
			$vars = '[辩辯]';
		} elsif ($ch eq '辫') {
			$vars = '[辫辮]';
		} elsif ($ch eq '辭') {
			$vars = '[辭辞]';
		} elsif ($ch eq '辮') {
			$vars = '[辮辫]';
		} elsif ($ch eq '辯') {
			$vars = '[辯辨辩]';
		} elsif ($ch eq '辰') {
			$vars = '[辰辰]';
		} elsif ($ch eq '農') {
			$vars = '[農农]';
		} elsif ($ch eq '边') {
			$vars = '[边邊]';
		} elsif ($ch eq '辺') {
			$vars = '[辺邊]';
		} elsif ($ch eq '辽') {
			$vars = '[辽遼]';
		} elsif ($ch eq '达') {
			$vars = '[达達]';
		} elsif ($ch eq '迁') {
			$vars = '[迁遷]';
		} elsif ($ch eq '迂') {
			$vars = '[迂遇]';
		} elsif ($ch eq '迆') {
			$vars = '[迆迤]';
		} elsif ($ch eq '过') {
			$vars = '[过過]';
		} elsif ($ch eq '迈') {
			$vars = '[迈邁]';
		} elsif ($ch eq '运') {
			$vars = '[运運]';
		} elsif ($ch eq '迕') {
			$vars = '[迕忤]';
		} elsif ($ch eq '还') {
			$vars = '[还還]';
		} elsif ($ch eq '这') {
			$vars = '[这這]';
		} elsif ($ch eq '进') {
			$vars = '[进進]';
		} elsif ($ch eq '远') {
			$vars = '[远遠]';
		} elsif ($ch eq '违') {
			$vars = '[违違]';
		} elsif ($ch eq '连') {
			$vars = '[连連]';
		} elsif ($ch eq '迟') {
			$vars = '[迟遲]';
		} elsif ($ch eq '迤') {
			$vars = '[迤迆]';
		} elsif ($ch eq '迥') {
			$vars = '[迥逈]';
		} elsif ($ch eq '迨') {
			$vars = '[迨逮]';
		} elsif ($ch eq '迩') {
			$vars = '[迩邇]';
		} elsif ($ch eq '迪') {
			$vars = '[迪廸]';
		} elsif ($ch eq '迭') {
			$vars = '[迭疊]';
		} elsif ($ch eq '迯') {
			$vars = '[迯逃]';
		} elsif ($ch eq '迳') {
			$vars = '[迳逕徑]';
		} elsif ($ch eq '迴') {
			$vars = '[迴回廻]';
		} elsif ($ch eq '迹') {
			$vars = '[迹速蹟跡]';
		} elsif ($ch eq '迺') {
			$vars = '[迺乃廼]';
		} elsif ($ch eq '迻') {
			$vars = '[迻移]';
		} elsif ($ch eq '适') {
			$vars = '[适適]';
		} elsif ($ch eq '逃') {
			$vars = '[逃迯]';
		} elsif ($ch eq '选') {
			$vars = '[选選]';
		} elsif ($ch eq '逊') {
			$vars = '[逊遜]';
		} elsif ($ch eq '递') {
			$vars = '[递遞]';
		} elsif ($ch eq '逓') {
			$vars = '[逓遞]';
		} elsif ($ch eq '逕') {
			$vars = '[逕迳徑]';
		} elsif ($ch eq '這') {
			$vars = '[這这]';
		} elsif ($ch eq '逞') {
			$vars = '[逞期]';
		} elsif ($ch eq '速') {
			$vars = '[速跡]';
		} elsif ($ch eq '連') {
			$vars = '[連连連]';
		} elsif ($ch eq '逦') {
			$vars = '[逦邐]';
		} elsif ($ch eq '逮') {
			$vars = '[逮迨]';
		} elsif ($ch eq '週') {
			$vars = '[週周]';
		} elsif ($ch eq '進') {
			$vars = '[進进]';
		} elsif ($ch eq '逹') {
			$vars = '[逹達]';
		} elsif ($ch eq '逻') {
			$vars = '[逻邏]';
		} elsif ($ch eq '逼') {
			$vars = '[逼偪]';
		} elsif ($ch eq '逾') {
			$vars = '[逾踰]';
		} elsif ($ch eq '逿') {
			$vars = '[逿盪]';
		} elsif ($ch eq '遅') {
			$vars = '[遅遲]';
		} elsif ($ch eq '遊') {
			$vars = '[遊游]';
		} elsif ($ch eq '運') {
			$vars = '[運运]';
		} elsif ($ch eq '過') {
			$vars = '[過过]';
		} elsif ($ch eq '遑') {
			$vars = '[遑徨]';
		} elsif ($ch eq '達') {
			$vars = '[達达]';
		} elsif ($ch eq '違') {
			$vars = '[違违]';
		} elsif ($ch eq '遗') {
			$vars = '[遗遺]';
		} elsif ($ch eq '遙') {
			$vars = '[遙遥]';
		} elsif ($ch eq '遜') {
			$vars = '[遜愻逊]';
		} elsif ($ch eq '遞') {
			$vars = '[遞逓递]';
		} elsif ($ch eq '遠') {
			$vars = '[遠远]';
		} elsif ($ch eq '遡') {
			$vars = '[遡溯泝]';
		} elsif ($ch eq '遥') {
			$vars = '[遥遙]';
		} elsif ($ch eq '適') {
			$vars = '[適适]';
		} elsif ($ch eq '遭') {
			$vars = '[遭蹧]';
		} elsif ($ch eq '遲') {
			$vars = '[遲遅迟]';
		} elsif ($ch eq '遶') {
			$vars = '[遶繞]';
		} elsif ($ch eq '遷') {
			$vars = '[遷迁]';
		} elsif ($ch eq '選') {
			$vars = '[選选]';
		} elsif ($ch eq '遺') {
			$vars = '[遺遗]';
		} elsif ($ch eq '遼') {
			$vars = '[遼遼辽]';
		} elsif ($ch eq '避') {
			$vars = '[避辟]';
		} elsif ($ch eq '邁') {
			$vars = '[邁迈]';
		} elsif ($ch eq '還') {
			$vars = '[還还]';
		} elsif ($ch eq '邇') {
			$vars = '[邇迩]';
		} elsif ($ch eq '邉') {
			$vars = '[邉邊]';
		} elsif ($ch eq '邊') {
			$vars = '[邊边]';
		} elsif ($ch eq '邏') {
			$vars = '[邏逻邏]';
		} elsif ($ch eq '邐') {
			$vars = '[邐逦]';
		} elsif ($ch eq '邑') {
			$vars = '[邑阝]';
		} elsif ($ch eq '邓') {
			$vars = '[邓鄧]';
		} elsif ($ch eq '邕') {
			$vars = '[邕雍]';
		} elsif ($ch eq '邝') {
			$vars = '[邝鄺]';
		} elsif ($ch eq '邠') {
			$vars = '[邠豳]';
		} elsif ($ch eq '邨') {
			$vars = '[邨村]';
		} elsif ($ch eq '邬') {
			$vars = '[邬鄔]';
		} elsif ($ch eq '邮') {
			$vars = '[邮郵]';
		} elsif ($ch eq '邹') {
			$vars = '[邹鄒]';
		} elsif ($ch eq '邺') {
			$vars = '[邺鄴]';
		} elsif ($ch eq '邻') {
			$vars = '[邻鄰]';
		} elsif ($ch eq '郁') {
			$vars = '[郁鬱]';
		} elsif ($ch eq '郄') {
			$vars = '[郄郤隙]';
		} elsif ($ch eq '郅') {
			$vars = '[郅胝]';
		} elsif ($ch eq '郎') {
			$vars = '[郎郞]';
		} elsif ($ch eq '郏') {
			$vars = '[郏郟]';
		} elsif ($ch eq '郐') {
			$vars = '[郐鄶]';
		} elsif ($ch eq '郑') {
			$vars = '[郑鄭]';
		} elsif ($ch eq '郓') {
			$vars = '[郓鄆]';
		} elsif ($ch eq '郞') {
			$vars = '[郞郎]';
		} elsif ($ch eq '郟') {
			$vars = '[郟郏]';
		} elsif ($ch eq '郤') {
			$vars = '[郤郄]';
		} elsif ($ch eq '郦') {
			$vars = '[郦酈]';
		} elsif ($ch eq '郧') {
			$vars = '[郧鄖]';
		} elsif ($ch eq '部') {
			$vars = '[部卩]';
		} elsif ($ch eq '郰') {
			$vars = '[郰鄹]';
		} elsif ($ch eq '郵') {
			$vars = '[郵邮]';
		} elsif ($ch eq '郷') {
			$vars = '[郷鄉]';
		} elsif ($ch eq '郸') {
			$vars = '[郸鄲]';
		} elsif ($ch eq '鄆') {
			$vars = '[鄆郓]';
		} elsif ($ch eq '鄉') {
			$vars = '[鄉乡郷鄕]';
		} elsif ($ch eq '鄒') {
			$vars = '[鄒邹]';
		} elsif ($ch eq '鄔') {
			$vars = '[鄔塢邬]';
		} elsif ($ch eq '鄕') {
			$vars = '[鄕鄉]';
		} elsif ($ch eq '鄖') {
			$vars = '[鄖郧]';
		} elsif ($ch eq '鄧') {
			$vars = '[鄧邓]';
		} elsif ($ch eq '鄭') {
			$vars = '[鄭郑]';
		} elsif ($ch eq '鄰') {
			$vars = '[鄰邻隣]';
		} elsif ($ch eq '鄲') {
			$vars = '[鄲郸]';
		} elsif ($ch eq '鄴') {
			$vars = '[鄴邺]';
		} elsif ($ch eq '鄶') {
			$vars = '[鄶郐]';
		} elsif ($ch eq '鄹') {
			$vars = '[鄹郰]';
		} elsif ($ch eq '鄺') {
			$vars = '[鄺邝]';
		} elsif ($ch eq '酈') {
			$vars = '[酈郦]';
		} elsif ($ch eq '酉') {
			$vars = '[酉酋]';
		} elsif ($ch eq '酋') {
			$vars = '[酋酉]';
		} elsif ($ch eq '酔') {
			$vars = '[酔醉]';
		} elsif ($ch eq '酖') {
			$vars = '[酖鴆]';
		} elsif ($ch eq '酝') {
			$vars = '[酝醞]';
		} elsif ($ch eq '酢') {
			$vars = '[酢醋榨]';
		} elsif ($ch eq '酪') {
			$vars = '[酪酪]';
		} elsif ($ch eq '酱') {
			$vars = '[酱醬]';
		} elsif ($ch eq '酹') {
			$vars = '[酹儡]';
		} elsif ($ch eq '酽') {
			$vars = '[酽釅]';
		} elsif ($ch eq '酾') {
			$vars = '[酾釃]';
		} elsif ($ch eq '酿') {
			$vars = '[酿釀]';
		} elsif ($ch eq '醃') {
			$vars = '[醃腌]';
		} elsif ($ch eq '醉') {
			$vars = '[醉酔]';
		} elsif ($ch eq '醊') {
			$vars = '[醊餟]';
		} elsif ($ch eq '醋') {
			$vars = '[醋酢]';
		} elsif ($ch eq '醑') {
			$vars = '[醑湑]';
		} elsif ($ch eq '醒') {
			$vars = '[醒惺]';
		} elsif ($ch eq '醗') {
			$vars = '[醗醱]';
		} elsif ($ch eq '醜') {
			$vars = '[醜丑]';
		} elsif ($ch eq '醞') {
			$vars = '[醞酝]';
		} elsif ($ch eq '醡') {
			$vars = '[醡詐榨]';
		} elsif ($ch eq '醤') {
			$vars = '[醤醬]';
		} elsif ($ch eq '醫') {
			$vars = '[醫医]';
		} elsif ($ch eq '醬') {
			$vars = '[醬酱]';
		} elsif ($ch eq '醴') {
			$vars = '[醴醴]';
		} elsif ($ch eq '醼') {
			$vars = '[醼燕]';
		} elsif ($ch eq '釀') {
			$vars = '[釀醸酿]';
		} elsif ($ch eq '釁') {
			$vars = '[釁衅]';
		} elsif ($ch eq '釃') {
			$vars = '[釃酾]';
		} elsif ($ch eq '釅') {
			$vars = '[釅酽]';
		} elsif ($ch eq '釆') {
			$vars = '[釆采]';
		} elsif ($ch eq '采') {
			$vars = '[采釆埰採]';
		} elsif ($ch eq '釈') {
			$vars = '[釈釋]';
		} elsif ($ch eq '释') {
			$vars = '[释釋]';
		} elsif ($ch eq '釋') {
			$vars = '[釋释]';
		} elsif ($ch eq '里') {
			$vars = '[里裡裏]';
		} elsif ($ch eq '野') {
			$vars = '[野埜]';
		} elsif ($ch eq '量') {
			$vars = '[量量]';
		} elsif ($ch eq '釐') {
			$vars = '[釐厘]';
		} elsif ($ch eq '金') {
			$vars = '[金钅]';
		} elsif ($ch eq '釓') {
			$vars = '[釓钆]';
		} elsif ($ch eq '釔') {
			$vars = '[釔钇]';
		} elsif ($ch eq '釕') {
			$vars = '[釕钌]';
		} elsif ($ch eq '釖') {
			$vars = '[釖劍]';
		} elsif ($ch eq '釗') {
			$vars = '[釗钊]';
		} elsif ($ch eq '釘') {
			$vars = '[釘钉]';
		} elsif ($ch eq '釙') {
			$vars = '[釙钋]';
		} elsif ($ch eq '釜') {
			$vars = '[釜釡]';
		} elsif ($ch eq '針') {
			$vars = '[針鍼箴针]';
		} elsif ($ch eq '釡') {
			$vars = '[釡釜]';
		} elsif ($ch eq '釣') {
			$vars = '[釣钓]';
		} elsif ($ch eq '釤') {
			$vars = '[釤钐]';
		} elsif ($ch eq '釧') {
			$vars = '[釧钏]';
		} elsif ($ch eq '釩') {
			$vars = '[釩钒]';
		} elsif ($ch eq '釬') {
			$vars = '[釬銲]';
		} elsif ($ch eq '釵') {
			$vars = '[釵叉钗]';
		} elsif ($ch eq '釷') {
			$vars = '[釷钍]';
		} elsif ($ch eq '釹') {
			$vars = '[釹钕]';
		} elsif ($ch eq '釼') {
			$vars = '[釼劍]';
		} elsif ($ch eq '鈀') {
			$vars = '[鈀钯耙]';
		} elsif ($ch eq '鈁') {
			$vars = '[鈁钫]';
		} elsif ($ch eq '鈄') {
			$vars = '[鈄钭]';
		} elsif ($ch eq '鈆') {
			$vars = '[鈆鉛]';
		} elsif ($ch eq '鈉') {
			$vars = '[鈉钠]';
		} elsif ($ch eq '鈍') {
			$vars = '[鈍钝]';
		} elsif ($ch eq '鈎') {
			$vars = '[鈎钩鉤]';
		} elsif ($ch eq '鈐') {
			$vars = '[鈐钤]';
		} elsif ($ch eq '鈑') {
			$vars = '[鈑钣]';
		} elsif ($ch eq '鈔') {
			$vars = '[鈔钞]';
		} elsif ($ch eq '鈕') {
			$vars = '[鈕钮]';
		} elsif ($ch eq '鈞') {
			$vars = '[鈞钧]';
		} elsif ($ch eq '鈣') {
			$vars = '[鈣钙]';
		} elsif ($ch eq '鈥') {
			$vars = '[鈥钬]';
		} elsif ($ch eq '鈦') {
			$vars = '[鈦钛]';
		} elsif ($ch eq '鈧') {
			$vars = '[鈧钪]';
		} elsif ($ch eq '鈬') {
			$vars = '[鈬鐸]';
		} elsif ($ch eq '鈮') {
			$vars = '[鈮铌]';
		} elsif ($ch eq '鈰') {
			$vars = '[鈰铈]';
		} elsif ($ch eq '鈳') {
			$vars = '[鈳钶]';
		} elsif ($ch eq '鈴') {
			$vars = '[鈴鈴铃]';
		} elsif ($ch eq '鈷') {
			$vars = '[鈷钴]';
		} elsif ($ch eq '鈸') {
			$vars = '[鈸钹]';
		} elsif ($ch eq '鈹') {
			$vars = '[鈹铍]';
		} elsif ($ch eq '鈺') {
			$vars = '[鈺钰]';
		} elsif ($ch eq '鈽') {
			$vars = '[鈽钸]';
		} elsif ($ch eq '鈾') {
			$vars = '[鈾铀]';
		} elsif ($ch eq '鈿') {
			$vars = '[鈿钿]';
		} elsif ($ch eq '鉀') {
			$vars = '[鉀钾]';
		} elsif ($ch eq '鉄') {
			$vars = '[鉄鐵銕]';
		} elsif ($ch eq '鉅') {
			$vars = '[鉅钜巨]';
		} elsif ($ch eq '鉆') {
			$vars = '[鉆鑽鉗]';
		} elsif ($ch eq '鉈') {
			$vars = '[鉈铊砣]';
		} elsif ($ch eq '鉉') {
			$vars = '[鉉铉]';
		} elsif ($ch eq '鉋') {
			$vars = '[鉋刨]';
		} elsif ($ch eq '鉍') {
			$vars = '[鉍铋]';
		} elsif ($ch eq '鉏') {
			$vars = '[鉏鋤]';
		} elsif ($ch eq '鉑') {
			$vars = '[鉑铂]';
		} elsif ($ch eq '鉗') {
			$vars = '[鉗鉆箝钳]';
		} elsif ($ch eq '鉚') {
			$vars = '[鉚铆]';
		} elsif ($ch eq '鉛') {
			$vars = '[鉛鈆铅]';
		} elsif ($ch eq '鉞') {
			$vars = '[鉞钺戉]';
		} elsif ($ch eq '鉢') {
			$vars = '[鉢缽钵]';
		} elsif ($ch eq '鉤') {
			$vars = '[鉤钩鈎]';
		} elsif ($ch eq '鉦') {
			$vars = '[鉦钲]';
		} elsif ($ch eq '鉬') {
			$vars = '[鉬钼]';
		} elsif ($ch eq '鉭') {
			$vars = '[鉭钽]';
		} elsif ($ch eq '鉱') {
			$vars = '[鉱礦]';
		} elsif ($ch eq '鉴') {
			$vars = '[鉴鑒]';
		} elsif ($ch eq '鉸') {
			$vars = '[鉸铰]';
		} elsif ($ch eq '鉺') {
			$vars = '[鉺铒]';
		} elsif ($ch eq '鉻') {
			$vars = '[鉻铬]';
		} elsif ($ch eq '鉿') {
			$vars = '[鉿铪]';
		} elsif ($ch eq '銀') {
			$vars = '[銀银]';
		} elsif ($ch eq '銃') {
			$vars = '[銃铳]';
		} elsif ($ch eq '銅') {
			$vars = '[銅铜]';
		} elsif ($ch eq '銑') {
			$vars = '[銑铣]';
		} elsif ($ch eq '銓') {
			$vars = '[銓铨]';
		} elsif ($ch eq '銕') {
			$vars = '[銕鐵鉄]';
		} elsif ($ch eq '銖') {
			$vars = '[銖铢]';
		} elsif ($ch eq '銘') {
			$vars = '[銘铭]';
		} elsif ($ch eq '銚') {
			$vars = '[銚铫]';
		} elsif ($ch eq '銜') {
			$vars = '[銜衔]';
		} elsif ($ch eq '銠') {
			$vars = '[銠铑]';
		} elsif ($ch eq '銣') {
			$vars = '[銣铷]';
		} elsif ($ch eq '銥') {
			$vars = '[銥铱]';
		} elsif ($ch eq '銦') {
			$vars = '[銦铟]';
		} elsif ($ch eq '銨') {
			$vars = '[銨铵]';
		} elsif ($ch eq '銩') {
			$vars = '[銩铥]';
		} elsif ($ch eq '銪') {
			$vars = '[銪铕]';
		} elsif ($ch eq '銫') {
			$vars = '[銫铯]';
		} elsif ($ch eq '銬') {
			$vars = '[銬铐]';
		} elsif ($ch eq '銭') {
			$vars = '[銭錢]';
		} elsif ($ch eq '銮') {
			$vars = '[銮鑾]';
		} elsif ($ch eq '銲') {
			$vars = '[銲釬]';
		} elsif ($ch eq '銳') {
			$vars = '[銳锐鋭]';
		} elsif ($ch eq '銷') {
			$vars = '[銷销]';
		} elsif ($ch eq '銹') {
			$vars = '[銹锈鏽]';
		} elsif ($ch eq '銻') {
			$vars = '[銻锑]';
		} elsif ($ch eq '銼') {
			$vars = '[銼剉锉]';
		} elsif ($ch eq '鋁') {
			$vars = '[鋁铝]';
		} elsif ($ch eq '鋃') {
			$vars = '[鋃锒]';
		} elsif ($ch eq '鋅') {
			$vars = '[鋅锌]';
		} elsif ($ch eq '鋇') {
			$vars = '[鋇钡]';
		} elsif ($ch eq '鋌') {
			$vars = '[鋌铤]';
		} elsif ($ch eq '鋏') {
			$vars = '[鋏铗]';
		} elsif ($ch eq '鋑') {
			$vars = '[鋑鑴鐫]';
		} elsif ($ch eq '鋒') {
			$vars = '[鋒锋]';
		} elsif ($ch eq '鋝') {
			$vars = '[鋝锊]';
		} elsif ($ch eq '鋟') {
			$vars = '[鋟锓]';
		} elsif ($ch eq '鋤') {
			$vars = '[鋤锄鉏]';
		} elsif ($ch eq '鋦') {
			$vars = '[鋦锔]';
		} elsif ($ch eq '鋨') {
			$vars = '[鋨锇]';
		} elsif ($ch eq '鋪') {
			$vars = '[鋪铺舖]';
		} elsif ($ch eq '鋭') {
			$vars = '[鋭锐銳]';
		} elsif ($ch eq '鋮') {
			$vars = '[鋮铖]';
		} elsif ($ch eq '鋯') {
			$vars = '[鋯锆]';
		} elsif ($ch eq '鋰') {
			$vars = '[鋰锂]';
		} elsif ($ch eq '鋱') {
			$vars = '[鋱铽]';
		} elsif ($ch eq '鋳') {
			$vars = '[鋳鑄]';
		} elsif ($ch eq '鋸') {
			$vars = '[鋸锯]';
		} elsif ($ch eq '鋼') {
			$vars = '[鋼钢]';
		} elsif ($ch eq '錁') {
			$vars = '[錁锞]';
		} elsif ($ch eq '錄') {
			$vars = '[錄録录]';
		} elsif ($ch eq '錆') {
			$vars = '[錆锖]';
		} elsif ($ch eq '錈') {
			$vars = '[錈锩]';
		} elsif ($ch eq '錐') {
			$vars = '[錐锥]';
		} elsif ($ch eq '錒') {
			$vars = '[錒锕]';
		} elsif ($ch eq '錕') {
			$vars = '[錕锟]';
		} elsif ($ch eq '錘') {
			$vars = '[錘锤鎚]';
		} elsif ($ch eq '錙') {
			$vars = '[錙锱]';
		} elsif ($ch eq '錚') {
			$vars = '[錚铮]';
		} elsif ($ch eq '錛') {
			$vars = '[錛锛]';
		} elsif ($ch eq '錟') {
			$vars = '[錟锬]';
		} elsif ($ch eq '錠') {
			$vars = '[錠锭]';
		} elsif ($ch eq '錢') {
			$vars = '[錢钱]';
		} elsif ($ch eq '錦') {
			$vars = '[錦锦]';
		} elsif ($ch eq '錨') {
			$vars = '[錨锚]';
		} elsif ($ch eq '錫') {
			$vars = '[錫锡]';
		} elsif ($ch eq '錬') {
			$vars = '[錬煉]';
		} elsif ($ch eq '錮') {
			$vars = '[錮锢]';
		} elsif ($ch eq '錯') {
			$vars = '[錯错]';
		} elsif ($ch eq '録') {
			$vars = '[録录錄]';
		} elsif ($ch eq '錳') {
			$vars = '[錳锰]';
		} elsif ($ch eq '錶') {
			$vars = '[錶表]';
		} elsif ($ch eq '錸') {
			$vars = '[錸铼]';
		} elsif ($ch eq '錾') {
			$vars = '[錾鏨]';
		} elsif ($ch eq '鍆') {
			$vars = '[鍆钔]';
		} elsif ($ch eq '鍇') {
			$vars = '[鍇锴]';
		} elsif ($ch eq '鍉') {
			$vars = '[鍉匙]';
		} elsif ($ch eq '鍊') {
			$vars = '[鍊鍊]';
		} elsif ($ch eq '鍋') {
			$vars = '[鍋锅]';
		} elsif ($ch eq '鍍') {
			$vars = '[鍍镀]';
		} elsif ($ch eq '鍔') {
			$vars = '[鍔锷]';
		} elsif ($ch eq '鍘') {
			$vars = '[鍘铡]';
		} elsif ($ch eq '鍛') {
			$vars = '[鍛锻煅]';
		} elsif ($ch eq '鍜') {
			$vars = '[鍜煆]';
		} elsif ($ch eq '鍤') {
			$vars = '[鍤锸]';
		} elsif ($ch eq '鍥') {
			$vars = '[鍥锲]';
		} elsif ($ch eq '鍬') {
			$vars = '[鍬锹]';
		} elsif ($ch eq '鍰') {
			$vars = '[鍰锾鐶]';
		} elsif ($ch eq '鍵') {
			$vars = '[鍵键]';
		} elsif ($ch eq '鍶') {
			$vars = '[鍶锶]';
		} elsif ($ch eq '鍺') {
			$vars = '[鍺锗]';
		} elsif ($ch eq '鍼') {
			$vars = '[鍼針箴]';
		} elsif ($ch eq '鍾') {
			$vars = '[鍾锺钟]';
		} elsif ($ch eq '鎂') {
			$vars = '[鎂镁]';
		} elsif ($ch eq '鎊') {
			$vars = '[鎊镑]';
		} elsif ($ch eq '鎌') {
			$vars = '[鎌鐮]';
		} elsif ($ch eq '鎏') {
			$vars = '[鎏鏐]';
		} elsif ($ch eq '鎒') {
			$vars = '[鎒耨]';
		} elsif ($ch eq '鎔') {
			$vars = '[鎔熔]';
		} elsif ($ch eq '鎖') {
			$vars = '[鎖锁]';
		} elsif ($ch eq '鎘') {
			$vars = '[鎘镉]';
		} elsif ($ch eq '鎙') {
			$vars = '[鎙槊]';
		} elsif ($ch eq '鎚') {
			$vars = '[鎚錘锤]';
		} elsif ($ch eq '鎢') {
			$vars = '[鎢钨]';
		} elsif ($ch eq '鎣') {
			$vars = '[鎣蓥]';
		} elsif ($ch eq '鎦') {
			$vars = '[鎦镏]';
		} elsif ($ch eq '鎧') {
			$vars = '[鎧铠]';
		} elsif ($ch eq '鎩') {
			$vars = '[鎩铩]';
		} elsif ($ch eq '鎪') {
			$vars = '[鎪锼]';
		} elsif ($ch eq '鎬') {
			$vars = '[鎬镐]';
		} elsif ($ch eq '鎭') {
			$vars = '[鎭鎮]';
		} elsif ($ch eq '鎮') {
			$vars = '[鎮镇]';
		} elsif ($ch eq '鎰') {
			$vars = '[鎰镒]';
		} elsif ($ch eq '鎳') {
			$vars = '[鎳镍]';
		} elsif ($ch eq '鎵') {
			$vars = '[鎵镓]';
		} elsif ($ch eq '鏃') {
			$vars = '[鏃镞]';
		} elsif ($ch eq '鏇') {
			$vars = '[鏇镟]';
		} elsif ($ch eq '鏈') {
			$vars = '[鏈链]';
		} elsif ($ch eq '鏌') {
			$vars = '[鏌镆]';
		} elsif ($ch eq '鏍') {
			$vars = '[鏍镙]';
		} elsif ($ch eq '鏐') {
			$vars = '[鏐鎏]';
		} elsif ($ch eq '鏑') {
			$vars = '[鏑镝]';
		} elsif ($ch eq '鏗') {
			$vars = '[鏗铿]';
		} elsif ($ch eq '鏘') {
			$vars = '[鏘锵]';
		} elsif ($ch eq '鏜') {
			$vars = '[鏜镗]';
		} elsif ($ch eq '鏝') {
			$vars = '[鏝镘]';
		} elsif ($ch eq '鏞') {
			$vars = '[鏞镛]';
		} elsif ($ch eq '鏟') {
			$vars = '[鏟铲]';
		} elsif ($ch eq '鏡') {
			$vars = '[鏡镜]';
		} elsif ($ch eq '鏢') {
			$vars = '[鏢鑣镖]';
		} elsif ($ch eq '鏤') {
			$vars = '[鏤镂]';
		} elsif ($ch eq '鏥') {
			$vars = '[鏥銹鏽]';
		} elsif ($ch eq '鏨') {
			$vars = '[鏨錾]';
		} elsif ($ch eq '鏵') {
			$vars = '[鏵铧]';
		} elsif ($ch eq '鏷') {
			$vars = '[鏷镤]';
		} elsif ($ch eq '鏹') {
			$vars = '[鏹镪]';
		} elsif ($ch eq '鏽') {
			$vars = '[鏽銹锈]';
		} elsif ($ch eq '鐀') {
			$vars = '[鐀匱櫃]';
		} elsif ($ch eq '鐃') {
			$vars = '[鐃铙]';
		} elsif ($ch eq '鐋') {
			$vars = '[鐋铴]';
		} elsif ($ch eq '鐐') {
			$vars = '[鐐镣]';
		} elsif ($ch eq '鐒') {
			$vars = '[鐒铹]';
		} elsif ($ch eq '鐓') {
			$vars = '[鐓镦]';
		} elsif ($ch eq '鐔') {
			$vars = '[鐔镡]';
		} elsif ($ch eq '鐘') {
			$vars = '[鐘鍾钟]';
		} elsif ($ch eq '鐙') {
			$vars = '[鐙镫]';
		} elsif ($ch eq '鐠') {
			$vars = '[鐠镨]';
		} elsif ($ch eq '鐡') {
			$vars = '[鐡鐵]';
		} elsif ($ch eq '鐨') {
			$vars = '[鐨镄]';
		} elsif ($ch eq '鐫') {
			$vars = '[鐫鑴鋑镌]';
		} elsif ($ch eq '鐮') {
			$vars = '[鐮镰鎌]';
		} elsif ($ch eq '鐲') {
			$vars = '[鐲镯]';
		} elsif ($ch eq '鐳') {
			$vars = '[鐳镭]';
		} elsif ($ch eq '鐵') {
			$vars = '[鐵铁鉄銕]';
		} elsif ($ch eq '鐶') {
			$vars = '[鐶鍰]';
		} elsif ($ch eq '鐸') {
			$vars = '[鐸铎鈬]';
		} elsif ($ch eq '鐺') {
			$vars = '[鐺铛]';
		} elsif ($ch eq '鐿') {
			$vars = '[鐿镱]';
		} elsif ($ch eq '鑄') {
			$vars = '[鑄铸]';
		} elsif ($ch eq '鑊') {
			$vars = '[鑊镬]';
		} elsif ($ch eq '鑌') {
			$vars = '[鑌镔]';
		} elsif ($ch eq '鑑') {
			$vars = '[鑑鑒]';
		} elsif ($ch eq '鑒') {
			$vars = '[鑒鉴鑑]';
		} elsif ($ch eq '鑚') {
			$vars = '[鑚鑽]';
		} elsif ($ch eq '鑛') {
			$vars = '[鑛礦]';
		} elsif ($ch eq '鑠') {
			$vars = '[鑠铄]';
		} elsif ($ch eq '鑣') {
			$vars = '[鑣镳鏢]';
		} elsif ($ch eq '鑭') {
			$vars = '[鑭镧]';
		} elsif ($ch eq '鑰') {
			$vars = '[鑰钥]';
		} elsif ($ch eq '鑲') {
			$vars = '[鑲镶]';
		} elsif ($ch eq '鑴') {
			$vars = '[鑴鋑鐫]';
		} elsif ($ch eq '鑵') {
			$vars = '[鑵罐]';
		} elsif ($ch eq '鑷') {
			$vars = '[鑷镊]';
		} elsif ($ch eq '鑼') {
			$vars = '[鑼锣]';
		} elsif ($ch eq '鑽') {
			$vars = '[鑽钻鉆鑚]';
		} elsif ($ch eq '鑾') {
			$vars = '[鑾銮]';
		} elsif ($ch eq '鑿') {
			$vars = '[鑿凿]';
		} elsif ($ch eq '钁') {
			$vars = '[钁镢]';
		} elsif ($ch eq '钅') {
			$vars = '[钅金]';
		} elsif ($ch eq '钆') {
			$vars = '[钆釓]';
		} elsif ($ch eq '钇') {
			$vars = '[钇釔]';
		} elsif ($ch eq '针') {
			$vars = '[针針]';
		} elsif ($ch eq '钉') {
			$vars = '[钉釘]';
		} elsif ($ch eq '钊') {
			$vars = '[钊釗]';
		} elsif ($ch eq '钋') {
			$vars = '[钋釙]';
		} elsif ($ch eq '钌') {
			$vars = '[钌釕]';
		} elsif ($ch eq '钍') {
			$vars = '[钍釷]';
		} elsif ($ch eq '钏') {
			$vars = '[钏釧]';
		} elsif ($ch eq '钐') {
			$vars = '[钐釤]';
		} elsif ($ch eq '钒') {
			$vars = '[钒釩]';
		} elsif ($ch eq '钓') {
			$vars = '[钓釣]';
		} elsif ($ch eq '钔') {
			$vars = '[钔鍆]';
		} elsif ($ch eq '钕') {
			$vars = '[钕釹]';
		} elsif ($ch eq '钗') {
			$vars = '[钗釵]';
		} elsif ($ch eq '钙') {
			$vars = '[钙鈣]';
		} elsif ($ch eq '钛') {
			$vars = '[钛鈦]';
		} elsif ($ch eq '钜') {
			$vars = '[钜鉅巨]';
		} elsif ($ch eq '钝') {
			$vars = '[钝鈍]';
		} elsif ($ch eq '钞') {
			$vars = '[钞鈔]';
		} elsif ($ch eq '钟') {
			$vars = '[钟鍾鐘]';
		} elsif ($ch eq '钠') {
			$vars = '[钠鈉]';
		} elsif ($ch eq '钡') {
			$vars = '[钡鋇]';
		} elsif ($ch eq '钢') {
			$vars = '[钢鋼]';
		} elsif ($ch eq '钣') {
			$vars = '[钣鈑]';
		} elsif ($ch eq '钤') {
			$vars = '[钤鈐]';
		} elsif ($ch eq '钥') {
			$vars = '[钥鑰]';
		} elsif ($ch eq '钦') {
			$vars = '[钦欽]';
		} elsif ($ch eq '钧') {
			$vars = '[钧鈞]';
		} elsif ($ch eq '钨') {
			$vars = '[钨鎢]';
		} elsif ($ch eq '钩') {
			$vars = '[钩鉤鈎]';
		} elsif ($ch eq '钪') {
			$vars = '[钪鈧]';
		} elsif ($ch eq '钫') {
			$vars = '[钫鈁]';
		} elsif ($ch eq '钬') {
			$vars = '[钬鈥]';
		} elsif ($ch eq '钭') {
			$vars = '[钭鈄]';
		} elsif ($ch eq '钮') {
			$vars = '[钮鈕]';
		} elsif ($ch eq '钯') {
			$vars = '[钯鈀]';
		} elsif ($ch eq '钰') {
			$vars = '[钰鈺]';
		} elsif ($ch eq '钱') {
			$vars = '[钱錢]';
		} elsif ($ch eq '钲') {
			$vars = '[钲鉦]';
		} elsif ($ch eq '钳') {
			$vars = '[钳箝鉗]';
		} elsif ($ch eq '钴') {
			$vars = '[钴鈷]';
		} elsif ($ch eq '钵') {
			$vars = '[钵鉢缽]';
		} elsif ($ch eq '钶') {
			$vars = '[钶鈳]';
		} elsif ($ch eq '钸') {
			$vars = '[钸鈽]';
		} elsif ($ch eq '钹') {
			$vars = '[钹鈸]';
		} elsif ($ch eq '钺') {
			$vars = '[钺鉞]';
		} elsif ($ch eq '钻') {
			$vars = '[钻鑽]';
		} elsif ($ch eq '钼') {
			$vars = '[钼鉬]';
		} elsif ($ch eq '钽') {
			$vars = '[钽鉭]';
		} elsif ($ch eq '钾') {
			$vars = '[钾鉀]';
		} elsif ($ch eq '钿') {
			$vars = '[钿鈿]';
		} elsif ($ch eq '铀') {
			$vars = '[铀鈾]';
		} elsif ($ch eq '铁') {
			$vars = '[铁鐵]';
		} elsif ($ch eq '铂') {
			$vars = '[铂鉑]';
		} elsif ($ch eq '铃') {
			$vars = '[铃鈴]';
		} elsif ($ch eq '铄') {
			$vars = '[铄鑠]';
		} elsif ($ch eq '铅') {
			$vars = '[铅鉛]';
		} elsif ($ch eq '铆') {
			$vars = '[铆鉚]';
		} elsif ($ch eq '铈') {
			$vars = '[铈鈰]';
		} elsif ($ch eq '铉') {
			$vars = '[铉鉉]';
		} elsif ($ch eq '铊') {
			$vars = '[铊鉈]';
		} elsif ($ch eq '铋') {
			$vars = '[铋鉍]';
		} elsif ($ch eq '铌') {
			$vars = '[铌鈮]';
		} elsif ($ch eq '铍') {
			$vars = '[铍鈹]';
		} elsif ($ch eq '铎') {
			$vars = '[铎鐸]';
		} elsif ($ch eq '铐') {
			$vars = '[铐銬]';
		} elsif ($ch eq '铑') {
			$vars = '[铑銠]';
		} elsif ($ch eq '铒') {
			$vars = '[铒鉺]';
		} elsif ($ch eq '铕') {
			$vars = '[铕銪]';
		} elsif ($ch eq '铖') {
			$vars = '[铖鋮]';
		} elsif ($ch eq '铗') {
			$vars = '[铗鋏]';
		} elsif ($ch eq '铙') {
			$vars = '[铙鐃]';
		} elsif ($ch eq '铛') {
			$vars = '[铛鐺]';
		} elsif ($ch eq '铜') {
			$vars = '[铜銅]';
		} elsif ($ch eq '铝') {
			$vars = '[铝鋁]';
		} elsif ($ch eq '铟') {
			$vars = '[铟銦]';
		} elsif ($ch eq '铠') {
			$vars = '[铠鎧]';
		} elsif ($ch eq '铡') {
			$vars = '[铡鍘]';
		} elsif ($ch eq '铢') {
			$vars = '[铢銖]';
		} elsif ($ch eq '铣') {
			$vars = '[铣銑]';
		} elsif ($ch eq '铤') {
			$vars = '[铤鋌]';
		} elsif ($ch eq '铥') {
			$vars = '[铥銩]';
		} elsif ($ch eq '铧') {
			$vars = '[铧鏵]';
		} elsif ($ch eq '铨') {
			$vars = '[铨銓]';
		} elsif ($ch eq '铩') {
			$vars = '[铩鎩]';
		} elsif ($ch eq '铪') {
			$vars = '[铪鉿]';
		} elsif ($ch eq '铫') {
			$vars = '[铫銚]';
		} elsif ($ch eq '铬') {
			$vars = '[铬鉻]';
		} elsif ($ch eq '铭') {
			$vars = '[铭銘]';
		} elsif ($ch eq '铮') {
			$vars = '[铮錚]';
		} elsif ($ch eq '铯') {
			$vars = '[铯銫]';
		} elsif ($ch eq '铰') {
			$vars = '[铰鉸]';
		} elsif ($ch eq '铱') {
			$vars = '[铱銥]';
		} elsif ($ch eq '铲') {
			$vars = '[铲鏟]';
		} elsif ($ch eq '铳') {
			$vars = '[铳銃]';
		} elsif ($ch eq '铴') {
			$vars = '[铴鐋]';
		} elsif ($ch eq '铵') {
			$vars = '[铵銨]';
		} elsif ($ch eq '银') {
			$vars = '[银銀]';
		} elsif ($ch eq '铷') {
			$vars = '[铷銣]';
		} elsif ($ch eq '铸') {
			$vars = '[铸鑄]';
		} elsif ($ch eq '铹') {
			$vars = '[铹鐒]';
		} elsif ($ch eq '铺') {
			$vars = '[铺鋪]';
		} elsif ($ch eq '铼') {
			$vars = '[铼錸]';
		} elsif ($ch eq '铽') {
			$vars = '[铽鋱]';
		} elsif ($ch eq '链') {
			$vars = '[链鏈]';
		} elsif ($ch eq '铿') {
			$vars = '[铿鏗]';
		} elsif ($ch eq '销') {
			$vars = '[销銷]';
		} elsif ($ch eq '锁') {
			$vars = '[锁鎖]';
		} elsif ($ch eq '锂') {
			$vars = '[锂鋰]';
		} elsif ($ch eq '锄') {
			$vars = '[锄鋤]';
		} elsif ($ch eq '锅') {
			$vars = '[锅鍋]';
		} elsif ($ch eq '锆') {
			$vars = '[锆鋯]';
		} elsif ($ch eq '锇') {
			$vars = '[锇鋨]';
		} elsif ($ch eq '锈') {
			$vars = '[锈銹鏽]';
		} elsif ($ch eq '锉') {
			$vars = '[锉銼]';
		} elsif ($ch eq '锊') {
			$vars = '[锊鋝]';
		} elsif ($ch eq '锋') {
			$vars = '[锋鋒]';
		} elsif ($ch eq '锌') {
			$vars = '[锌鋅]';
		} elsif ($ch eq '锐') {
			$vars = '[锐銳鋭]';
		} elsif ($ch eq '锑') {
			$vars = '[锑銻]';
		} elsif ($ch eq '锒') {
			$vars = '[锒鋃]';
		} elsif ($ch eq '锓') {
			$vars = '[锓鋟]';
		} elsif ($ch eq '锔') {
			$vars = '[锔鋦]';
		} elsif ($ch eq '锕') {
			$vars = '[锕錒]';
		} elsif ($ch eq '锖') {
			$vars = '[锖錆]';
		} elsif ($ch eq '锗') {
			$vars = '[锗鍺]';
		} elsif ($ch eq '错') {
			$vars = '[错錯]';
		} elsif ($ch eq '锚') {
			$vars = '[锚錨]';
		} elsif ($ch eq '锛') {
			$vars = '[锛錛]';
		} elsif ($ch eq '锞') {
			$vars = '[锞錁]';
		} elsif ($ch eq '锟') {
			$vars = '[锟錕]';
		} elsif ($ch eq '锡') {
			$vars = '[锡錫]';
		} elsif ($ch eq '锢') {
			$vars = '[锢錮]';
		} elsif ($ch eq '锣') {
			$vars = '[锣鑼]';
		} elsif ($ch eq '锤') {
			$vars = '[锤錘鎚]';
		} elsif ($ch eq '锥') {
			$vars = '[锥錐]';
		} elsif ($ch eq '锦') {
			$vars = '[锦錦]';
		} elsif ($ch eq '锨') {
			$vars = '[锨杴]';
		} elsif ($ch eq '锩') {
			$vars = '[锩錈]';
		} elsif ($ch eq '锬') {
			$vars = '[锬錟]';
		} elsif ($ch eq '锭') {
			$vars = '[锭錠]';
		} elsif ($ch eq '键') {
			$vars = '[键鍵]';
		} elsif ($ch eq '锯') {
			$vars = '[锯鋸]';
		} elsif ($ch eq '锰') {
			$vars = '[锰錳]';
		} elsif ($ch eq '锱') {
			$vars = '[锱錙]';
		} elsif ($ch eq '锲') {
			$vars = '[锲鍥]';
		} elsif ($ch eq '锴') {
			$vars = '[锴鍇]';
		} elsif ($ch eq '锵') {
			$vars = '[锵鏘]';
		} elsif ($ch eq '锶') {
			$vars = '[锶鍶]';
		} elsif ($ch eq '锷') {
			$vars = '[锷鍔]';
		} elsif ($ch eq '锸') {
			$vars = '[锸鍤]';
		} elsif ($ch eq '锹') {
			$vars = '[锹鍬]';
		} elsif ($ch eq '锺') {
			$vars = '[锺鍾]';
		} elsif ($ch eq '锻') {
			$vars = '[锻鍛]';
		} elsif ($ch eq '锼') {
			$vars = '[锼鎪]';
		} elsif ($ch eq '锾') {
			$vars = '[锾鍰]';
		} elsif ($ch eq '镀') {
			$vars = '[镀鍍]';
		} elsif ($ch eq '镁') {
			$vars = '[镁鎂]';
		} elsif ($ch eq '镂') {
			$vars = '[镂鏤]';
		} elsif ($ch eq '镄') {
			$vars = '[镄鐨]';
		} elsif ($ch eq '镆') {
			$vars = '[镆鏌]';
		} elsif ($ch eq '镇') {
			$vars = '[镇鎮]';
		} elsif ($ch eq '镉') {
			$vars = '[镉鎘]';
		} elsif ($ch eq '镊') {
			$vars = '[镊鑷]';
		} elsif ($ch eq '镌') {
			$vars = '[镌鐫]';
		} elsif ($ch eq '镍') {
			$vars = '[镍鎳]';
		} elsif ($ch eq '镏') {
			$vars = '[镏鎦]';
		} elsif ($ch eq '镐') {
			$vars = '[镐鎬]';
		} elsif ($ch eq '镑') {
			$vars = '[镑鎊]';
		} elsif ($ch eq '镒') {
			$vars = '[镒鎰]';
		} elsif ($ch eq '镓') {
			$vars = '[镓鎵]';
		} elsif ($ch eq '镔') {
			$vars = '[镔鑌]';
		} elsif ($ch eq '镖') {
			$vars = '[镖鏢]';
		} elsif ($ch eq '镗') {
			$vars = '[镗鏜]';
		} elsif ($ch eq '镘') {
			$vars = '[镘鏝]';
		} elsif ($ch eq '镙') {
			$vars = '[镙鏍]';
		} elsif ($ch eq '镛') {
			$vars = '[镛鏞]';
		} elsif ($ch eq '镜') {
			$vars = '[镜鏡]';
		} elsif ($ch eq '镝') {
			$vars = '[镝鏑]';
		} elsif ($ch eq '镞') {
			$vars = '[镞鏃]';
		} elsif ($ch eq '镟') {
			$vars = '[镟鏇]';
		} elsif ($ch eq '镡') {
			$vars = '[镡鐔]';
		} elsif ($ch eq '镢') {
			$vars = '[镢钁]';
		} elsif ($ch eq '镣') {
			$vars = '[镣鐐]';
		} elsif ($ch eq '镤') {
			$vars = '[镤鏷]';
		} elsif ($ch eq '镦') {
			$vars = '[镦鐓]';
		} elsif ($ch eq '镧') {
			$vars = '[镧鑭]';
		} elsif ($ch eq '镨') {
			$vars = '[镨鐠]';
		} elsif ($ch eq '镪') {
			$vars = '[镪鏹]';
		} elsif ($ch eq '镫') {
			$vars = '[镫鐙]';
		} elsif ($ch eq '镬') {
			$vars = '[镬鑊]';
		} elsif ($ch eq '镭') {
			$vars = '[镭鐳]';
		} elsif ($ch eq '镯') {
			$vars = '[镯鐲]';
		} elsif ($ch eq '镰') {
			$vars = '[镰鐮]';
		} elsif ($ch eq '镱') {
			$vars = '[镱鐿]';
		} elsif ($ch eq '镳') {
			$vars = '[镳鑣]';
		} elsif ($ch eq '镶') {
			$vars = '[镶鑲]';
		} elsif ($ch eq '長') {
			$vars = '[長长]';
		} elsif ($ch eq '长') {
			$vars = '[长長]';
		} elsif ($ch eq '門') {
			$vars = '[門门]';
		} elsif ($ch eq '閂') {
			$vars = '[閂闩]';
		} elsif ($ch eq '閃') {
			$vars = '[閃闪]';
		} elsif ($ch eq '閆') {
			$vars = '[閆閻闫]';
		} elsif ($ch eq '閇') {
			$vars = '[閇閉]';
		} elsif ($ch eq '閉') {
			$vars = '[閉閇闭]';
		} elsif ($ch eq '開') {
			$vars = '[開开]';
		} elsif ($ch eq '閌') {
			$vars = '[閌闶]';
		} elsif ($ch eq '閎') {
			$vars = '[閎闳]';
		} elsif ($ch eq '閏') {
			$vars = '[閏闰]';
		} elsif ($ch eq '閑') {
			$vars = '[閑闲]';
		} elsif ($ch eq '閒') {
			$vars = '[閒間]';
		} elsif ($ch eq '間') {
			$vars = '[間间閒]';
		} elsif ($ch eq '閔') {
			$vars = '[閔闵]';
		} elsif ($ch eq '閘') {
			$vars = '[閘闸]';
		} elsif ($ch eq '閙') {
			$vars = '[閙鬧]';
		} elsif ($ch eq '閡') {
			$vars = '[閡阂]';
		} elsif ($ch eq '関') {
			$vars = '[関關]';
		} elsif ($ch eq '閣') {
			$vars = '[閣阁]';
		} elsif ($ch eq '閤') {
			$vars = '[閤合]';
		} elsif ($ch eq '閥') {
			$vars = '[閥阀]';
		} elsif ($ch eq '閧') {
			$vars = '[閧鬨哄]';
		} elsif ($ch eq '閨') {
			$vars = '[閨闺]';
		} elsif ($ch eq '閩') {
			$vars = '[閩闽]';
		} elsif ($ch eq '閫') {
			$vars = '[閫阃]';
		} elsif ($ch eq '閬') {
			$vars = '[閬阆]';
		} elsif ($ch eq '閭') {
			$vars = '[閭閭闾]';
		} elsif ($ch eq '閱') {
			$vars = '[閱閲阅]';
		} elsif ($ch eq '閲') {
			$vars = '[閲閱阅]';
		} elsif ($ch eq '閶') {
			$vars = '[閶阊]';
		} elsif ($ch eq '閹') {
			$vars = '[閹阉]';
		} elsif ($ch eq '閻') {
			$vars = '[閻閆阎]';
		} elsif ($ch eq '閼') {
			$vars = '[閼阏]';
		} elsif ($ch eq '閽') {
			$vars = '[閽阍]';
		} elsif ($ch eq '閾') {
			$vars = '[閾阈]';
		} elsif ($ch eq '閿') {
			$vars = '[閿阌]';
		} elsif ($ch eq '闃') {
			$vars = '[闃阒]';
		} elsif ($ch eq '闆') {
			$vars = '[闆板]';
		} elsif ($ch eq '闇') {
			$vars = '[闇暗]';
		} elsif ($ch eq '闈') {
			$vars = '[闈闱]';
		} elsif ($ch eq '闊') {
			$vars = '[闊濶阔]';
		} elsif ($ch eq '闋') {
			$vars = '[闋阕]';
		} elsif ($ch eq '闌') {
			$vars = '[闌阑]';
		} elsif ($ch eq '闐') {
			$vars = '[闐阗]';
		} elsif ($ch eq '闔') {
			$vars = '[闔閤阖]';
		} elsif ($ch eq '闕') {
			$vars = '[闕阙]';
		} elsif ($ch eq '闖') {
			$vars = '[闖闯]';
		} elsif ($ch eq '闘') {
			$vars = '[闘鬥]';
		} elsif ($ch eq '關') {
			$vars = '[關関寡关]';
		} elsif ($ch eq '闞') {
			$vars = '[闞阚]';
		} elsif ($ch eq '闡') {
			$vars = '[闡阐]';
		} elsif ($ch eq '闥') {
			$vars = '[闥闼]';
		} elsif ($ch eq '门') {
			$vars = '[门門]';
		} elsif ($ch eq '闩') {
			$vars = '[闩閂]';
		} elsif ($ch eq '闪') {
			$vars = '[闪閃]';
		} elsif ($ch eq '闫') {
			$vars = '[闫閻閆]';
		} elsif ($ch eq '闭') {
			$vars = '[闭閉]';
		} elsif ($ch eq '问') {
			$vars = '[问問]';
		} elsif ($ch eq '闯') {
			$vars = '[闯闖]';
		} elsif ($ch eq '闰') {
			$vars = '[闰閏]';
		} elsif ($ch eq '闱') {
			$vars = '[闱闈]';
		} elsif ($ch eq '闲') {
			$vars = '[闲閑]';
		} elsif ($ch eq '闳') {
			$vars = '[闳閎]';
		} elsif ($ch eq '间') {
			$vars = '[间間]';
		} elsif ($ch eq '闵') {
			$vars = '[闵閔]';
		} elsif ($ch eq '闶') {
			$vars = '[闶閌]';
		} elsif ($ch eq '闷') {
			$vars = '[闷悶]';
		} elsif ($ch eq '闸') {
			$vars = '[闸閘]';
		} elsif ($ch eq '闹') {
			$vars = '[闹鬧]';
		} elsif ($ch eq '闺') {
			$vars = '[闺閨]';
		} elsif ($ch eq '闻') {
			$vars = '[闻聞]';
		} elsif ($ch eq '闼') {
			$vars = '[闼闥]';
		} elsif ($ch eq '闽') {
			$vars = '[闽閩]';
		} elsif ($ch eq '闾') {
			$vars = '[闾閭]';
		} elsif ($ch eq '阀') {
			$vars = '[阀閥]';
		} elsif ($ch eq '阁') {
			$vars = '[阁閣]';
		} elsif ($ch eq '阂') {
			$vars = '[阂閡]';
		} elsif ($ch eq '阃') {
			$vars = '[阃閫]';
		} elsif ($ch eq '阄') {
			$vars = '[阄鬮]';
		} elsif ($ch eq '阅') {
			$vars = '[阅閱閲]';
		} elsif ($ch eq '阆') {
			$vars = '[阆閬]';
		} elsif ($ch eq '阈') {
			$vars = '[阈閾]';
		} elsif ($ch eq '阉') {
			$vars = '[阉閹]';
		} elsif ($ch eq '阊') {
			$vars = '[阊閶]';
		} elsif ($ch eq '阋') {
			$vars = '[阋鬩]';
		} elsif ($ch eq '阌') {
			$vars = '[阌閿]';
		} elsif ($ch eq '阍') {
			$vars = '[阍閽]';
		} elsif ($ch eq '阎') {
			$vars = '[阎閻]';
		} elsif ($ch eq '阏') {
			$vars = '[阏閼]';
		} elsif ($ch eq '阐') {
			$vars = '[阐闡]';
		} elsif ($ch eq '阑') {
			$vars = '[阑闌]';
		} elsif ($ch eq '阒') {
			$vars = '[阒闃]';
		} elsif ($ch eq '阔') {
			$vars = '[阔闊]';
		} elsif ($ch eq '阕') {
			$vars = '[阕闋]';
		} elsif ($ch eq '阖') {
			$vars = '[阖閤闔]';
		} elsif ($ch eq '阗') {
			$vars = '[阗闐]';
		} elsif ($ch eq '阙') {
			$vars = '[阙闕]';
		} elsif ($ch eq '阚') {
			$vars = '[阚闞]';
		} elsif ($ch eq '阜') {
			$vars = '[阜阝]';
		} elsif ($ch eq '阝') {
			$vars = '[阝邑阜]';
		} elsif ($ch eq '队') {
			$vars = '[队隊]';
		} elsif ($ch eq '阡') {
			$vars = '[阡仟]';
		} elsif ($ch eq '阨') {
			$vars = '[阨厄呃]';
		} elsif ($ch eq '阪') {
			$vars = '[阪坂]';
		} elsif ($ch eq '阬') {
			$vars = '[阬坑]';
		} elsif ($ch eq '阮') {
			$vars = '[阮阮]';
		} elsif ($ch eq '阯') {
			$vars = '[阯址]';
		} elsif ($ch eq '阱') {
			$vars = '[阱穽]';
		} elsif ($ch eq '阳') {
			$vars = '[阳陽]';
		} elsif ($ch eq '阴') {
			$vars = '[阴陰]';
		} elsif ($ch eq '阵') {
			$vars = '[阵陣]';
		} elsif ($ch eq '阶') {
			$vars = '[阶階]';
		} elsif ($ch eq '阿') {
			$vars = '[阿啊]';
		} elsif ($ch eq '际') {
			$vars = '[际際]';
		} elsif ($ch eq '陆') {
			$vars = '[陆陸]';
		} elsif ($ch eq '陇') {
			$vars = '[陇隴]';
		} elsif ($ch eq '陈') {
			$vars = '[陈陳]';
		} elsif ($ch eq '陉') {
			$vars = '[陉陘]';
		} elsif ($ch eq '陋') {
			$vars = '[陋陋]';
		} elsif ($ch eq '降') {
			$vars = '[降降]';
		} elsif ($ch eq '陏') {
			$vars = '[陏隋]';
		} elsif ($ch eq '陔') {
			$vars = '[陔垓]';
		} elsif ($ch eq '陕') {
			$vars = '[陕陝]';
		} elsif ($ch eq '陘') {
			$vars = '[陘陉]';
		} elsif ($ch eq '陜') {
			$vars = '[陜陝狹]';
		} elsif ($ch eq '陝') {
			$vars = '[陝陕陜]';
		} elsif ($ch eq '陞') {
			$vars = '[陞升]';
		} elsif ($ch eq '陣') {
			$vars = '[陣陳阵]';
		} elsif ($ch eq '陥') {
			$vars = '[陥陷]';
		} elsif ($ch eq '陧') {
			$vars = '[陧隉]';
		} elsif ($ch eq '陨') {
			$vars = '[陨隕]';
		} elsif ($ch eq '险') {
			$vars = '[险險]';
		} elsif ($ch eq '陰') {
			$vars = '[陰阴]';
		} elsif ($ch eq '陳') {
			$vars = '[陳陣陈]';
		} elsif ($ch eq '陵') {
			$vars = '[陵陵]';
		} elsif ($ch eq '陶') {
			$vars = '[陶匋]';
		} elsif ($ch eq '陷') {
			$vars = '[陷陥]';
		} elsif ($ch eq '陸') {
			$vars = '[陸六陆]';
		} elsif ($ch eq '険') {
			$vars = '[険險]';
		} elsif ($ch eq '陼') {
			$vars = '[陼渚]';
		} elsif ($ch eq '陽') {
			$vars = '[陽昜阳]';
		} elsif ($ch eq '隄') {
			$vars = '[隄堤]';
		} elsif ($ch eq '隆') {
			$vars = '[隆隆]';
		} elsif ($ch eq '隈') {
			$vars = '[隈偎渨]';
		} elsif ($ch eq '隉') {
			$vars = '[隉陧]';
		} elsif ($ch eq '隊') {
			$vars = '[隊队]';
		} elsif ($ch eq '隋') {
			$vars = '[隋陏]';
		} elsif ($ch eq '隍') {
			$vars = '[隍堭]';
		} elsif ($ch eq '階') {
			$vars = '[階阶]';
		} elsif ($ch eq '随') {
			$vars = '[随隨]';
		} elsif ($ch eq '隐') {
			$vars = '[隐隱隠]';
		} elsif ($ch eq '隕') {
			$vars = '[隕陨殒]';
		} elsif ($ch eq '際') {
			$vars = '[際际]';
		} elsif ($ch eq '隠') {
			$vars = '[隠隱隐]';
		} elsif ($ch eq '隣') {
			$vars = '[隣鄰]';
		} elsif ($ch eq '隨') {
			$vars = '[隨随]';
		} elsif ($ch eq '險') {
			$vars = '[險险]';
		} elsif ($ch eq '隮') {
			$vars = '[隮躋]';
		} elsif ($ch eq '隱') {
			$vars = '[隱隐]';
		} elsif ($ch eq '隲') {
			$vars = '[隲騭]';
		} elsif ($ch eq '隴') {
			$vars = '[隴陇]';
		} elsif ($ch eq '隶') {
			$vars = '[隶隸]';
		} elsif ($ch eq '隷') {
			$vars = '[隷隸]';
		} elsif ($ch eq '隸') {
			$vars = '[隸隷隶]';
		} elsif ($ch eq '隻') {
			$vars = '[隻只]';
		} elsif ($ch eq '隼') {
			$vars = '[隼鵻]';
		} elsif ($ch eq '隽') {
			$vars = '[隽雋]';
		} elsif ($ch eq '难') {
			$vars = '[难難]';
		} elsif ($ch eq '雁') {
			$vars = '[雁鳫鴈]';
		} elsif ($ch eq '雇') {
			$vars = '[雇僱]';
		} elsif ($ch eq '雋') {
			$vars = '[雋隽]';
		} elsif ($ch eq '雍') {
			$vars = '[雍邕]';
		} elsif ($ch eq '雏') {
			$vars = '[雏雛]';
		} elsif ($ch eq '雑') {
			$vars = '[雑雜]';
		} elsif ($ch eq '雕') {
			$vars = '[雕鵰彫]';
		} elsif ($ch eq '雖') {
			$vars = '[雖虽]';
		} elsif ($ch eq '雙') {
			$vars = '[雙双]';
		} elsif ($ch eq '雛') {
			$vars = '[雛雏鶵]';
		} elsif ($ch eq '雜') {
			$vars = '[雜雑杂襍]';
		} elsif ($ch eq '雝') {
			$vars = '[雝廱]';
		} elsif ($ch eq '雞') {
			$vars = '[雞鸡鷄]';
		} elsif ($ch eq '雠') {
			$vars = '[雠仇讎]';
		} elsif ($ch eq '離') {
			$vars = '[離离離]';
		} elsif ($ch eq '難') {
			$vars = '[難难]';
		} elsif ($ch eq '雨') {
			$vars = '[雨馭]';
		} elsif ($ch eq '雲') {
			$vars = '[雲云]';
		} elsif ($ch eq '雳') {
			$vars = '[雳靂]';
		} elsif ($ch eq '零') {
			$vars = '[零零]';
		} elsif ($ch eq '雷') {
			$vars = '[雷雷]';
		} elsif ($ch eq '電') {
			$vars = '[電电]';
		} elsif ($ch eq '雾') {
			$vars = '[雾霧]';
		} elsif ($ch eq '霁') {
			$vars = '[霁霽]';
		} elsif ($ch eq '霊') {
			$vars = '[霊靈]';
		} elsif ($ch eq '霍') {
			$vars = '[霍癨]';
		} elsif ($ch eq '霜') {
			$vars = '[霜孀]';
		} elsif ($ch eq '霥') {
			$vars = '[霥濛]';
		} elsif ($ch eq '霧') {
			$vars = '[霧雾]';
		} elsif ($ch eq '霭') {
			$vars = '[霭靄]';
		} elsif ($ch eq '露') {
			$vars = '[露露]';
		} elsif ($ch eq '霸') {
			$vars = '[霸覇]';
		} elsif ($ch eq '霽') {
			$vars = '[霽霁]';
		} elsif ($ch eq '靂') {
			$vars = '[靂雳]';
		} elsif ($ch eq '靄') {
			$vars = '[靄霭]';
		} elsif ($ch eq '靈') {
			$vars = '[靈靈灵]';
		} elsif ($ch eq '靑') {
			$vars = '[靑青]';
		} elsif ($ch eq '青') {
			$vars = '[青靑]';
		} elsif ($ch eq '靓') {
			$vars = '[靓靚]';
		} elsif ($ch eq '静') {
			$vars = '[静靜]';
		} elsif ($ch eq '靚') {
			$vars = '[靚靜靓]';
		} elsif ($ch eq '靜') {
			$vars = '[靜静]';
		} elsif ($ch eq '面') {
			$vars = '[面麵]';
		} elsif ($ch eq '靥') {
			$vars = '[靥靨]';
		} elsif ($ch eq '靦') {
			$vars = '[靦腼]';
		} elsif ($ch eq '靨') {
			$vars = '[靨靥]';
		} elsif ($ch eq '靭') {
			$vars = '[靭韌]';
		} elsif ($ch eq '靱') {
			$vars = '[靱韌]';
		} elsif ($ch eq '鞀') {
			$vars = '[鞀鼗]';
		} elsif ($ch eq '鞏') {
			$vars = '[鞏巩]';
		} elsif ($ch eq '鞑') {
			$vars = '[鞑韃]';
		} elsif ($ch eq '鞒') {
			$vars = '[鞒橇]';
		} elsif ($ch eq '鞙') {
			$vars = '[鞙琄]';
		} elsif ($ch eq '鞝') {
			$vars = '[鞝绱]';
		} elsif ($ch eq '鞯') {
			$vars = '[鞯韉]';
		} elsif ($ch eq '鞲') {
			$vars = '[鞲韝]';
		} elsif ($ch eq '韁') {
			$vars = '[韁缰]';
		} elsif ($ch eq '韃') {
			$vars = '[韃鞑]';
		} elsif ($ch eq '韈') {
			$vars = '[韈襪]';
		} elsif ($ch eq '韉') {
			$vars = '[韉鞯]';
		} elsif ($ch eq '韋') {
			$vars = '[韋韦]';
		} elsif ($ch eq '韌') {
			$vars = '[韌韧靭肕]';
		} elsif ($ch eq '韓') {
			$vars = '[韓韩]';
		} elsif ($ch eq '韙') {
			$vars = '[韙韪]';
		} elsif ($ch eq '韜') {
			$vars = '[韜弢韬]';
		} elsif ($ch eq '韝') {
			$vars = '[韝鞲]';
		} elsif ($ch eq '韞') {
			$vars = '[韞韫縕]';
		} elsif ($ch eq '韦') {
			$vars = '[韦韋]';
		} elsif ($ch eq '韧') {
			$vars = '[韧韌]';
		} elsif ($ch eq '韩') {
			$vars = '[韩韓]';
		} elsif ($ch eq '韪') {
			$vars = '[韪韙]';
		} elsif ($ch eq '韫') {
			$vars = '[韫韞]';
		} elsif ($ch eq '韬') {
			$vars = '[韬韜]';
		} elsif ($ch eq '韭') {
			$vars = '[韭韮艽]';
		} elsif ($ch eq '韮') {
			$vars = '[韮韭]';
		} elsif ($ch eq '韲') {
			$vars = '[韲齏]';
		} elsif ($ch eq '韵') {
			$vars = '[韵韻]';
		} elsif ($ch eq '韻') {
			$vars = '[韻韵]';
		} elsif ($ch eq '響') {
			$vars = '[響响]';
		} elsif ($ch eq '頁') {
			$vars = '[頁页]';
		} elsif ($ch eq '頂') {
			$vars = '[頂顶]';
		} elsif ($ch eq '頃') {
			$vars = '[頃顷]';
		} elsif ($ch eq '項') {
			$vars = '[項项]';
		} elsif ($ch eq '順') {
			$vars = '[順顺]';
		} elsif ($ch eq '頇') {
			$vars = '[頇顸]';
		} elsif ($ch eq '須') {
			$vars = '[須须]';
		} elsif ($ch eq '頊') {
			$vars = '[頊顼]';
		} elsif ($ch eq '頌') {
			$vars = '[頌颂]';
		} elsif ($ch eq '頎') {
			$vars = '[頎颀]';
		} elsif ($ch eq '頏') {
			$vars = '[頏颃]';
		} elsif ($ch eq '預') {
			$vars = '[預预豫]';
		} elsif ($ch eq '頑') {
			$vars = '[頑顽]';
		} elsif ($ch eq '頒') {
			$vars = '[頒颁]';
		} elsif ($ch eq '頓') {
			$vars = '[頓顿]';
		} elsif ($ch eq '頗') {
			$vars = '[頗颇]';
		} elsif ($ch eq '領') {
			$vars = '[領领領]';
		} elsif ($ch eq '頚') {
			$vars = '[頚頸]';
		} elsif ($ch eq '頜') {
			$vars = '[頜颌]';
		} elsif ($ch eq '頡') {
			$vars = '[頡颉]';
		} elsif ($ch eq '頤') {
			$vars = '[頤颐]';
		} elsif ($ch eq '頦') {
			$vars = '[頦颏]';
		} elsif ($ch eq '頫') {
			$vars = '[頫俯]';
		} elsif ($ch eq '頬') {
			$vars = '[頬頰]';
		} elsif ($ch eq '頭') {
			$vars = '[頭头]';
		} elsif ($ch eq '頰') {
			$vars = '[頰颊]';
		} elsif ($ch eq '頴') {
			$vars = '[頴穎]';
		} elsif ($ch eq '頷') {
			$vars = '[頷颔]';
		} elsif ($ch eq '頸') {
			$vars = '[頸颈]';
		} elsif ($ch eq '頹') {
			$vars = '[頹颓頽]';
		} elsif ($ch eq '頻') {
			$vars = '[頻频]';
		} elsif ($ch eq '頼') {
			$vars = '[頼賴]';
		} elsif ($ch eq '頽') {
			$vars = '[頽頹颓]';
		} elsif ($ch eq '顆') {
			$vars = '[顆颗]';
		} elsif ($ch eq '顋') {
			$vars = '[顋腮]';
		} elsif ($ch eq '題') {
			$vars = '[題题]';
		} elsif ($ch eq '額') {
			$vars = '[額额]';
		} elsif ($ch eq '顎') {
			$vars = '[顎颚]';
		} elsif ($ch eq '顏') {
			$vars = '[顏颜]';
		} elsif ($ch eq '顓') {
			$vars = '[顓颛]';
		} elsif ($ch eq '顔') {
			$vars = '[顔颜顏]';
		} elsif ($ch eq '顕') {
			$vars = '[顕顯]';
		} elsif ($ch eq '願') {
			$vars = '[願愿]';
		} elsif ($ch eq '顙') {
			$vars = '[顙颡]';
		} elsif ($ch eq '顚') {
			$vars = '[顚顛]';
		} elsif ($ch eq '顛') {
			$vars = '[顛颠]';
		} elsif ($ch eq '類') {
			$vars = '[類类類]';
		} elsif ($ch eq '顢') {
			$vars = '[顢颟]';
		} elsif ($ch eq '顥') {
			$vars = '[顥颢皝皓]';
		} elsif ($ch eq '顧') {
			$vars = '[顧顾]';
		} elsif ($ch eq '顫') {
			$vars = '[顫颤]';
		} elsif ($ch eq '顯') {
			$vars = '[顯显顕]';
		} elsif ($ch eq '顰') {
			$vars = '[顰颦嚬]';
		} elsif ($ch eq '顱') {
			$vars = '[顱颅]';
		} elsif ($ch eq '顳') {
			$vars = '[顳颞]';
		} elsif ($ch eq '顴') {
			$vars = '[顴颧]';
		} elsif ($ch eq '页') {
			$vars = '[页頁]';
		} elsif ($ch eq '顶') {
			$vars = '[顶頂]';
		} elsif ($ch eq '顷') {
			$vars = '[顷頃]';
		} elsif ($ch eq '顸') {
			$vars = '[顸頇]';
		} elsif ($ch eq '项') {
			$vars = '[项項]';
		} elsif ($ch eq '顺') {
			$vars = '[顺順]';
		} elsif ($ch eq '须') {
			$vars = '[须鬚須]';
		} elsif ($ch eq '顼') {
			$vars = '[顼頊]';
		} elsif ($ch eq '顽') {
			$vars = '[顽頑]';
		} elsif ($ch eq '顾') {
			$vars = '[顾顧]';
		} elsif ($ch eq '顿') {
			$vars = '[顿頓]';
		} elsif ($ch eq '颀') {
			$vars = '[颀頎]';
		} elsif ($ch eq '颁') {
			$vars = '[颁頒]';
		} elsif ($ch eq '颂') {
			$vars = '[颂頌]';
		} elsif ($ch eq '颃') {
			$vars = '[颃頏]';
		} elsif ($ch eq '预') {
			$vars = '[预預]';
		} elsif ($ch eq '颅') {
			$vars = '[颅顱]';
		} elsif ($ch eq '领') {
			$vars = '[领領]';
		} elsif ($ch eq '颇') {
			$vars = '[颇頗]';
		} elsif ($ch eq '颈') {
			$vars = '[颈頸]';
		} elsif ($ch eq '颉') {
			$vars = '[颉頡]';
		} elsif ($ch eq '颊') {
			$vars = '[颊頰]';
		} elsif ($ch eq '颌') {
			$vars = '[颌頜]';
		} elsif ($ch eq '颍') {
			$vars = '[颍潁]';
		} elsif ($ch eq '颏') {
			$vars = '[颏頦]';
		} elsif ($ch eq '颐') {
			$vars = '[颐頤]';
		} elsif ($ch eq '频') {
			$vars = '[频頻]';
		} elsif ($ch eq '颓') {
			$vars = '[颓頹頽]';
		} elsif ($ch eq '颔') {
			$vars = '[颔頷]';
		} elsif ($ch eq '颖') {
			$vars = '[颖穎]';
		} elsif ($ch eq '颗') {
			$vars = '[颗顆]';
		} elsif ($ch eq '题') {
			$vars = '[题題]';
		} elsif ($ch eq '颚') {
			$vars = '[颚顎]';
		} elsif ($ch eq '颛') {
			$vars = '[颛顓]';
		} elsif ($ch eq '颜') {
			$vars = '[颜顔顏]';
		} elsif ($ch eq '额') {
			$vars = '[额額]';
		} elsif ($ch eq '颞') {
			$vars = '[颞顳]';
		} elsif ($ch eq '颟') {
			$vars = '[颟顢]';
		} elsif ($ch eq '颠') {
			$vars = '[颠顛]';
		} elsif ($ch eq '颡') {
			$vars = '[颡顙]';
		} elsif ($ch eq '颢') {
			$vars = '[颢顥]';
		} elsif ($ch eq '颤') {
			$vars = '[颤顫]';
		} elsif ($ch eq '颦') {
			$vars = '[颦顰]';
		} elsif ($ch eq '颧') {
			$vars = '[颧顴]';
		} elsif ($ch eq '風') {
			$vars = '[風风]';
		} elsif ($ch eq '颮') {
			$vars = '[颮飑飇猋]';
		} elsif ($ch eq '颯') {
			$vars = '[颯飒]';
		} elsif ($ch eq '颱') {
			$vars = '[颱台]';
		} elsif ($ch eq '颳') {
			$vars = '[颳刮]';
		} elsif ($ch eq '颶') {
			$vars = '[颶飓]';
		} elsif ($ch eq '颼') {
			$vars = '[颼飕]';
		} elsif ($ch eq '飄') {
			$vars = '[飄飃飘]';
		} elsif ($ch eq '飆') {
			$vars = '[飆飙]';
		} elsif ($ch eq '飇') {
			$vars = '[飇颮猋]';
		} elsif ($ch eq '风') {
			$vars = '[风風]';
		} elsif ($ch eq '飑') {
			$vars = '[飑颮]';
		} elsif ($ch eq '飒') {
			$vars = '[飒颯]';
		} elsif ($ch eq '飓') {
			$vars = '[飓颶]';
		} elsif ($ch eq '飕') {
			$vars = '[飕颼]';
		} elsif ($ch eq '飘') {
			$vars = '[飘飄]';
		} elsif ($ch eq '飙') {
			$vars = '[飙飆]';
		} elsif ($ch eq '飛') {
			$vars = '[飛飞]';
		} elsif ($ch eq '飜') {
			$vars = '[飜翻]';
		} elsif ($ch eq '飞') {
			$vars = '[飞飛]';
		} elsif ($ch eq '食') {
			$vars = '[食饣]';
		} elsif ($ch eq '飡') {
			$vars = '[飡餐]';
		} elsif ($ch eq '飢') {
			$vars = '[飢饑饥]';
		} elsif ($ch eq '飨') {
			$vars = '[飨饗]';
		} elsif ($ch eq '飩') {
			$vars = '[飩饨]';
		} elsif ($ch eq '飪') {
			$vars = '[飪饪]';
		} elsif ($ch eq '飫') {
			$vars = '[飫饫饇]';
		} elsif ($ch eq '飭') {
			$vars = '[飭饬]';
		} elsif ($ch eq '飮') {
			$vars = '[飮飲]';
		} elsif ($ch eq '飯') {
			$vars = '[飯饭]';
		} elsif ($ch eq '飲') {
			$vars = '[飲饮飮]';
		} elsif ($ch eq '飴') {
			$vars = '[飴饴]';
		} elsif ($ch eq '飼') {
			$vars = '[飼饲]';
		} elsif ($ch eq '飽') {
			$vars = '[飽饱]';
		} elsif ($ch eq '飾') {
			$vars = '[飾饰]';
		} elsif ($ch eq '餂') {
			$vars = '[餂舔]';
		} elsif ($ch eq '餃') {
			$vars = '[餃饺]';
		} elsif ($ch eq '餅') {
			$vars = '[餅饼餠]';
		} elsif ($ch eq '餉') {
			$vars = '[餉饟饷]';
		} elsif ($ch eq '養') {
			$vars = '[養养]';
		} elsif ($ch eq '餌') {
			$vars = '[餌饵]';
		} elsif ($ch eq '餍') {
			$vars = '[餍饜]';
		} elsif ($ch eq '餐') {
			$vars = '[餐飡]';
		} elsif ($ch eq '餑') {
			$vars = '[餑饽]';
		} elsif ($ch eq '餒') {
			$vars = '[餒餧馁]';
		} elsif ($ch eq '餓') {
			$vars = '[餓饿]';
		} elsif ($ch eq '餘') {
			$vars = '[餘馀余]';
		} elsif ($ch eq '餚') {
			$vars = '[餚肴]';
		} elsif ($ch eq '餛') {
			$vars = '[餛餫馄]';
		} elsif ($ch eq '餝') {
			$vars = '[餝飾]';
		} elsif ($ch eq '餞') {
			$vars = '[餞饯]';
		} elsif ($ch eq '餟') {
			$vars = '[餟醊]';
		} elsif ($ch eq '餠') {
			$vars = '[餠餅]';
		} elsif ($ch eq '餡') {
			$vars = '[餡馅]';
		} elsif ($ch eq '餧') {
			$vars = '[餧喂餒]';
		} elsif ($ch eq '館') {
			$vars = '[館馆舘]';
		} elsif ($ch eq '餫') {
			$vars = '[餫餛]';
		} elsif ($ch eq '餱') {
			$vars = '[餱糇]';
		} elsif ($ch eq '餳') {
			$vars = '[餳饧]';
		} elsif ($ch eq '餵') {
			$vars = '[餵喂諉]';
		} elsif ($ch eq '餼') {
			$vars = '[餼饩]';
		} elsif ($ch eq '餽') {
			$vars = '[餽饋]';
		} elsif ($ch eq '餾') {
			$vars = '[餾馏]';
		} elsif ($ch eq '餿') {
			$vars = '[餿馊]';
		} elsif ($ch eq '饃') {
			$vars = '[饃馍]';
		} elsif ($ch eq '饅') {
			$vars = '[饅馒]';
		} elsif ($ch eq '饇') {
			$vars = '[饇飫]';
		} elsif ($ch eq '饈') {
			$vars = '[饈馐]';
		} elsif ($ch eq '饉') {
			$vars = '[饉馑]';
		} elsif ($ch eq '饋') {
			$vars = '[饋匱餽櫃馈]';
		} elsif ($ch eq '饌') {
			$vars = '[饌馔]';
		} elsif ($ch eq '饍') {
			$vars = '[饍膳]';
		} elsif ($ch eq '饑') {
			$vars = '[饑飢饥]';
		} elsif ($ch eq '饒') {
			$vars = '[饒饶]';
		} elsif ($ch eq '饕') {
			$vars = '[饕叨]';
		} elsif ($ch eq '饗') {
			$vars = '[饗飨]';
		} elsif ($ch eq '饜') {
			$vars = '[饜餍]';
		} elsif ($ch eq '饞') {
			$vars = '[饞嚵馋]';
		} elsif ($ch eq '饟') {
			$vars = '[饟餉]';
		} elsif ($ch eq '饥') {
			$vars = '[饥饑飢]';
		} elsif ($ch eq '饧') {
			$vars = '[饧餳]';
		} elsif ($ch eq '饨') {
			$vars = '[饨飩]';
		} elsif ($ch eq '饩') {
			$vars = '[饩餼]';
		} elsif ($ch eq '饪') {
			$vars = '[饪飪]';
		} elsif ($ch eq '饫') {
			$vars = '[饫飫]';
		} elsif ($ch eq '饬') {
			$vars = '[饬飭]';
		} elsif ($ch eq '饭') {
			$vars = '[饭飯]';
		} elsif ($ch eq '饮') {
			$vars = '[饮飮飲]';
		} elsif ($ch eq '饯') {
			$vars = '[饯餞]';
		} elsif ($ch eq '饰') {
			$vars = '[饰飾]';
		} elsif ($ch eq '饱') {
			$vars = '[饱飽]';
		} elsif ($ch eq '饲') {
			$vars = '[饲飼]';
		} elsif ($ch eq '饴') {
			$vars = '[饴飴]';
		} elsif ($ch eq '饵') {
			$vars = '[饵餌]';
		} elsif ($ch eq '饶') {
			$vars = '[饶饒]';
		} elsif ($ch eq '饷') {
			$vars = '[饷餉]';
		} elsif ($ch eq '饺') {
			$vars = '[饺餃]';
		} elsif ($ch eq '饼') {
			$vars = '[饼餅]';
		} elsif ($ch eq '饽') {
			$vars = '[饽餑]';
		} elsif ($ch eq '饿') {
			$vars = '[饿餓]';
		} elsif ($ch eq '馀') {
			$vars = '[馀余餘]';
		} elsif ($ch eq '馁') {
			$vars = '[馁餒]';
		} elsif ($ch eq '馄') {
			$vars = '[馄餛]';
		} elsif ($ch eq '馅') {
			$vars = '[馅餡]';
		} elsif ($ch eq '馆') {
			$vars = '[馆館]';
		} elsif ($ch eq '馈') {
			$vars = '[馈餽饋]';
		} elsif ($ch eq '馊') {
			$vars = '[馊餿]';
		} elsif ($ch eq '馋') {
			$vars = '[馋饞]';
		} elsif ($ch eq '馍') {
			$vars = '[馍饃]';
		} elsif ($ch eq '馏') {
			$vars = '[馏餾]';
		} elsif ($ch eq '馐') {
			$vars = '[馐饈]';
		} elsif ($ch eq '馑') {
			$vars = '[馑饉]';
		} elsif ($ch eq '馒') {
			$vars = '[馒饅]';
		} elsif ($ch eq '馔') {
			$vars = '[馔饌]';
		} elsif ($ch eq '馘') {
			$vars = '[馘聝]';
		} elsif ($ch eq '馬') {
			$vars = '[馬马]';
		} elsif ($ch eq '馭') {
			$vars = '[馭驭御]';
		} elsif ($ch eq '馮') {
			$vars = '[馮冯]';
		} elsif ($ch eq '馱') {
			$vars = '[馱驮駄]';
		} elsif ($ch eq '馳') {
			$vars = '[馳驰]';
		} elsif ($ch eq '馴') {
			$vars = '[馴驯]';
		} elsif ($ch eq '駁') {
			$vars = '[駁驳駮]';
		} elsif ($ch eq '駄') {
			$vars = '[駄馱]';
		} elsif ($ch eq '駅') {
			$vars = '[駅驛]';
		} elsif ($ch eq '駆') {
			$vars = '[駆驅]';
		} elsif ($ch eq '駈') {
			$vars = '[駈驅]';
		} elsif ($ch eq '駐') {
			$vars = '[駐驻]';
		} elsif ($ch eq '駑') {
			$vars = '[駑驽]';
		} elsif ($ch eq '駒') {
			$vars = '[駒驹]';
		} elsif ($ch eq '駔') {
			$vars = '[駔驵]';
		} elsif ($ch eq '駕') {
			$vars = '[駕驾]';
		} elsif ($ch eq '駘') {
			$vars = '[駘骀]';
		} elsif ($ch eq '駙') {
			$vars = '[駙驸]';
		} elsif ($ch eq '駛') {
			$vars = '[駛驶]';
		} elsif ($ch eq '駝') {
			$vars = '[駝驼]';
		} elsif ($ch eq '駟') {
			$vars = '[駟驷]';
		} elsif ($ch eq '駢') {
			$vars = '[駢騈骈]';
		} elsif ($ch eq '駪') {
			$vars = '[駪侁詵]';
		} elsif ($ch eq '駭') {
			$vars = '[駭骇]';
		} elsif ($ch eq '駮') {
			$vars = '[駮駁]';
		} elsif ($ch eq '駱') {
			$vars = '[駱駱骆]';
		} elsif ($ch eq '駿') {
			$vars = '[駿骏]';
		} elsif ($ch eq '騁') {
			$vars = '[騁骋]';
		} elsif ($ch eq '騃') {
			$vars = '[騃呆]';
		} elsif ($ch eq '騅') {
			$vars = '[騅骓]';
		} elsif ($ch eq '騈') {
			$vars = '[騈駢]';
		} elsif ($ch eq '騍') {
			$vars = '[騍骒]';
		} elsif ($ch eq '騎') {
			$vars = '[騎骑]';
		} elsif ($ch eq '騏') {
			$vars = '[騏骐]';
		} elsif ($ch eq '騒') {
			$vars = '[騒騷]';
		} elsif ($ch eq '験') {
			$vars = '[験驗]';
		} elsif ($ch eq '騖') {
			$vars = '[騖骛]';
		} elsif ($ch eq '騙') {
			$vars = '[騙骗]';
		} elsif ($ch eq '騣') {
			$vars = '[騣鬃]';
		} elsif ($ch eq '騨') {
			$vars = '[騨驒]';
		} elsif ($ch eq '騫') {
			$vars = '[騫骞]';
		} elsif ($ch eq '騭') {
			$vars = '[騭骘隲]';
		} elsif ($ch eq '騮') {
			$vars = '[騮骝]';
		} elsif ($ch eq '騰') {
			$vars = '[騰腾]';
		} elsif ($ch eq '騶') {
			$vars = '[騶驺]';
		} elsif ($ch eq '騷') {
			$vars = '[騷骚]';
		} elsif ($ch eq '騸') {
			$vars = '[騸骟]';
		} elsif ($ch eq '騾') {
			$vars = '[騾骡]';
		} elsif ($ch eq '驀') {
			$vars = '[驀蓦]';
		} elsif ($ch eq '驁') {
			$vars = '[驁骜]';
		} elsif ($ch eq '驂') {
			$vars = '[驂骖]';
		} elsif ($ch eq '驃') {
			$vars = '[驃骠]';
		} elsif ($ch eq '驄') {
			$vars = '[驄骢]';
		} elsif ($ch eq '驅') {
			$vars = '[驅驱敺]';
		} elsif ($ch eq '驊') {
			$vars = '[驊骅]';
		} elsif ($ch eq '驍') {
			$vars = '[驍骁]';
		} elsif ($ch eq '驏') {
			$vars = '[驏骣]';
		} elsif ($ch eq '驒') {
			$vars = '[驒騨]';
		} elsif ($ch eq '驕') {
			$vars = '[驕骄]';
		} elsif ($ch eq '驗') {
			$vars = '[驗验]';
		} elsif ($ch eq '驚') {
			$vars = '[驚惊]';
		} elsif ($ch eq '驛') {
			$vars = '[驛驿]';
		} elsif ($ch eq '驟') {
			$vars = '[驟骤]';
		} elsif ($ch eq '驢') {
			$vars = '[驢驴]';
		} elsif ($ch eq '驤') {
			$vars = '[驤骧]';
		} elsif ($ch eq '驥') {
			$vars = '[驥骥]';
		} elsif ($ch eq '驩') {
			$vars = '[驩歡]';
		} elsif ($ch eq '驪') {
			$vars = '[驪骊]';
		} elsif ($ch eq '马') {
			$vars = '[马馬]';
		} elsif ($ch eq '驭') {
			$vars = '[驭馭]';
		} elsif ($ch eq '驮') {
			$vars = '[驮馱]';
		} elsif ($ch eq '驯') {
			$vars = '[驯馴]';
		} elsif ($ch eq '驰') {
			$vars = '[驰馳]';
		} elsif ($ch eq '驱') {
			$vars = '[驱驅]';
		} elsif ($ch eq '驳') {
			$vars = '[驳駁]';
		} elsif ($ch eq '驴') {
			$vars = '[驴驢]';
		} elsif ($ch eq '驵') {
			$vars = '[驵駔]';
		} elsif ($ch eq '驶') {
			$vars = '[驶駛]';
		} elsif ($ch eq '驷') {
			$vars = '[驷駟]';
		} elsif ($ch eq '驸') {
			$vars = '[驸駙]';
		} elsif ($ch eq '驹') {
			$vars = '[驹駒]';
		} elsif ($ch eq '驺') {
			$vars = '[驺騶]';
		} elsif ($ch eq '驻') {
			$vars = '[驻駐]';
		} elsif ($ch eq '驼') {
			$vars = '[驼駝]';
		} elsif ($ch eq '驽') {
			$vars = '[驽駑]';
		} elsif ($ch eq '驾') {
			$vars = '[驾駕]';
		} elsif ($ch eq '驿') {
			$vars = '[驿驛]';
		} elsif ($ch eq '骀') {
			$vars = '[骀駘]';
		} elsif ($ch eq '骁') {
			$vars = '[骁驍]';
		} elsif ($ch eq '骂') {
			$vars = '[骂罵]';
		} elsif ($ch eq '骄') {
			$vars = '[骄驕]';
		} elsif ($ch eq '骅') {
			$vars = '[骅驊]';
		} elsif ($ch eq '骆') {
			$vars = '[骆駱]';
		} elsif ($ch eq '骇') {
			$vars = '[骇駭]';
		} elsif ($ch eq '骈') {
			$vars = '[骈駢]';
		} elsif ($ch eq '骊') {
			$vars = '[骊驪]';
		} elsif ($ch eq '骋') {
			$vars = '[骋騁]';
		} elsif ($ch eq '验') {
			$vars = '[验驗]';
		} elsif ($ch eq '骏') {
			$vars = '[骏駿]';
		} elsif ($ch eq '骐') {
			$vars = '[骐騏]';
		} elsif ($ch eq '骑') {
			$vars = '[骑騎]';
		} elsif ($ch eq '骒') {
			$vars = '[骒騍]';
		} elsif ($ch eq '骓') {
			$vars = '[骓騅]';
		} elsif ($ch eq '骖') {
			$vars = '[骖驂]';
		} elsif ($ch eq '骗') {
			$vars = '[骗騙]';
		} elsif ($ch eq '骘') {
			$vars = '[骘騭]';
		} elsif ($ch eq '骚') {
			$vars = '[骚騷]';
		} elsif ($ch eq '骛') {
			$vars = '[骛騖]';
		} elsif ($ch eq '骜') {
			$vars = '[骜驁]';
		} elsif ($ch eq '骝') {
			$vars = '[骝騮]';
		} elsif ($ch eq '骞') {
			$vars = '[骞騫]';
		} elsif ($ch eq '骟') {
			$vars = '[骟騸]';
		} elsif ($ch eq '骠') {
			$vars = '[骠驃]';
		} elsif ($ch eq '骡') {
			$vars = '[骡騾]';
		} elsif ($ch eq '骢') {
			$vars = '[骢驄]';
		} elsif ($ch eq '骣') {
			$vars = '[骣驏]';
		} elsif ($ch eq '骤') {
			$vars = '[骤驟]';
		} elsif ($ch eq '骥') {
			$vars = '[骥驥]';
		} elsif ($ch eq '骧') {
			$vars = '[骧驤]';
		} elsif ($ch eq '骯') {
			$vars = '[骯腌肮]';
		} elsif ($ch eq '骴') {
			$vars = '[骴胔]';
		} elsif ($ch eq '骻') {
			$vars = '[骻胯]';
		} elsif ($ch eq '骾') {
			$vars = '[骾挭鯁]';
		} elsif ($ch eq '髄') {
			$vars = '[髄髓]';
		} elsif ($ch eq '髅') {
			$vars = '[髅髏]';
		} elsif ($ch eq '髋') {
			$vars = '[髋髖]';
		} elsif ($ch eq '髌') {
			$vars = '[髌臏髕]';
		} elsif ($ch eq '髏') {
			$vars = '[髏髅]';
		} elsif ($ch eq '髒') {
			$vars = '[髒脏]';
		} elsif ($ch eq '髓') {
			$vars = '[髓膸]';
		} elsif ($ch eq '體') {
			$vars = '[體体]';
		} elsif ($ch eq '髕') {
			$vars = '[髕髌臏]';
		} elsif ($ch eq '髖') {
			$vars = '[髖髋]';
		} elsif ($ch eq '髣') {
			$vars = '[髣仿彷]';
		} elsif ($ch eq '髦') {
			$vars = '[髦犛]';
		} elsif ($ch eq '髪') {
			$vars = '[髪髮]';
		} elsif ($ch eq '髮') {
			$vars = '[髮发]';
		} elsif ($ch eq '髯') {
			$vars = '[髯髥]';
		} elsif ($ch eq '髴') {
			$vars = '[髴彿]';
		} elsif ($ch eq '髼') {
			$vars = '[髼鬅]';
		} elsif ($ch eq '鬅') {
			$vars = '[鬅髼]';
		} elsif ($ch eq '鬆') {
			$vars = '[鬆松]';
		} elsif ($ch eq '鬍') {
			$vars = '[鬍胡]';
		} elsif ($ch eq '鬓') {
			$vars = '[鬓鬢]';
		} elsif ($ch eq '鬚') {
			$vars = '[鬚须]';
		} elsif ($ch eq '鬢') {
			$vars = '[鬢鬓]';
		} elsif ($ch eq '鬥') {
			$vars = '[鬥斗鬪]';
		} elsif ($ch eq '鬧') {
			$vars = '[鬧闹閙]';
		} elsif ($ch eq '鬨') {
			$vars = '[鬨閧哄]';
		} elsif ($ch eq '鬩') {
			$vars = '[鬩阋]';
		} elsif ($ch eq '鬪') {
			$vars = '[鬪鬥]';
		} elsif ($ch eq '鬮') {
			$vars = '[鬮阄]';
		} elsif ($ch eq '鬱') {
			$vars = '[鬱欝郁]';
		} elsif ($ch eq '鬻') {
			$vars = '[鬻粥]';
		} elsif ($ch eq '魇') {
			$vars = '[魇魘]';
		} elsif ($ch eq '魉') {
			$vars = '[魉魎]';
		} elsif ($ch eq '魎') {
			$vars = '[魎魉]';
		} elsif ($ch eq '魏') {
			$vars = '[魏巍]';
		} elsif ($ch eq '魘') {
			$vars = '[魘魇]';
		} elsif ($ch eq '魚') {
			$vars = '[魚鱼]';
		} elsif ($ch eq '魟') {
			$vars = '[魟鰩]';
		} elsif ($ch eq '魦') {
			$vars = '[魦鯊]';
		} elsif ($ch eq '魯') {
			$vars = '[魯魯鲁]';
		} elsif ($ch eq '魴') {
			$vars = '[魴鲂]';
		} elsif ($ch eq '魷') {
			$vars = '[魷鱿鰌]';
		} elsif ($ch eq '鮃') {
			$vars = '[鮃鲆]';
		} elsif ($ch eq '鮎') {
			$vars = '[鮎鲇]';
		} elsif ($ch eq '鮐') {
			$vars = '[鮐鲐]';
		} elsif ($ch eq '鮑') {
			$vars = '[鮑鲍]';
		} elsif ($ch eq '鮒') {
			$vars = '[鮒鲋]';
		} elsif ($ch eq '鮚') {
			$vars = '[鮚鲒]';
		} elsif ($ch eq '鮞') {
			$vars = '[鮞鲕]';
		} elsif ($ch eq '鮪') {
			$vars = '[鮪鲔]';
		} elsif ($ch eq '鮫') {
			$vars = '[鮫鲛]';
		} elsif ($ch eq '鮭') {
			$vars = '[鮭鲑]';
		} elsif ($ch eq '鮮') {
			$vars = '[鮮尟鲜]';
		} elsif ($ch eq '鯀') {
			$vars = '[鯀鲧]';
		} elsif ($ch eq '鯁') {
			$vars = '[鯁挭鲠骾]';
		} elsif ($ch eq '鯇') {
			$vars = '[鯇鲩]';
		} elsif ($ch eq '鯉') {
			$vars = '[鯉鲤]';
		} elsif ($ch eq '鯊') {
			$vars = '[鯊魦鲨]';
		} elsif ($ch eq '鯔') {
			$vars = '[鯔鲻]';
		} elsif ($ch eq '鯖') {
			$vars = '[鯖鲭]';
		} elsif ($ch eq '鯗') {
			$vars = '[鯗鲞]';
		} elsif ($ch eq '鯛') {
			$vars = '[鯛鲷]';
		} elsif ($ch eq '鯡') {
			$vars = '[鯡鲱]';
		} elsif ($ch eq '鯢') {
			$vars = '[鯢鲵]';
		} elsif ($ch eq '鯤') {
			$vars = '[鯤鲲]';
		} elsif ($ch eq '鯧') {
			$vars = '[鯧鲳]';
		} elsif ($ch eq '鯨') {
			$vars = '[鯨鲸]';
		} elsif ($ch eq '鯪') {
			$vars = '[鯪鲮]';
		} elsif ($ch eq '鯫') {
			$vars = '[鯫鲰]';
		} elsif ($ch eq '鯰') {
			$vars = '[鯰鲇鲶]';
		} elsif ($ch eq '鯽') {
			$vars = '[鯽鲫]';
		} elsif ($ch eq '鰈') {
			$vars = '[鰈鲽]';
		} elsif ($ch eq '鰉') {
			$vars = '[鰉鳇]';
		} elsif ($ch eq '鰌') {
			$vars = '[鰌魷鰍]';
		} elsif ($ch eq '鰍') {
			$vars = '[鰍鳅鰌]';
		} elsif ($ch eq '鰐') {
			$vars = '[鰐鳄鱷]';
		} elsif ($ch eq '鰒') {
			$vars = '[鰒鳆]';
		} elsif ($ch eq '鰓') {
			$vars = '[鰓鳃]';
		} elsif ($ch eq '鰕') {
			$vars = '[鰕蝦]';
		} elsif ($ch eq '鰣') {
			$vars = '[鰣鲥]';
		} elsif ($ch eq '鰥') {
			$vars = '[鰥鳏]';
		} elsif ($ch eq '鰨') {
			$vars = '[鰨鳎]';
		} elsif ($ch eq '鰩') {
			$vars = '[鰩魟鳐]';
		} elsif ($ch eq '鰭') {
			$vars = '[鰭鳍]';
		} elsif ($ch eq '鰱') {
			$vars = '[鰱鲢]';
		} elsif ($ch eq '鰲') {
			$vars = '[鰲鼇鳌]';
		} elsif ($ch eq '鰳') {
			$vars = '[鰳鳓]';
		} elsif ($ch eq '鰷') {
			$vars = '[鰷鲦]';
		} elsif ($ch eq '鰹') {
			$vars = '[鰹鲣]';
		} elsif ($ch eq '鰻') {
			$vars = '[鰻鳗]';
		} elsif ($ch eq '鰾') {
			$vars = '[鰾鳔]';
		} elsif ($ch eq '鱈') {
			$vars = '[鱈鳕]';
		} elsif ($ch eq '鱉') {
			$vars = '[鱉鳖鼈]';
		} elsif ($ch eq '鱒') {
			$vars = '[鱒鳟]';
		} elsif ($ch eq '鱔') {
			$vars = '[鱔鳝]';
		} elsif ($ch eq '鱖') {
			$vars = '[鱖鳜]';
		} elsif ($ch eq '鱗') {
			$vars = '[鱗鱗鳞]';
		} elsif ($ch eq '鱘') {
			$vars = '[鱘鲟]';
		} elsif ($ch eq '鱟') {
			$vars = '[鱟鲎]';
		} elsif ($ch eq '鱠') {
			$vars = '[鱠膾]';
		} elsif ($ch eq '鱧') {
			$vars = '[鱧鳢]';
		} elsif ($ch eq '鱭') {
			$vars = '[鱭鲚]';
		} elsif ($ch eq '鱷') {
			$vars = '[鱷鰐鳄]';
		} elsif ($ch eq '鱸') {
			$vars = '[鱸鲈]';
		} elsif ($ch eq '鱺') {
			$vars = '[鱺鲡]';
		} elsif ($ch eq '鱼') {
			$vars = '[鱼魚]';
		} elsif ($ch eq '鱿') {
			$vars = '[鱿魷]';
		} elsif ($ch eq '鲁') {
			$vars = '[鲁魯]';
		} elsif ($ch eq '鲂') {
			$vars = '[鲂魴]';
		} elsif ($ch eq '鲆') {
			$vars = '[鲆鮃]';
		} elsif ($ch eq '鲇') {
			$vars = '[鲇鯰鮎]';
		} elsif ($ch eq '鲈') {
			$vars = '[鲈鱸]';
		} elsif ($ch eq '鲋') {
			$vars = '[鲋鮒]';
		} elsif ($ch eq '鲍') {
			$vars = '[鲍鮑]';
		} elsif ($ch eq '鲎') {
			$vars = '[鲎鱟]';
		} elsif ($ch eq '鲐') {
			$vars = '[鲐鮐]';
		} elsif ($ch eq '鲑') {
			$vars = '[鲑鮭]';
		} elsif ($ch eq '鲒') {
			$vars = '[鲒鮚]';
		} elsif ($ch eq '鲔') {
			$vars = '[鲔鮪]';
		} elsif ($ch eq '鲕') {
			$vars = '[鲕鮞]';
		} elsif ($ch eq '鲚') {
			$vars = '[鲚鱭]';
		} elsif ($ch eq '鲛') {
			$vars = '[鲛鮫]';
		} elsif ($ch eq '鲜') {
			$vars = '[鲜鮮]';
		} elsif ($ch eq '鲞') {
			$vars = '[鲞鯗]';
		} elsif ($ch eq '鲟') {
			$vars = '[鲟鱘]';
		} elsif ($ch eq '鲠') {
			$vars = '[鲠鯁]';
		} elsif ($ch eq '鲡') {
			$vars = '[鲡鱺]';
		} elsif ($ch eq '鲢') {
			$vars = '[鲢鰱]';
		} elsif ($ch eq '鲣') {
			$vars = '[鲣鰹]';
		} elsif ($ch eq '鲤') {
			$vars = '[鲤鯉]';
		} elsif ($ch eq '鲥') {
			$vars = '[鲥鰣]';
		} elsif ($ch eq '鲦') {
			$vars = '[鲦鰷]';
		} elsif ($ch eq '鲧') {
			$vars = '[鲧鯀]';
		} elsif ($ch eq '鲨') {
			$vars = '[鲨鯊]';
		} elsif ($ch eq '鲩') {
			$vars = '[鲩鯇]';
		} elsif ($ch eq '鲫') {
			$vars = '[鲫鯽]';
		} elsif ($ch eq '鲭') {
			$vars = '[鲭鯖]';
		} elsif ($ch eq '鲮') {
			$vars = '[鲮鯪]';
		} elsif ($ch eq '鲰') {
			$vars = '[鲰鯫]';
		} elsif ($ch eq '鲱') {
			$vars = '[鲱鯡]';
		} elsif ($ch eq '鲲') {
			$vars = '[鲲鯤]';
		} elsif ($ch eq '鲳') {
			$vars = '[鲳鯧]';
		} elsif ($ch eq '鲵') {
			$vars = '[鲵鯢]';
		} elsif ($ch eq '鲶') {
			$vars = '[鲶鯰]';
		} elsif ($ch eq '鲷') {
			$vars = '[鲷鯛]';
		} elsif ($ch eq '鲸') {
			$vars = '[鲸鯨]';
		} elsif ($ch eq '鲻') {
			$vars = '[鲻鯔]';
		} elsif ($ch eq '鲽') {
			$vars = '[鲽鰈]';
		} elsif ($ch eq '鳃') {
			$vars = '[鳃鰓]';
		} elsif ($ch eq '鳄') {
			$vars = '[鳄鰐鱷]';
		} elsif ($ch eq '鳅') {
			$vars = '[鳅鰍]';
		} elsif ($ch eq '鳆') {
			$vars = '[鳆鰒]';
		} elsif ($ch eq '鳇') {
			$vars = '[鳇鰉]';
		} elsif ($ch eq '鳌') {
			$vars = '[鳌鰲]';
		} elsif ($ch eq '鳍') {
			$vars = '[鳍鰭]';
		} elsif ($ch eq '鳎') {
			$vars = '[鳎鰨]';
		} elsif ($ch eq '鳏') {
			$vars = '[鳏鰥]';
		} elsif ($ch eq '鳐') {
			$vars = '[鳐鰩]';
		} elsif ($ch eq '鳓') {
			$vars = '[鳓鰳]';
		} elsif ($ch eq '鳔') {
			$vars = '[鳔鰾]';
		} elsif ($ch eq '鳕') {
			$vars = '[鳕鱈]';
		} elsif ($ch eq '鳖') {
			$vars = '[鳖鱉]';
		} elsif ($ch eq '鳗') {
			$vars = '[鳗鰻]';
		} elsif ($ch eq '鳜') {
			$vars = '[鳜鱖]';
		} elsif ($ch eq '鳝') {
			$vars = '[鳝鱔]';
		} elsif ($ch eq '鳞') {
			$vars = '[鳞鱗]';
		} elsif ($ch eq '鳟') {
			$vars = '[鳟鱒]';
		} elsif ($ch eq '鳢') {
			$vars = '[鳢鱧]';
		} elsif ($ch eq '鳥') {
			$vars = '[鳥鸟]';
		} elsif ($ch eq '鳧') {
			$vars = '[鳧凫]';
		} elsif ($ch eq '鳩') {
			$vars = '[鳩鸠]';
		} elsif ($ch eq '鳫') {
			$vars = '[鳫雁]';
		} elsif ($ch eq '鳬') {
			$vars = '[鳬凫]';
		} elsif ($ch eq '鳳') {
			$vars = '[鳳凤]';
		} elsif ($ch eq '鳴') {
			$vars = '[鳴鸣]';
		} elsif ($ch eq '鳶') {
			$vars = '[鳶鸢]';
		} elsif ($ch eq '鴃') {
			$vars = '[鴃鵙]';
		} elsif ($ch eq '鴄') {
			$vars = '[鴄裒]';
		} elsif ($ch eq '鴆') {
			$vars = '[鴆酖鸩]';
		} elsif ($ch eq '鴇') {
			$vars = '[鴇鸨]';
		} elsif ($ch eq '鴈') {
			$vars = '[鴈雁]';
		} elsif ($ch eq '鴉') {
			$vars = '[鴉鸦]';
		} elsif ($ch eq '鴎') {
			$vars = '[鴎鷗]';
		} elsif ($ch eq '鴕') {
			$vars = '[鴕鸵]';
		} elsif ($ch eq '鴛') {
			$vars = '[鴛鸳]';
		} elsif ($ch eq '鴝') {
			$vars = '[鴝朐鸲]';
		} elsif ($ch eq '鴞') {
			$vars = '[鴞梟]';
		} elsif ($ch eq '鴟') {
			$vars = '[鴟鸱]';
		} elsif ($ch eq '鴣') {
			$vars = '[鴣鸪]';
		} elsif ($ch eq '鴦') {
			$vars = '[鴦鸯]';
		} elsif ($ch eq '鴨') {
			$vars = '[鴨鸭]';
		} elsif ($ch eq '鴬') {
			$vars = '[鴬鶯]';
		} elsif ($ch eq '鴯') {
			$vars = '[鴯鸸]';
		} elsif ($ch eq '鴰') {
			$vars = '[鴰鸹]';
		} elsif ($ch eq '鴳') {
			$vars = '[鴳鷃]';
		} elsif ($ch eq '鴻') {
			$vars = '[鴻鸿]';
		} elsif ($ch eq '鴿') {
			$vars = '[鴿鸽]';
		} elsif ($ch eq '鵂') {
			$vars = '[鵂鸺]';
		} elsif ($ch eq '鵑') {
			$vars = '[鵑鹃]';
		} elsif ($ch eq '鵒') {
			$vars = '[鵒鹆]';
		} elsif ($ch eq '鵓') {
			$vars = '[鵓鹁]';
		} elsif ($ch eq '鵙') {
			$vars = '[鵙鴃]';
		} elsif ($ch eq '鵜') {
			$vars = '[鵜鹈]';
		} elsif ($ch eq '鵝') {
			$vars = '[鵝鵞鹅]';
		} elsif ($ch eq '鵞') {
			$vars = '[鵞鵝]';
		} elsif ($ch eq '鵠') {
			$vars = '[鵠鹄]';
		} elsif ($ch eq '鵡') {
			$vars = '[鵡鹉]';
		} elsif ($ch eq '鵪') {
			$vars = '[鵪鹌]';
		} elsif ($ch eq '鵬') {
			$vars = '[鵬鹏]';
		} elsif ($ch eq '鵯') {
			$vars = '[鵯鹎]';
		} elsif ($ch eq '鵰') {
			$vars = '[鵰彫雕]';
		} elsif ($ch eq '鵲') {
			$vars = '[鵲鹊]';
		} elsif ($ch eq '鵻') {
			$vars = '[鵻隼]';
		} elsif ($ch eq '鶇') {
			$vars = '[鶇鸫]';
		} elsif ($ch eq '鶉') {
			$vars = '[鶉鹑]';
		} elsif ($ch eq '鶏') {
			$vars = '[鶏雞]';
		} elsif ($ch eq '鶘') {
			$vars = '[鶘鹕]';
		} elsif ($ch eq '鶚') {
			$vars = '[鶚鹗]';
		} elsif ($ch eq '鶩') {
			$vars = '[鶩鹜]';
		} elsif ($ch eq '鶯') {
			$vars = '[鶯莺]';
		} elsif ($ch eq '鶴') {
			$vars = '[鶴鹤]';
		} elsif ($ch eq '鶵') {
			$vars = '[鶵雛]';
		} elsif ($ch eq '鶻') {
			$vars = '[鶻鹘]';
		} elsif ($ch eq '鶼') {
			$vars = '[鶼鹣]';
		} elsif ($ch eq '鶿') {
			$vars = '[鶿鹚]';
		} elsif ($ch eq '鷂') {
			$vars = '[鷂鹞]';
		} elsif ($ch eq '鷃') {
			$vars = '[鷃鴳]';
		} elsif ($ch eq '鷄') {
			$vars = '[鷄鸡雞]';
		} elsif ($ch eq '鷏') {
			$vars = '[鷏鷆]';
		} elsif ($ch eq '鷓') {
			$vars = '[鷓鹧]';
		} elsif ($ch eq '鷗') {
			$vars = '[鷗鸥]';
		} elsif ($ch eq '鷙') {
			$vars = '[鷙鸷]';
		} elsif ($ch eq '鷚') {
			$vars = '[鷚鹨]';
		} elsif ($ch eq '鷥') {
			$vars = '[鷥鸶]';
		} elsif ($ch eq '鷦') {
			$vars = '[鷦鹪]';
		} elsif ($ch eq '鷩') {
			$vars = '[鷩氅]';
		} elsif ($ch eq '鷯') {
			$vars = '[鷯鹩]';
		} elsif ($ch eq '鷰') {
			$vars = '[鷰燕]';
		} elsif ($ch eq '鷲') {
			$vars = '[鷲鹫]';
		} elsif ($ch eq '鷳') {
			$vars = '[鷳鹇]';
		} elsif ($ch eq '鷸') {
			$vars = '[鷸鹬]';
		} elsif ($ch eq '鷹') {
			$vars = '[鷹鹰]';
		} elsif ($ch eq '鷺') {
			$vars = '[鷺鹭鷺]';
		} elsif ($ch eq '鸕') {
			$vars = '[鸕鸬]';
		} elsif ($ch eq '鸚') {
			$vars = '[鸚鹦]';
		} elsif ($ch eq '鸛') {
			$vars = '[鸛鹳]';
		} elsif ($ch eq '鸝') {
			$vars = '[鸝鹂]';
		} elsif ($ch eq '鸞') {
			$vars = '[鸞鸾]';
		} elsif ($ch eq '鸟') {
			$vars = '[鸟鳥]';
		} elsif ($ch eq '鸠') {
			$vars = '[鸠鳩]';
		} elsif ($ch eq '鸡') {
			$vars = '[鸡雞鷄]';
		} elsif ($ch eq '鸢') {
			$vars = '[鸢鳶]';
		} elsif ($ch eq '鸣') {
			$vars = '[鸣鳴]';
		} elsif ($ch eq '鸥') {
			$vars = '[鸥鷗]';
		} elsif ($ch eq '鸦') {
			$vars = '[鸦鴉]';
		} elsif ($ch eq '鸨') {
			$vars = '[鸨鴇]';
		} elsif ($ch eq '鸩') {
			$vars = '[鸩鴆]';
		} elsif ($ch eq '鸪') {
			$vars = '[鸪鴣]';
		} elsif ($ch eq '鸫') {
			$vars = '[鸫鶇]';
		} elsif ($ch eq '鸬') {
			$vars = '[鸬鸕]';
		} elsif ($ch eq '鸭') {
			$vars = '[鸭鴨]';
		} elsif ($ch eq '鸯') {
			$vars = '[鸯鴦]';
		} elsif ($ch eq '鸱') {
			$vars = '[鸱鴟]';
		} elsif ($ch eq '鸲') {
			$vars = '[鸲鴝]';
		} elsif ($ch eq '鸳') {
			$vars = '[鸳鴛]';
		} elsif ($ch eq '鸵') {
			$vars = '[鸵鴕]';
		} elsif ($ch eq '鸶') {
			$vars = '[鸶鷥]';
		} elsif ($ch eq '鸷') {
			$vars = '[鸷鷙]';
		} elsif ($ch eq '鸸') {
			$vars = '[鸸鴯]';
		} elsif ($ch eq '鸹') {
			$vars = '[鸹鴰]';
		} elsif ($ch eq '鸺') {
			$vars = '[鸺鵂]';
		} elsif ($ch eq '鸽') {
			$vars = '[鸽鴿]';
		} elsif ($ch eq '鸾') {
			$vars = '[鸾鸞]';
		} elsif ($ch eq '鸿') {
			$vars = '[鸿鴻]';
		} elsif ($ch eq '鹁') {
			$vars = '[鹁鵓]';
		} elsif ($ch eq '鹂') {
			$vars = '[鹂鸝]';
		} elsif ($ch eq '鹃') {
			$vars = '[鹃鵑]';
		} elsif ($ch eq '鹄') {
			$vars = '[鹄鵠]';
		} elsif ($ch eq '鹅') {
			$vars = '[鹅鵝]';
		} elsif ($ch eq '鹆') {
			$vars = '[鹆鵒]';
		} elsif ($ch eq '鹇') {
			$vars = '[鹇鷳]';
		} elsif ($ch eq '鹈') {
			$vars = '[鹈鵜]';
		} elsif ($ch eq '鹉') {
			$vars = '[鹉鵡]';
		} elsif ($ch eq '鹊') {
			$vars = '[鹊鵲]';
		} elsif ($ch eq '鹌') {
			$vars = '[鹌鵪]';
		} elsif ($ch eq '鹎') {
			$vars = '[鹎鵯]';
		} elsif ($ch eq '鹏') {
			$vars = '[鹏鵬]';
		} elsif ($ch eq '鹑') {
			$vars = '[鹑鶉]';
		} elsif ($ch eq '鹕') {
			$vars = '[鹕鶘]';
		} elsif ($ch eq '鹗') {
			$vars = '[鹗鶚]';
		} elsif ($ch eq '鹘') {
			$vars = '[鹘鶻]';
		} elsif ($ch eq '鹚') {
			$vars = '[鹚鶿]';
		} elsif ($ch eq '鹜') {
			$vars = '[鹜鶩]';
		} elsif ($ch eq '鹞') {
			$vars = '[鹞鷂]';
		} elsif ($ch eq '鹣') {
			$vars = '[鹣鶼]';
		} elsif ($ch eq '鹤') {
			$vars = '[鹤鶴]';
		} elsif ($ch eq '鹦') {
			$vars = '[鹦鸚]';
		} elsif ($ch eq '鹧') {
			$vars = '[鹧鷓]';
		} elsif ($ch eq '鹨') {
			$vars = '[鹨鷚]';
		} elsif ($ch eq '鹩') {
			$vars = '[鹩鷯]';
		} elsif ($ch eq '鹪') {
			$vars = '[鹪鷦]';
		} elsif ($ch eq '鹫') {
			$vars = '[鹫鷲]';
		} elsif ($ch eq '鹬') {
			$vars = '[鹬鷸]';
		} elsif ($ch eq '鹭') {
			$vars = '[鹭鷺]';
		} elsif ($ch eq '鹰') {
			$vars = '[鹰鷹]';
		} elsif ($ch eq '鹳') {
			$vars = '[鹳鸛]';
		} elsif ($ch eq '鹵') {
			$vars = '[鹵卤]';
		} elsif ($ch eq '鹸') {
			$vars = '[鹸鹼]';
		} elsif ($ch eq '鹹') {
			$vars = '[鹹咸]';
		} elsif ($ch eq '鹺') {
			$vars = '[鹺鹾]';
		} elsif ($ch eq '鹼') {
			$vars = '[鹼硷堿碱]';
		} elsif ($ch eq '鹽') {
			$vars = '[鹽盐塩]';
		} elsif ($ch eq '鹾') {
			$vars = '[鹾鹺]';
		} elsif ($ch eq '鹿') {
			$vars = '[鹿鹿]';
		} elsif ($ch eq '麁') {
			$vars = '[麁粗]';
		} elsif ($ch eq '麇') {
			$vars = '[麇麕]';
		} elsif ($ch eq '麓') {
			$vars = '[麓梺]';
		} elsif ($ch eq '麕') {
			$vars = '[麕麇]';
		} elsif ($ch eq '麗') {
			$vars = '[麗丽]';
		} elsif ($ch eq '麟') {
			$vars = '[麟麟]';
		} elsif ($ch eq '麤') {
			$vars = '[麤觕粗]';
		} elsif ($ch eq '麥') {
			$vars = '[麥麦]';
		} elsif ($ch eq '麦') {
			$vars = '[麦麥]';
		} elsif ($ch eq '麩') {
			$vars = '[麩麸]';
		} elsif ($ch eq '麪') {
			$vars = '[麪麵]';
		} elsif ($ch eq '麰') {
			$vars = '[麰牟]';
		} elsif ($ch eq '麴') {
			$vars = '[麴麹]';
		} elsif ($ch eq '麵') {
			$vars = '[麵麺面麪]';
		} elsif ($ch eq '麸') {
			$vars = '[麸麩]';
		} elsif ($ch eq '麺') {
			$vars = '[麺麵]';
		} elsif ($ch eq '麻') {
			$vars = '[麻菻]';
		} elsif ($ch eq '麼') {
			$vars = '[麼么麽]';
		} elsif ($ch eq '麽') {
			$vars = '[麽麼么]';
		} elsif ($ch eq '黃') {
			$vars = '[黃黄]';
		} elsif ($ch eq '黄') {
			$vars = '[黄黃]';
		} elsif ($ch eq '黉') {
			$vars = '[黉黌]';
		} elsif ($ch eq '黌') {
			$vars = '[黌黉]';
		} elsif ($ch eq '黎') {
			$vars = '[黎黎]';
		} elsif ($ch eq '黏') {
			$vars = '[黏粘]';
		} elsif ($ch eq '黑') {
			$vars = '[黑黒]';
		} elsif ($ch eq '黒') {
			$vars = '[黒黑]';
		} elsif ($ch eq '默') {
			$vars = '[默黙嘿]';
		} elsif ($ch eq '黙') {
			$vars = '[黙默]';
		} elsif ($ch eq '點') {
			$vars = '[點点]';
		} elsif ($ch eq '黨') {
			$vars = '[黨党]';
		} elsif ($ch eq '黩') {
			$vars = '[黩黷]';
		} elsif ($ch eq '黪') {
			$vars = '[黪黲]';
		} elsif ($ch eq '黲') {
			$vars = '[黲黪]';
		} elsif ($ch eq '黷') {
			$vars = '[黷黩]';
		} elsif ($ch eq '黽') {
			$vars = '[黽黾]';
		} elsif ($ch eq '黾') {
			$vars = '[黾黽]';
		} elsif ($ch eq '黿') {
			$vars = '[黿鼋]';
		} elsif ($ch eq '鼇') {
			$vars = '[鼇鰲]';
		} elsif ($ch eq '鼈') {
			$vars = '[鼈鱉]';
		} elsif ($ch eq '鼉') {
			$vars = '[鼉鼍]';
		} elsif ($ch eq '鼋') {
			$vars = '[鼋黿]';
		} elsif ($ch eq '鼍') {
			$vars = '[鼍鼉]';
		} elsif ($ch eq '鼏') {
			$vars = '[鼏幂冪]';
		} elsif ($ch eq '鼓') {
			$vars = '[鼓皷]';
		} elsif ($ch eq '鼕') {
			$vars = '[鼕冬]';
		} elsif ($ch eq '鼗') {
			$vars = '[鼗鞀]';
		} elsif ($ch eq '鼠') {
			$vars = '[鼠鼡]';
		} elsif ($ch eq '鼡') {
			$vars = '[鼡鼠]';
		} elsif ($ch eq '鼴') {
			$vars = '[鼴鼹]';
		} elsif ($ch eq '鼹') {
			$vars = '[鼹鼴]';
		} elsif ($ch eq '齊') {
			$vars = '[齊齐斉齋斋]';
		} elsif ($ch eq '齋') {
			$vars = '[齋斋齊斎]';
		} elsif ($ch eq '齎') {
			$vars = '[齎赍]';
		} elsif ($ch eq '齏') {
			$vars = '[齏齑韲]';
		} elsif ($ch eq '齐') {
			$vars = '[齐齊]';
		} elsif ($ch eq '齑') {
			$vars = '[齑齏]';
		} elsif ($ch eq '齒') {
			$vars = '[齒齿歯]';
		} elsif ($ch eq '齔') {
			$vars = '[齔龀]';
		} elsif ($ch eq '齙') {
			$vars = '[齙龅]';
		} elsif ($ch eq '齜') {
			$vars = '[齜龇]';
		} elsif ($ch eq '齟') {
			$vars = '[齟龃]';
		} elsif ($ch eq '齠') {
			$vars = '[齠龆]';
		} elsif ($ch eq '齡') {
			$vars = '[齡齢龄]';
		} elsif ($ch eq '齢') {
			$vars = '[齢齡]';
		} elsif ($ch eq '齦') {
			$vars = '[齦啃龈]';
		} elsif ($ch eq '齧') {
			$vars = '[齧嚙囓]';
		} elsif ($ch eq '齪') {
			$vars = '[齪龊]';
		} elsif ($ch eq '齬') {
			$vars = '[齬龉]';
		} elsif ($ch eq '齲') {
			$vars = '[齲龋]';
		} elsif ($ch eq '齶') {
			$vars = '[齶腭]';
		} elsif ($ch eq '齷') {
			$vars = '[齷龌]';
		} elsif ($ch eq '齿') {
			$vars = '[齿齒]';
		} elsif ($ch eq '龀') {
			$vars = '[龀齔]';
		} elsif ($ch eq '龃') {
			$vars = '[龃齟]';
		} elsif ($ch eq '龄') {
			$vars = '[龄齡]';
		} elsif ($ch eq '龅') {
			$vars = '[龅齙]';
		} elsif ($ch eq '龆') {
			$vars = '[龆齠]';
		} elsif ($ch eq '龇') {
			$vars = '[龇齜]';
		} elsif ($ch eq '龈') {
			$vars = '[龈齦]';
		} elsif ($ch eq '龉') {
			$vars = '[龉齬]';
		} elsif ($ch eq '龊') {
			$vars = '[龊齪]';
		} elsif ($ch eq '龋') {
			$vars = '[龋齲]';
		} elsif ($ch eq '龌') {
			$vars = '[龌齷]';
		} elsif ($ch eq '龍') {
			$vars = '[龍龒竜龙]';
		} elsif ($ch eq '龐') {
			$vars = '[龐庞]';
		} elsif ($ch eq '龒') {
			$vars = '[龒龍]';
		} elsif ($ch eq '龔') {
			$vars = '[龔龚]';
		} elsif ($ch eq '龕') {
			$vars = '[龕龛]';
		} elsif ($ch eq '龙') {
			$vars = '[龙龍]';
		} elsif ($ch eq '龚') {
			$vars = '[龚龔]';
		} elsif ($ch eq '龛') {
			$vars = '[龛龕]';
		} elsif ($ch eq '龜') {
			$vars = '[龜龟]';
		} elsif ($ch eq '龝') {
			$vars = '[龝秋]';
		} elsif ($ch eq '龟') {
			$vars = '[龟龜]';
		} elsif ($ch eq '龠') {
			$vars = '[龠籥]';
		} elsif ($ch eq '龢') {
			$vars = '[龢和]';
		} elsif ($ch eq '龤') {
			$vars = '[龤諧]';
		} elsif ($ch eq '豈') {
			$vars = '[豈豈]';
		} elsif ($ch eq '更') {
			$vars = '[更更]';
		} elsif ($ch eq '車') {
			$vars = '[車車]';
		} elsif ($ch eq '賈') {
			$vars = '[賈賈]';
		} elsif ($ch eq '滑') {
			$vars = '[滑滑]';
		} elsif ($ch eq '串') {
			$vars = '[串串]';
		} elsif ($ch eq '句') {
			$vars = '[句句]';
		} elsif ($ch eq '龜') {
			$vars = '[龜龜]';
		} elsif ($ch eq '龜') {
			$vars = '[龜龜]';
		} elsif ($ch eq '契') {
			$vars = '[契契]';
		} elsif ($ch eq '金') {
			$vars = '[金金]';
		} elsif ($ch eq '喇') {
			$vars = '[喇喇]';
		} elsif ($ch eq '奈') {
			$vars = '[奈奈]';
		} elsif ($ch eq '懶') {
			$vars = '[懶懶]';
		} elsif ($ch eq '癩') {
			$vars = '[癩癩]';
		} elsif ($ch eq '羅') {
			$vars = '[羅羅]';
		} elsif ($ch eq '蘿') {
			$vars = '[蘿蘿]';
		} elsif ($ch eq '螺') {
			$vars = '[螺螺]';
		} elsif ($ch eq '裸') {
			$vars = '[裸裸]';
		} elsif ($ch eq '邏') {
			$vars = '[邏邏]';
		} elsif ($ch eq '樂') {
			$vars = '[樂樂]';
		} elsif ($ch eq '洛') {
			$vars = '[洛洛]';
		} elsif ($ch eq '烙') {
			$vars = '[烙烙]';
		} elsif ($ch eq '珞') {
			$vars = '[珞珞]';
		} elsif ($ch eq '落') {
			$vars = '[落落]';
		} elsif ($ch eq '酪') {
			$vars = '[酪酪]';
		} elsif ($ch eq '駱') {
			$vars = '[駱駱]';
		} elsif ($ch eq '亂') {
			$vars = '[亂亂]';
		} elsif ($ch eq '卵') {
			$vars = '[卵卵]';
		} elsif ($ch eq '欄') {
			$vars = '[欄欄]';
		} elsif ($ch eq '爛') {
			$vars = '[爛爛]';
		} elsif ($ch eq '蘭') {
			$vars = '[蘭蘭]';
		} elsif ($ch eq '鸞') {
			$vars = '[鸞鸞]';
		} elsif ($ch eq '嵐') {
			$vars = '[嵐嵐]';
		} elsif ($ch eq '濫') {
			$vars = '[濫濫]';
		} elsif ($ch eq '藍') {
			$vars = '[藍藍]';
		} elsif ($ch eq '襤') {
			$vars = '[襤襤]';
		} elsif ($ch eq '拉') {
			$vars = '[拉拉]';
		} elsif ($ch eq '臘') {
			$vars = '[臘臘]';
		} elsif ($ch eq '蠟') {
			$vars = '[蠟蠟]';
		} elsif ($ch eq '廊') {
			$vars = '[廊廊]';
		} elsif ($ch eq '朗') {
			$vars = '[朗朗]';
		} elsif ($ch eq '浪') {
			$vars = '[浪浪]';
		} elsif ($ch eq '狼') {
			$vars = '[狼狼]';
		} elsif ($ch eq '郎') {
			$vars = '[郎郎]';
		} elsif ($ch eq '來') {
			$vars = '[來來]';
		} elsif ($ch eq '冷') {
			$vars = '[冷冷]';
		} elsif ($ch eq '勞') {
			$vars = '[勞勞]';
		} elsif ($ch eq '擄') {
			$vars = '[擄擄]';
		} elsif ($ch eq '櫓') {
			$vars = '[櫓櫓]';
		} elsif ($ch eq '爐') {
			$vars = '[爐爐]';
		} elsif ($ch eq '盧') {
			$vars = '[盧盧]';
		} elsif ($ch eq '老') {
			$vars = '[老老]';
		} elsif ($ch eq '蘆') {
			$vars = '[蘆蘆]';
		} elsif ($ch eq '虜') {
			$vars = '[虜虜]';
		} elsif ($ch eq '路') {
			$vars = '[路路]';
		} elsif ($ch eq '露') {
			$vars = '[露露]';
		} elsif ($ch eq '魯') {
			$vars = '[魯魯]';
		} elsif ($ch eq '鷺') {
			$vars = '[鷺鷺]';
		} elsif ($ch eq '碌') {
			$vars = '[碌碌]';
		} elsif ($ch eq '祿') {
			$vars = '[祿祿]';
		} elsif ($ch eq '綠') {
			$vars = '[綠綠]';
		} elsif ($ch eq '菉') {
			$vars = '[菉菉]';
		} elsif ($ch eq '錄') {
			$vars = '[錄錄]';
		} elsif ($ch eq '鹿') {
			$vars = '[鹿鹿]';
		} elsif ($ch eq '論') {
			$vars = '[論論]';
		} elsif ($ch eq '壟') {
			$vars = '[壟壟]';
		} elsif ($ch eq '弄') {
			$vars = '[弄弄]';
		} elsif ($ch eq '籠') {
			$vars = '[籠籠]';
		} elsif ($ch eq '聾') {
			$vars = '[聾聾]';
		} elsif ($ch eq '牢') {
			$vars = '[牢牢]';
		} elsif ($ch eq '磊') {
			$vars = '[磊磊]';
		} elsif ($ch eq '賂') {
			$vars = '[賂賂]';
		} elsif ($ch eq '雷') {
			$vars = '[雷雷]';
		} elsif ($ch eq '壘') {
			$vars = '[壘壘]';
		} elsif ($ch eq '屢') {
			$vars = '[屢屢]';
		} elsif ($ch eq '樓') {
			$vars = '[樓樓]';
		} elsif ($ch eq '淚') {
			$vars = '[淚淚]';
		} elsif ($ch eq '漏') {
			$vars = '[漏漏]';
		} elsif ($ch eq '累') {
			$vars = '[累累]';
		} elsif ($ch eq '縷') {
			$vars = '[縷縷]';
		} elsif ($ch eq '陋') {
			$vars = '[陋陋]';
		} elsif ($ch eq '勒') {
			$vars = '[勒勒]';
		} elsif ($ch eq '肋') {
			$vars = '[肋肋]';
		} elsif ($ch eq '凜') {
			$vars = '[凜凜]';
		} elsif ($ch eq '凌') {
			$vars = '[凌凌]';
		} elsif ($ch eq '稜') {
			$vars = '[稜稜]';
		} elsif ($ch eq '綾') {
			$vars = '[綾綾]';
		} elsif ($ch eq '菱') {
			$vars = '[菱菱]';
		} elsif ($ch eq '陵') {
			$vars = '[陵陵]';
		} elsif ($ch eq '讀') {
			$vars = '[讀讀]';
		} elsif ($ch eq '拏') {
			$vars = '[拏拏]';
		} elsif ($ch eq '樂') {
			$vars = '[樂樂]';
		} elsif ($ch eq '諾') {
			$vars = '[諾諾]';
		} elsif ($ch eq '丹') {
			$vars = '[丹丹]';
		} elsif ($ch eq '寧') {
			$vars = '[寧寧]';
		} elsif ($ch eq '怒') {
			$vars = '[怒怒]';
		} elsif ($ch eq '率') {
			$vars = '[率率]';
		} elsif ($ch eq '異') {
			$vars = '[異異]';
		} elsif ($ch eq '北') {
			$vars = '[北北]';
		} elsif ($ch eq '磻') {
			$vars = '[磻磻]';
		} elsif ($ch eq '便') {
			$vars = '[便便]';
		} elsif ($ch eq '復') {
			$vars = '[復復]';
		} elsif ($ch eq '不') {
			$vars = '[不不]';
		} elsif ($ch eq '泌') {
			$vars = '[泌泌]';
		} elsif ($ch eq '數') {
			$vars = '[數數]';
		} elsif ($ch eq '索') {
			$vars = '[索索]';
		} elsif ($ch eq '參') {
			$vars = '[參參]';
		} elsif ($ch eq '塞') {
			$vars = '[塞塞]';
		} elsif ($ch eq '省') {
			$vars = '[省省]';
		} elsif ($ch eq '葉') {
			$vars = '[葉葉]';
		} elsif ($ch eq '說') {
			$vars = '[說說]';
		} elsif ($ch eq '殺') {
			$vars = '[殺殺]';
		} elsif ($ch eq '辰') {
			$vars = '[辰辰]';
		} elsif ($ch eq '沈') {
			$vars = '[沈瀋沈]';
		} elsif ($ch eq '拾') {
			$vars = '[拾拾十]';
		} elsif ($ch eq '若') {
			$vars = '[若若]';
		} elsif ($ch eq '掠') {
			$vars = '[掠掠]';
		} elsif ($ch eq '略') {
			$vars = '[略略]';
		} elsif ($ch eq '亮') {
			$vars = '[亮亮]';
		} elsif ($ch eq '兩') {
			$vars = '[兩兩]';
		} elsif ($ch eq '凉') {
			$vars = '[凉涼凉]';
		} elsif ($ch eq '梁') {
			$vars = '[梁梁]';
		} elsif ($ch eq '糧') {
			$vars = '[糧糧]';
		} elsif ($ch eq '良') {
			$vars = '[良良]';
		} elsif ($ch eq '諒') {
			$vars = '[諒諒]';
		} elsif ($ch eq '量') {
			$vars = '[量量]';
		} elsif ($ch eq '勵') {
			$vars = '[勵勵]';
		} elsif ($ch eq '呂') {
			$vars = '[呂呂]';
		} elsif ($ch eq '女') {
			$vars = '[女女]';
		} elsif ($ch eq '廬') {
			$vars = '[廬廬]';
		} elsif ($ch eq '旅') {
			$vars = '[旅旅]';
		} elsif ($ch eq '濾') {
			$vars = '[濾濾]';
		} elsif ($ch eq '礪') {
			$vars = '[礪礪]';
		} elsif ($ch eq '閭') {
			$vars = '[閭閭]';
		} elsif ($ch eq '驪') {
			$vars = '[驪驪]';
		} elsif ($ch eq '麗') {
			$vars = '[麗麗]';
		} elsif ($ch eq '黎') {
			$vars = '[黎黎]';
		} elsif ($ch eq '力') {
			$vars = '[力力]';
		} elsif ($ch eq '曆') {
			$vars = '[曆曆]';
		} elsif ($ch eq '歷') {
			$vars = '[歷歷]';
		} elsif ($ch eq '轢') {
			$vars = '[轢轢]';
		} elsif ($ch eq '年') {
			$vars = '[年年]';
		} elsif ($ch eq '憐') {
			$vars = '[憐憐]';
		} elsif ($ch eq '戀') {
			$vars = '[戀戀]';
		} elsif ($ch eq '撚') {
			$vars = '[撚撚]';
		} elsif ($ch eq '漣') {
			$vars = '[漣漣]';
		} elsif ($ch eq '煉') {
			$vars = '[煉煉]';
		} elsif ($ch eq '璉') {
			$vars = '[璉璉]';
		} elsif ($ch eq '秊') {
			$vars = '[秊秊]';
		} elsif ($ch eq '練') {
			$vars = '[練練]';
		} elsif ($ch eq '聯') {
			$vars = '[聯聯]';
		} elsif ($ch eq '輦') {
			$vars = '[輦輦]';
		} elsif ($ch eq '蓮') {
			$vars = '[蓮蓮]';
		} elsif ($ch eq '連') {
			$vars = '[連連]';
		} elsif ($ch eq '鍊') {
			$vars = '[鍊鍊]';
		} elsif ($ch eq '列') {
			$vars = '[列列]';
		} elsif ($ch eq '劣') {
			$vars = '[劣劣]';
		} elsif ($ch eq '咽') {
			$vars = '[咽咽]';
		} elsif ($ch eq '烈') {
			$vars = '[烈烈]';
		} elsif ($ch eq '裂') {
			$vars = '[裂裂]';
		} elsif ($ch eq '說') {
			$vars = '[說說]';
		} elsif ($ch eq '廉') {
			$vars = '[廉廉]';
		} elsif ($ch eq '念') {
			$vars = '[念念]';
		} elsif ($ch eq '捻') {
			$vars = '[捻捻]';
		} elsif ($ch eq '殮') {
			$vars = '[殮殮]';
		} elsif ($ch eq '簾') {
			$vars = '[簾簾]';
		} elsif ($ch eq '獵') {
			$vars = '[獵獵]';
		} elsif ($ch eq '令') {
			$vars = '[令令]';
		} elsif ($ch eq '囹') {
			$vars = '[囹囹]';
		} elsif ($ch eq '寧') {
			$vars = '[寧寧]';
		} elsif ($ch eq '嶺') {
			$vars = '[嶺嶺]';
		} elsif ($ch eq '怜') {
			$vars = '[怜怜]';
		} elsif ($ch eq '玲') {
			$vars = '[玲玲]';
		} elsif ($ch eq '瑩') {
			$vars = '[瑩瑩]';
		} elsif ($ch eq '羚') {
			$vars = '[羚羚]';
		} elsif ($ch eq '聆') {
			$vars = '[聆聆]';
		} elsif ($ch eq '鈴') {
			$vars = '[鈴鈴]';
		} elsif ($ch eq '零') {
			$vars = '[零零]';
		} elsif ($ch eq '靈') {
			$vars = '[靈靈]';
		} elsif ($ch eq '領') {
			$vars = '[領領]';
		} elsif ($ch eq '例') {
			$vars = '[例例]';
		} elsif ($ch eq '禮') {
			$vars = '[禮禮]';
		} elsif ($ch eq '醴') {
			$vars = '[醴醴]';
		} elsif ($ch eq '隸') {
			$vars = '[隸隸]';
		} elsif ($ch eq '惡') {
			$vars = '[惡惡]';
		} elsif ($ch eq '了') {
			$vars = '[了了]';
		} elsif ($ch eq '僚') {
			$vars = '[僚僚]';
		} elsif ($ch eq '寮') {
			$vars = '[寮寮]';
		} elsif ($ch eq '尿') {
			$vars = '[尿尿]';
		} elsif ($ch eq '料') {
			$vars = '[料料]';
		} elsif ($ch eq '樂') {
			$vars = '[樂樂]';
		} elsif ($ch eq '燎') {
			$vars = '[燎燎]';
		} elsif ($ch eq '療') {
			$vars = '[療療]';
		} elsif ($ch eq '蓼') {
			$vars = '[蓼蓼]';
		} elsif ($ch eq '遼') {
			$vars = '[遼遼]';
		} elsif ($ch eq '龍') {
			$vars = '[龍龍]';
		} elsif ($ch eq '暈') {
			$vars = '[暈暈]';
		} elsif ($ch eq '阮') {
			$vars = '[阮阮]';
		} elsif ($ch eq '劉') {
			$vars = '[劉劉]';
		} elsif ($ch eq '杻') {
			$vars = '[杻杻]';
		} elsif ($ch eq '柳') {
			$vars = '[柳柳]';
		} elsif ($ch eq '流') {
			$vars = '[流流]';
		} elsif ($ch eq '溜') {
			$vars = '[溜溜]';
		} elsif ($ch eq '琉') {
			$vars = '[琉琉]';
		} elsif ($ch eq '留') {
			$vars = '[留留]';
		} elsif ($ch eq '硫') {
			$vars = '[硫硫]';
		} elsif ($ch eq '紐') {
			$vars = '[紐紐]';
		} elsif ($ch eq '類') {
			$vars = '[類類]';
		} elsif ($ch eq '六') {
			$vars = '[六六]';
		} elsif ($ch eq '戮') {
			$vars = '[戮戮]';
		} elsif ($ch eq '陸') {
			$vars = '[陸陸]';
		} elsif ($ch eq '倫') {
			$vars = '[倫倫]';
		} elsif ($ch eq '崙') {
			$vars = '[崙崙]';
		} elsif ($ch eq '淪') {
			$vars = '[淪淪]';
		} elsif ($ch eq '輪') {
			$vars = '[輪輪]';
		} elsif ($ch eq '律') {
			$vars = '[律律]';
		} elsif ($ch eq '慄') {
			$vars = '[慄慄]';
		} elsif ($ch eq '栗') {
			$vars = '[栗栗]';
		} elsif ($ch eq '率') {
			$vars = '[率率]';
		} elsif ($ch eq '隆') {
			$vars = '[隆隆]';
		} elsif ($ch eq '利') {
			$vars = '[利利]';
		} elsif ($ch eq '吏') {
			$vars = '[吏吏]';
		} elsif ($ch eq '履') {
			$vars = '[履履]';
		} elsif ($ch eq '易') {
			$vars = '[易易]';
		} elsif ($ch eq '李') {
			$vars = '[李李]';
		} elsif ($ch eq '梨') {
			$vars = '[梨梨]';
		} elsif ($ch eq '泥') {
			$vars = '[泥泥]';
		} elsif ($ch eq '理') {
			$vars = '[理理]';
		} elsif ($ch eq '痢') {
			$vars = '[痢痢]';
		} elsif ($ch eq '罹') {
			$vars = '[罹罹]';
		} elsif ($ch eq '裏') {
			$vars = '[裏裏]';
		} elsif ($ch eq '裡') {
			$vars = '[裡裡裏]';
		} elsif ($ch eq '里') {
			$vars = '[里里]';
		} elsif ($ch eq '離') {
			$vars = '[離離]';
		} elsif ($ch eq '匿') {
			$vars = '[匿匿]';
		} elsif ($ch eq '溺') {
			$vars = '[溺溺]';
		} elsif ($ch eq '吝') {
			$vars = '[吝吝]';
		} elsif ($ch eq '燐') {
			$vars = '[燐燐]';
		} elsif ($ch eq '璘') {
			$vars = '[璘璘]';
		} elsif ($ch eq '藺') {
			$vars = '[藺藺]';
		} elsif ($ch eq '隣') {
			$vars = '[隣隣鄰]';
		} elsif ($ch eq '鱗') {
			$vars = '[鱗鱗]';
		} elsif ($ch eq '麟') {
			$vars = '[麟麟]';
		} elsif ($ch eq '林') {
			$vars = '[林林]';
		} elsif ($ch eq '淋') {
			$vars = '[淋淋]';
		} elsif ($ch eq '臨') {
			$vars = '[臨臨]';
		} elsif ($ch eq '立') {
			$vars = '[立立]';
		} elsif ($ch eq '笠') {
			$vars = '[笠笠]';
		} elsif ($ch eq '粒') {
			$vars = '[粒粒]';
		} elsif ($ch eq '狀') {
			$vars = '[狀狀]';
		} elsif ($ch eq '炙') {
			$vars = '[炙炙]';
		} elsif ($ch eq '識') {
			$vars = '[識識]';
		} elsif ($ch eq '什') {
			$vars = '[什什]';
		} elsif ($ch eq '茶') {
			$vars = '[茶茶]';
		} elsif ($ch eq '刺') {
			$vars = '[刺刺]';
		} elsif ($ch eq '切') {
			$vars = '[切切]';
		} elsif ($ch eq '度') {
			$vars = '[度度]';
		} elsif ($ch eq '拓') {
			$vars = '[拓拓]';
		} elsif ($ch eq '糖') {
			$vars = '[糖糖]';
		} elsif ($ch eq '宅') {
			$vars = '[宅宅]';
		} elsif ($ch eq '洞') {
			$vars = '[洞洞]';
		} elsif ($ch eq '暴') {
			$vars = '[暴暴]';
		} elsif ($ch eq '輻') {
			$vars = '[輻輻]';
		} elsif ($ch eq '行') {
			$vars = '[行行]';
		} elsif ($ch eq '降') {
			$vars = '[降降]';
		} elsif ($ch eq '見') {
			$vars = '[見見]';
		} elsif ($ch eq '廓') {
			$vars = '[廓廓]';
		} elsif ($ch eq '兀') {
			$vars = '[兀兀]';
		} elsif ($ch eq '嗀') {
			$vars = '[嗀嗀]';
		} 
	} elsif ($dumplang eq 'de') {
		if ($ch eq '?') {
			$vars = '[äöüÄÖÜß]';
		} elsif ($ch eq 'a' && $ch2 eq 'e') {
			$vars = '(ae|ä)'; $len = 1;
		} elsif ($ch eq 'o' && $ch2 eq 'e') {
			$vars = '(oe|ö)'; $len = 1;
		} elsif ($ch eq 's' && $ch2 eq 's') {
			$vars = '(ss|ß)'; $len = 1;
		} elsif ($ch eq 'u' && $ch2 eq 'e') {
			$vars = '(ue|ü)'; $len = 1;
		} elsif ($ch eq 'A' && $ch2 eq 'e') {
			$vars = '(Ae|Ä)'; $len = 1;
		} elsif ($ch eq 'A' && $ch2 eq 'E') {
			$vars = '(AE|Ä)'; $len = 1;
		} elsif ($ch eq 'O' && $ch2 eq 'e') {
			$vars = '(Oe|Ö)'; $len = 1;
		} elsif ($ch eq 'O' && $ch2 eq 'E') {
			$vars = '(OE|Ö)'; $len = 1;
		} elsif ($ch eq 'U' && $ch2 eq 'e') {
			$vars = '(Ue|Ü)'; $len = 1;
		} elsif ($ch eq 'U' && $ch2 eq 'E') {
			$vars = '(UE|Ü)'; $len = 1;
		}
	} elsif ($dumplang eq 'en') {
		if ($ch eq '?') {
			$vars = '[æçéïñôœÆÇÉÏÑÔŒ’]';
		} elsif ($ch eq 'a' && $ch2 eq 'e') {
			$vars = '(ae|æ)'; $len = 1;
		} elsif ($ch eq 'c') {
			$vars = '[cç]';
		} elsif ($ch eq 'e') {
			$vars = '[eé]';
		} elsif ($ch eq 'i') {
			$vars = '[iï]';
		} elsif ($ch eq 'n') {
			$vars = '[nñ]';
		} elsif ($ch eq 'o' && $ch2 eq 'e') {
			$vars = '(oe|œ)'; $len = 1;
		} elsif ($ch eq 'o') {
			$vars = '[oô]';
		} elsif ($ch eq 'A' && $ch2 eq 'e') {
			$vars = '(Ae|Æ)'; $len = 1;
		} elsif ($ch eq 'A' && $ch2 eq 'E') {
			$vars = '(AE|Æ)'; $len = 1;
		} elsif ($ch eq 'C') {
			$vars = '[CÇ]';
		} elsif ($ch eq 'E') {
			$vars = '[EÉ]';
		} elsif ($ch eq 'I') {
			$vars = '[IÏ]';
		} elsif ($ch eq 'N') {
			$vars = '[NÑ]';
		} elsif ($ch eq 'O' && $ch2 eq 'e') {
			$vars = '(Oe|Œ)'; $len = 1;
		} elsif ($ch eq 'O' && $ch2 eq 'E') {
			$vars = '(OE|Œ)'; $len = 1;
		} elsif ($ch eq 'O') {
			$vars = '[OÔ]';
		} elsif ($ch eq '\'') {
			$vars = '[\'’]';
		}
	} elsif ($dumplang eq 'es') {
		if ($ch eq '?') {
			$vars = '[áéíñóúüÁÉÍÑÓÚÜ]';
		} elsif ($ch eq 'a') {
			$vars = '[aá]';
		} elsif ($ch eq 'e') {
			$vars = '[eé]';
		} elsif ($ch eq 'i') {
			$vars = '[ií]';
		} elsif ($ch eq 'n') {
			$vars = '[nñ]';
		} elsif ($ch eq 'o') {
			$vars = '[oó]';
		} elsif ($ch eq 'u') {
			$vars = '[uúü]';
		} elsif ($ch eq 'A') {
			$vars = '[AÁ]';
		} elsif ($ch eq 'E') {
			$vars = '[EÉ]';
		} elsif ($ch eq 'I') {
			$vars = '[IÍ]';
		} elsif ($ch eq 'N') {
			$vars = '[NÑ]';
		} elsif ($ch eq 'O') {
			$vars = '[OÓ]';
		} elsif ($ch eq 'U') {
			$vars = '[UÚÜ]';
		}
	} elsif ($dumplang eq 'hu') {
		if ($ch eq '?') {
			$vars = '[áéíóöőúüűÁÉÍÓÖŐÚÜŰ]';
		} elsif ($ch eq 'a') {
			$vars = '[aá]';
		} elsif ($ch eq 'e') {
			$vars = '[eé]';
		} elsif ($ch eq 'i') {
			$vars = '[ií]';
		} elsif ($ch eq 'o' || $ch eq 'ó') {
			$vars = '[oóöő]';
		} elsif ($ch eq 'u' || $ch eq 'ú') {
			$vars = '[uúüű]';
		} elsif ($ch eq 'A') {
			$vars = '[AÁ]';
		} elsif ($ch eq 'E') {
			$vars = '[EÉ]';
		} elsif ($ch eq 'I') {
			$vars = '[IÍ]';
		} elsif ($ch eq 'O' || $ch eq 'Ó') {
			$vars = '[OÓÖŐ]';
		} elsif ($ch eq 'U' || $ch eq 'Ú') {
			$vars = '[UÚÜŰ]';
		}
	} elsif ($dumplang eq 'ja') {
		if ($ch eq '?') {
			$vars = '[āēīōūĀĒĪŌŪ]';
		} elsif ($ch eq 'a') {
			$vars = '[aā]';
		} elsif ($ch eq 'e') {
			$vars = '[eē]';
		} elsif ($ch eq 'i') {
			if ($ch2 eq 'i') {
				$vars = '(ii|ī)'; $len = 1;
			} else {
				$vars = '[iī]';
			}
		} elsif ($ch eq 'o') {
			$vars = '[oō]';
		} elsif ($ch eq 'u') {
			$vars = '[uū]';
		} elsif ($ch eq 'A') {
			$vars = '[AĀ]';
		} elsif ($ch eq 'E') {
			$vars = '[EĒ]';
		} elsif ($ch eq 'I') {
			if ($ch2 eq 'I') {
				$vars = '(II|Ī)'; $len = 1;
			} else {
				$vars = '[IĪ]';
			}
		} elsif ($ch eq 'O') {
			$vars = '[OŌ]';
		} elsif ($ch eq 'U') {
			$vars = '[UŪ]';
		# Shinjitai / Kyūjitai
		} elsif ($ch eq '圧' || $ch eq '壓') {
			$vars = '[圧壓]';
		} elsif ($ch eq '医' || $ch eq '醫') {
			$vars = '[医醫]';
		} elsif ($ch eq '囲' || $ch eq '圍') {
			$vars = '[囲圍]';
		} elsif ($ch eq '壱' || $ch eq '壹') {
			$vars = '[壱壹]';
		} elsif ($ch eq '隠' || $ch eq '隱') {
			$vars = '[隠隱]';
		} elsif ($ch eq '栄' || $ch eq '榮') {
			$vars = '[栄榮]';
		} elsif ($ch eq '営' || $ch eq '營') {
			$vars = '[営營]';
		} elsif ($ch eq '駅' || $ch eq '驛') {
			$vars = '[駅驛]';
		} elsif ($ch eq '円' || $ch eq '圓') {
			$vars = '[円圓]';
		} elsif ($ch eq '塩' || $ch eq '鹽') {
			$vars = '[塩鹽]';
		} elsif ($ch eq '欧' || $ch eq '歐') {
			$vars = '[欧歐]';
		} elsif ($ch eq '殴' || $ch eq '毆') {
			$vars = '[殴毆]';
		} elsif ($ch eq '穏' || $ch eq '穩') {
			$vars = '[穏穩]';
		} elsif ($ch eq '仮' || $ch eq '假') {
			$vars = '[仮假]';
		} elsif ($ch eq '画' || $ch eq '畫') {
			$vars = '[画畫]';
		} elsif ($ch eq '会' || $ch eq '會') {
			$vars = '[会會]';
		} elsif ($ch eq '絵' || $ch eq '繪') {
			$vars = '[絵繪]';
		} elsif ($ch eq '拡' || $ch eq '擴') {
			$vars = '[拡擴]';
		} elsif ($ch eq '覚' || $ch eq '覺') {
			$vars = '[覚覺]';
		} elsif ($ch eq '岳' || $ch eq '嶽') {
			$vars = '[岳嶽]';
		} elsif ($ch eq '学' || $ch eq '學') {
			$vars = '[学學]';
		} elsif ($ch eq '関' || $ch eq '關') {
			$vars = '[関關]';
		} elsif ($ch eq '歓' || $ch eq '歡') {
			$vars = '[歓歡]';
		} elsif ($ch eq '観' || $ch eq '觀') {
			$vars = '[観觀]';
		} elsif ($ch eq '勧' || $ch eq '勸') {
			$vars = '[勧勸]';
		} elsif ($ch eq '帰' || $ch eq '歸') {
			$vars = '[帰歸]';
		} elsif ($ch eq '犠' || $ch eq '犧') {
			$vars = '[犠犧]';
		} elsif ($ch eq '旧' || $ch eq '舊') {
			$vars = '[旧舊]';
		} elsif ($ch eq '拠' || $ch eq '據') {
			$vars = '[拠據]';
		} elsif ($ch eq '挙' || $ch eq '擧') {
			$vars = '[挙擧]';
		} elsif ($ch eq '区' || $ch eq '區') {
			$vars = '[区區]';
		} elsif ($ch eq '駆' || $ch eq '驅') {
			$vars = '[駆驅]';
		} elsif ($ch eq '径' || $ch eq '徑') {
			$vars = '[径徑]';
		} elsif ($ch eq '茎' || $ch eq '莖') {
			$vars = '[茎莖]';
		} elsif ($ch eq '経' || $ch eq '經') {
			$vars = '[経經]';
		} elsif ($ch eq '継' || $ch eq '繼') {
			$vars = '[継繼]';
		} elsif ($ch eq '軽' || $ch eq '輕') {
			$vars = '[軽輕]';
		} elsif ($ch eq '欠' || $ch eq '缺') {
			$vars = '[欠缺]';
		} elsif ($ch eq '研' || $ch eq '硏') {
			$vars = '[研硏]';
		} elsif ($ch eq '献' || $ch eq '獻') {
			$vars = '[献獻]';
		} elsif ($ch eq '権' || $ch eq '權') {
			$vars = '[権權]';
		} elsif ($ch eq '鉱' || $ch eq '鑛') {
			$vars = '[鉱鑛]';
		} elsif ($ch eq '号' || $ch eq '號') {
			$vars = '[号號]';
		} elsif ($ch eq '済' || $ch eq '濟') {
			$vars = '[済濟]';
		} elsif ($ch eq '斉' || $ch eq '齊') {
			$vars = '[斉齊]';
		} elsif ($ch eq '剤' || $ch eq '劑') {
			$vars = '[剤劑]';
		} elsif ($ch eq '参' || $ch eq '參') {
			$vars = '[参參]';
		} elsif ($ch eq '蚕' || $ch eq '蠶') {
			$vars = '[蚕蠶]';
		} elsif ($ch eq '賛' || $ch eq '贊') {
			$vars = '[賛贊]';
		} elsif ($ch eq '惨' || $ch eq '慘') {
			$vars = '[惨慘]';
		} elsif ($ch eq '残' || $ch eq '殘') {
			$vars = '[残殘]';
		} elsif ($ch eq '糸' || $ch eq '絲') {
			$vars = '[糸絲]';
		} elsif ($ch eq '歯' || $ch eq '齒') {
			$vars = '[歯齒]';
		} elsif ($ch eq '辞' || $ch eq '辭') {
			$vars = '[辞辭]';
		} elsif ($ch eq '実' || $ch eq '實') {
			$vars = '[実實]';
		} elsif ($ch eq '写' || $ch eq '寫') {
			$vars = '[写寫]';
		} elsif ($ch eq '釈' || $ch eq '釋') {
			$vars = '[釈釋]';
		} elsif ($ch eq '粛' || $ch eq '肅') {
			$vars = '[粛肅]';
		} elsif ($ch eq '処' || $ch eq '處') {
			$vars = '[処處]';
		} elsif ($ch eq '称' || $ch eq '稱') {
			$vars = '[称稱]';
		} elsif ($ch eq '証' || $ch eq '證') {
			$vars = '[証證]';
		} elsif ($ch eq '触' || $ch eq '觸') {
			$vars = '[触觸]';
		} elsif ($ch eq '嘱' || $ch eq '囑') {
			$vars = '[嘱囑]';
		} elsif ($ch eq '図' || $ch eq '圖') {
			$vars = '[図圖]';
		} elsif ($ch eq '随' || $ch eq '隨') {
			$vars = '[随隨]';
		} elsif ($ch eq '髄' || $ch eq '髓') {
			$vars = '[髄髓]';
		} elsif ($ch eq '枢' || $ch eq '樞') {
			$vars = '[枢樞]';
		} elsif ($ch eq '数' || $ch eq '數') {
			$vars = '[数數]';
		} elsif ($ch eq '声' || $ch eq '聲') {
			$vars = '[声聲]';
		} elsif ($ch eq '窃' || $ch eq '竊') {
			$vars = '[窃竊]';
		} elsif ($ch eq '浅' || $ch eq '淺') {
			$vars = '[浅淺]';
		} elsif ($ch eq '践' || $ch eq '踐') {
			$vars = '[践踐]';
		} elsif ($ch eq '潜' || $ch eq '潛') {
			$vars = '[潜潛]';
		} elsif ($ch eq '銭' || $ch eq '錢') {
			$vars = '[銭錢]';
		} elsif ($ch eq '双' || $ch eq '雙') {
			$vars = '[双雙]';
		} elsif ($ch eq '総' || $ch eq '總') {
			$vars = '[総總]';
		} elsif ($ch eq '属' || $ch eq '屬') {
			$vars = '[属屬]';
		} elsif ($ch eq '続' || $ch eq '續') {
			$vars = '[続續]';
		} elsif ($ch eq '堕' || $ch eq '墮') {
			$vars = '[堕墮]';
		} elsif ($ch eq '体' || $ch eq '體') {
			$vars = '[体體]';
		} elsif ($ch eq '対' || $ch eq '對') {
			$vars = '[対對]';
		} elsif ($ch eq '台' || $ch eq '臺') {
			$vars = '[台臺]';
		} elsif ($ch eq '滝' || $ch eq '瀧') {
			$vars = '[滝瀧]';
		} elsif ($ch eq '沢' || $ch eq '澤') {
			$vars = '[沢澤]';
		} elsif ($ch eq '択' || $ch eq '擇') {
			$vars = '[択擇]';
		} elsif ($ch eq '担' || $ch eq '擔') {
			$vars = '[担擔]';
		} elsif ($ch eq '胆' || $ch eq '膽') {
			$vars = '[胆膽]';
		} elsif ($ch eq '断' || $ch eq '斷') {
			$vars = '[断斷]';
		} elsif ($ch eq '遅' || $ch eq '遲') {
			$vars = '[遅遲]';
		} elsif ($ch eq '虫' || $ch eq '蟲') {
			$vars = '[虫蟲]';
		} elsif ($ch eq '逓' || $ch eq '遞') {
			$vars = '[逓遞]';
		} elsif ($ch eq '鉄' || $ch eq '鐵') {
			$vars = '[鉄鐵]';
		} elsif ($ch eq '点' || $ch eq '點') {
			$vars = '[点點]';
		} elsif ($ch eq '当' || $ch eq '當') {
			$vars = '[当當]';
		} elsif ($ch eq '党' || $ch eq '黨') {
			$vars = '[党黨]';
		} elsif ($ch eq '独' || $ch eq '獨') {
			$vars = '[独獨]';
		} elsif ($ch eq '読' || $ch eq '讀') {
			$vars = '[読讀]';
		} elsif ($ch eq '届' || $ch eq '屆') {
			$vars = '[届屆]';
		} elsif ($ch eq '弐' || $ch eq '貳') {
			$vars = '[弐貳]';
		} elsif ($ch eq '悩' || $ch eq '惱') {
			$vars = '[悩惱]';
		} elsif ($ch eq '脳' || $ch eq '腦') {
			$vars = '[脳腦]';
		} elsif ($ch eq '廃' || $ch eq '廢') {
			$vars = '[廃廢]';
		} elsif ($ch eq '麦' || $ch eq '麥') {
			$vars = '[麦麥]';
		} elsif ($ch eq '発' || $ch eq '發') {
			$vars = '[発發]';
		} elsif ($ch eq '蛮' || $ch eq '蠻') {
			$vars = '[蛮蠻]';
		} elsif ($ch eq '浜' || $ch eq '濱') {
			$vars = '[浜濱]';
		} elsif ($ch eq '並' || $ch eq '竝') {
			$vars = '[並竝]';
		} elsif ($ch eq '併' || $ch eq '倂') {
			$vars = '[併倂]';
		} elsif ($ch eq '辺' || $ch eq '邊') {
			$vars = '[辺邊]';
		} elsif ($ch eq '変' || $ch eq '變') {
			$vars = '[変變]';
		} elsif ($ch eq '弁' || $ch eq '辨' || $ch eq '瓣' || $ch eq '辯') {
			$vars = '[弁辨瓣辯]';
		} elsif ($ch eq '宝' || $ch eq '寶') {
			$vars = '[宝寶]';
		} elsif ($ch eq '豊' || $ch eq '豐') {
			$vars = '[豊豐]';
		} elsif ($ch eq '万' || $ch eq '萬') {
			$vars = '[万萬]';
		} elsif ($ch eq '満' || $ch eq '滿') {
			$vars = '[満滿]';
		} elsif ($ch eq '訳' || $ch eq '譯') {
			$vars = '[訳譯]';
		} elsif ($ch eq '予' || $ch eq '豫') {
			$vars = '[予豫]';
		} elsif ($ch eq '余' || $ch eq '餘') {
			$vars = '[余餘]';
		} elsif ($ch eq '誉' || $ch eq '譽') {
			$vars = '[誉譽]';
		} elsif ($ch eq '乱' || $ch eq '亂') {
			$vars = '[乱亂]';
		} elsif ($ch eq '両' || $ch eq '兩') {
			$vars = '[両兩]';
		} elsif ($ch eq '猟' || $ch eq '獵') {
			$vars = '[猟獵]';
		} elsif ($ch eq '礼' || $ch eq '禮') {
			$vars = '[礼禮]';
		} elsif ($ch eq '励' || $ch eq '勵') {
			$vars = '[励勵]';
		} elsif ($ch eq '霊' || $ch eq '靈') {
			$vars = '[霊靈]';
		} elsif ($ch eq '齢' || $ch eq '齡') {
			$vars = '[齢齡]';
		} elsif ($ch eq '恋' || $ch eq '戀') {
			$vars = '[恋戀]';
		} elsif ($ch eq '炉' || $ch eq '爐') {
			$vars = '[炉爐]';
		} elsif ($ch eq '労' || $ch eq '勞') {
			$vars = '[労勞]';
		} elsif ($ch eq '楼' || $ch eq '樓') {
			$vars = '[楼樓]';
		} elsif ($ch eq '湾' || $ch eq '灣') {
			$vars = '[湾灣]';
		} elsif ($ch eq '亜' || $ch eq '亞') {
			$vars = '[亜亞]';
		} elsif ($ch eq '悪' || $ch eq '惡') {
			$vars = '[悪惡]';
		} elsif ($ch eq '為' || $ch eq '爲') {
			$vars = '[為爲]';
		} elsif ($ch eq '応' || $ch eq '應') {
			$vars = '[応應]';
		} elsif ($ch eq '桜' || $ch eq '櫻') {
			$vars = '[桜櫻]';
		} elsif ($ch eq '価' || $ch eq '價') {
			$vars = '[価價]';
		} elsif ($ch eq '壊' || $ch eq '壞') {
			$vars = '[壊壞]';
		} elsif ($ch eq '懐' || $ch eq '懷') {
			$vars = '[懐懷]';
		} elsif ($ch eq '楽' || $ch eq '樂') {
			$vars = '[楽樂]';
		} elsif ($ch eq '気' || $ch eq '氣') {
			$vars = '[気氣]';
		} elsif ($ch eq '偽' || $ch eq '僞') {
			$vars = '[偽僞]';
		} elsif ($ch eq '戯' || $ch eq '戲') {
			$vars = '[戯戲]';
		} elsif ($ch eq '峡' || $ch eq '峽') {
			$vars = '[峡峽]';
		} elsif ($ch eq '狭' || $ch eq '狹') {
			$vars = '[狭狹]';
		} elsif ($ch eq '暁' || $ch eq '曉') {
			$vars = '[暁曉]';
		} elsif ($ch eq '勲' || $ch eq '勳') {
			$vars = '[勲勳]';
		} elsif ($ch eq '恵' || $ch eq '惠') {
			$vars = '[恵惠]';
		} elsif ($ch eq '鶏' || $ch eq '雞') {
			$vars = '[鶏雞]';
		} elsif ($ch eq '芸' || $ch eq '藝') {
			$vars = '[芸藝]';
		} elsif ($ch eq '県' || $ch eq '縣') {
			$vars = '[県縣]';
		} elsif ($ch eq '倹' || $ch eq '儉') {
			$vars = '[倹儉]';
		} elsif ($ch eq '剣' || $ch eq '劍') {
			$vars = '[剣劍]';
		} elsif ($ch eq '険' || $ch eq '險') {
			$vars = '[険險]';
		} elsif ($ch eq '検' || $ch eq '檢') {
			$vars = '[検檢]';
		} elsif ($ch eq '顕' || $ch eq '顯') {
			$vars = '[顕顯]';
		} elsif ($ch eq '験' || $ch eq '驗') {
			$vars = '[験驗]';
		} elsif ($ch eq '広' || $ch eq '廣') {
			$vars = '[広廣]';
		} elsif ($ch eq '国' || $ch eq '國') {
			$vars = '[国國]';
		} elsif ($ch eq '酔' || $ch eq '醉') {
			$vars = '[酔醉]';
		} elsif ($ch eq '児' || $ch eq '兒') {
			$vars = '[児兒]';
		} elsif ($ch eq '湿' || $ch eq '濕') {
			$vars = '[湿濕]';
		} elsif ($ch eq '寿' || $ch eq '壽') {
			$vars = '[寿壽]';
		} elsif ($ch eq '収' || $ch eq '收') {
			$vars = '[収收]';
		} elsif ($ch eq '従' || $ch eq '從') {
			$vars = '[従從]';
		} elsif ($ch eq '渋' || $ch eq '澁') {
			$vars = '[渋澁]';
		} elsif ($ch eq '獣' || $ch eq '獸') {
			$vars = '[獣獸]';
		} elsif ($ch eq '縦' || $ch eq '縱') {
			$vars = '[縦縱]';
		} elsif ($ch eq '叙' || $ch eq '敍') {
			$vars = '[叙敍]';
		} elsif ($ch eq '将' || $ch eq '將') {
			$vars = '[将將]';
		} elsif ($ch eq '焼' || $ch eq '燒') {
			$vars = '[焼燒]';
		} elsif ($ch eq '奨' || $ch eq '獎') {
			$vars = '[奨獎]';
		} elsif ($ch eq '条' || $ch eq '條') {
			$vars = '[条條]';
		} elsif ($ch eq '状' || $ch eq '狀') {
			$vars = '[状狀]';
		} elsif ($ch eq '乗' || $ch eq '乘') {
			$vars = '[乗乘]';
		} elsif ($ch eq '浄' || $ch eq '淨') {
			$vars = '[浄淨]';
		} elsif ($ch eq '剰' || $ch eq '剩') {
			$vars = '[剰剩]';
		} elsif ($ch eq '畳' || $ch eq '疊') {
			$vars = '[畳疊]';
		} elsif ($ch eq '嬢' || $ch eq '孃') {
			$vars = '[嬢孃]';
		} elsif ($ch eq '譲' || $ch eq '讓') {
			$vars = '[譲讓]';
		} elsif ($ch eq '醸' || $ch eq '釀') {
			$vars = '[醸釀]';
		} elsif ($ch eq '真' || $ch eq '眞') {
			$vars = '[真眞]';
		} elsif ($ch eq '慎' || $ch eq '愼') {
			$vars = '[慎愼]';
		} elsif ($ch eq '尽' || $ch eq '盡') {
			$vars = '[尽盡]';
		} elsif ($ch eq '粋' || $ch eq '粹') {
			$vars = '[粋粹]';
		} elsif ($ch eq '瀬' || $ch eq '瀨') {
			$vars = '[瀬瀨]';
		} elsif ($ch eq '静' || $ch eq '靜') {
			$vars = '[静靜]';
		} elsif ($ch eq '摂' || $ch eq '攝') {
			$vars = '[摂攝]';
		} elsif ($ch eq '専' || $ch eq '專') {
			$vars = '[専專]';
		} elsif ($ch eq '戦' || $ch eq '戰') {
			$vars = '[戦戰]';
		} elsif ($ch eq '繊' || $ch eq '纖') {
			$vars = '[繊纖]';
		} elsif ($ch eq '禅' || $ch eq '禪') {
			$vars = '[禅禪]';
		} elsif ($ch eq '壮' || $ch eq '壯') {
			$vars = '[壮壯]';
		} elsif ($ch eq '争' || $ch eq '爭') {
			$vars = '[争爭]';
		} elsif ($ch eq '荘' || $ch eq '莊') {
			$vars = '[荘莊]';
		} elsif ($ch eq '捜' || $ch eq '搜') {
			$vars = '[捜搜]';
		} elsif ($ch eq '巣' || $ch eq '巢') {
			$vars = '[巣巢]';
		} elsif ($ch eq '装' || $ch eq '裝') {
			$vars = '[装裝]';
		} elsif ($ch eq '蔵' || $ch eq '藏') {
			$vars = '[蔵藏]';
		} elsif ($ch eq '臓' || $ch eq '臟') {
			$vars = '[臓臟]';
		} elsif ($ch eq '帯' || $ch eq '帶') {
			$vars = '[帯帶]';
		} elsif ($ch eq '滞' || $ch eq '滯') {
			$vars = '[滞滯]';
		} elsif ($ch eq '単' || $ch eq '單') {
			$vars = '[単單]';
		} elsif ($ch eq '団' || $ch eq '團') {
			$vars = '[団團]';
		} elsif ($ch eq '弾' || $ch eq '彈') {
			$vars = '[弾彈]';
		} elsif ($ch eq '昼' || $ch eq '晝') {
			$vars = '[昼晝]';
		} elsif ($ch eq '鋳' || $ch eq '鑄') {
			$vars = '[鋳鑄]';
		} elsif ($ch eq '庁' || $ch eq '廳') {
			$vars = '[庁廳]';
		} elsif ($ch eq '鎮' || $ch eq '鎭') {
			$vars = '[鎮鎭]';
		} elsif ($ch eq '転' || $ch eq '轉') {
			$vars = '[転轉]';
		} elsif ($ch eq '伝' || $ch eq '傳') {
			$vars = '[伝傳]';
		} elsif ($ch eq '稲' || $ch eq '稻') {
			$vars = '[稲稻]';
		} elsif ($ch eq '売' || $ch eq '賣') {
			$vars = '[売賣]';
		} elsif ($ch eq '秘' || $ch eq '祕') {
			$vars = '[秘祕]';
		} elsif ($ch eq '払' || $ch eq '拂') {
			$vars = '[払拂]';
		} elsif ($ch eq '仏' || $ch eq '佛') {
			$vars = '[仏佛]';
		} elsif ($ch eq '翻' || $ch eq '飜') {
			$vars = '[翻飜]';
		} elsif ($ch eq '黙' || $ch eq '默') {
			$vars = '[黙默]';
		} elsif ($ch eq '薬' || $ch eq '藥') {
			$vars = '[薬藥]';
		} elsif ($ch eq '与' || $ch eq '與') {
			$vars = '[与與]';
		} elsif ($ch eq '揺' || $ch eq '搖') {
			$vars = '[揺搖]';
		} elsif ($ch eq '様' || $ch eq '樣') {
			$vars = '[様樣]';
		} elsif ($ch eq '謡' || $ch eq '謠') {
			$vars = '[謡謠]';
		} elsif ($ch eq '来' || $ch eq '來') {
			$vars = '[来來]';
		} elsif ($ch eq '覧' || $ch eq '覽') {
			$vars = '[覧覽]';
		} elsif ($ch eq '塁' || $ch eq '壘') {
			$vars = '[塁壘]';
		} elsif ($ch eq '隷' || $ch eq '隸') {
			$vars = '[隷隸]';
		}
	} elsif ($dumplang eq 'sv') {
		if ($ch eq '?') {
			$vars = '[åäöÅÄÖéÉ]';
		} elsif ($ch eq 'a') {
			$vars = '[aåä]';
		} elsif ($ch eq 'o') {
			$vars = '[oö]';
		} elsif ($ch eq 'A') {
			$vars = '[AÅÄ]';
		} elsif ($ch eq 'O') {
			$vars = '[OÖ]';
		} elsif ($ch eq 'e') {
			$vars = '[eé]';
		} elsif ($ch eq 'E') {
			$vars = '[EÉ]';
		}
	} elsif ($dumplang eq 'th') {
		# consonants	0e01 - 0e2e
		# right vowels	0e2f - 0e30, 0e32 - 0e33, 0e45 - 0e46
		# top vowels	0e31, 0e34 - 0e37
		# bottom vowels	0e3a - 0e3a
		# left vowels	0e40 - 0e44
		# accents	0e47 - 0e4e
		if ($oc >= 0x0e47 && $oc <= 0x0e4e) {
			$vars = "(|\x{0e47}|\x{0e48}|\x{0e49}|\x{0e4a}|\x{0e4b}|\x{0e4c}|\x{0e4d}|\x{0e4e})";
		}
	} elsif ($dumplang eq 'lo') {
		# consonants	
		# right vowels	
		# top vowels	
		# bottom vowels	
		# left vowels	
		# accents	
		if ($oc >= 0x0ec8 && $oc <= 0x0ecd) {
			$vars = "(|\x{0ec8}|\x{0ec9}|\x{0eca}|\x{0ecb}|\x{0ecc}|\x{0ecd})";
		}
	}

	return ($vars, $len);
}

###############################

sub gettitle {
	my $index_s = shift;
	my $index_r;
	my $offset;
	my $title = undef;

	$index_s < $haystacksize || die "sorted index $index_s too big";

	seek(IFH, $index_s * 4, 0) || die "sorted index seek error";
	read(IFH, $index_r, 4);
	$index_r = unpack 'I', $index_r;

	$index_r < $haystacksize || die "raw index $index_r too big (sorted index $index_s)";

	seek(TOFH, $index_r * 4, 0) || die "raw index seek error";
	read(TOFH, $offset, 4);
	$offset = unpack 'I', $offset;

	$offset < -s TFH || die "title offset $offset too big";

	seek(TFH, $offset, 0) || die "titles seek error";
	$title = <TFH>;
	chomp $title;

	#$opt_d && print STDERR "si: $index_s, ri: $index_r, offset: $offset, title: '$title'\n";
	#$opt_d && print STDERR "offset: $offset, title: '$title'\n";

	return $title;
}

sub thumb {
	my $f = substr(shift, 0, 1);
	my $size = shift;
	my $r = [ 0, $size - 1 ];
	$opt_d && print STDERR "** thumb $f $size\n";

	if ($usethumb) {
		if (scalar keys %thumbindex == 0) {
			$opt_d && print STDERR "no thumb index\n";
		} elsif ($f eq '') {
			$opt_d && print STDERR "empty string\n";
		} else {
			$opt_d && print STDERR "using thumb index\n";

			if (exists $thumbindex{$f}) {
				$opt_d && print STDERR "** alpha $f\n";
				$r = $thumbindex{$f};
			} elsif ($f lt 'A') {
				$opt_d && print STDERR "** pre alpha $f\n";
				$r = $thumbindex{'before'};
			} elsif ($f gt 'z') {
				$opt_d && print STDERR "** post alpha $f\n";
				$r = $thumbindex{'after'};
			} elsif ($f gt 'Z' && $f lt 'a') {
				$opt_d && print STDERR "** tween alpha $f\n";
				$r = $thumbindex{'after'};
			}
		}
	} else {
		$opt_d && print STDERR "not using thumb index\n";
	}

	return ($r->[0], $r->[1]);
}

sub printresults {
	my ($arg, $r) = @_;

	my $resarray = $r->{'results'};
	my $resstring = scalar @$resarray ? join(', ', @$resarray) : '-';
	print $arg, ': ', scalar @$resarray, ': ', $resstring, " ($r->{'compcount'} comparisons)\n";
}

