#!/usr/bin/perl -I/home/hippietrail/lib

# random en.wiktionary page per language

use strict;

use CGI;
use FCGI;
use Getopt::Long;
use MediaWiki::API;
use URI::Escape;

binmode STDOUT, ':utf8';

my $PAGE_LIST_PATH = '/home/hippietrail/buxxo';
my $scriptmode = 'cli';

# initialize
my $cli_retval = -1; # fail by default

my %cache;

my $mw = MediaWiki::API->new();
$mw->{config}->{api_url} = 'http://en.wiktionary.org/w/api.php';

# FastCGI loop

while (FCGI::accept >= 0) {
    my %opts = ('langname' => 'English');                    
    
    # get command line or cgi args
    CliOrCgiOptions(\%opts, qw{dumpsource langname langcode langs}); 
        
    # process this request

    # MediaWiki functions can result in spaces becomeing pluses
    $opts{langname} =~ s/\+/ /g if (exists $opts{langname});

    if (exists $opts{dumpsource}) {
        $cli_retval = dumpsource();
        next;
    }

    if (exists $opts{langs}) {
        my $q = CGI->new;
        print $q->header(-charset=>'UTF-8');
        print $q->start_html(-title=>'Random Wiktionary entry by language');
        my @files = <$PAGE_LIST_PATH/*>;
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
    } else {
        if (exists $opts{langcode}) {
            $opts{langname} = '';
            my $json;
            my $ok = 0;
            if ($json = $mw->api( { action => 'expandtemplates',
                                    text   => '{{' . $opts{langcode} . '}}' } )) {
                my $et = $json->{expandtemplates}->{'*'};
                $et =~ /^([^:]+): /g;
                my $c = $1;
                if ($et =~ /\G(?:(?:\[\[)?([^];]*)(?:]])?(?: \((.*)\))?)$/s) {
                    if ($1 && $1 !~ /[[|<*]/s && $1 ne "\n") {  # catch false positives
                        if (index($1, ':Template:') == -1) {
                            $ok = 1;
                        }
                    }
                }
                if ($ok) {
                    $opts{langname} = $2 ? $1 . ' (' . $2 . ')' : $1;
                }
            }
        }
        if (!$opts{langname}) {
            $cli_retval = dumperr(exists $opts{langcode} ? 'can\'t find language for code'
                                           : 'no language name specified');

        } elsif (open(FILE, "<:utf8", $PAGE_LIST_PATH . '/' . $opts{langname} . '.txt')) {
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
            my $title = $words->[$r];
            chomp $title;

            if (substr($opts{langname}, 0, 1) eq '_') {
                if ($opts{langname} ne '_Redirect' && substr($opts{langname}, 0, 10) ne '_Category:') {
                    $title = substr($opts{langname}, 1) . ':' . $title;
                }
            }

            $cli_retval = dumpresults($opts{langname}, $title, $iscached);
        } else {
            $cli_retval = dumperr("couldn't open word file for '$opts{langname}'");
        }
    }
}

exit $cli_retval;

##########################################

sub CliOrCgiOptions {
    my $opts = shift;
    my @optnames = @_;
    
    if (exists($ENV{'QUERY_STRING'})) {
        $scriptmode = 'cgi';

        my %q = map { split('=') } split('&', $ENV{'QUERY_STRING'});

        foreach my $o (@optnames) {
            $opts->{$o} = uri_unescape($q{$o}) if (exists $q{$o});
        }
    } else {
        GetOptions($opts, map { $_ . '=s', } @optnames);
    }
}

sub dumpresults {
    my $langname = shift;
    my $word = shift;
    my $iscached = shift;

    # XXX should this just use $word or uri_escape_utf8($word) ?
    # TODO build with URI module. it would avoid prolems like where I had a ? where an & belonged
    my $url = 'http://en.wiktionary.org/wiki/' . $word;

    $url .= '?rndlangcached=' . ($iscached ? 'yes' : 'no');

    # Needed so that Wiktionary can create a "go again" link
    $url .= '&rndlang=' . uri_escape($langname);

    if (substr($langname, 0, 1) ne '_') {
        my $frag = uri_escape($langname);
        $frag =~ s/%20/_/g;
        $frag =~ s/%/./g;
        $url .= '#' . $frag;
    }

    if ($scriptmode eq 'cgi') {
        # XXX FGCI.pm <= 0.68 behaviour
        # XXX we're outputting UTF-8 but FCGI doesn't have a way to set binmode utf8
        # TODO what's the correct way to turn a UTF-8 string into a raw byte string?
        use bytes;
        print CGI->new->redirect(-uri=>$url, -status=>303);
    } else {
        print "How about the nice $langname word '$word' ";
        print $iscached ? "which I just happened to have lying around"
                        : "which I've gone to a bit of trouble to get for you";
        print "?\n";

        print "\n$url\n\n";
    }

    return 0; # cli success
}

sub dumperr {
    my $err = shift;

    # we must output the HTTP headers to STDOUT before anything else
    $scriptmode eq 'cgi' && print "Content-type: text/plain; charset=UTF-8\n\n";

    # do output
    print "** ERROR: $err\n";

    return -1; # cli failure
}

sub dumpsource {
    my $retval = -1;
    my $path = $scriptmode eq 'cgi' ? $0 : "/home/hippietrail/$0";

    # we must output the HTTP headers to STDOUT before anything else
    $scriptmode eq 'cgi' && print "Content-type: text/plain; charset=UTF-8\n\n";

    if (open(SRC, $path)) {
        while (<SRC>) {
            print;
        }
        close SRC;
        $retval = 0; # cli success
    } else {
        print "couldn't open $path\n"
    }

    return $retval;
}
