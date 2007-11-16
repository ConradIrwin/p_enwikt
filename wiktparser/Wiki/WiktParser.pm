# vi: ts=4 sw=4 sts=4
package Wiki::WiktParser;

use strict;

require WiktParser::Source;

my @scope;

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

#
# Constructor
#

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->{_language_code} = '';
	$self->{_language_pattern} = '';
	$self->{_headword_parse_tried} = 0;
	$self->{_headword_parse_ok} = 0;
	$self->{_headword_genders} = {};
	return $self;
}

sub set_article_handler {
	my ($self, $handler) = @_;

	$self->{article_handler} = $handler;
}

sub set_template_handler {
	my ($self, $handler) = @_;

	$self->{template_handler} = $handler;
}

#
# This can be called only once
#

sub set_lang {
	my ($self, $code, $pattern) = @_;

	$self->{_language_code} = $code;

	for my $hm (@$headword_matchers) {
		$hm->[0] =~ s/LANG_CODE/$code/g;
	}

	$self->{_language_pattern} = $pattern;
}

#
# Parse wikitext of a Wiktionary page
#

sub parse {
	my $self = shift;
	my ($ns, $title) = @_;

	if ($ns eq '') {
		# Custom article handler
		if ($self->{article_handler}) {
			&{$self->{article_handler}}();

		# Built-in article parser method
		} else {
			$self->parse_article( $title );
		}
	# TODO localize by using namespace numbers
	} elsif ($ns eq 'Template') {
		if ($self->{template_handler}) {
			&{$self->{template_handler}}();
		}
	}
}

sub parse_article {
	my $self = shift;
	my $title = shift;

	my $page;					# a page is an article

	$page = {};
	$page->{raw} = {};			# level 1 heading, root for tree of headings
	$page->{cooked} = {};		# TODO not yet used

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

	$prevsection = $self->appendsection($section);

	# Each line of page wikitext
	while (1) {
		$WiktParser::Source::line =~ /^\s*(?:<text xml:space="preserve">)?(.*?)(<\/text>)?$/;
		my ($tline, $post) = ($1, $2);

		# TODO shouldn't this test be at the bottom of the loop?
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

			# Section more than 1 level deeper than its parent?
			if ($prevsection->{level} - $level < -1) {
				$section->{toodeep} = 1;
			}

			$prevsection = $self->appendsection($section);
		} # Heading
		
		# Not heading, just plain lines
		else {
			push @{$section->{lines}}, $tline;
		}

		last unless (WiktParser::Source::nextline());
	} # while (1)

	# Process raw section tree into a more structured entry
	my $p = $page->{raw}->{sections}[0];
	my $w = $p->{heading};

	my @nouns;

	# Collect all the noun sections we want to parse

	# Each language in this page
	foreach my $lang (@{$p->{sections}}) {
		if ($lang->{heading} =~ /$self->{_language_pattern}/o) {

			my $etymcount = 0;
			my $nouncount = 0;

			# Each l3 heading: we care about Noun and Etymology
			foreach my $l3 (@{$lang->{sections}}) {

				# Noun, possibly numbered
				if ($l3->{heading} =~ /^Noun(?:\s+\d+)?$/) {
					$l3->{etymcount} = 1;
					$l3->{nouncount} = ++$nouncount;
					push @nouns, $l3;
				}
				# Unsupported variations on Noun
				elsif ($l3->{heading} =~ /\b[Nn]oun/) {
					print STDERR "** $w ** $l3->{heading}\n";
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
							push @nouns, $l4;
						}
						# Unsupported variations on Noun
						elsif ($l3->{heading} =~ /\b[Nn]oun/) {
							print STDERR "** $w ** $l4->{heading}\n";
						}
					}
				}
			}
			last;	# Skip the following language entries
		}
	}

	# Parse all the noun sections we collected
	my $t;
	foreach my $ns (@nouns) {
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

			++$self->{_headword_parse_tried};

			if ((my $hw = $self->parse_headword($w, $l))) {
				$g = $hw->{g};
				$n = $hw->{n};
				++$self->{_headword_parse_ok};
			}

			if ($g) {
				++$self->{_headword_genders}->{$g};
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

		$self->parse_definitions(\$ln, $ns, \$t, $w, $g);

		# END process noun body
	}
}

#######################################################

#
# @scope is a global, should be a member I guess
#

sub appendsection {
	my ($self, $section) = @_;

	# This make a circular reference which prevents garbage collection!
	#$section->{parent} = @scope[$section->{level} - 1];
	push @{@scope[$section->{level} - 1]->{sections}}, $section;

	for (my $l = $section->{level}; $l <= 7; ++$l) {
		@scope[$l] = $section;
	}

	return $section;
}

########################################################################

#
# This is normally a single line so we can pass it as a single parameter
#
# Slovak entries in particular use multiple lines however
#

sub parse_headword {
	my $self = shift;
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

sub show_headword_log() {
	my $self = shift;

	print 'Tried to parse ', $self->{_headword_parse_tried}, ' headword sections, ', $self->{_headword_parse_ok}, " succeeded\n";
	for my $g (keys %{$self->{_headword_genders}}) {
		print "Gender '$g': ", $self->{_headword_genders}->{$g}, "\n";
	}
	for (my $i = 0; $i < scalar @$headword_matchers; ++$i) {
		print $headword_matchers->[$i]->[2], ' : ', $headword_matchers->[$i]->[0], "\n";
	}
}

#
# The definitions section consists of all lines beginning with #
# Each definition consists of a first line beginning with just #
#  followed by 0 or more lines beginning with ##, #*, or #:
#

sub parse_definitions {
	my $self = shift;
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

1;

