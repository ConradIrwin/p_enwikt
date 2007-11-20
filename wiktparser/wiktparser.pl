#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

use Getopt::Std;

use Wiki::DumpParser;
use Wiki::WiktLang;
use Wiki::WiktParser;

require WiktParser::Source;

my %opts;
my $lang;

getopt('lLx', \%opts);

if ($opts{l} && $opts{L}) {
	die "Use either -l for language code or -L for language name\n";
} elsif ($opts{l}) {
	$lang = Wiki::WiktLang::bycode($opts{l});
} elsif ($opts{L}) {
	$lang = Wiki::WiktLang::byname($opts{L});
} else {
	die "Use either -l for language code or -L for language name\n";
}

unless ($lang) {
	die "Couldn't find language\n";
}

my $headword_matchers = [
	# '''headword''' {{m}}
	[ "^'''.*?''',?\\s+{{(m|f|n|c|mf|fm)(\\.?pl\\.?)?}}",								'g1,n2?p' ],
	# '''headword''' ''m''
	[ "^'''.*?''',?\\s+''([mfnc])\\.?''",												'g1' ],
	# Gender followed by ambiguous plurality info
	[ "^'''.*?'''\\s+''([mfnc]), ?pl(?:ural)?''(.*)",									'g1,n2:p' ],
	# '''headword''' ''m pl''
	[ "^'''.*?'''\\s+''([mfnc]) ?pl(?:ural)?''",										'g1,np' ],
	# Two genders separated by slash or comma
	# '''headword''' ''m/f''			'''headword''' ''m, f''
	[ "^'''.*?'''\\s+''([mfnc])(?:\\/|, )([mfnc])''",									'g1+2' ],
	# '''headword''' (translit) {{m}}
	[ "^'''.*?'''(?:\\s+\\(.*?\\))?(?:\\s+{{([mfnc])}})?\\s*\$",						'g1?1:-' ],
	# '''headword''' (translit) ''m''
	[ "^'''.*?'''(?:\\s+\\(.*?\\))?(?:\\s+''([mfnc])'')?\\s*\$",						'g1?1:-' ],
	# {{he-link|headword}} {{m}}
	[ "^{{LANG_CODE-link\\|.*?}}(?:\\s+{{([mfnc])}})?\\s*\$",							'g1?1:-' ],
	# '''headword''' {{?????|translit}} {{m}}
	[ "^'''.*?'''(?:\\s+{{(?:IPAchar|unicode)\\|.*?}})?(?:\\s+{{([mfnc])}})?\\s*\$",	'g1?1:-' ],
	# '''headword''' {{?????|translit}} ''m''
	[ "^'''.*?'''(?:\\s+{{(?:IPAchar|unicode)\\|.*?}})?(?:\\s+''([mfnc])'')?\\s*\$",	'g1?1:-' ],
	# '''headword'''
	[ "^'''.*?'''\\s*\$",																'g-' ],
	# '''{{Script|headword}}''' (translit) {{m}}
	# '''{{SCchar|headword}}''' (translit) {{m}}
	# {{SCchar|'''headword'''}} (translit) {{m}}
	# {{SCchar|headword}} (translit) {{m}}
	# Careful - this one is actually for "mf" pairs (not invariants)
	[ "^{{LANG_CODE-noun-mf\\|f(?:emale)?=",											'gm' ],
	[ "^{{LANG_CODE-noun-(m|f|n|c|mf|fm)\\b",											'g1' ],
	[ "^{{LANG_CODE-noun2?\\|(m|f|n|c|mf|fm)\\b",										'g1' ],
	[ "^{{LANG_CODE-noun2?\\|g(?:ender)?=(m|f|n|c|mf|fm)\\b",							'g1' ],
	[ "^{{infl\\|LANG_CODE\\|noun(?:\\|g(?:ender)?=([mfnc]))?\\b",						'g1?1:-' ],
	[ "^'''.*?'''\\s+\\((?:'')?plural:?(?:'')?:? '''.*?'''\\)(?:\\s+{{([mfnc])}})?",	'g1?1:-' ],
];

my $namespace;
my $title;

my $article_nouns = [];
my $article_w = '';

my $headword_parse_tried = 0;
my $headword_parse_ok = 0;
my $headword_genders = {};

my $dumpparser = new Wiki::DumpParser;
my $wiktparser = new Wiki::WiktParser;

my $source = new WiktParser::Source;

if ($dumpparser && $wiktparser && $source) {
	$dumpparser->set_source( $source );
	$dumpparser->set_title_handler( \&title_handler );
	$dumpparser->set_text_handler( \&text_handler );

	if ($opts{x}) {
		$dumpparser->set_maxpages( $opts{x} );
	}

	set_lang( $lang );

	$wiktparser->set_source( $source );
	$wiktparser->set_article_start_handler( \&article_start_handler );
	$wiktparser->set_langsection_handler( \&langsection_handler );
	$wiktparser->set_article_end_handler( \&article_end_handler );

	$dumpparser->parse();

	$dumpparser->show_page_counts;

	show_headword_log();
}

exit;

