#!/usr/bin/perl -I/home/hippietrail/perl5/lib/perl5 -I/home/hippietrail/lib

# This was a simple IRC bot that knows about languages.
# It originally responded to:
# "lang <code>", "dumps", "random <language code|language name>"

use warnings;
use strict;
use utf8; # needed due to literal unicode for stripping diacritics

use File::HomeDir;
use Getopt::Std;
use HTML::Entities;
use HTTP::Request::Common qw(GET);
use JSON -support_by_pp;
use LWP::Simple qw(get $ua);
use LWP::UserAgent;                # used in do_random for HTTP head
use POE;
use POE::Component::Client::HTTP;
use POE::Component::IRC::Common qw(irc_to_utf8);
use POE::Component::IRC::Plugin::BotAddressed;
use POE::Component::IRC::State;
use Sys::Hostname;
use Tie::TextDir;
use Time::Duration;
use Unicode::UCD 'charscript';
use URI::Escape;
use XML::Parser::Lite;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

print STDERR "** running on $^O / ", hostname, "\n";

our($opt_c, $opt_d, $opt_F, $opt_n);

getopts('c:dFn:');

my $tick_num = 0;

# set a useragent and timeout for LWP::Simple
$ua->agent('hippiebot');
$ua->timeout(60);

my %googlefights;
my $googlefight_id = 0;

my %suggests;
my $suggest_id = 0;

# slurp dumped enwikt language code : name mappings
open(IN, '<:encoding(utf8)', 'enwiktlangs.txt') or die "$!"; # Input as UTF-8
my $enwikt = do { local $/; <IN> }; # Read file contents into scalar
close(IN);

my %enwikt;
eval '%enwikt = (' . $enwikt . ');';

# XXX this is a full list of ISO 639-3 macrolanguages which map to language families
# XXX plus some language family codes from ISO 639-5
my %fam = (
    afa => 'Afro-Asiatic',
    alg => 'Algonquian',
    apa => 'Apache',
    art => 'Artificial',
    ath => 'Athapascan',
    aus => 'Australian',
    bad => 'Banda',
    bai => 'Bamileke',
    bat => 'Baltic',
    ber => 'Berber',
    btk => 'Batak',
    cai => 'Central American Indian',
    cau => 'Caucasian',
    cba => 'Chibchan',
    cel => 'Celtic',
    cmc => 'Chamic',
    cus => 'Cushitic',
    day => 'Land Dayak',
    dra => 'Dravidian',
    esx => 'Eskimo-Aleut',
    fiu => 'Finno-Ugrian',
    gem => 'Germanic',
    gme => 'East Germanic',
    gmq => 'North Germanic',
    ijo => 'Ijo',
    inc => 'Indic',
    ine => 'Indo-European',
    ira => 'Iranian',
    iro => 'Iroquoian',
    itc => 'Italic',
    kar => 'Karen',
    khi => 'Khoisan',
    kro => 'Kru',
    map => 'Austronesian',
    mis => 'Uncoded',
    mkh => 'Mon-Khmer',
    mno => 'Manobo',
    mul => 'Multiple',
    mun => 'Munda',
    myn => 'Mayan',
    nah => 'Nahuatl',
    nai => 'North American Indian',
    nic => 'Niger-Kordofanian',
    nub => 'Nubian',
    oto => 'Otomian',
    paa => 'Papuan',
    phi => 'Philippine',
    pra => 'Prakrit',
    roa => 'Romance',
    sal => 'Salishan',
    sem => 'Semitic',
    sio => 'Siouan',
    sit => 'Sino-Tibetan',
    sla => 'Slavic',
    smi => 'Sami',
    son => 'Songhai',
    ssa => 'Nilo-Saharan',
    tai => 'Tai',
    trk => 'Turkic',
    tup => 'Tupi',
    tut => 'Altaic',
    wak => 'Wakashan',
    wen => 'Sorbian',
    ypk => 'Yupik',
    znd => 'Zande',
);

my $js = JSON->new;

print STDERR '** using ', $js->backend, " back end\n";

print STDERR "** LWP::Simple version: $LWP::Simple::VERSION\n";

print STDERR "** POE version: $POE::VERSION\n";
print STDERR "** POE::Component::IRC version: $POE::Component::IRC::VERSION\n";
print STDERR "** POE::Component::IRC::Common version: $POE::Component::IRC::Common::VERSION\n";

$js = $js->utf8 if $LWP::Simple::VERSION < 5.827;

# ISO 639-3 to ISO 639-1 mapping: 3-letter to 2-letter
my %three2one;
my %name2code;

my $json = get 'http://toolserver.org/~hippietrail/langmetadata.fcgi?format=json&fields=iso3,isoname,n';

unless ($json) {
    print STDERR "couldn't get data on language names and ISO 639-3 codes from langmetadata sever\n";
} else {
    my $data = $js->decode($json);

    while (my ($k, $v) = each %$data) {
        $three2one{$v->{iso3}} = $k if (exists $v->{iso3});
        my @a;
        if (ref($v->{n}) eq 'ARRAY') {
            push @a, @{$v->{n}};
        } elsif (exists $v->{n}) {
            push @a, $v->{n};
        }
        push @a, $v->{isoname} if (exists $v->{isoname});
        foreach (@a) {
            my $n = normalize_lang_name($_);
            if (!exists $name2code{$n} || !grep ($n eq $k, @{$name2code{$n}})) {
                push @{$name2code{$n}}, $k;
            }
        }
    }
}

my %hippiebot = (
    botnick => 'hippiebot',
    channels => [ '#wiktionary', '#Wiktionarydev', '#hippiebot' ],
);

$hippiebot{botnick} = $opt_n if defined $opt_n;
$hippiebot{channels} = [ $opt_c ] if defined $opt_c;

