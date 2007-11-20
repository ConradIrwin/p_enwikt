#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

use Wiki::DumpParser;
use Wiki::WiktParser;

use WiktParser::Source;

my $namespace;
my $title;

my %langnamestocodes;
my $langcodetemplate_counter;
my $langcodetemplate2_counter;

my %langcodestonames;
my $interwiktionary_counter;
my $ethnologue_counter;

my $dumpparser = new Wiki::DumpParser;
my $wiktparser = new Wiki::WiktParser;

my $source = new WiktParser::Source::Stdin;

if ($dumpparser && $wiktparser && $source) {
	$dumpparser->set_source( $source );
	$dumpparser->set_title_handler( \&title_handler );
	$dumpparser->set_text_handler( \&text_handler );

	$wiktparser->set_source( $source );
	$wiktparser->set_template_handler( \&template_handler );
	$wiktparser->set_article_handler( \&article_handler );

	$dumpparser->set_maxpages(2375);
	$dumpparser->parse();
}

print "Names to codes\n";
print "--------------\n";

my %nametosyns;
my @namesets;

foreach my $n (sort keys %langnamestocodes) {

	if (exists $nametosyns{$n}) {
		print "** $n already done\n";
	} else {
		my %syns;
		foreach my $c (keys %{$langnamestocodes{$n}}) {
			foreach my $n2 (keys %{$langcodestonames{$c}}) {
				$syns{$n2}++;
			}
		}
		print $n, ' -> ', join(', ', keys %syns), ' -> ', join(', ', keys %{$langnamestocodes{$n}}), "\n";
		foreach my $syn (%syns) {
			$nametosyns{$syn} = \%syns;
		}
		push @namesets, \%syns;
	}
}

print "\n";

print "Codes to names\n";
print "--------------\n";

my %codetosyns;
my @codesets;

foreach my $c (sort keys %langcodestonames) {

	if (exists $codetosyns{$c}) {
		print "** $c already done\n";
	} else {
		my %syns;
		foreach my $n (keys %{$langcodestonames{$c}}) {
			foreach my $c2 (keys %{$langnamestocodes{$n}}) {
				$syns{$c2}++;
			}
		}
		print $c, ' -> ', join(', ', keys %syns), ' -> ', join(', ', keys %{$langcodestonames{$c}}), "\n";
		foreach my $syn (%syns) {
			$codetosyns{$syn} = \%syns;
		}
		push @codesets, \%syns;
	}
}

print "\n";

print "Names to codes 2\n";
print "----------------\n";

foreach (@namesets) {
	my @k1 = keys %{$_};
	my @k2 = keys %{$langnamestocodes{$k1[0]}};
	print join(', ', @k1), "\t", join(', ', keys %{$codetosyns{$k2[0]}}), "\n";
}

print "\n";

print "Codes to names 2\n";
print "----------------\n";

foreach (@codesets) {
	my @k1 = keys %{$_};
	my @k2 = keys %{$langcodestonames{$k1[0]}};
	print join(', ', @k1), "\t", join(', ', keys %{$nametosyns{$k2[0]}}), "\n";
}

exit;

#######################################################

sub title_handler {
	my ($ns, $t) = @_;
	$namespace = $ns;
	$title = $t;
}

sub text_handler {
	$wiktparser->parse( $namespace, $title );
}

sub template_handler {

	if ($title =~ /^(lang:)?([a-z][a-z][a-z]?)$/) {
		my ($which, $langcode) = ($1, $2);

		if ($source->line() =~ /<text xml:space="preserve">(.*?)&lt;noinclude&gt;\[\[Category:Language templates|$title]]&lt;\/noinclude&gt;<\/text>/) {
			my $langname = $1;
			if ($langname =~ /^\[\[(?:.*\|)?(.*?)]]$/) {
				$langname = $1;
			}

			if ($langname ne '') {
				$langnamestocodes{$langname}->{$langcode}++;
				$langcodestonames{$langcode}->{$langname}++;
				if ($which eq '') {
					++$langcodetemplate_counter;
					print STDERR "** t1 $langcodetemplate_counter: $langname -> $langcode\n";
				} else {
					++$langcodetemplate2_counter;
					print STDERR "** t2 $langcodetemplate2_counter: $langname -> $langcode\n";
				}
			}
		}
	}
}

sub article_handler {

	# Each line of page wikitext
	while (1) {
		$source->line() =~ /^\s*(?:<text xml:space="preserve">)?(.*?)(<\/text>)?$/;
		my ($tline, $post) = ($1, $2);

		last if ($post ne '');

		if ($tline =~ /^{{ethnologue\|code=([a-z][a-z][a-z]?)}}\s*/) {
			my $langcode = $1;

			$langcodestonames{$langcode}->{$title}++;
			$langnamestocodes{$title}->{$langcode}++;
			++$ethnologue_counter;
			print STDERR "** eth $ethnologue_counter: $langcode -> $title\n";
		} elsif ($tline =~ /^{{interwiktionary\|code=([a-z][a-z][a-z]?)}}\s*/) {
			my $langcode = $1;

			$langcodestonames{$langcode}->{$title}++;
			$langnamestocodes{$title}->{$langcode}++;
			++$interwiktionary_counter;
			print STDERR "** iw  $interwiktionary_counter: $langcode -> $title\n";
		}

		last unless ($source->nextline());
	}
}

