#!/usr/bin/perl

# what are the latest dumps of en.wiktionary.org

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

my ($latest, $latesturi, $age) = latest_official();
my ($latest2, $latesturi2, $age2) = latest_devtionary();

####

tie my %home, 'Tie::TextDir', home(), 'rw';  # Open in read/write mode

my $last;
if (exists $home{'.enwikt'}) {
    $last = $home{'.enwikt'}
}

my $last2;
if (exists $home{'.enwikt2'}) {
    $last2 = $home{'.enwikt2'}
}

####

print 'official dump: last: ', ($last ? $last : 'none'), ', latest: ', $latest, ($last && $latest gt $last ? ' ** NEW ** (' : ' ('), duration($age), " ago)\n";
print substr($latesturi, 0, -8), "\n\n";

$home{'.enwikt'} = $latest;

print 'devtionary dump: last: ', ($last2 ? $last2 : 'none'), ', latest: ', $latest2, ($last2 && $latest2 gt $last2 ? ' ** NEW ** (' : ' ('), duration($age2), " ago)\n";
print $latesturi2, "\n\n";

$home{'.enwikt2'} = $latest2;

untie %home;

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

    $rp->parse($xml);
    my $latest =  substr($latest, -8);
    my $then = str2time($pubdate);
    my $now  = time;

    my $dumpuri = $feeduri;
    $dumpuri =~ s/latest/$latest/g;

    return ($latest, $dumpuri, $now - $then);
}

sub latest_devtionary {
    my $ua = LWP::UserAgent->new;
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
        }
    }

    $parser->eof;

    my $dumpuri = "http://$site/w/dump/xmlu/en-wikt-$newest.xml.bz2";

	$req = HTTP::Request->new(HEAD => $dumpuri);
    $res = $ua->simple_request($req);

    my $date = $res->header('date');
    my $lastmod = $res->header('last-modified');
    my $then = str2time($lastmod);
    my $now  = str2time($date);

    return ($newest, $dumpuri, $now - $then);
}
