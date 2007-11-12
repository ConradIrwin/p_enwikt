# vi: ts=4 sw=4 sts=4
package Wiki::WiktParser;

use strict;

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

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	return $self;
}

sub set_lang_code {
	my ($self, $code) = @_;

	$self->{lang_code} = $code;

	for my $hm (@$headword_matchers) {
		$hm->[0] =~ s/LANG_CODE/$code/g;
	}
}

sub parse {
	my $self = shift;
	my ($ns, $pagecounter, $title, $xline, $lang_pat, $tried_to_parse, $parsed_ok, $gendercount) = @_;

	if ($ns eq '') {

		$$pagecounter++;

		# Does this mean new page references are allocated on the stack every time?
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

		$prevsection = $self->appendsection($section);

		# Each line of page wikitext
		while (1) {
			$$xline =~ /^\s*(?:<text xml:space="preserve">)?(.*?)(<\/text>)?$/;
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

			last unless ($$xline = <STDIN>);
		} # while (1)

		# Process raw section tree into a more structured entry
		my $p = $page->{raw}->{sections}[0];
		my $w = $p->{heading};

		my @nouns;

		# Collect all the noun sections we want to parse

		# Each language in this page
		foreach my $lang (@{$p->{sections}}) {
			if ($lang->{heading} =~ /$lang_pat/o) {

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

				++$$tried_to_parse;

				# Gender template
				if ((my $hw = $self->parse_headword($l))) {
					$g = $hw->{g};
					$n = $hw->{n}
				}

				if ($g) {
					++$$parsed_ok;
					++$gendercount->{$g};
					#print "$w :: $g\n";
				} else {
					print STDERR "$w : $l\n";
				}

				#print STDERR "$w - nouns: $tried_to_parse, parsed: $parsed_ok",
				#	", genders: ", $parsed_ok - $gendercount{'-'};

				#foreach (keys %gendercount) {
				#	print STDERR ", $_: ", $gendercount{$_};
				#}
				#print STDERR "\n";
			}
			# END parse headword/inflection line

			# Transition from headword/inflection section to definitions section

			while (++$ln < scalar @{$ns->{lines}}) {
				$t = $ns->{lines}[$ln];
				#print STDERR ".. $t\n";
				# Ignore certain lines
				if ($t =~ /^\s*$/) {
					next;
				# Anything else will be treated as the start of the definition lines
				} else {
					last;
				}
			}

			# START process definitions
			while ($ln < scalar @{$ns->{lines}}) {
				$t = $ns->{lines}[$ln++];
				#print STDERR "** def? $t\n";
				# Definition line?
				if ($t =~ /^#/) {
					if ($t =~ /^#\s*(?:[aA]n?\s*)?\[\[([^\]#\|]*)(?:#[^\]\|]*)?(?:\|[^\]]*)?]]\.?\s*$/) {
						my $tw = $1;

						# Hebrew glosses sometimes contain bogus trailing text direction marks
						# TODO this test does not work!
						print STDERR "** gloss contains direction marks!\n" if ($tw =~ /\x{200f}/);
						$tw =~ s/\x{200f}+$//;

						# A link with a # but no page name means the same spelling as the English word
						$tw = $tw ? $tw : $w;

						my ($en, $nn) = ($ns->{etymcount}, $ns->{nouncount});
						print "$w $en.$nn [$g] $tw\n";
					} else {
						#print STDERR "** unparsable def: $t\n";
						print STDERR "U $w : $t\n";
					}

					# Eat following lines that are part of the same definition
					while ($ln < scalar @{$ns->{lines}}) {
						$t = $ns->{lines}[$ln++];
						#print STDERR "** eat? $t\n";
						# Ignore certain lines
						if ($t =~ /^#[#*:]/) {
							#print STDERR "** eating: $t\n";
							next;
						# Anything else will be treated as the start of the definition lines
						} else {
							#print STDERR "** done eating: $t\n";
							--$ln;
							last;
						}
					}
				# Anything else will be treated as the end of the Noun section
				} else {
					if ($t !~ /^\s*$/) {
						print STDERR "E $w : $t\n";
					}
					last;
				}
			}
			# END process definitions

			# END process noun body
		}
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

#################################################################

sub parse_headword {
	my $self = shift;
	my $l = shift;

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
	};

	if ($success) {
		return { 'g' => $g, 'n' => $n };
	} else {
		return undef;
	}
}

sub show_headword_log() {
	my $self = shift;

	for (my $i = 0; $i < scalar @$headword_matchers; ++$i) {
		print $headword_matchers->[$i]->[2], ' : ', $headword_matchers->[$i]->[0], "\n";
	}
}

1;