# TODO should be per-channel when one bot can be on multiple channels
my $feed_delay = defined $opt_d ? 10 : 60;

my @feeds = (
    {   url   => 'http://download.wikipedia.org/enwiktionary/latest/enwiktionary-latest-pages-articles.xml.bz2-rss.xml',
        name  => 'official dumps',
    },
    {   url   => 'http://www.devtionary.org/cgi-bin/feed.pl',
        name  => 'daily dumps',
    },
    {   url   => 'https://bugzilla.wikimedia.org/buglist.cgi?bug_file_loc=&bug_file_loc_type=allwordssubstr&bug_id=&bugidtype=include&chfieldfrom=&chfieldto=Now&chfieldvalue=&email1=&email2=&emailtype1=substring&emailtype2=substring&field-1-0-0=product&field0-0-0=noop&keywords=&keywords_type=allwords&long_desc=&long_desc_type=substring&product=Wiktionary%20tools&query_format=advanced&remaction=&short_desc=&short_desc_type=allwordssubstr&type-1-0-0=anyexact&type0-0-0=noop&value-1-0-0=Wiktionary%20tools&value0-0-0=&votes=&title=Bug%20List&ctype=atom',
        name  => 'bugs',
    },
    {   url   => 'https://jira.toolserver.org/plugins/servlet/streams?key=10350',
        name  => 'toolserver',
    },
    {   url   => 'https://fisheye.toolserver.org/changelog/enwikt?view=all&max=30&RSS=true',
        name  => 'svn',
    },
    {   url   => 'http://www.xvpa.com/wotd/?feed=atom',
        name  => 'wotd',
    },
);

my @kia_queue;
my @cb_queue;

# Create the IRC component
my $irc = POE::Component::IRC::State->spawn();

# Create the HTTP component for RSS/Atom feeds
POE::Component::Client::HTTP->spawn(
    Agent   => 'hippiebot',
    Alias   => 'my-http',
    Timeout => 10);

$irc->plugin_add( 'BotAddressed', POE::Component::IRC::Plugin::BotAddressed->new() );

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->create(
    inline_states => {
        _start            => \&bot_start,
        irc_001           => \&on_connect,
        irc_public        => \&on_public,
        irc_msg           => \&on_msg,
        irc_bot_addressed => \&on_bot_addressed,
        irc_disconnected  => \&on_disconnected,
        irc_error         => \&on_error,
        irc_socketerr     => \&on_socketerr,
        feed_timer        => \&on_feed_timer,
        feed_response     => \&on_feed_response,
        gf_response       => \&on_gf_response,
        sugg_response     => \&on_sugg_response,
    },
);

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
    my $kernel = $_[KERNEL];

    # feed stuff
    $kernel->delay( feed_timer => $feed_delay );

    # IRC stuff
    $irc->yield( register => "all" );

    $irc->yield( connect =>
          { Nick     => $hippiebot{botnick},
            Username => 'hippiebot',
            Ircname  => 'POE::Component::IRC hippietrail bot',
            Server   => 'irc.freenode.net',
            Port     => '6667',
          }
    );
}

#### on_ handlers ####

