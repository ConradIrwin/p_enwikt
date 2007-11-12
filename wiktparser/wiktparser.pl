#! /usr/bin/perl
# vi: ts=4 sw=4 sts=4

use strict;

use Getopt::Std;

use Wiki::DumpParser;
use Wiki::WiktLang;
use Wiki::WiktParser;

my %opts;
my $lang;

getopt('lL', \%opts);

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
my $pagecounter = 0;
my $xline;
my $tried_to_parse = 0;
my $parsed_ok = 0;
my %gendercount;

my $dumpparser = new Wiki::DumpParser;
my $wiktparser = new Wiki::WiktParser;

if ($dumpparser && $wiktparser) {
	$dumpparser->set_title_handler( \&title_handler );
	$dumpparser->set_text_handler( \&text_handler );

	$wiktparser->set_lang_code( $lang->{code} );

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

sub text_handler {
	$wiktparser->parse( $namespace, \$pagecounter, $title, \$xline, $lang->{pattern}, \$tried_to_parse, \$parsed_ok, \%gendercount );
}

