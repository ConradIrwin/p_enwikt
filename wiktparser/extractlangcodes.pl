#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

use Wiki::DumpParser;
use Wiki::WiktParser;

use WiktParser::Source;

my $namespace;
my $title;

my %langnamestocodes;			# TODO change to map to handle duplicates better
my $langcodetemplate_counter;
my $langcodetemplate2_counter;

my %langcodestonames;			# TODO change to map to handle duplicates better
my $interwiktionary_counter;
my $ethnologue_counter;

my $dumpparser = new Wiki::DumpParser;
my $wiktparser = new Wiki::WiktParser;

if ($dumpparser && $wiktparser) {
	$dumpparser->set_title_handler( \&title_handler );
	$dumpparser->set_text_handler( \&text_handler );

	$wiktparser->set_template_handler( \&template_handler );
	$wiktparser->set_article_handler( \&article_handler );

	$dumpparser->set_maxpages(2000);
	$dumpparser->parse();
}

print "Names to codes\n";

foreach my $n (sort keys %langnamestocodes) {
	print $n, ' -> ', join(', ', @{$langnamestocodes{$n}}), "\n";

	foreach my $c (@{$langnamestocodes{$n}}) {
		print '  ', $c, ' -> ', $langcodestonames{$c} ? join(', ', @{$langcodestonames{$c}}) : '-', "\n";
	}
}

print "\n";

print "Codes to names\n";

foreach my $c (sort keys %langcodestonames) {
	print $c, ' -> ', join(', ', @{$langcodestonames{$c}}), "\n";

	foreach my $n (@{$langcodestonames{$c}}) {
		print '  ', $n, ' -> ', $langnamestocodes{$n} ? join(', ', @{$langnamestocodes{$n}}) : '-', "\n";
	}
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

		if ($WiktParser::Source::line =~ /<text xml:space="preserve">(.*?)&lt;noinclude&gt;\[\[Category:Language templates|$title]]&lt;\/noinclude&gt;<\/text>/) {
			my $langname = $1;
			if ($langname =~ /^\[\[(?:.*\|)?(.*?)]]$/) {
				$langname = $1;
			}

			if ($langname ne '') {
				push @{$langnamestocodes{$langname}}, $langcode;
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
		$WiktParser::Source::line =~ /^\s*(?:<text xml:space="preserve">)?(.*?)(<\/text>)?$/;
		my ($tline, $post) = ($1, $2);

		last if ($post ne '');

		if ($tline =~ /^{{ethnologue\|code=([a-z][a-z][a-z]?)}}\s*/) {
			my $langcode = $1;

			push @{$langcodestonames{$langcode}}, $title;
			++$ethnologue_counter;
			print STDERR "** eth $ethnologue_counter: $langcode -> $title\n";
		} elsif ($tline =~ /^{{interwiktionary\|code=([a-z][a-z][a-z]?)}}\s*/) {
			my $langcode = $1;

			push @{$langcodestonames{$langcode}}, $title;
			++$interwiktionary_counter;
			print STDERR "** iw  $interwiktionary_counter: $langcode -> $title\n";
		}

		last unless (WiktParser::Source::nextline());
	}
}

