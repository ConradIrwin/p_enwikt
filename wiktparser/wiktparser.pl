#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

my $maxpages = 100000;
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

		my $page;				# a page is an article

		$page = {};
		$page->{title} = $title;
		$page->{sections} = [];		# each heading starts a section

		@scope[1] = $page;

		my $tline;

		my $entry;					# each language heading starts an entry

		my $section;				# each heading starts a section

		my $prevsection;

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
				$section->{heading} = {};
				my $headinglabel = $2;
				if ($headinglabel =~ /^\[\[\s*(?:.*\|)?(.*?)\s*\]\]$/) {
					$headinglabel = $1;
				}
				$section->{heading}->{label} = $headinglabel;
				$section->{lines} = [];
				$section->{sections} = [];

				# Language heading
				if ($level ==2) {
					my $langname = $headinglabel;
					#my $langcode = $langnamestocodes{$langname};
					my $lang;
					if (exists $langnamestocodes{$langname}) {
						$lang = '<' . join('|', @{$langnamestocodes{$langname}}) . '>';
					} else {
						$lang = $langname;
					}
					#push @{$page->{langs}}, $lang . ':' . $level;
					#$entry = {};
					#$entry->{emitme} = 0;
					#$entry->{lang} = {};
					#$entry->{lang}->{label} = $langname;
					#if (exists $langnamestocodes{$langname}) {
					#	$entry->{lang}->{code} = $langnamestocodes{$langname}[0];
					#}
					#$entry->{sections} = [];

					#$entry->{parent} = $page;
					#push @{$page->{sections}}, $entry;

					#$section->{parent} = $page;
					#push @{$page->{sections}}, $section;

					#$section->{parent} = @scope[$level - 1];
					#push @{@scope[$level - 1]->{sections}}, $section;

					#for (my $l = $level; $l <= 7; ++$l) {
					#	@scope[$l] = $section;
					#}

					#for (my $l = $level; $l <= 7; ++$l) {
					#	@scope[$l] = $entry;
					#}
				}

				# Other headings
				else {
					if ($prevsection->{level} - $level < -1) {
						print STDERR "$page->{title}::$section->{heading}->{label} prev level $prevsection->{level}, this level $level\n";
					}
					#$section->{parent} = @scope[$level - 1];
					#push @{@scope[$level - 1]->{sections}}, $section;

					#for (my $l = $level; $l <= 7; ++$l) {
					#	@scope[$l] = $section;
					#}
				}

				$section->{parent} = @scope[$level - 1];
				push @{@scope[$level - 1]->{sections}}, $section;

				for (my $l = $level; $l <= 7; ++$l) {
					@scope[$l] = $section;
				}

				$prevsection = $section;
			} # Heading
			
			else {
				# Not heading
				if ($section) {
					push @{$section->{lines}}, $tline;
				}
			}

			last unless ($xline = <STDIN>);
		} # while (1)

		# Emit page
		print "<a c=\"" . scalar @{$page->{sections}} . "\" l=\"1\" h=\"$page->{title}\">\n";
		foreach (@{$page->{sections}}) {
			#print "<e c=\"" . scalar @{$_->{sections}} . "\" l=\"2\" h=\"$_->{lang}->{label}\">\n";
			print "<e c=\"" . scalar @{$_->{sections}} . "\" l=\"$_->{level}\" h=\"$_->{heading}->{label}\">\n";
			if ($_->{unbalanced}) {
				print "<unbalanced />\n";
			}
			foreach (@{$_->{lines}}) {
				print "<x>$_</x>\n";
			}
			foreach (@{$_->{sections}}) {
				print "<s c=\"" . scalar @{$_->{sections}} . "\" l=\"$_->{level}\" h=\"$_->{heading}->{label}\">\n";
				if ($_->{unbalanced}) {
					print "<unbalanced />\n";
				}
				foreach (@{$_->{lines}}) {
					print "<x>$_</x>\n";
				}
				foreach (@{$_->{sections}}) {
					print "<s c=\"" . scalar @{$_->{sections}} . "\" l=\"$_->{level}\" h=\"$_->{heading}->{label}\">\n";
					if ($_->{unbalanced}) {
						print "<unbalanced />\n";
					}
					foreach (@{$_->{lines}}) {
						print "<x>$_</x>\n";
					}
					foreach (@{$_->{sections}}) {
						print "<s c=\"" . scalar @{$_->{sections}} . "\" l=\"$_->{level}\" h=\"$_->{heading}->{label}\">\n";
						if ($_->{unbalanced}) {
							print "<unbalanced />\n";
						}
						foreach (@{$_->{lines}}) {
							print "<x>$_</x>\n";
						}
						foreach (@{$_->{sections}}) {
							print "<s c=\"" . scalar @{$_->{sections}} . "\" l=\"$_->{level}\" h=\"$_->{heading}->{label}\">\n";
							if ($_->{unbalanced}) {
								print "<unbalanced />\n";
							}
							foreach (@{$_->{lines}}) {
								print "<x>$_</x>\n";
							}
							print "</s>\n";
						}
						print "</s>\n";
					}
					print "</s>\n";
				}
				print "</s>\n";
			}
			print "</e>\n";
		}
		print "</a>\n";
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