#######################################################

#
# This can be called only once
#

sub set_lang {
	my $lang = shift;

	for my $hm (@$headword_matchers) {
		$hm->[0] =~ s/LANG_CODE/$lang->{code}/g;
	}
}

#
# Handlers for DumpParser
#

sub title_handler {
	my ($ns, $t) = @_;
	$namespace = $ns;
	$title = $t;
}

sub text_handler {
	$wiktparser->parse( $namespace, $title );
}

#
# Handlers for WiktParser
#

sub article_start_handler {
	my $p = shift;

	$article_nouns = [];
	$article_w = $p->{heading};
}

sub langsection_handler {
	# TODO turn into flexible per-language callback

	my $langsection = shift;

	if ($langsection->{heading} =~ /$lang->{pattern}/o) {

		my $etymcount = 0;
		my $nouncount = 0;

		# Each l3 heading: we care about Noun and Etymology
		foreach my $l3 (@{$langsection->{sections}}) {

			# Noun, possibly numbered
			# TODO per-POS filter
			if ($l3->{heading} =~ /^Noun(?:\s+\d+)?$/) {
				$l3->{etymcount} = 1;
				$l3->{nouncount} = ++$nouncount;
				push @{$article_nouns}, $l3;
			}
			# Unsupported variations on Noun
			elsif ($l3->{heading} =~ /\b[Nn]oun/) {
				print STDERR "** $article_w ** $l3->{heading}\n";
			}

			# Etymology, supposed to be numbered
			elsif ($l3->{heading} =~ /^Etymology(?:\s+\d+)?$/) {

				my $nouncount = 0;

				# Each l4 subheading of an l3 Etymology section
				foreach my $l4 (@{$l3->{sections}}) {

					# Noun, possibly numbered
					if ($l4->{heading} =~ /^Noun(?: \d+)?$/) {
						$l4->{etymcount} = ++$etymcount;
						$l4->{nouncount} = ++$nouncount;
						push @{$article_nouns}, $l4;
					}
					# Unsupported variations on Noun
					elsif ($l3->{heading} =~ /\b[Nn]oun/) {
						print STDERR "** $article_w ** $l4->{heading}\n";
					}
				}
			}
		}
		last;	# Skip the following language entries
	}
}

