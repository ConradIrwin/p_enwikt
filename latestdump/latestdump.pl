#!/usr/bin/perl

# what are the latest dumps of en.wiktionary.org
# with no args outputs pretty format and writes latest dates to hidden files
# with any args outputs tab-delimited format and doesn't write to the files

use strict;

use Date::Parse;
use File::HomeDir;
use HTML::Parser;
use LWP::Simple;
use LWP::UserAgent;
use Tie::TextDir;
use Time::Duration;
use URI::Escape;
use XML::Parser::Lite;

my $botmode = exists $ARGV[0];

my $res = latest_official();
my $res2 = latest_devtionary();

####

my $last;
my $last2;

unless ($botmode) {
    tie my %home, 'Tie::TextDir', home(), 'rw';  # Open in read/write mode

    if ($res) {
        if (exists $home{'.enwikt'}) {
            $last = $home{'.enwikt'}
        }
        $home{'.enwikt'} = $res->[0];
    }

    if ($res2) {
        if (exists $home{'.enwikt2'}) {
            $last2 = $home{'.enwikt2'}
        }
        $home{'.enwikt2'} = $res2->[0];
    }

    untie %home;
}

####

my $now = time;

if ($botmode) {
    print "official\t$res->[0]\t", $res->[2],"\n" if ($res);
    print "devtionary\t$res2->[0]\t", $res2->[2], "\n" if ($res2);
} else {
    print 'official dump: ',
        'last: ', ($last ? $last : 'none'),
        ', latest: ', ($res ? $res->[0] : 'none'),
        ($last && $res && $res->[0] gt $last ? ' ** NEW **' : ''),
        $res ? ' ('. duration($now - $res->[2]). ' ago)' : '',
        "\n";
    print substr($res->[1], 0, -8), "\n\n" if ($res);

    print 'devtionary dump: ',
        'last: ', ($last2 ? $last2 : 'none'),
        ', latest: ', ($res2 ? $res2->[0] : 'none'),
        ($last2 && $res2 && $res2->[0] gt $last2 ? ' ** NEW **' : ''),
        $res2 ? ' ('. duration($now - $res2->[2]). ' ago)' : '',
        "\n";
    print $res2->[1], "\n\n" if ($res2);
}

exit;

###############################

sub latest_official {
    my $feeduri = 'http://download.wikipedia.org/enwiktionary/latest/enwiktionary-latest-pages-articles.xml.bz2-rss.xml';

    my $xml = get($feeduri);
    #my $rp = new XML::RSS::Parser::Lite;
    #my $rp = XML::RSS::Parser->new;
    my $rp = new XML::Parser::Lite;
    my $start;
    my $latest;
    my $pubdate;
    $rp->setHandlers(
        Start => sub { shift; $start = shift; },
        Char => sub {
                        shift; my $c = shift;
                        $latest = $c if ($start eq 'link' && $latest eq undef);
                        $pubdate = $c if ($start eq 'pubDate' && $pubdate eq undef);
                    },
        End => sub { $start = undef; } );

    # try
    eval {
        $rp->parse($xml);
    };

    # catch
    if ($@) {
        return undef;
    }

    my $latest =  substr($latest, -8);

    my $dumpuri = $feeduri;
    $dumpuri =~ s/latest/$latest/g;

    return [$latest, $dumpuri, str2time($pubdate)];
}

sub latest_devtionary {
    my $ua = LWP::UserAgent->new(timeout=>5);
    my %inside;
    my $newest = '';

    ####################################################################

    sub tag {
        my($tag, $dir) = @_;
        $inside{$tag} += $dir;
    }

    sub text {
        return if $inside{script} || $inside{style};

        my $t = $_[0];

        if ($t =~ /en-wikt-(\d\d\d\d\d\d\d\d).xml.bz2/) {
            if ($1 gt $newest) {
                $newest = $1;
            }
        }
    }

    ####################################################################

    my $parser = HTML::Parser->new(start_h => [\&tag,  "tagname, '+1'"],
                       end_h   => [\&tag,  "tagname, '-1'"],
                       text_h  => [\&text, "dtext"],
                      );

    my $site;
    my $req;
    my $res;
    foreach my $s ('www.devtionary.info', '70.79.96.121') {
        $req = HTTP::Request->new(GET => "http://$s/w/dump/xmlu/");

        $res = $ua->request($req);

        if ($res->is_success) {
            $site = $s;
            $parser->parse( $res->content );
            last;
        } else {
            #print STDERR $res->status_line, "\n";
        }
    }

    $parser->eof;

    if ($site) {
        my $dumpuri = "http://$site/w/dump/xmlu/en-wikt-$newest.xml.bz2";

        $req = HTTP::Request->new(HEAD => $dumpuri);
        $res = $ua->simple_request($req);

        my $lastmod = $res->header('last-modified');

        return [$newest, $dumpuri, str2time($lastmod)];
    }

    return undef;
}