# The bot has successfully connected to a server.  Join all channels.
sub on_connect {
    foreach my $ch (@{$hippiebot{channels}}) {
        $irc->yield( join => $ch );
    }
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub on_public {
    my ( $kernel, $who, $where, $msg, $nickserv ) = @_[ KERNEL, ARG0, ARG1, ARG2, ARG3 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    $msg = irc_to_utf8($msg);

    my $ts = scalar localtime;

    # SYNCHRONOUS
    if ( my ($kiaterm) = $msg =~ /^define (.+)$/) {
        print "1 [$ts] <$nick:$channel> $msg\n";

        my $resp = do_define($channel, 'know-it-all', $kiaterm);

        $resp && $irc->yield( privmsg => $channel, $resp );
    }

    # SYNCHRONOUS
    elsif ( my ($dbterm) = $msg =~ /^\.\? (.+)$/) {
        print "2 [$ts] <$nick:$channel> $msg\n";

        my $resp = do_define($channel, 'club_butler', $dbterm);

        $resp && $irc->yield( privmsg => $channel, $resp );
    }

    #elsif ( $nick eq 'hippietrail' && $nickserv ) {
    #    print "3 [$ts] <$nick:$channel> $msg\n";

    #    my $resp = do_hippietrail($msg);

    #    $resp && $irc->yield( privmsg => $channel, $resp );
    #}

    # ASYNCHRONOUS
    elsif ( $nick eq 'know-it-all' && $channel ne '#wiktionary' ) {
        my ($defineresp, $known);

        if ( $msg =~ '^This page does( not|nt) seem to exist\.' ) {
            print STDERR "KIA-DYM\t$msg\n";
            $defineresp = 1;
            $known = 0;

        # long definitions are cut short so don't check for the final full stop
        } elsif ( $msg =~ /^'.*' is .*: / ) {
            shift @kia_queue;
            print STDERR "KIA-DEF\t$msg\t(", scalar @kia_queue, ")\n";
            $defineresp = 1;
            $known = 1;
        }

        if ($defineresp) {
            #print "4 [$ts] <$nick:$channel> $msg\n";

            unless ($known) {
                print STDERR "SUGGEST\t'$kia_queue[-1]'\t(", scalar @kia_queue, ")\n"; 
                # ASYNCH
                my $resp = do_suggest($kernel, $channel, undef, shift @kia_queue);

                $resp && $irc->yield( privmsg => $channel, $resp );
            }
        }
    }

    # ASYNCHRONOUS
    elsif ( $nick eq 'club_butler' && $channel ne '#wiktionary' ) {
        my ($defineresp, $known);
        my ($term, $pos);

        if ( ($term) = $msg =~ '^Couldn\'t get any definitions for (.*)\.$' ) {
            print STDERR "CB-DYM\t$term\n";
            $defineresp = 1;
            $known = 0;

        } elsif ( ($term) = $msg =~ '^Couldn\'t get any definitions from http:\/\/en\.wiktionary\.org\/wiki\/(.*)\.$' ) {
            print STDERR "CB-DYM\t$term\n";
            $defineresp = 1;
            $known = 0;

        } elsif ( ($term, $pos) = $msg =~ /^(.*?) — (.*?): \d+\. / ) {
            shift @cb_queue;
            print STDERR "CB-DEF\t$term:$pos\t(", scalar @cb_queue, ")\n";
            $defineresp = 1;
            $known = 1;
        }

        if ($defineresp) {
            #print "5 [$ts] <$nick:$channel> $msg\n";

            unless ($known) {
                print STDERR "SUGGEST\t'$cb_queue[-1]'\t(", scalar @cb_queue, ")\n"; 
                # ASYNCH
                my $resp = do_suggest($kernel, $channel, undef, shift @cb_queue);

                $resp && $irc->yield( privmsg => $channel, $resp );
            }
        }
    }

    # SYNCHRONOUS & ASYNCHRONOUS
    else {
        print "PUBLIC [$ts] <$nick:$channel> $msg\n";
        my $resps = do_command($kernel, $channel, undef, $msg);

        foreach (@$resps) {
            $irc->yield( privmsg => $channel, $_ );
        }
    }
}

# The bot has received a private message.  Parse it for commands, and
# respond to interesting things.
sub on_msg {
    my ( $kernel, $who, $where, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];
    my $resps;

    $msg = irc_to_utf8($msg);

    my $ts = scalar localtime;
    print "MSG [$ts] <$nick:$channel> $msg\n";

    $resps = do_command($kernel, undef, $nick, $msg);

    foreach (@$resps) {
        $irc->yield( privmsg => $nick, $_ );
    }
}

# The bot has been addressed in a channel.  Parse it for commands, and
# respond to interesting things.
sub on_bot_addressed {
    my ( $kernel, $who, $where, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];
    my $resps;

    $msg = irc_to_utf8($msg);

    my $ts = scalar localtime;
    print "ADDRESS [$ts] <$nick:$channel> $msg\n";

    $resps = do_command($kernel, $channel, $nick, $msg);

    foreach (@$resps) {
        $irc->yield( privmsg => $channel, $nick . ': ' . $_ );
    }
}

# Time to check the next RSS/Atom feed
sub on_feed_timer {
    my $kernel = $_[KERNEL];

    my $feednum = $tick_num % scalar @feeds;
    my $feed = $feeds[ $feednum ];

    $kernel->post(
        'my-http', 'request',
        'feed_response',
        GET ($feed->{url}),
        $feednum);
}

# handle an incoming RSS/Atom feed
sub on_feed_response {
    my ($kernel, $request_packet, $response_packet) = @_[KERNEL, ARG0, ARG1];

    my $feednum       = $request_packet->[1];
    my $http_response = $response_packet->[0];

    my $feed = $feeds[ $feednum ];

    my $was_working = $feed->{working};
    my $is_working = $feed->{working} = $http_response->is_success;

    # unless we're just starting up report feeds which start or stop working
    #if ($tick_num >= scalar @feeds) {
        if ($is_working != $was_working) {
            my $msg = '** feed \'' . $feed->{name} . '\' is now ' . ($is_working ? 'working' : 'down');
            print STDERR "$msg\n";
            $irc->yield( privmsg => '#hippiebot', $msg );
        }
    #}

    if ($is_working) {
        my $in = 0;
        my %title_atts;
        my $txt;
        my @titles;
        my $parser = XML::Parser::Lite->new(
            Handlers => {
                Start => sub {
                    my (undef, $tag) = (shift, shift);
                    %title_atts = @_ if $tag eq 'title';
                    $txt = '';
                    ++ $in if $tag eq 'entry' || $tag eq 'item';
                },
                Char => sub {
                    my (undef, $c) = @_;
                    $txt .= $c if $in;
                },
                End => sub {
                    my (undef, $tag) = @_;
                    if ($in && $tag eq 'title') {
                        decode_entities($txt) if exists $title_atts{type} && $title_atts{type} eq 'html';
                        push @titles, $txt;
                        %title_atts = ();
                    }
                    $in -= $tag eq 'entry' || $tag eq 'item';
                    $txt = '';
                }
            }
        );

        $parser->parse($http_response->decoded_content);

        for (my $i = 0; $i < scalar @titles; ++$i) {
            my $t = $titles[$i];
            $t =~ s/(\s|\r|\n)+/ /sg;
            $t =~ s/\s+$//;
            decode_entities($t);
            $t =~ s/<(?:[^>'"]*|(['"]).*?\1)*>//gs;

            my $announce = 0;

            # at first successful feed check, the newest item, unless -F
            # after that, all *new* items

            if (exists $feed->{initial_check_done}) {
$i == 0 && print STDERR $feed->{name}, " has been checked before\n";
                $announce = ! exists $feed->{seen}->{$t};
            } else {
$i == 0 && print STDERR $feed->{name}, " initial feed check\n";
                $announce = $i == 0 && !$opt_F;
            }
print STDERR 'announce: ', $announce, ' ', $feed->{name}, '[', $i, "]\n";

            $opt_d && !$opt_F && print STDERR 'tick: ', $tick_num, ' ', $feed->{name}, ' item: ', $i, ' title: \'', $t, '\'', $announce ? ' ANNOUNCE' : '', "\n";

            # TODO should each channel should have its own feed delay when one bot can join multiple channels
            foreach my $ch (@{$hippiebot{channels}}) {
                $announce && $irc->yield( privmsg => $ch, $feed->{name} . ': ' . $t );
            }

            $feed->{seen}->{$t} = 1;
        }
        $feed->{initial_check_done} = 1;
    }

    $kernel->delay( feed_timer => $feed_delay );
    ++ $tick_num;
}

# The bot has received a disconnection message.
sub on_disconnected {
    my ( $kernel, $server ) = @_[ KERNEL, ARG0 ];
    my $resps;

    my $ts = scalar localtime;
    print "DISCONNECTED [$ts] $server\n";
}

# The bot has received an error message.
sub on_error {
    my ( $kernel, $err ) = @_[ KERNEL, ARG0 ];
    my $resps;

    my $ts = scalar localtime;
    print "ERROR [$ts] $err\n";
}

# The bot has received a socket error message.
sub on_socketerr {
    my ( $kernel, $err ) = @_[ KERNEL, ARG0 ];
    my $resps;

    my $ts = scalar localtime;
    print "SOCKETERR [$ts] $err\n";
}

#### do_ implementations ####

sub do_command {
    my ( $kernel, $channel, $nick, $msg ) = @_;
    my $force;
    my $args;
    my $resps = [];

    # synchronous commands which can return multiple lines
    if ( ($args) = $msg =~ /^lang (.+)/ ) {
        # TODO ASYNCH ?
        $resps = do_lang($args);
    }

    # synchronous commands which return one line
    elsif ( $msg =~ /^dumps$/ ) {
        # TODO ASYNCH ??
        $resps->[0] = do_dumps();
    } elsif ( ($args) = $msg =~ /^random\s+(.+)\s*$/ ) {
        # TODO ASYNCH ?
        $resps->[0] = do_random($args);
    } elsif ( ($args) = $msg =~ /^toc\s+(.+)\s*$/ ) {
        # TODO ASYNCH ?
        $resps->[0] = do_toc($args);
    }

    # asynchronous commands
    elsif ( ($force, $args) = $msg =~ /^gf(!)?\s+(.+)\s*$/ ) {
        # ASYNCH
        my $resp = do_gf($kernel, $channel, $nick, $force, $args);
        $resps->[0] = $resp if defined $resp;
    } elsif ( ($args) = $msg =~ /^!suggest\s+(.+)\s*$/ ) {
        # TODO ASYNCH
        my $resp = do_suggest($kernel, $channel, $nick, $args);
        $resps->[0] = $resp if defined $resp;
    }

    return $resps;
}

# TOO ASYNCHRONOUS ?
sub do_lang {
    my $input = shift;
    my $codes = $input;

    my $newuri = 'http://toolserver.org/~hippietrail/langmetadata.fcgi?langs=';
    if (exists $three2one{$input}) {
        $codes .= ',' . $three2one{$input};
    }

    my $nname = normalize_lang_name($input);
    if (exists $name2code{$nname}) {
        $codes .= ',' . join(',', @{$name2code{$nname}});
    }

    # TODO asynch?
    my $metadata;
    my $json = get $newuri . $codes;

    if ($json) {
        $metadata = $js->decode($json);
    } else {
        print STDERR "couldn't get data on language codes ($codes) from langmetadata sever\n";
    }

    # add info extracted from the Wiktionary templates
    if (exists $enwikt{$input}) {
        $metadata->{$input}->{enwiktname} = $enwikt{$input};
    }

    my $ok = 0;
    my @resps;

    if ($metadata) {
        if (scalar keys %$metadata) {

            # DBpedia metadata
            my $endpoint = 'http://dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fdbpedia.org&format=json&query=';
            my $query = 'PREFIX p: <http://dbpedia.org/property/> PREFIX t: <http://dbpedia.org/resource/Template:> SELECT DISTINCT ?lc,?fn,?fc WHERE{?lp p:wikiPageUsesTemplate t:infobox_language;p:iso ?lc;p:fam ?fp.?fp p:wikiPageUsesTemplate t:infobox_language_family;p:name ?fn.optional{?fp p:iso ?fc}.FILTER (regex(?lc,"^(' . join('|', keys %$metadata) . ')$"))}ORDER BY ?lc';
            my $uri = $endpoint . uri_escape($query);
            my @dbp;

            # TODO asynch?
            if (my $json = get $uri) {
                if ($json) {
                    my $data = $js->decode($json);
                    if (exists $data->{results} && exists $data->{results}->{bindings}) {
                        foreach my $b (@{$data->{results}->{bindings}}) {
                            my $l = {
                                lc => $b->{lc}->{value},
                                fc => exists $b->{fc}->{value} ? $b->{fc}->{value} : undef,
                                fn => $b->{fn}->{value} };
                            push @dbp, $l;
                        }
                    } else {
                        use Data::Dumper; print 'no DBpedia: ', Dumper $data;
                    }
                }
            }

            foreach my $l (%$metadata) {
                my $eng = metadata_to_english($l, $metadata->{$l}, \@dbp);
                if ($eng) {
                    $ok = 1;
                    push @resps, $eng;
                }
            }
        } else {
            @resps = ($input . ': can\'t find it in ISO 639-3, WikiMedia Sitematrix, or en.wiktionary language templates.');
        }
    } else {
        if ($@) {
            @resps = ('something went wrong: ' . $@);
        } else {
            @resps = ($input . ': can\'t find it in en.wiktionary language templates.');
        }
    }

    hippbotlog('lang', $input, $ok);

    return \@resps;
}

sub metadata_to_english {
    my $incode = shift;
    my $l = shift;
    my $dbp = shift;
    my $resp;

    my %names;

    if (ref($l->{n}) eq 'ARRAY') {
        foreach (@{$l->{n}}) {
            $names{$_} = 1;
        }
    } elsif ($l->{n}) {
        $names{$l->{n}} = 1;
    }
    if ($l->{isoname}) {
        $names{$l->{isoname}} = 1;
    }
    if ($l->{enwiktname}) {
        $names{$l->{enwiktname}} = 1;
    }
    if ($l->{nn}) {
        if ($l->{nn} =~ /^(.*?) ?\/ ?(.*?)$/) { # bpy/cr/cu/iu/ku/pih/sh/sr/tt/ug
            $names{$1} = 1;
            $names{$2} = 1;
        } elsif ($l->{nn} =~ /^(.*?) - \((.*?)\)$/) { # ks
            $names{$1} = 1;
            $names{$2} = 1;
        } else {
            $names{$l->{nn}} = 1;
        }
    }

    if (scalar keys %names) {
        $resp = $incode;

        if (exists $l->{iso3}) {
            $resp .= ', ' . $l->{iso3};
        }
        $resp .= ': '. join '; ', keys %names;

        if (exists $l->{fam} || exists $l->{geo} || scalar @$dbp) {
            $resp .= ', a';

            my $famcode;
            my $famname;

            if (exists $l->{fam}) {
                $famcode = $l->{fam};
                $famname = $fam{$famcode};
            } elsif (scalar @$dbp) {
                # TODO look at all entries
                $famcode = $dbp->[0]->{fc};
                $famname = $dbp->[0]->{fn};
            }

            if (defined $famcode || defined $famname) {
                $famname = '"' . $famcode . '"' unless defined $famname;

                if (defined $famcode && $famcode eq 'Isolate') {
                    $resp .= ' language isolate';
                } else {
                    $resp .= 'n' if ($famname =~ /^[aeiouAEIUO]/);
                    $resp .= ' ' . $famname;
                    $resp .= ' language';
                }
            } else {
                $resp .= ' language';
            }

            if (exists $l->{geo}) {
                $resp .= ' of ';
                if (ref($l->{geo}) eq 'ARRAY') {
                    my $n = scalar @{$l->{geo}};
                    $resp .= join ', ', @{$l->{geo}}[0 .. $n-2];
                    $resp .= ' and ' . $l->{geo}->[-1];
                } else {
                    $resp .= $l->{geo};
                }
            }
        }
        $resp .= '.';

        $resp .= ' ';
        if (exists $l->{isoscope}) {
            $resp .= 'It\'s in ISO';
        } elsif (exists $l->{wm}) {
            $resp .= 'It\'s a WikiMedia extension to ISO';
        } else {
            $resp .= 'It\'s an en.wiktionary extension to ISO';
        }
        if (exists $l->{hw}) {
            $resp .= ' and has its own Wiktionary';
        }
        $resp .= '.';

        if (exists $l->{sc} || exists $l->{wsc}) {
            $resp .= ' It';
            if (exists $l->{sc}) {
                $resp .= '\'s written in the ';
                my $n = 1;
                if (ref($l->{sc}) eq 'ARRAY') {
                    $n = scalar @{$l->{sc}};
                    $resp .= join ', ', @{$l->{sc}}[0 .. $n-2];
                    $resp .= ' or ' . $l->{sc}->[-1];
                } else {
                    $resp .= $l->{sc};
                }
                $resp .= ' script';
                $resp .= 's' if ($n > 1);

                $resp .= ' but' if (exists $l->{wsc});
            }
            if (exists $l->{wsc}) {
                $resp .= ' uses the "' . $l->{wsc} . '" script template';
            }
            $resp .= '.';
        }

        if (exists $l->{g}) {
            $resp .= ' ';
            $resp .= 'Nouns ';
            if ($l->{g}) {
                $resp .= 'can be ';
                my %g = (m=>'masculine',f=>'feminine',n=>'neuter',c=>'common');
                my @g = map $g{$_}, split(//, $l->{g});
                my $n = scalar @g;
                $resp .= join ', ', @g[0 .. $n-2];
                $resp .= ' or ' . $g[-1];
            } else {
                $resp .= 'don\'t have';
            }
            $resp .= ' gender';
            $resp .= '.';
        }
    }
    return $resp;
}

# TODO ASYNCHRONOUS ??
sub do_dumps {
    my $ok = 0;
    my $resp = 'I don\'t know anything about the dumps right now.';
    my @dat = `perl latestdump.pl x`;
    if (@dat) {
        $ok = 1;
        $resp = join(', ', map {
            /^(.*)\t(.*)\t(.*)$/;
            $1 . ': ' . $2 . ' (' . duration(time - $3) . ' ago)';
        } @dat);
    }
    hippbotlog('dumps', '', $ok);

    return $resp;
}

# TODO ASYNCHRONOUS ?
sub do_random {
    my $lang = shift;
    my $ok = 0;
    my $resp = 'Something random went wrong.';

    my $langenc = $lang;
    $langenc =~ s/ /\\ /g;

    my $args = substr($lang, 0, 1) =~ /^[a-z]$/ ? 'langcode' : 'langname';

    my $uri = 'http://toolserver.org/~hippietrail/randompage.fcgi?' . $args . '=' . $lang;
    my $head = LWP::UserAgent->new->simple_request(HTTP::Request->new(HEAD => $uri));
    my $location = $head->header('location');

    if ($location) {
        $ok = 1;
        my $uri = URI->new($location);

        my $langname = $uri->fragment;
        $langname =~ tr/\._/% /;
        $langname = uri_unescape($langname);
        utf8::decode($langname);

        $uri->path =~ /^\/wiki\/(.*)$/;
        my $word = $1;

        my %q = $uri->query_form;
        my $iscached = $q{rndlangcached} eq 'yes';

        $word = uri_unescape($word);
        utf8::decode($word);

        if ($langname eq ' Redirect') {
            $resp = "How about the nice redirect [[$word]] ";
        } elsif ($langname =~ /^ /) {
            my $namespace = substr($langname, 1);
            $resp = "How about [[$namespace:$word]] from the $namespace namespace ";
        } else {
            $resp = "How about the nice $langname word [[$word]] ";
        }
        $resp .= $iscached ? 'which I just happened to have lying around?'
                           : 'which I’ve gone to a bit of trouble to get for you?';
    }

    else {
        my @dat = `perl public_html/randompage.fcgi --$args=$langenc`;

        if (@dat) {
            my $l = $dat[0];
            if ($l =~ s/word '(.*)' which/word [[$1]] which/) {
                $ok = 1;
                $resp = $l;
            }
        }
    }

    hippbotlog('random', $lang, $ok);

    return $resp;
}

# TODO ASYNCHRONOUS ?
sub do_toc {
    my $page = shift;
    my $ok = 0;
    my $resp = $page . ': ';

    my $uri = 'http://en.wiktionary.org/w/api.php?format=json&action=parse&prop=sections&page=';

    # TODO use POE::Component::Client::HTTP
    my $data;
    my $json = get $uri . $page;

    if ($json) {
        $data = $js->decode($json);

        if (exists $data->{parse} && exists $data->{parse}->{sections}) {
            my @langs;
            foreach my $s (@{$data->{parse}->{sections}}) {
                push @langs, $s->{line} if $s->{level} == 2;
            }
            if (@langs) {
                $ok = 1;
                $resp .= join(', ', @langs);
            } else {
                $resp .= 'couldn\'t see any language headings';
            }
        }
    } else {
        print STDERR "couldn't get data on TOC\'s for \'$page\' from the Toolserver\n";
    }

    hippbotlog('toc', '', $ok);

    return $resp;
}

# ASYNCHRONOUS
sub do_gf {
    my $kernel = shift;
    my $channel = shift;
    my $nick = shift;
    my $force = shift;
    my $args= shift;
    my $ok = 0;
    my $resp = undef;

    if ($channel) {
        if (grep $_ eq 'know-it-all', $irc->channel_list($channel)) {
            # gf know it all
            $ok = 1 if $force;
        } else {
            $ok = 1;
            # gf no know it all
        }
    } else {
        $ok = 1;
    }

    if ($ok) {
        my %terms;

        $terms{$_} = undef for ($args =~ /(".*?"|\S+)/g);

        $googlefights{$googlefight_id} = {
            channel => $channel,
            nick => $nick,
            numterms => scalar keys %terms,
        };

        foreach my $term (keys %terms) {
            $term =~ s/  +/+/g;

            $kernel->post(
                'my-http', 'request',
                'gf_response',
                GET ('http://www.google.com.au/search?q=' . $term),
                $googlefight_id . '.' . $term);
        }

        ++ $googlefight_id;
    }

    hippbotlog('gf', '', $ok);

    return undef;
}

# handle an incoming googlefight response
sub on_gf_response {
    my ($kernel, $request_packet, $response_packet) = @_[KERNEL, ARG0, ARG1];

    my $gf_req_id     = $request_packet->[1];
    my $http_response = $response_packet->[0];

    $gf_req_id =~ /^(\d+)\.(.*)$/;
    my ($gf_id, $term) = ($1, $2);
    my $fight = $googlefights{$gf_id};

    # parse html
    if ($http_response->decoded_content =~ /Results <b>1<\/b> - <b>\d+<\/b> of about <b>([0-9,]+)<\/b> for <b>/) {
        $fight->{terms}->{$term} = [$1, $1];
        $fight->{terms}->{$term}->[1] =~ s/,//g;
    } else {
        $fight->{terms}->{$term} = [0, 0];
    }

    -- $fight->{numterms};

    if ($fight->{numterms} == 0) {
        my $resp = 'Googlefight: ' . join(
            ', ',
            map {
                ($_ =~ /^".*"$/ ? $_ : '\'' . $_ . '\'') . ': ' . $fight->{terms}->{$_}->[0]
            } sort {
                $fight->{terms}->{$b}->[1] <=> $fight->{terms}->{$a}->[1]
            } keys %{$fight->{terms}});

        if (defined $fight->{channel} && defined $fight->{nick}) {
            $irc->yield( privmsg => $fight->{channel}, $fight->{nick} . ': ' . $resp );
        } elsif (defined $fight->{channel}) {
            $irc->yield( privmsg => $fight->{channel}, $resp );
        } elsif (defined $fight->{nick}) {
            $irc->yield( privmsg => $fight->{nick}, $resp );
        } else {
            print STDERR "** gf no channel or nick impossible!\n";
        }
    }
}

# handle know-it-all define and club_butler .?
# if a commmand is used but the bot is missing and the other is here suggest the other bot's command
sub do_define {
    my $channel = shift;
    my $bot = shift;
    my $term = shift;
    my $ok = 0;
    my $resp = undef;

    my ($kia, $cb);

    $kia = scalar grep $_ eq 'know-it-all', $irc->channel_list($channel);
    $cb = scalar grep $_ eq 'club_butler', $irc->channel_list($channel);

    # define doesn't work with /msg
    if ($channel) {
        if ($bot eq 'know-it-all') {
            if ($kia) {
                if ($channel ne '#wiktionary') {
                    push @kia_queue, $term;
                    $ok = 1;
                    print STDERR "KIA-DEFINE '$term' (", scalar @kia_queue, ")\n";
                }
            } elsif ($cb) {
                $resp = 'try ".?" instead of "define"';
            } else {
                $resp = 'too bad know-it-all isn\'t here';
            }
        } elsif ($bot eq 'club_butler') {
            if ($cb) {
                if ($channel ne '#wiktionary') {
                    push @cb_queue, $term;
                    $ok = 1;
                    print STDERR "CB-DEFINE '$term' (", scalar @cb_queue, ")\n";
                }
            } elsif ($kia) {
                $resp = 'try "define" instead of ".?"';
            } else {
                $resp = 'too bad club_butler isn\'t here';
            }
        }
    }

    hippbotlog('define', '', $ok);

    return $resp;
}

# ASYNCHRONOUS
sub do_suggest {
    my $kernel = shift;
    my $channel = shift;
    my $nick = shift;
    my $term = shift;

    ## which scripts are used in this term

    my %script;

    my @ch = split //, $term;
    for my $ch (@ch) {
        my $s = charscript(ord $ch);
        ++ $script{$s}
    }

    ## heuristics to decide languages based on scripts
    ## TODO use langmetadata server

    my %codes;
    my %names;

    for my $s (keys %script) {
        if ($s eq 'Arabic') {
            ++ $codes{$_} for ('ar', 'fa', 'ur');
            ++ $names{$_} for ('Arabic', 'Persian', 'Urdu');
        } elsif ($s eq 'Armenian') {
            ++ $codes{$_} for ('hy');
            ++ $names{$_} for ('Armenian');
        } elsif ($s eq 'Devanagari') {
            ++ $codes{$_} for ('hi', 'sa');
            ++ $names{$_} for ('Hindi', 'Sanskrit');
        } elsif ($s eq 'Cyrillic') {
            ++ $codes{$_} for ('bg', 'ru', 'sr', 'uk');
            ++ $names{$_} for ('Bulgarian', 'Russian', 'Serbian', 'Ukrainian');
        } elsif ($s eq 'Georgian') {
            ++ $codes{$_} for ('ka');
            ++ $names{$_} for ('Georgian');
        } elsif ($s eq 'Greek') {
            ++ $codes{$_} for ('el');
            ++ $names{$_} for ('Greek', 'Ancient Greek');
        } elsif ($s eq 'Han') {
            ++ $codes{$_} for ('zh', 'ja');
            ++ $names{$_} for ('Chinese', 'Korean', 'Mandarin', 'Japanese');
        } elsif ($s eq 'Hangul') {
            ++ $codes{$_} for ('ko');
            ++ $names{$_} for ('Korean');
        } elsif ($s eq 'Hebrew') {
            ++ $codes{$_} for ('he', 'yi');
            ++ $names{$_} for ('Hebrew', 'Yiddish');
        } elsif ($s eq 'Hiragana') {
            ++ $codes{$_} for ('ja');
            ++ $names{$_} for ('Japanese');
        } elsif ($s eq 'Katakana') {
            ++ $codes{$_} for ('ain', 'ja');
            ++ $names{$_} for ('Ainu', 'Japanese');
        } elsif ($s eq 'Khmer') {
            ++ $codes{$_} for ('km');
            ++ $names{$_} for ('Khmer');
        } elsif ($s eq 'Lao') {
            ++ $codes{$_} for ('lo');
            ++ $names{$_} for ('Lao');
        } elsif ($s eq 'Latin') {
            ++ $codes{$_} for ('en', 'de', 'fr', 'es');
            ++ $names{$_} for ('English', 'German', 'French', 'Spanish');
        } elsif ($s eq 'Malayalam') {
            ++ $codes{$_} for ('ml');
            ++ $names{$_} for ('Malayalam');
        } elsif ($s eq 'Thai') {
            ++ $codes{$_} for ('th');
            ++ $names{$_} for ('Thai');
        } else {
            print STDERR "** unhandled script: $s\n";
        }
    }

    # we no longer need the UTF-8 term so encode it for use in URLs
    $term = uri_escape_utf8($term);

    my $suggq = $suggests{$suggest_id} = {
        channel => $channel,
        nick => $nick,
        allreqs => 0,
    };

    my $url;

    # decide which sites to scrape or call based on language code
    for my $lc (keys %codes) {

        # Google does many languages and uses language codes

        $url = 'http://www.google.com.au/search?hl=' . $lc . '&q=' . $term;

        $kernel->post(
            'my-http', 'request',
            'sugg_response',
            GET ($url),
            $suggest_id . '.' . 'g' . '-' . $lc . '-' . $term);

        ++ $suggq->{numresps};

        # English-only sites
        # merriam-webster.com
        if ($lc eq 'en') {
            $url = 'http://www.merriam-webster.com/dictionary/' . $term;

            $kernel->post(
                'my-http', 'request',
                'sugg_response',
                GET ($url),
                $suggest_id . '.' . 'mw' . '-' . $lc . '-' . $term);

            ++ $suggq->{numresps};
        }

        # Spanish-only sites
        # merriam-webster.com
        if ($lc eq 'es') {
            $url = 'http://www.merriam-webster.com/spanish/' . $term;

            $kernel->post(
                'my-http', 'request',
                'sugg_response',
                GET ($url),
                $suggest_id . '.' . 'mw' . '-' . $lc . '-' . $term);

            ++ $suggq->{numresps};
        }

        # Wiktionaries and Wikipedias
        for my $site (('wiktionary', 'wikipedia')) {
            $url = 'http://' . $lc . '.' . $site . '.org/w/api.php?format=json&action=query&list=search&srinfo=suggestion&srprop=&srlimit=1&srsearch='. $term;

            $kernel->post(
                'my-http', 'request',
                'sugg_response',
                GET ($url),
                $suggest_id . '.' . $site . '-' . $lc . '-' . $term);

            ++ $suggq->{numresps};
        }
    }

    # get previous and next terms across all language names
    $url = 'http://toolserver.org/~hippietrail/nearbypages.fcgi?langname=*&term=' . $term;

    $kernel->post(
        'my-http', 'request',
        'sugg_response',
        GET ($url),
        $suggest_id . '.' . 'nearby' . '-' . '*' . '-' . $term);

    ++ $suggq->{numresps};

    $suggq->{allreqs} = 1;
    ++ $suggest_id;

    return undef;
}

# handle an incoming suggest response
sub on_sugg_response {
    my ($kernel, $request_packet, $response_packet) = @_[KERNEL, ARG0, ARG1];

    my $sugg_req_id     = $request_packet->[1];
    my $http_response = $response_packet->[0];

    $sugg_req_id =~ /^(\d+)\.(.*)-(.*)-(.*)$/;
    my ($sugg_id, $site, $lang, $term) = ($1, $2, $3, $4);
    my $fight = $suggests{$sugg_id};

    # PARSE $http_response->decoded_content
    my @a;

    if ($site eq 'g') {
        if ($http_response->decoded_content =~ /class="?spell"?><b><i>(.*?)<\/i><\/b><\/a>/) {
            my $t = decode_entities($1);
            ++ $fight->{dym}->{$t};
        }
    } elsif ($site eq 'mw') {
        if ($http_response->decoded_content =~ /class="franklin-spelling-help">((?: \t<li><a href=".*?">.*?<\/a><\/li>)+) <\/ol>/) {
            if (@a = $1 =~ / \t<li><a href=".*?">(.*?)<\/a><\/li>/g) {
                for (@a) {
                    $fight->{dym}->{$_} += 0.5;
                }
            }
        }
    } elsif ($site eq 'wiktionary' or $site eq 'wikipedia') {
        $json = $http_response->decoded_content;

        if ($http_response->is_success) {
            if ($json) {
                my $res = $js->decode($json);
                if (exists $res->{query} && exists $res->{query}->{searchinfo} && exists $res->{query}->{searchinfo}->{suggestion}) {
                    ++ $fight->{dym}->{$res->{query}->{searchinfo}->{suggestion}};
                }
            }
        }
    } elsif ($site eq 'nearby') {
        if ($http_response->is_success) {

            # decodes gzip data etc and return result with character semantics
            $json = $http_response->decoded_content;

            if ($json) {
                # the logic of utf8() is reversed for decode() but correct for encode()!!
                my $confusing = ! utf8::is_utf8($json);
                my $res = $js->utf8($confusing)->decode($json);  # works with charset => 'UTF-8' above

                if (exists $res->{prev}) {
                    $fight->{dym}->{$res->{prev}->[0]} += 0.5;
                }
                if (exists $res->{next}) {
                    $fight->{dym}->{$res->{next}->[0]} += 0.5;
                }
            }
        } else {
            print STDERR "** toolserver nearbypages.fcgi timeout\n";
        }
    }

    -- $fight->{numresps};

    if ($fight->{allreqs} && $fight->{numresps} == 0) {

        # build overall response from all part responses
        my $resp = undef;
        my $sugg = '';

        if (exists $fight->{dym}) {
            $json = get 'http://en.wiktionary.org/w/api.php?format=json&action=query&titles=' . join('|', keys %{$fight->{dym}});

            my %col;

            if ($json) {
                my $res = $js->decode($json);

                if (exists $res->{query} && exists $res->{query}->{pages}) {
                    for my $d (values %{$res->{query}->{pages}}) {
                        my $t = $d->{title};
                        if (exists $d->{missing}) {
                            $col{$t} = '04';     # IRC red 04 ANSI 31
                        } else {
                            $fight->{dym}->{$t} += 2;
                            $col{$t} = '02';     # IRC blue 02 ANSI 34
                        }
                    }
                }
            }

            # #let's see how they rated
            for my $t (sort {$fight->{dym}->{$b} <=> $fight->{dym}->{$a}} keys %{$fight->{dym}}) {
                if (length $sugg < 64) {
                    $sugg .= ", " if $sugg ne '';
                    $sugg .= "\003$col{$t}$t\00301";    # IRC black 01 ANSI 30
                }
            }
        }

        if ($sugg) {
            $resp = 'did you mean ' . $sugg . ' ?';
            # IRC -> ANSI colour conversion
            $sugg =~ s/\00301/\e[0m/g; # IRC black / ANSI white
            $sugg =~ s/\00302/\e[34m/g; # red
            $sugg =~ s/\00304/\e[31m/g; # blue
        } else {
            $resp = 'I have little to suggest for "' . $term . '".';
        }

        if (defined $fight->{channel} && defined $fight->{nick}) {
            $irc->yield( privmsg => $fight->{channel}, $fight->{nick} . ': ' . $resp );
        } elsif (defined $fight->{channel}) {
            $irc->yield( privmsg => $fight->{channel}, $resp );
        } elsif (defined $fight->{nick}) {
            $irc->yield( privmsg => $fight->{nick}, $resp );
        } else {
            print STDERR "** sugg no channel or nick impossible!\n";
        }
    }
}

# SYNCHRONOUS
sub do_hippietrail {
    my $msg = shift;
    my $resp = undef;

    if ($msg =~ /\bmy bot\b/) {
        $resp = 'Woof!';
    } elsif ($msg =~ /\bbad bot\b/) {
        $resp = 'Sorry master.';
    } elsif ($msg =~ /( |^)\\o\/( |$)/) {
        $resp = '\o/';
    } elsif ($msg =~ /\b(g'day|hi|greetings) bot\b/) {
        $resp = $1 . ' master';
    }

    return $resp;
}

####

sub hippbotlog {
    if (open(LFH, ">>hippiebot.log")) {
        print LFH shift, "\t", shift, "\t", shift, "\n";
        close(LFH);
    }
}

sub normalize_lang_name {
    my $n = shift;

    # ignore the dates in entries like Old English (ca. 450-1100)
    # but don't ignore other parenthesised data such as Ainu (Japan)
    $n = $1 if $n =~ /^(.*) \(.*\d.*\)$/;

    $n = lc $n;
    $n =~ s/[- '()!\.\/=ʼ’]//g;
    $n =~ tr/àáâãäåçèéêëìíîñóôõöùúüāīṣṭ/aaaaaaceeeeiiinoooouuuaist/;

    return $n;
}

# Run the bot until it is done.
$poe_kernel->run();

exit 0;

