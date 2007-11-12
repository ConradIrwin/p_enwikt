#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;
use Wiki::DumpParser;
use Wiki::WiktParser;

#my ($lang_code, $lang_pat, $lang_g) = ('ar', '^Arabic$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('ang', '^Old English$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('bg', '^Bulgarian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('ca', '^Catalan$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('cs', '^Czech$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('da', '^Danish$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('de', '^German$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('el', '^Greek$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('eo', '^Esperanto$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('es', '^Spanish$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('fa', '^(Persian|Farsi)$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('fr', '^French$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('he', '^Hebrew$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('hi', '^Hindi$', [] );
my ($lang_code, $lang_pat, $lang_g) = ('hr', '^Croatian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('hu', '^Hungarian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('is', '^Icelandic$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('ko', '^Korean$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('lt', '^Lithuanian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('lv', '^Latvian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('mi', '^M[aā]ori$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('mn', '^Mongolian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('nl', '^Dutch$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('no', '^Norwegian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('pl', '^Polish$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('pt', '^Portuguese$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('ro', '^R[ou]manian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('ru', '^Russian$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('sk', '^Slovak(?:ian)?$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('sl', '^Sloven(?:e|ian)$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('sv', '^Swedish$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('sw', '^(?:Ki[sS]|S)wahili$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('th', '^Thai$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('vi', '^Vietnamese$', [] );
#my ($lang_code, $lang_pat, $lang_g) = ('yi', '^Yiddish$', [] );

my $namespace;
my $title;
my $pagecounter = 0;
my $xline;
my $tried_to_parse = 0;
my $parsed_ok = 0;
my %gendercount;

my $dumpparser = new Wiki::DumpParser;
my $wiktparser = new Wiki::WiktParser;

if ($dumpparser && $wiktparser) {
	$dumpparser->set_title_handler( \&title_handler );
	$dumpparser->set_text_start_handler( \&text_start_handler );
	$dumpparser->set_text_end_handler( \&text_end_handler );
	$dumpparser->set_text_handler( \&text_handler );

	$wiktparser->set_lang_code( $lang_code );

	$dumpparser->parse( \$xline );

	$wiktparser->show_headword_log;
}

print STDERR "** wiktparser2.pl done\n";

exit;

#######################################################

sub title_handler {
	my ($ns, $t) = @_;
	$namespace = $ns;
	$title = $t;
}

sub text_start_handler {
}

sub text_end_handler {
}

sub text_handler {
	#print "** $namespace $title\n";
	$wiktparser->parse( $namespace, \$pagecounter, $title, \$xline, $lang_pat, \$tried_to_parse, \$parsed_ok, \%gendercount );
	#print "** p $pagecounter t $tried_to_parse ok $parsed_ok\n";
}

#######################################################

#my $headword_matchers = [
#	# '''headword''' {{m}}
#	[ "^'''.*?''',?\\s+{{(m|f|n|c|mf|fm)(\\.?pl\\.?)?}}",								'g1,n2?p' ],
#	# '''headword''' ''m''
#	[ "^'''.*?''',?\\s+''([mfnc])\\.?''",												'g1' ],
#	# Gender followed by ambiguous plurality info
#	[ "^'''.*?'''\\s+''([mfnc]), ?pl(?:ural)?''(.*)",									'g1,n2:p' ],
#	# '''headword''' ''m pl''
#	[ "^'''.*?'''\\s+''([mfnc]) ?pl(?:ural)?''",										'g1,np' ],
#	# Two genders separated by slash or comma
#	# '''headword''' ''m/f''			'''headword''' ''m, f''
#	[ "^'''.*?'''\\s+''([mfnc])(?:\\/|, )([mfnc])''",									'g1+2' ],
#	# '''headword''' (translit) {{m}}
#	[ "^'''.*?'''(?:\\s+\\(.*?\\))?(?:\\s+{{([mfnc])}})?\\s*\$",						'g1?1:-' ],
#	# '''headword''' (translit) ''m''
#	[ "^'''.*?'''(?:\\s+\\(.*?\\))?(?:\\s+''([mfnc])'')?\\s*\$",						'g1?1:-' ],
#	# {{he-link|headword}} {{m}}
#	[ "^{{he-link\\|.*?}}(?:\\s+{{([mfnc])}})?\\s*\$",									'g1?1:-' ],
#	# '''headword''' {{?????|translit}} {{m}}
#	[ "^'''.*?'''(?:\\s+{{(?:IPAchar|unicode)\\|.*?}})?(?:\\s+{{([mfnc])}})?\\s*\$",	'g1?1:-' ],
#	# '''headword''' {{?????|translit}} ''m''
#	[ "^'''.*?'''(?:\\s+{{(?:IPAchar|unicode)\\|.*?}})?(?:\\s+''([mfnc])'')?\\s*\$",	'g1?1:-' ],
#	# '''headword'''
#	[ "^'''.*?'''\\s*\$",																'g-' ],
#	# '''{{Script|headword}}''' (translit) {{m}}
#	# '''{{SCchar|headword}}''' (translit) {{m}}
#	# {{SCchar|'''headword'''}} (translit) {{m}}
#	# {{SCchar|headword}} (translit) {{m}}
#	# Careful - this one is actually for "mf" pairs (not invariants)
#	[ "^{{$lang_code-noun-mf\\|f(?:emale)?=",											'gm' ],
#	[ "^{{$lang_code-noun-(m|f|n|c|mf|fm)\\b",											'g1' ],
#	[ "^{{$lang_code-noun2?\\|(m|f|n|c|mf|fm)\\b",										'g1' ],
#	[ "^{{$lang_code-noun2?\\|g(?:ender)?=(m|f|n|c|mf|fm)\\b",							'g1' ],
#	[ "^{{infl\\|$lang_code\\|noun(?:\\|g(?:ender)?=([mfnc]))?\\b",						'g1?1:-' ],
#	[ "^'''.*?'''\\s+\\((?:'')?plural:?(?:'')?:? '''.*?'''\\)(?:\\s+{{([mfnc])}})?",	'g1?1:-' ],
#];
#
#my @scope;
#
#my $maxpages = 0;
#my $pagecounter = 0;
#
#my $tried_to_parse = 0;
#my $parsed_ok = 0;
#
#my %langnamestocodes;
#my %namespaces;
#my %titles;
#
#my $xline;
#
#while ($xline = <STDIN>) {
#	last if ($xline =~ /<namespaces>/);
#}
#
#if ($xline !~ /<namespaces>/) {
#	print STDERR "** namespaces section not found\n";
#	exit;
#}
#
#print STDERR "** found namespaces\n";
#
#while ($xline = <STDIN>) {
#	if ($xline =~ /<namespace key="-?\d+"(.*)>/) {
#		my $rest = $1;
#		if ($rest =~ />(.*)<\/namespace/) {
#			$namespaces{$1} = 1;
#		}
#	} else {
#		last;
#	}
#}
#
#if ($xline !~ /<\/namespaces>/) {
#	print STDERR "** end of namespaces section not found\n";
#	exit;
#}
#
#print STDERR "** namespaces done\n";
#
#my $nsre = '^(' . join('|', 'webster 1913', keys %namespaces) . '):(.*)$';
#
#print "<wiktionary>\n";
#
#my %gendercount;
#
## One page reference that will be used over and over
##my $page;					# a page is an article
#
## Each line of dump file
#while (1) {
#
#	my $title = '';
#
#	while ($xline = <STDIN>) {
#		if ($xline =~ /<title>(.*)<\/title>/) {
#			$title = $1;
#			last;
#		}
#	}
#
#	if ($xline !~ /<title>.*<\/title>/) {
#		print STDERR "** no more pages";
#		show_headword_log();
#		exit;
#	}
#
#	my $ns = '';
#
#	# Check namespace
#	if ($title =~ /$nsre/o) {
#		$ns = $1;
#		$title = $2;
#	}
#
#	# Skip to start of wikitext
#	while ($xline = <STDIN>) {
#		last if ($xline =~ /<text xml:space="preserve">/);
#	}
#
#	# If we ever had an article record without a text record
#	if ($xline =~ /<title>.*<\/title>/) {
#		print STDERR "** $title has no text field\n";
#		exit;
#	}
#
#	if ($xline !~ /<text xml:space="preserve">/) {
#		print STDERR "** unexpected end of file while looking for $title's text field\n";
#		exit;
#	}
#
#	# Article wikitext?
#	if ($ns eq '') {
#
#		$pagecounter++;
#
#		# Does this mean new page references are allocated on the stack every time?
#		my $page;					# a page is an article
#
#		$page = {};
#		$page->{raw} = {};			# level 1 heading, root for tree of headings
#		$page->{cooked} = {};
#
#		@scope[0] = $page->{raw};
#
#		my $tline;					# line of wikitext to be parsed
#
#		my $prevsection;
#		my $section;				# each heading starts a new section
#
#		my $entry;					# each language heading starts a new entry
#
#		$page->{title} = $title;
#
#		$section = {};
#		$section->{level} = 1;
#		$section->{heading} = $title;
#		$section->{lines} = [];
#		$section->{sections} = [];
#
#		$prevsection = appendsection($section);
#
#		# Each line of page wikitext
#		while (1) {
#			$xline =~ /^\s*(?:<text xml:space="preserve">)?(.*?)(<\/text>)?$/;
#			my ($tline, $post) = ($1, $2);
#
#			last if ($post ne '');
#
#			# Heading
#			if ($tline =~ /^(==+)\s*([^=]+?)\s*(==+)\s*$/) {
#				$section = {};
#				$section->{unbalanced} = (length($1) != length($3));
#				my $level = length($1) < length($3) ? length($1) : length($3);
#				$section->{level} = $level;
#				my $headinglabel = $2;
#				if ($headinglabel =~ /^\[\[\s*(?:.*\|)?(.*?)\s*\]\]$/) {
#					$headinglabel = $1;
#				}
#				$section->{heading} = $headinglabel;
#				$section->{lines} = [];
#				$section->{sections} = [];
#
#				# Section more than 1 level deeper than its parent?
#				if ($prevsection->{level} - $level < -1) {
#					$section->{toodeep} = 1;
#				}
#
#				$prevsection = appendsection($section);
#			} # Heading
#			
#			# Not heading, just plain lines
#			else {
#				push @{$section->{lines}}, $tline;
#			}
#
#			last unless ($xline = <STDIN>);
#		} # while (1)
#
#		# Process raw section tree into a more structured entry
#		my $p = $page->{raw}->{sections}[0];
#		my $w = $p->{heading};
#
#		my @nouns;
#
#		# Collect all the noun sections we want to parse
#		# Each language in this page
#
#		foreach my $lang (@{$p->{sections}}) {
#			if ($lang->{heading} =~ /$lang_pat/o) {
#
#				my $etymcount = 0;
#				my $nouncount = 0;
#
#				# Each l3 heading: we care about Noun and Etymology
#				foreach my $l3 (@{$lang->{sections}}) {
#
#					# TODO handle l3=Etymology # + l4=Noun
#					if ($l3->{heading} =~ /^Noun(?: \d+)?$/) {
#						$l3->{etymcount} = 1;
#						$l3->{nouncount} = ++$nouncount;
#						push @nouns, $l3;
#					}
#					elsif ($l3->{heading} =~ /Noun/) {
#						print STDERR "** $w ** $l3->{heading}\n";
#					}
#					elsif ($l3->{heading} =~ /^Etymology \d+$/) {
#						print STDERR "** $w ** $l3->{heading}\n";
#
#						my $nouncount = 0;
#
#						# Each l4 subheading of an l3 Etymology subheading
#						foreach my $l4 (@{$l3->{sections}}) {
#
#							# TODO handle l3=Etymology # + l4=Noun
#							if ($l4->{heading} =~ /^Noun(?: \d+)?$/) {
#								$l4->{etymcount} = ++$etymcount;
#								$l4->{nouncount} = ++$nouncount;
#								push @nouns, $l4;
#							}
#							elsif ($l4->{heading} =~ /Noun/) {
#								print STDERR "** $w ** $l4->{heading}\n";
#							}
#						}
#					}
#				}
#				last;	# Skip the following language entries
#			}
#		}
#
#		# Parse all the noun sections we collected
#		my $t;
#		foreach my $ns (@nouns) {
#			# START process noun body
#			my ($ln, $l);
#			for ($ln = 0; $ln < scalar @{$ns->{lines}}; ++$ln) {
#				$t = $ns->{lines}[$ln];
#
#				# Ignore certain lines
#				if ($t =~ /^\s*$/ || $t =~ /^{{wikipedia(?:Alt)?\|/ || $t =~ /^\[\[Category:[^]]*]]/) {				# }}
#					next;
#				# Did we get to the definitions already?
#				} elsif ($t =~ /^#/) {
#					last;
#				# Anything else will be treated as a headword/inflection line
#				} else {
#					$l = $t;
#					last;
#				}
#			}
#
#			my $g = undef;	# gender (m, f, n, c, ...)
#			my $n = undef;	# number (singular, plural, ...)
#
#			#next if ($l eq undef);
#			if ($t !~ /^#/) {
#
#				# Parse the headword/inflection line for gender and number
#
#				++$tried_to_parse;
#
#				# Gender template
#				if ((my $hw = parse_headword($l))) {
#					$g = $hw->{g};
#					$n = $hw->{n}
#				}
#
#				if ($g) {
#					++$parsed_ok;
#					++$gendercount{$g};
#					#print "$w :: $g\n";
#				} else {
#					print STDERR "$w : $l\n";
#				}
#
#				#print STDERR "$w - nouns: $tried_to_parse, parsed: $parsed_ok",
#				#	", genders: ", $parsed_ok - $gendercount{'-'};
#
#				#foreach (keys %gendercount) {
#				#	print STDERR ", $_: ", $gendercount{$_};
#				#}
#				#print STDERR "\n";
#			}
#
#			# END parse headword/inflection line
#
#			while (++$ln < scalar @{$ns->{lines}}) {
#				$t = $ns->{lines}[$ln];
#				#print STDERR ".. $t\n";
#				# Ignore certain lines
#				if ($t =~ /^\s*$/) {
#					next;
#				# Anything else will be treated as the start of the definition lines
#				} else {
#					last;
#				}
#			}
#
#			# START process definitions
#			while ($ln < scalar @{$ns->{lines}}) {
#				$t = $ns->{lines}[$ln++];
#				#print STDERR "** def? $t\n";
#				# Definition line?
#				if ($t =~ /^#/) {
#					if ($t =~ /^#\s*(?:[aA]n?\s*)?\[\[([^\]#\|]*)(?:#[^\]\|]*)?(?:\|[^\]]*)?]]\.?\s*$/) {
#						my $tw = $1;
#
#						# Hebrew glosses sometimes contain bogus trailing text direction marks
#						print STDERR "** gloss contains direction marks!\n" if ($tw =~ /\x{200f}/);
#						$tw =~ s/\x{200f}+$//;
#
#						# A link with a # but no page name means the same spelling as the English word
#						$tw = $tw ? $tw : $w;
#
#						my ($en, $nn) = ($ns->{etymcount}, $ns->{nouncount});
#						print "$w $en.$nn [$g] $tw\n";
#					} else {
#						#print STDERR "** unparsable def: $t\n";
#						print STDERR "U $w : $t\n";
#					}
#
#					# Eat following lines that are part of the same definition
#					while ($ln < scalar @{$ns->{lines}}) {
#						$t = $ns->{lines}[$ln++];
#						#print STDERR "** eat? $t\n";
#						# Ignore certain lines
#						if ($t =~ /^#[#*:]/) {
#							#print STDERR "** eating: $t\n";
#							next;
#						# Anything else will be treated as the start of the definition lines
#						} else {
#							#print STDERR "** done eating: $t\n";
#							--$ln;
#							last;
#						}
#					}
#				# Anything else will be treated as the end of the Noun section
#				} else {
#					if ($t !~ /^\s*$/) {
#						print STDERR "E $w : $t\n";
#					}
#					last;
#				}
#			}
#			# END process definitions
#
#			# END process noun body
#		}
#	}
#
#	# Skip remainder of page
#	while ($xline = <STDIN>) {
#		last if ($xline =~ /<\/page>/);
#	}
#	if ($xline !~ /<\/page>/) {
#		print STDERR "** unexpected end of file in $title\n";
#		exit;
#	}
#
#	# Enough pages processed?
#	if ($ns eq '') {
#		if ($maxpages != 0 && $pagecounter >= $maxpages) {
#			print STDERR "** max number of pages parsed\n";
#			print "</wiktionary>\n";
#			show_headword_log();
#			exit;
#		}
#	}
#} # while (1)
#
#######################################################
#
#sub emitsection {
#	my $s = shift;
#
#	my $ot = '<s';
#	#$ot .= ' c="' . scalar @{$_->{sections}} . '"';
#	$ot .= " l=\"$s->{level}\"";
#	$ot .= " h=\"$s->{heading}\"";
#	if ($s->{toodeep}) {
#		$ot .= ' td';
#	}
#	if ($s->{unbalanced}) {
#		$ot .= ' ub';
#	}
#	$ot .= ">\n";
#	print $ot;
#	foreach (@{$s->{lines}}) {
#		print "<x>$_</x>\n";
#	}
#	foreach (@{$s->{sections}}) {
#		emitsection($_);
#	}
#	print "</s>\n";
#}
#
##
## @scope is a global, should be a member I guess
##
#
#sub appendsection {
#	my $section = shift;
#
#	# This make a circular reference which prevents garbage collection!
#	#$section->{parent} = @scope[$section->{level} - 1];
#	push @{@scope[$section->{level} - 1]->{sections}}, $section;
#
#	for (my $l = $section->{level}; $l <= 7; ++$l) {
#		@scope[$l] = $section;
#	}
#
#	return $section;
#}
#
#################################################################
#
#sub parse_headword {
#	my $l = shift;
#
#	my $success = 0;	# set to 0 if no matches succeed
#	my $g;				# gender: m:masculine f:feminine n:neuter c:common or some combination
#	my $n;				# number: s:singular p:plural d:dual
#
#	for (my $i = 0; $i < scalar @$headword_matchers; ++$i) {
#		if ($l =~ /$headword_matchers->[$i]->[0]/) {
#			$success = 1;
#			++$headword_matchers->[$i]->[2];
#			if ($headword_matchers->[$i]->[1]      eq 'g1,n2?p') {
#				$g = $1; $n = 'p' if ($2);
#			} elsif ($headword_matchers->[$i]->[1] eq 'g1') {
#				$g = $1;
#			} elsif ($headword_matchers->[$i]->[1] eq 'g1,n2:p') {
#				$g = $1; $n = 'p' unless ($2);
#			} elsif ($headword_matchers->[$i]->[1] eq 'g1,np') {
#				$g = $1; $n = 'p';
#			} elsif ($headword_matchers->[$i]->[1] eq 'g1+2') {
#				$g = $1 . $2;
#			} elsif ($headword_matchers->[$i]->[1] eq 'g1?1:-') {
#				$g = $1 ? $1 : '-';
#			} elsif ($headword_matchers->[$i]->[1] eq 'g-') {
#				$g = '-';
#			} elsif ($headword_matchers->[$i]->[1] eq 'gm') {
#				$g = 'm';
#			} else {
#				print STDERR "** unknown gender/number opcode '", $headword_matchers->[$i]->[1], "'\n";
#			}
#			last;
#		}
#	};
#
#	if ($success) {
#		return { 'g' => $g, 'n' => $n };
#	} else {
#		return undef;
#	}
#}
#
#sub show_headword_log() {
#	for (my $i = 0; $i < scalar @$headword_matchers; ++$i) {
#		print $headword_matchers->[$i]->[2], ' : ', $headword_matchers->[$i]->[0], "\n";
#	}
#}
#
