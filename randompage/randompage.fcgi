#!/usr/bin/perl -I/home/hippietrail/lib

# random en.wiktionary page per language

use utf8;
use strict;

use CGI;
use CGI::Util;
use FCGI;
use Getopt::Long;

my $scriptmode = 'cli';

# initialize
my %cache;

# FastCGI loop

while (FCGI::accept >= 0) {
    my %opts = ('langname' => 'English');                    
    
    # get command line or cgi args
    CliOrCgiOptions(\%opts, qw{langname langs}); 
        
    # process this request

    if (exists $opts{langs}) {
        my $q = CGI->new;
        print $q->header(-charset=>'UTF-8');
        print $q->start_html(-title=>'Random Wiktionary entry by language');
        my @files = </home/hippietrail/buxxo/*>;
        my $half = int((scalar @files + 1) / 2);
        print "<table><tr><td><ul>";
        for (my $i = 0; $i < $half; ++$i) {
            if (substr($files[$i],-4) eq '.txt') {
                print '<li><a href="http://toolserver.org/~hippietrail/randompage.fcgi?langname=', substr($files[$i],24,-4), '">', substr($files[$i],24,-4), "</a></li>\n"
            }
        } 
        print "</ul></td><td><ul>";
        for (my $i = $half; $i < scalar @files; ++$i) {
            if (substr($files[$i],-4) eq '.txt') {
                print '<li><a href="http://toolserver.org/~hippietrail/randompage.fcgi?langname=', substr($files[$i],24,-4), '">', substr($files[$i],24,-4), "</a></li>\n"
            }
        } 
        print "</ul></td></tr></table>";
        print $q->end_html;
    } elsif (!$opts{langname}) {
        dumperr("no language name specified");
    } elsif (open(FILE, "/home/hippietrail/buxxo/$opts{langname}.txt")) {
        my $iscached;
        my $words;

        if (exists $cache{$opts{langname}}) {
            $iscached = 1;
            $words = $cache{$opts{langname}};
        } else {
            $iscached = 0;

            # read file into an array
            my @words = <FILE>;
            $words = \@words;

            $cache{$opts{langname}} = $words;

            # close file 
            close(FILE);
        }

        my $numwords = scalar @$words;
        my $r = int(rand($numwords));
        my $w = $words->[$r];
        chomp $w;

        dumpresults($opts{langname}, $w, $iscached);
    } else {
        dumperr("couldn't open word file for '$opts{langname}'");
    }
}

exit;

##########################################

sub CliOrCgiOptions {
    my $opts = shift;
    my @optnames = @_;
    
    if (exists($ENV{'QUERY_STRING'})) {
        $scriptmode = 'cgi';

        my %q = map { split('=') } split('&', $ENV{'QUERY_STRING'});

        foreach my $o (@optnames) {
            $opts->{$o} = CGI::Util::unescape($q{$o}) if (exists $q{$o});
        }
    } else {
        GetOptions($opts, map { $_ . '=s', } @optnames);
    }
}

sub dumpresults {
    my $langname = shift;
    my $word = shift;
    my $iscached = shift;

	binmode(STDOUT, 'utf8');

    my $url = 'http://en.wiktionary.org/wiki/' . $word;

    $url .= '?rndlangcached=' . ($iscached ? 'yes' : 'no');
    $url .= '#' . $langname;

    if ($scriptmode eq 'cgi') {
        print CGI->new->redirect(-uri=>$url, -status=>303);
    } else {
        print "How about the nice $langname word '$word' ";
        print $iscached ? "which I just happened to have lying around"
                        : "which I've gone to a bit of trouble to get for you";
        print "?\n";

        print "\n$url\n\n";
    }
}

sub dumperr {
    my $err = shift;

    # we must output the HTTP headers to STDOUT before anything else
	binmode(STDOUT, 'utf8');
    $scriptmode eq 'cgi' && print "Content-type: text/plain; charset=UTF-8\n\n";

    # do output
    print "** ERROR: $err\n";
}
