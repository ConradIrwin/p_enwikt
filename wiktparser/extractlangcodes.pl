#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

use Wiki::DumpParser;
use Wiki::WiktParser;

my $namespace;
my $title;

my $line;						# TODO this is used as though it's a member of both parsers

my $tried_to_parse = 0;			# TODO should be part of Wiki::WiktParser
my $parsed_ok = 0;				# TODO should be part of Wiki::WiktParser
my %gendercount;				# TODO should be part of Wiki::WiktParser

my %langnamestocodes;
my $langcodetemplate_counter;
my $langcodetemplate2_counter;

my %langcodestonames;
my $interwiktionary_counter;
my $ethnologue_counter;

my $dumpparser = new Wiki::DumpParser;
my $wiktparser = new Wiki::WiktParser;

if ($dumpparser && $wiktparser) {
	$dumpparser->set_title_handler( \&title_handler );
	$dumpparser->set_text_handler( \&text_handler );

	$wiktparser->set_template_handler( \&template_handler );
	$wiktparser->set_article_handler( \&article_handler );

	$dumpparser->parse( \$line );
}

print STDERR "** extractlangcodes.pl done\n";

exit;

#######################################################

sub title_handler {
	my ($ns, $t) = @_;
	$namespace = $ns;
	$title = $t;
}

sub text_handler {
	$wiktparser->parse(
		$namespace,
		$title,
		\$line,
		undef,
		\$tried_to_parse,
		\$parsed_ok,
		\%gendercount );
}

sub template_handler {
	my $line = shift;

	if ($title =~ /^(lang:)?([a-z][a-z][a-z]?)$/) {
		my ($which, $langcode) = ($1, $2);

		if ($$line =~ /<text xml:space="preserve">(.*?)&lt;noinclude&gt;\[\[Category:Language templates|$title]]&lt;\/noinclude&gt;<\/text>/) {
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
	my $line = shift;

	# Each line of page wikitext
	while (1) {
		$$line =~ /^\s*(?:<text xml:space="preserve">)?(.*?)(<\/text>)?$/;
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

		last unless ($$line = <STDIN>);
	}
}

