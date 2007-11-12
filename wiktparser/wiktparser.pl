#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

my $maxpages = 0;
my $pagecounter = 0;

my %langnamestocodes;
my %namespaces;
my %titles;

my $xline;

while ($xline = <STDIN>) {
	last if ($xline =~ /<namespaces>/);
}

if ($xline !~ /<namespaces>/) {
	print STDERR "namespaces section not found\n";
	exit;
}

print STDERR "found namespaces\n";

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
	print STDERR "end of namespaces section not found\n";
	exit;
}

print STDERR "namespaces done\n";

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
		print STDERR "no more pages";
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
		print STDERR "$title has no text field\n";
		exit;
	}

	if ($xline !~ /<text xml:space="preserve">/) {
		print STDERR "unexpected end of file while looking for $title's text field\n";
		exit;
	}

	# Language code template?
	if ($ns eq 'Template') {
		if ($title =~ /^(?:lang:)?([a-z][a-z][a-z]?)$/) {
			my $langcode = $1;

			if ($xline =~ /<text xml:space="preserve">(.*?)&lt;noinclude&gt;\[\[Category:Language templates|$title]]&lt;\/noinclude&gt;<\/text>/) {
				my $langname = $1;
				if ($langname =~ /^\[\[(?:.*\|)?(.*?)]]$/) {
					$langname = $1;
				}

				if ($langname ne '') {
					push @{$langnamestocodes{$langname}}, $langcode;
				}
			}
		}

	# Article wikitext?
	} elsif ($ns eq '') {

		$pagecounter++;

		my @scope;

		my $page;					# a page is an article

		$page = {};
		$page->{raw} = {};			# level 1 heading, root for tree of headings
		$page->{cooked} = {};

		@scope[0] = $page->{raw};

		my $tline;

		my $section;				# each heading starts a new section

		my $entry;					# each language heading starts a new entry

		my $prevsection;

		$page->{title} = $title;

		$section = {};
		my $level = 1;
		$section->{level} = $level;
		$section->{heading} = $title;
		$section->{lines} = [];
		$section->{sections} = [];

		$section->{parent} = @scope[$level - 1];
		push @{@scope[$level - 1]->{sections}}, $section;

		for (my $l = $level; $l <= 7; ++$l) {
			@scope[$l] = $section;
		}

		$prevsection = $section;

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
					$entry = {};
					if ($langname eq 'English') {
						$entry->{isen} = 1;
						$page->{hasen} = 1;
					} elsif ($langname eq 'Spanish') {
						$entry->{ises} = 1;
						$page->{hases} = 1;
					}
					#$entry->{emitme} = 0;
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
						print STDERR "$page->{title}::$section->{heading} prev level $prevsection->{level}, this level $level\n";
						#print STDERR "$page->{raw}->{sections}[0]->{heading}::$section->{heading} prev level $prevsection->{level}, this level $level\n";
					}
				}

				$section->{parent} = @scope[$level - 1];
				push @{@scope[$level - 1]->{sections}}, $section;

				for (my $l = $level; $l <= 7; ++$l) {
					@scope[$l] = $section;
				}

				$prevsection = $section;
			} # Heading
			
			else {
				# Not heading, just plain lines
				push @{$section->{lines}}, $tline;
			}

			last unless ($xline = <STDIN>);
		} # while (1)

		# Emit page
		emitsection($page->{raw}->{sections}[0]);
	}

	# Skip remainder of page
	while ($xline = <STDIN>) {
		last if ($xline =~ /<\/page>/);
	}
	if ($xline !~ /<\/page>/) {
		print STDERR "unexpected end of file in $title\n";
		exit;
	}

	# Enough pages processed?
	if ($ns eq '') {
		if ($maxpages != 0 && $pagecounter >= $maxpages) {
			print STDERR "max number of pages parsed\n";
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

#sub emitsection {
#	my $s = shift;
#
#	foreach (@{$s->{lines}}) {
#		print "<x>$_</x>\n";
#	}
#	foreach (@{$s->{sections}}) {
#		my $ot = '<s';
#		#$ot .= ' c="' . scalar @{$_->{sections}} . '"';
#		$ot .= " l=\"$_->{level}\"";
#		$ot .= " h=\"$_->{heading}\"";
#		if ($_->{toodeep}) {
#			$ot .= ' td="1"';
#		}
#		if ($_->{unbalanced}) {
#			$ot .= ' u="1"';
#		}
#		$ot .= ">\n";
#		print $ot;
#		emitsection($_);
#		print "</s>\n";
#	}
#}