sub article_end_handler {
	# Parse all the noun sections we collected
	my $t;
	foreach my $ns (@{$article_nouns}) {
		# START process noun body
		my ($ln, $l);
		for ($ln = 0; $ln < scalar @{$ns->{lines}}; ++$ln) {
			$t = $ns->{lines}[$ln];

			# Ignore certain lines
			if ($t =~ /^\s*$/
				|| $t =~ /^{{wikipedia(?:Alt)?\|/						# }}
				|| $t =~ /^\[\[Category:[^]]*]]/) {
				next;
			# Did we get to the definitions already?
			} elsif ($t =~ /^#/) {
				last;
			# Anything else will be treated as a headword/inflection line
			} else {
				$l = $t;
				last;
			}
		}

		my $g = undef;	# gender (m, f, n, c, ...)
		my $n = undef;	# number (singular, plural, ...)

		#next if ($l eq undef);
		if ($t !~ /^#/) {

			# Parse the headword/inflection line for gender and number

			++$headword_parse_tried;

			if ((my $hw = parse_headword($article_w, $l))) {
				$g = $hw->{g};
				$n = $hw->{n};
				++$headword_parse_ok;
			}

			if ($g) {
				++$headword_genders->{$g};
			}
		}
		# END parse headword/inflection line

		# Transition from headword/inflection section to definitions section

		while (++$ln < scalar @{$ns->{lines}}) {
			$t = $ns->{lines}[$ln];
			# Ignore certain lines
			if ($t =~ /^\s*$/) {
				next;
			# Anything else will be treated as the start of the definition lines
			} else {
				#print STDERR "EH $w : $t\n";
				last;
			}
		}

		parse_definitions(\$ln, $ns, \$t, $article_w, $g);

		# END process noun body
	}
}

#
# This is normally a single line so we can pass it as a single parameter
#
# Slovak entries in particular use multiple lines however
#

sub parse_headword {
	my ($w, $l) = @_;

	my $success = 0;	# set to 0 if no matches succeed
	my $g;				# gender: m:masculine f:feminine n:neuter c:common or some combination
	my $n;				# number: s:singular p:plural d:dual

	for (my $i = 0; $i < scalar @$headword_matchers; ++$i) {
		if ($l =~ /$headword_matchers->[$i]->[0]/) {
			$success = 1;
			++$headword_matchers->[$i]->[2];

			if ($headword_matchers->[$i]->[1]      eq 'g1,n2?p') {
				$g = $1; $n = 'p' if ($2);
			} elsif ($headword_matchers->[$i]->[1] eq 'g1') {
				$g = $1;
			} elsif ($headword_matchers->[$i]->[1] eq 'g1,n2:p') {
				$g = $1; $n = 'p' unless ($2);
			} elsif ($headword_matchers->[$i]->[1] eq 'g1,np') {
				$g = $1; $n = 'p';
			} elsif ($headword_matchers->[$i]->[1] eq 'g1+2') {
				$g = $1 . $2;
			} elsif ($headword_matchers->[$i]->[1] eq 'g1?1:-') {
				$g = $1 ? $1 : '-';
			} elsif ($headword_matchers->[$i]->[1] eq 'g-') {
				$g = '-';
			} elsif ($headword_matchers->[$i]->[1] eq 'gm') {
				$g = 'm';
			} else {
				print STDERR "** unknown gender/number opcode '", $headword_matchers->[$i]->[1], "'\n";
			}
			last;
		}
	}

	if ($success) {
		return { 'g' => $g, 'n' => $n };
	} else {
		print STDERR "UH $w : $l\n";
		return undef;
	}
}

#
# The definitions section consists of all lines beginning with #
# Each definition consists of a first line beginning with just #
#  followed by 0 or more lines beginning with ##, #*, or #:
#

sub parse_definitions {
	my ($ln, $ns, $t, $w, $g) = @_;

	# Etymology, Noun, Sense numbers
	my ($en, $nn, $sn) = ($ns->{etymcount}, $ns->{nouncount}, 0);

	# START process definitions
	while ($$ln < scalar @{$ns->{lines}}) {
		$$t = $ns->{lines}[$$ln++];
		++$sn;

		# Definition line?
		if ($$t =~ /^#/) {
			if ($$t =~ /^#\s*(?:[aA]n?\s*)?\[\[([^\]#\|]*)(?:#[^\]\|]*)?(?:\|[^\]]*)?]]\s*[;,]\s*(?:[aA]n?\s*)?\[\[([^\]#\|]*)(?:#[^\]\|]*)?(?:\|[^\]]*)?]]\s*[;,]\s*(?:[aA]n?\s*)?\[\[([^\]#\|]*)(?:#[^\]\|]*)?(?:\|[^\]]*)?]]\.?\s*$/) {
				my $tw1 = $1;
				my $tw2 = $2;
				my $tw3 = $3;

				# A link such as [[#foo]] means the English word also uses this spelling
				$tw1 = $tw1 ? $tw1 : $w;
				$tw2 = $tw2 ? $tw2 : $w;
				$tw3 = $tw3 ? $tw3 : $w;

				print "$w $en.$nn.$sn.1 [$g] $tw1\n";
				print "$w $en.$nn.$sn.2 [$g] $tw2\n";
				print "$w $en.$nn.$sn.3 [$g] $tw3\n";
			}
			elsif ($$t =~ /^#\s*(?:[aA]n?\s*)?\[\[([^\]#\|]*)(?:#[^\]\|]*)?(?:\|[^\]]*)?]]\s*[;,]\s*(?:[aA]n?\s*)?\[\[([^\]#\|]*)(?:#[^\]\|]*)?(?:\|[^\]]*)?]]\.?\s*$/) {
				my $tw1 = $1;
				my $tw2 = $2;

				# A link such as [[#foo]] means the English word also uses this spelling
				$tw1 = $tw1 ? $tw1 : $w;
				$tw2 = $tw2 ? $tw2 : $w;

				print "$w $en.$nn.$sn.1 [$g] $tw1\n";
				print "$w $en.$nn.$sn.2 [$g] $tw2\n";
			}
			elsif ($$t =~ /^#\s*(?:[aA]n?\s*)?\[\[([^\]#\|]*)(?:#[^\]\|]*)?(?:\|[^\]]*)?]]\.?\s*$/) {
				my $tw = $1;

				# Hebrew glosses sometimes contain bogus trailing text direction marks
				# TODO this test does not work!
				print STDERR "** gloss contains direction marks!\n" if ($tw =~ /\x{200f}/);
				$tw =~ s/\x{200f}+$//;

				# A link such as [[#foo]] means the English word also uses this spelling
				$tw = $tw ? $tw : $w;

				print "$w $en.$nn.$sn.1 [$g] $tw\n";
			} else {
				print STDERR "UD $w : $$t\n";
			}

			# Eat following lines that are part of the same definition
			while ($$ln < scalar @{$ns->{lines}}) {
				$$t = $ns->{lines}[$$ln++];
				# Ignore certain lines
				if ($$t =~ /^#[#*:]/) {
					next;
				# Anything else will be treated as the start of the definition lines
				} else {
					--$$ln;
					last;
				}
			}
		# Anything else will be treated as the end of the definitions section
		} else {
			if ($$t !~ /^\s*$/) {
				print STDERR "ED $w : $$t\n";
			}
			last;
		}
	}
	# END process definitions
}

sub show_headword_log() {
	print 'Tried to parse ', $headword_parse_tried, ' headword sections, ', $headword_parse_ok, " succeeded\n";
	for my $g (keys %{$headword_genders}) {
		print "Gender '$g': ", $headword_genders->{$g}, "\n";
	}
	for (my $i = 0; $i < scalar @$headword_matchers; ++$i) {
		print $headword_matchers->[$i]->[2], ' : ', $headword_matchers->[$i]->[0], "\n";
	}
}

