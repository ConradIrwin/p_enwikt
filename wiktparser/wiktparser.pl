#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

#my ($lang_code, $lang_pat, $lang_g) = ('ang', '^Old English$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('ca', '^Catalan$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('cs', '^Czech$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('da', '^Danish$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('de', '^German$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('el', '^Greek$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('fr', '^French$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('he', '^Hebrew$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('is', '^Icelandic$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('lv', '^Latvian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('nl', '^Dutch$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('pl', '^Polish$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('ru', '^Russian$', [] );
my ($lang_code, $lang_pat, $lang_g) = ('sk', '^Slovak(?:ian)?$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('sl', '^Sloven(?:e|ian)$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('sv', '^Swedish$', [] );

my @scope;

my $maxpages = 0;
my $pagecounter = 0;

my $tried_to_parse = 0;
my $parsed_ok = 0;

my %langnamestocodes;
my %namespaces;
my %titles;

my $xline;

while ($xline = <STDIN>) {
	last if ($xline =~ /<namespaces>/);
}

if ($xline !~ /<namespaces>/) {
	print STDERR "** namespaces section not found\n";
	exit;
}

print STDERR "** found namespaces\n";

while ($xline = <STDIN>) {
	if ($xline =~ /<namespace key="-?\d+"(.*)>/) {
		my $rest = $1;
		if ($rest =~ />(.*)<\/namespace/) {
			$namespaces{$1} = 1;
		}
	} else {
		last;
	}
}

if ($xline !~ /<\/namespaces>/) {
	print STDERR "** end of namespaces section not found\n";
	exit;
}

print STDERR "** namespaces done\n";

my $nsre = '^(' . join('|', 'webster 1913', keys %namespaces) . '):(.*)$';

print "<wiktionary>\n";

# Each line of dump file
while (1) {

	my $title = '';

	while ($xline = <STDIN>) {
		if ($xline =~ /<title>(.*)<\/title>/) {
			$title = $1;
			last;
		}
	}

	if ($xline !~ /<title>.*<\/title>/) {
		print STDERR "** no more pages";
		exit;
	}

	my $ns = '';

	# Check namespace
	if ($title =~ /$nsre/o) {
		$ns = $1;
		$title = $2;
	}

	# Skip to start of wikitext
	while ($xline = <STDIN>) {
		last if ($xline =~ /<text xml:space="preserve">/);
	}

	# If we ever had an article record without a text record
	if ($xline =~ /<title>.*<\/title>/) {
		print STDERR "** $title has no text field\n";
		exit;
	}

	if ($xline !~ /<text xml:space="preserve">/) {
		print STDERR "** unexpected end of file while looking for $title's text field\n";
		exit;
	}

	# Language code template?
	#if ($ns eq 'Template') {
	#	if ($title =~ /^(?:lang:)?([a-z][a-z][a-z]?)$/) {
	#		my $langcode = $1;

	#		if ($xline =~ /<text xml:space="preserve">(.*?)&lt;noinclude&gt;\[\[Category:Language templates|$title]]&lt;\/noinclude&gt;<\/text>/) {
	#			my $langname = $1;
	#			if ($langname =~ /^\[\[(?:.*\|)?(.*?)]]$/) {
	#				$langname = $1;
	#			}

	#			if ($langname ne '') {
	#				push @{$langnamestocodes{$langname}}, $langcode;
	#			}
	#		}
	#	}

	# Article wikitext?
	#} elsif ($ns eq '') {
	if ($ns eq '') {

		$pagecounter++;

		my $page;					# a page is an article

		$page = {};
		$page->{raw} = {};			# level 1 heading, root for tree of headings
		$page->{cooked} = {};

		@scope[0] = $page->{raw};

		my $tline;					# line of wikitext to be parsed

		my $prevsection;
		my $section;				# each heading starts a new section

		my $entry;					# each language heading starts a new entry

		$page->{title} = $title;

		$section = {};
		$section->{level} = 1;
		$section->{heading} = $title;
		$section->{lines} = [];
		$section->{sections} = [];

		$prevsection = appendsection($section);

		# Each line of page wikitext
		while (1) {
			$xline =~ /^\s*(?:<text xml:space="preserve">)?(.*?)(<\/text>)?$/;
			my ($tline, $post) = ($1, $2);

			last if ($post ne '');

			# Heading
			if ($tline =~ /^(==+)\s*([^=]+?)\s*(==+)\s*$/) {
				$section = {};
				$section->{unbalanced} = (length($1) != length($3));
				my $level = length($1) < length($3) ? length($1) : length($3);
				$section->{level} = $level;
				my $headinglabel = $2;
				if ($headinglabel =~ /^\[\[\s*(?:.*\|)?(.*?)\s*\]\]$/) {
					$headinglabel = $1;
				}
				$section->{heading} = $headinglabel;
				$section->{lines} = [];
				$section->{sections} = [];

				# Language heading
				if ($level == 2) {
					my $langname = $headinglabel;
					#my $langcode = $langnamestocodes{$langname};
					my $lang;
					if (exists $langnamestocodes{$langname}) {
						$lang = '<' . join('|', @{$langnamestocodes{$langname}}) . '>';
					} else {
						$lang = $langname;
					}
					#push @{$page->{langs}}, $lang . ':' . $level;
					#$entry->{lang} = {};
					#$entry->{lang}->{label} = $langname;
					#if (exists $langnamestocodes{$langname}) {
					#	$entry->{lang}->{code} = $langnamestocodes{$langname}[0];
					#}
					#$entry->{sections} = [];
				}

				# Other headings
				else {
					# Section more than 1 level deeper than its parent?
					if ($prevsection->{level} - $level < -1) {
						$section->{toodeep} = 1;
					}
				}

				$prevsection = appendsection($section);
			} # Heading
			
			# Not heading, just plain lines
			else {
				push @{$section->{lines}}, $tline;
			}

			last unless ($xline = <STDIN>);
		} # while (1)

		# Process raw section tree into a more structured entry
		foreach my $p ($page->{raw}->{sections}[0]) {
			foreach my $lang (@{$p->{sections}}) {
				if ($lang->{heading} =~ /$lang_pat/o) {
					foreach my $l3 (@{$lang->{sections}}) {
						# TODO handle l3=Etymology # + l4=Noun
						if ($l3->{heading} eq 'Noun') {
							my $w = $p->{heading};
							my $l = $l3->{lines}[0];

							# TODO should be a loop
							if ($l3->{lines}[1]) {
								if ($l eq '' || $l =~ /^{{wikipediaAlt\|/ || $l =~ /^\[\[Category:[^]]*]]/) {
									$l = $l3->{lines}[1];
								}
							}

							my $g = undef;
							my $n = undef;

							++$tried_to_parse;

#							if ($l =~ /^'''.*?''',?\s+{{(m|f|n|c|mf|fm)(\.?pl\.?)?}}/) {
#								$g = $1;
#								$n = 'p' if ($2);
#							} elsif ($l =~ /^'''.*?''',?\s+''([mfnc])\.?''/) {
#								$g = $1;
#							} elsif ($l =~ /^'''.*?'''\s+''([mfnc]), ?pl(?:ural)?''(.*)/) {
#								$g = $1;
#								$n = 'p' unless ($2);
#							} elsif ($l =~ /^'''.*?'''\s+''([mfnc]) ?pl(?:ural)?''/) {
#								$g = $1;
#								$n = 'p';
#							} elsif ($l =~ /^'''.*?'''\s+''([mfnc])(?:\/|, )([mfnc])''/) {
#								$g = $1 . $2;
#							} elsif ($l =~ /^'''.*?'''\s*$/) {
#								$g = '-';
#							# Careful - this one is actually for "mf" pairs (not invariants)
#							} elsif ($l =~ /^{{$lang_code-noun-mf\|f(?:emale)?=/o) {
#								$g = 'm';
#							} elsif ($l =~ /^{{$lang_code-noun-(m|f|n|c|mf|fm)\b/o) {
#								$g = $1;
#							} elsif ($l =~ /^{{$lang_code-noun2?\|(m|f|n|c|mf|fm)\b/o) {
#								$g = $1;
#							} elsif ($l =~ /^{{$lang_code-noun2?\|g(?:ender)?=(m|f|n|c|mf|fm)\b/o) {
#								$g = $1;
#							} elsif ($l =~ /^{{infl\|$lang_code\|noun(?:\|g(?:ender)?=([mfnc]))?\b/o) {
#								$g = $1 ? $1 : '-';
#							} elsif ($l =~ /^'''.*?'''\s+\((?:'')?plural:?(?:'')?:? '''.*?'''\)(?:\s+{{([mfnc])}})?/) {
#								$g = $1 ? $1 : '-';
#							}
#							if ($g) {
#								++$parsed_ok;
#								print "$w :: $g\n";
#							} else {
#								print "$w : $l\n";
#							}
							print STDERR "$w ($parsed_ok / $tried_to_parse)\n";
						}
					}
					last;	# Skip the following language entries
				}
			}
		}

		# Emit page
		#emitsection($page->{raw}->{sections}[0]);
	}

	# Skip remainder of page
	while ($xline = <STDIN>) {
		last if ($xline =~ /<\/page>/);
	}
	if ($xline !~ /<\/page>/) {
		print STDERR "** unexpected end of file in $title\n";
		exit;
	}

	# Enough pages processed?
	if ($ns eq '') {
		if ($maxpages != 0 && $pagecounter >= $maxpages) {
			print STDERR "** max number of pages parsed\n";
			print "</wiktionary>\n";
			exit;
		}
	}
} # while (1)

sub emitsection {
	my $s = shift;

	my $ot = '<s';
	#$ot .= ' c="' . scalar @{$_->{sections}} . '"';
	$ot .= " l=\"$s->{level}\"";
	$ot .= " h=\"$s->{heading}\"";
	if ($s->{toodeep}) {
		$ot .= ' td="1"';
	}
	if ($s->{unbalanced}) {
		$ot .= ' u="1"';
	}
	$ot .= ">\n";
	print $ot;
	foreach (@{$s->{lines}}) {
		print "<x>$_</x>\n";
	}
	foreach (@{$s->{sections}}) {
		emitsection($_);
	}
	print "</s>\n";
}

#
# @scope is a global, should be a member i guess
#
#
sub appendsection {
	my $section = shift;

	$section->{parent} = @scope[$section->{level} - 1];
	push @{@scope[$section->{level} - 1]->{sections}}, $section;

	for (my $l = $section->{level}; $l <= 7; ++$l) {
		@scope[$l] = $section;
	}

	return $section;
}
