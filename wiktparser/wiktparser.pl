#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

use Getopt::Std;

use Wiki::DumpParser;
use Wiki::WiktLang;
use Wiki::WiktParser;

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

if ($lang) {
	print "code:$lang->{code} pat:$lang->{pattern}\n";
} else {
	die "Couldn't find language\n";
}

my $namespace;
my $title;

my $line;						# TODO this is used as though it's a member of both parsers

my $dumpparser = new Wiki::DumpParser;
my $wiktparser = new Wiki::WiktParser;

if ($dumpparser && $wiktparser) {
	$dumpparser->set_title_handler( \&title_handler );
	$dumpparser->set_text_handler( \&text_handler );

	$wiktparser->set_lang( $lang->{code}, $lang->{pattern} );

	if ($opts{x}) {
		$dumpparser->set_maxpages( $opts{x} );
	}

	$dumpparser->parse( \$line );

	$dumpparser->show_page_counts;
	$wiktparser->show_headword_log;
}

exit;

#######################################################

sub title_handler {
	my ($ns, $t) = @_;
	$namespace = $ns;
	$title = $t;
}

sub text_handler {
	$wiktparser->parse( $namespace, $title, \$line );
}

