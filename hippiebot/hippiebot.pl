#!/usr/bin/perl -I/home/hippietrail/perl5/lib/perl5 -I/home/hippietrail/lib

# This was a simple IRC bot that knows about languages.
#
# commands:
#
# .?            only in channel, depends on the bot club_butler
# define        only in channel, depends on the bot know-it-all
# dumps         always
# gf(!) ...     in channels only when know-it-all is not present or suffixed with !
# lang ...      always though in #wiktionary maybe it should only add to know-it-all's information
# random ...    always
# !suggest ...  always though outside #wiktionary maybe it should work even without the ! prefix
# toc ...       always

use warnings;
use strict;
use utf8; # needed due to literal unicode for stripping diacritics

use File::HomeDir;
use Getopt::Std;
use HTML::Entities;
use HTML::Strip;
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

# debugging
my $USE_WIKI_TEMPLATES = 1;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

print STDERR "** running on $^O / ", hostname, "\n";

our($opt_c, $opt_d, $opt_F, $opt_n, $opt_s);

getopts('c:dFn:s:');

# XXX move to %g_hippiebot or heap?
my $g_feed_tick = 0;

# set a useragent and timeout for LWP::Simple
$ua->agent('hippiebot');
$ua->timeout(60);

# TODO move to session heap
my %g_googlefights;
my $g_googlefight_id = 0;

# TODO move to session heap
my %g_suggests;
my $g_suggest_id = 0;

my $g_lang_id = 0;
my $g_toc_id = 0;
my $g_whatis_id = 0;
my $g_whatis_id_2 = 0;

# slurp dumped enwikt language code : name mappings
my %g_enwikt;
{
    if (open(IN, '<:encoding(utf8)', 'enwiktlangs.txt')) {   # Input as UTF-8
        my $enwikt = do { local $/; <IN> }; # Read file contents into scalar
        close(IN);

        eval '%g_enwikt = (' . $enwikt . ');';
    } else { print STDERR "** couldn't read enwiktlangs.txt\n"; }
}

# slurp dumped enwiki language code : name mappings
my %g_enwiki;
{
    if (open(IN, '<:encoding(utf8)', 'enwikilangs.txt')) {   # Input as UTF-8
        my $enwiki = do { local $/; <IN> }; # Read file contents into scalar
        close(IN);

        eval '%g_enwiki = (' . $enwiki . ');';
    } else { print STDERR "** couldn't read enwikilangs.txt\n"; }
}

# XXX this is a full list of ISO 639-3 macrolanguages which map to language families
# XXX plus some language family codes from ISO 639-5
my %g_fam = (
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

my $g_js = JSON->new;

print STDERR '** using ', $g_js->backend, " back end\n";

print STDERR "** LWP::Simple version: $LWP::Simple::VERSION\n";

print STDERR "** POE version: $POE::VERSION\n";
print STDERR "** POE::Component::IRC version: $POE::Component::IRC::VERSION\n";
print STDERR "** POE::Component::IRC::Common version: $POE::Component::IRC::Common::VERSION\n";

$g_js = $g_js->utf8 if $LWP::Simple::VERSION < 5.827;

# ISO 639-3 to ISO 639-1 mapping: 3-letter to 2-letter
my %g_three2one;
my %g_twob2one;
my %g_name2code;
{
    my $data;
    my $json = get 'http://toolserver.org/~hippietrail/langmetadata.fcgi?format=json&fields=iso3,iso2b,isoname,n';

    unless ($json) {
        print STDERR "** couldn't get data on language names and ISO 639-3 codes from langmetadata sever\n";
    } else {
        eval {
            # the logic of utf8() is reversed for decode() but correct for encode()!!
            $data = $g_js->decode($json);
        };
        if ($@) {
            print STDERR "** langmetadata returned invalid JSON\n";
        } else {
            while (my ($k, $v) = each %$data) {
                $g_three2one{$v->{iso3}} = $k if (exists $v->{iso3});
                $g_twob2one{$v->{iso2b}} = $k if (exists $v->{iso2b});
                my @a;
                if (ref($v->{n}) eq 'ARRAY') {
                    push @a, @{$v->{n}};
                } elsif (exists $v->{n}) {
                    push @a, $v->{n};
                }
                push @a, $v->{isoname} if (exists $v->{isoname});
                foreach (@a) {
                    my $n = normalize_lang_name($_);
                    if (!exists $g_name2code{$n} || !grep ($n eq $k, @{$g_name2code{$n}})) {
                        push @{$g_name2code{$n}}, $k;
                    }
                }
            }
        }
    }
}

# part configuration, part main bot object
my %g_hippiebot = (
    owner => [ 'hippietrail', 'hippietrailwork' ],
    botnick => 'hippiebot',
    server => 'irc.freenode.net',
    channels => [ '#wiktionary', '#Wiktionarydev', '#hippiebot' ],
);

$g_hippiebot{botnick} = $opt_n if defined $opt_n;
$g_hippiebot{server} = $opt_s if defined $opt_s;
$g_hippiebot{channels} = [ $opt_c ] if defined $opt_c;

# TODO should be per-channel when one bot can be on multiple channels
my $g_feed_delay = defined $opt_d ? 10 : 60;

my @g_feeds = (
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

# XXX move to %g_hippiebot or heap?
my $g_siteinfo_delay = defined $opt_d ? 15 : 5 * 60;
my @g_siteinfo_ignore_fields = defined $opt_d ? ( 'time' ) : ( 'time', 'dbversion' );

my %g_siteinfo_cache;

# XXX move to %g_hippiebot or heap?
my $g_ts_ping_delay = 77; # how often to ping the metadata server to keep it alive

# XXX move to %g_hippiebot or heap?
my @g_kia_queue;
my @g_cb_queue;

# Create the IRC component
my $g_irc = POE::Component::IRC::State->spawn();

# Create the HTTP component for RSS/Atom feeds
POE::Component::Client::HTTP->spawn(
    Agent   => 'hippiebot',
    Alias   => 'my-http',
    Timeout => 10);

$g_irc->plugin_add( 'BotAddressed', POE::Component::IRC::Plugin::BotAddressed->new() );

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
        json_response     => \&on_json_response,
        siteinfo_timer    => \&on_siteinfo_timer,
        siteinfo_response => \&on_siteinfo_response,
        ts_ping_timer     => \&on_ts_ping_timer,
        ts_ping_response  => \&on_ts_ping_response,
        gf_response       => \&on_gf_response,
        lang_response     => \&on_lang_response,
        sugg_response     => \&on_sugg_response,
        toc_response      => \&on_toc_response,
        whatis_response   => \&on_whatis_response,
        whatis_response_2 => \&on_whatis_response_2,
    },
);

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
    my $kernel = $_[KERNEL];

    # timers
    $kernel->delay( feed_timer => $g_feed_delay );
    $kernel->delay( siteinfo_timer => $g_siteinfo_delay );
    $kernel->delay( ts_ping_timer => 2 );

    # IRC stuff
    $g_irc->yield( register => "all" );

    $g_irc->yield( connect =>
          { Nick     => $g_hippiebot{botnick},
            Username => 'hippiebot',
            Ircname  => 'POE::Component::IRC hippietrail bot',
            Server   => $g_hippiebot{server},
            Port     => '6667',
          }
    );
}

#### on_ handlers ####

# JSON wrapper for POE::Component::Client::HTTP

my $g_json_req_id = 0;

# post an asynchronous JSON request
sub post_json_req {
    my ($kernel, $heap, $response_state, $request, $id) = @_;

    my $_id = $g_json_req_id ++;

    $heap->{json}->[$_id] = { id => $id, response_state => $response_state };

    $kernel->post(
        'my-http', 'request',
        'json_response',
        $request,
        $_id);
}    

# handle an incoming asynchronous JSON response
sub on_json_response {
    my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];

    my $_id = $request_packet->[1];
    my $http_response = $response_packet->[0];

    my $ref;
    my $err;

    #print STDERR "** on_json_response code: ", $http_response->code, ", message: ", $http_response->message, "\n";

    if ($http_response->is_success) {
        my $json = $http_response->decoded_content;
        if ($json ne '') {
            eval {
                # the logic of utf8() is reversed for decode() but correct for encode()!!
                $ref = $g_js->utf8(!utf8::is_utf8($json))->decode($json);
            };
            if ($@) {
                $err = $@;
                print "** JSON can't decode this string: <<$json>>\n";
            }
        } else {
            $err = 'empty JSON string';
        }
    } else {
        #print STDERR "** json http no success\n";
        $err = $http_response->message;
    }

    $kernel->yield( $heap->{json}->[$_id]->{response_state} => $heap->{json}->[$_id]->{id}, $http_response->code, $ref, $err );
}

# The bot has successfully connected to a server.  Join all channels.
sub on_connect {
    foreach my $ch (@{$g_hippiebot{channels}}) {
        $g_irc->yield( join => $ch );
    }
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.

# respond to some plain commands always
# respond to all plain commands when followed by !
# respond to all ! prefixed commands
# respond to some comments by users and other bots which are not commands

sub on_public {
    my ( $kernel, $heap, $who, $where, $msg, $nickserv ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    $msg = irc_to_utf8($msg);

    my $ts = scalar localtime;

    # hippiebot doesn't respond to "define" or ".?" directly
    # but it tracks them and may respond if other bots fail

    # SYNCHRONOUS
    if ( my ($kiaterm) = $msg =~ /^define (.+)$/) {
        my $resp = do_define($channel, 'know-it-all', $kiaterm);

        $resp && $g_irc->yield( privmsg => $channel, $resp );
    }

    # SYNCHRONOUS
    elsif ( my ($dbterm) = $msg =~ /^\.\? (.+)$/) {
        my $resp = do_define($channel, 'club_butler', $dbterm);

        $resp && $g_irc->yield( privmsg => $channel, $resp );
    }

    # respond to the bot owner sometimes

    #elsif ( $nick eq 'hippietrail' && $nickserv ) {
    #    my $resp = do_hippietrail($msg);

    #    $resp && $g_irc->yield( privmsg => $channel, $resp );
    #}

    # respond when other bots return negative responses to commands

    # ASYNCHRONOUS TODO channels should be configurable
    elsif ( $nick eq 'know-it-all' && $channel ne '#wiktionary' ) {
        my ($defineresp, $known);

        if ( $msg =~ '^This page does( not|nt) seem to exist\.' ) {
            print STDERR "KIA-DYM\t$msg\n";
            $defineresp = 1;
            $known = 0;

        # long definitions are cut short so don't check for the final full stop
        } elsif ( $msg =~ /^'.*' is .*: / ) {
            shift @g_kia_queue;
            print STDERR "KIA-DEF\t$msg\t(", scalar @g_kia_queue, ")\n";
            $defineresp = 1;
            $known = 1;
        }

        if ($defineresp) {
            unless ($known) {
                print STDERR "SUGGEST\t'$g_kia_queue[-1]'\t(", scalar @g_kia_queue, ")\n"; 
                # ASYNCH
                my $resp = do_suggest($kernel, $channel, undef, shift @g_kia_queue);

                $resp && $g_irc->yield( privmsg => $channel, $resp );
            }
        }
    }

    # ASYNCHRONOUS TODO channels should be configurable
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
            shift @g_cb_queue;
            print STDERR "CB-DEF\t$term:$pos\t(", scalar @g_cb_queue, ")\n";
            $defineresp = 1;
            $known = 1;
        }

        if ($defineresp) {
            unless ($known) {
                print STDERR "SUGGEST\t'$g_cb_queue[-1]'\t(", scalar @g_cb_queue, ")\n"; 
                # ASYNCH
                my $resp = do_suggest($kernel, $channel, undef, shift @g_cb_queue);

                $resp && $g_irc->yield( privmsg => $channel, $resp );
            }
        }
    }

    # look for all other commands in a generic way that also works with /msg and addressing

    # SYNCHRONOUS & ASYNCHRONOUS
    else {
        print "PUBLIC [$ts] <$nick:$channel> $msg\n";
        my $resps = do_command($kernel, $heap, $channel, undef, $msg);

        foreach (@$resps) {
            $g_irc->yield( privmsg => $channel, $_ );
        }
    }
}

# The bot has received a private message.  Parse it for commands, and
# respond to interesting things.

# respond to all plain commands whether or not followed by !
# respond to all ! prefixed commands

sub on_msg {
    my ( $kernel, $heap, $who, $where, $msg ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];
    my $resps;

    $msg = irc_to_utf8($msg);

    my $ts = scalar localtime;
    print "MSG [$ts] <$nick:$channel> $msg\n";

    $resps = do_command($kernel, $heap, undef, $nick, $msg);

    foreach (@$resps) {
        $g_irc->yield( privmsg => $nick, $_ );
    }
}

# The bot has been addressed in a channel.  Parse it for commands, and
# respond to interesting things.

# respond to all plain commands whether or not followed by !
# respond to all ! prefixed commands

sub on_bot_addressed {
    my ( $kernel, $heap, $who, $where, $msg ) = @_[ KERNEL, HEAP, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];
    my $resps;

    $msg = irc_to_utf8($msg);

    my $ts = scalar localtime;
    print "ADDRESS [$ts] <$nick:$channel> $msg\n";

    $resps = do_command($kernel, $heap, $channel, $nick, $msg);

    foreach (@$resps) {
        $g_irc->yield( privmsg => $channel, $nick . ': ' . $_ );
    }
}

# Time to check the next RSS/Atom feed
sub on_feed_timer {
    my $kernel = $_[KERNEL];

    my $feednum = $g_feed_tick % scalar @g_feeds;
    my $feed = $g_feeds[ $feednum ];

    $kernel->post(
        'my-http', 'request',
        'feed_response',
        GET ($feed->{url}),
        $feednum);
}

# handle an incoming RSS/Atom feed
sub on_feed_response {
    my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];
    my $feednum       = $request_packet->[1];
    my $http_response = $response_packet->[0];

    my $feed = $g_feeds[ $feednum ];

    my $was_working = defined $feed->{working} ? $feed->{working} : -1;
    my $is_working = $feed->{working} = $http_response->is_success;

    # unless we're just starting up report feeds which start or stop working
    if ($is_working != $was_working) {
        my $msg = 'feed \'' . $feed->{name} . '\' is ';
        $msg .= 'now ' unless $was_working == -1;
        $msg .= ($is_working ? 'working' : 'down');
        $msg .= ' at startup' if $was_working == -1;

        print STDERR "** $msg\n";
        $g_irc->yield( privmsg => '#hippiebot', $msg );
    }

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

        # bug ENWIKT-36
        eval {
            $parser->parse($http_response->decoded_content);
        };
        if ($@) {
            my $info = "** feed $feed->{name} got invalid XML ($@)\n";
            print STDERR "** $info\n";
            print STDERR "** ", $parser->parse($http_response->decoded_content), "\n";
            $g_irc->yield( privmsg => '#hippiebot', $info );
        } else {
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
                    $announce = ! exists $feed->{seen}->{$t};
                } else {
                    $announce = $i == 0 && !$opt_F;
                }

                if ($opt_d && !$opt_F) {
                    print STDERR 'tick: ', $g_feed_tick, ' ', $feed->{name}, ' item: ', $i, ' title: \'', $t, '\'', $announce ? ' ANNOUNCE' : '', "\n";
                }

                # TODO should each channel should have its own feed delay when one bot can join multiple channels
                foreach my $ch (@{$g_hippiebot{channels}}) {
                    $announce && $g_irc->yield( privmsg => $ch, $feed->{name} . ': ' . $t );
                }

                $feed->{seen}->{$t} = 1;
            }
            $feed->{initial_check_done} = 1;
        }
    }

    $kernel->delay( feed_timer => $g_feed_delay );
    ++ $g_feed_tick;
}

# Time to check the siteinfo
sub on_siteinfo_timer {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    my $uri = 'http://en.wiktionary.org/w/api.php?format=json&action=query&meta=siteinfo';

    post_json_req(
        $kernel, $heap,
        'siteinfo_response',
        GET ($uri));

    return undef;
}

# handle an incoming siteinfo
sub on_siteinfo_response {
    my ($kernel, $heap, undef, $http_code, $ref, $err) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];

    my $was_working = defined $heap->{siteinfo}->{working} ? $heap->{siteinfo}->{working} : -1;
    my $is_working = $heap->{siteinfo}->{working} = defined $ref;

    # unless we're just starting up report when siteinfo starts or stops working
    if ($is_working != $was_working) {
        my $msg = 'siteinfo is ';
        $msg .= 'now ' unless $was_working == -1;
        $msg .= ($is_working ? 'working' : 'down');
        $msg .= ' at startup' if $was_working == -1;

        unless ($is_working) {
            $msg .= " ($http_code: $err)";
        }
        print STDERR "** $msg\n";
        $g_irc->yield( privmsg => '#hippiebot', $msg );
    }

    # report any changes to siteinfo fields
    if ($is_working) {
        my $info;
        if (defined $ref->{query} && defined $ref->{query}->{general}) {
            while (my ($field, $newval) = each %{$ref->{query}->{general}}) {
                # // operator requires Perl 5.10 or greater
                my $oldval = $heap->{siteinfo}->{prev}->{$field} // '(undefined)';

                my $changekey = join("\t", ($field, $oldval, $newval));

                if ($oldval ne $newval) {
                    if (defined $heap->{siteinfo}->{changecache}->{$changekey}) {
                        #print STDERR "** seen this change before '$changekey'\n";

                    } else {
                        if ($oldval eq '(undefined)') {
                            unless ($was_working == -1) {
                                $info = "siteinfo has a new field '$field'";
                                print STDERR "** $info\n";
                                $g_irc->yield( privmsg => '#hippiebot', $info );
                            }
                        } else {
                            unless (grep $_ eq $field, @g_siteinfo_ignore_fields) {
                                $info = "siteinfo field '$field' changed value from '$oldval' to '$newval'";
                                print STDERR "** $info\n";

                                foreach my $ch (@{$g_hippiebot{channels}}) {
                                    $g_irc->yield( privmsg => $ch, $info );
                                }
                            }
                        }

                        #print STDERR "** caching new change '$changekey'\n";
                        $heap->{siteinfo}->{changecache}->{$changekey} = 1;
                    }
                }
                $heap->{siteinfo}->{prev}->{$field} = $newval;
            }
        } else {
            print STDERR "** siteinfo response does not contain query/general\n";
        }
    }

    $kernel->delay( siteinfo_timer => $g_siteinfo_delay );
}

# Time to ping the toolserver to keep fcgi stuff alive
sub on_ts_ping_timer {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    #my $uri = 'http://toolserver.org/~hippietrail/langmetadata.fcgi?format=json&ping=1';
    my $uri = 'http://toolserver.org/~hippietrail/langmetadata.fcgi?format=json&has=syz&ping=1';

    post_json_req(
        $kernel, $heap,
        'ts_ping_response',
        GET ($uri));

    return undef;
}

# handle an incoming ts_ping
sub on_ts_ping_response {
    my ($kernel, $heap, undef, $http_code, $ref, $err) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];

    if (defined $ref) {
        if (exists $ref->{pong}) {
            if ($ref->{pong} == 0) {
                #my $info = "language metadata server has restarted";
                #print STDERR "** $info\n";
                #$g_irc->yield( privmsg => '#hippiebot', $info );
            } else {
                print STDERR "** metadata: pong $ref->{pong}\n";
            }
        } else {
            print STDERR "** metadata: no pong\n";
        }
    } else {
        print STDERR "** metadata: no data\n";
    }

    $kernel->delay( ts_ping_timer => $g_ts_ping_delay );
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

# generically handle commands whether they were said publicly in a channel,
# addressed to the bot specifically, or /msg'd to the bot
sub do_command {
    my ( $kernel, $heap, $channel, $nick, $msg ) = @_;
    my $site;   # XXX just for gf / bf commands
    my $force;
    my $args;
    my $resps = [];

    # asynchronous commands which can return multiple lines
    if ( ($args) = $msg =~ /^lang (.+)/ ) {
        # TODO ASYNCH ?
        $resps = do_lang($kernel, $heap, $channel, $nick, $args);
    }

    # synchronous commands which return one line
    elsif ( $msg =~ /^dumps$/ ) {
        # TODO ASYNCH ??
        $resps->[0] = do_dumps();
    } elsif ( ($args) = $msg =~ /^random\s+(.+)\s*$/ ) {
        # TODO ASYNCH ?
        $resps->[0] = do_random($args);
    }

    # ENWIKT-40     
    #
    # Implement linky to resolve [[wikilinks]] in IRC to full URLs
    elsif ( $msg =~ /\[\[.*\]\]/ ) {
        my $resp = do_linky($channel, $msg);
        $resps->[0] = $resp if defined $resp;
    }

    # asynchronous commands
    elsif ( ($site, $force, $args) = $msg =~ /^([bg])f(!)?\s+(.+)\s*$/ ) {
        my $resp = do_gf($kernel, $channel, $nick, $site, $force, $args);
        $resps->[0] = $resp if defined $resp;
    } elsif ( ($args) = $msg =~ /^!suggest\s+(.+)\s*$/ ) {
        my $resp = do_suggest($kernel, $channel, $nick, $args);
        $resps->[0] = $resp if defined $resp;
    } elsif ( ($args) = $msg =~ /^toc\s+(.+)\s*$/ ) {
        my $resp = do_toc($kernel, $heap, $channel, $nick, $args);
        $resps->[0] = $resp if defined $resp;
    } elsif ( ($args) = $msg =~ /^whatis\s+(.+)\s*$/ ) {
        my $resp = do_whatis($kernel, $heap, $channel, $nick, $args);
        $resps->[0] = $resp if defined $resp;
    }

    return $resps;
}

# TODO ASYNCHRONOUS
sub do_lang {
    my ( $kernel, $heap, $channel, $nick, $input ) = @_;
    my %codes = ( $input => 1 );

    my $newuri = 'http://toolserver.org/~hippietrail/langmetadata.fcgi?langs=';

    # input may be a language code or language name, in fact it could be both!

    # if input is a 3-letter language code we'll also look up any equivalent 2-letter code it may have
    
    # XXX not available if langmetadata failed at bot startup
    if (exists $g_three2one{$input}) {
        ++ $codes{ $g_three2one{$input} };
    } elsif (exists $g_twob2one{$input}) {
        ++ $codes{ $g_twob2one{$input} };
    }

    # try to ignore case and diacritics
    my $nname = normalize_lang_name($input);

    # if input is a language name we'll find all matching language codes, even when two languages have
    # the same name

    # XXX not available if langmetadata failed at bot startup
    if (exists $g_name2code{$nname}) {
        ++ $codes{ $_ } for @{$g_name2code{$nname}};
    }

    # now look up all the codes at once on the language metadata server

    my $fulluri = $newuri . join(',' , keys %codes);

    my $id = $g_lang_id ++;

    $heap->{lang}->[$id] = { channel => $channel, nick => $nick, input => $input, codes => join(',' , keys %codes) };

    post_json_req(
        $kernel, $heap,
        'lang_response',
        GET ($fulluri),
        $id);

    return undef;
}

sub on_lang_response {
    my ($kernel, $heap, $id, $http_code, $ref, $err) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];

    my $langreq = $heap->{lang}->[$id];
    my $input = $langreq->{input};
    #my $codes = $langreq->{codes};

    my $ok = 0;
    my @resps;

    if (my $metadata = $ref) {
        # add code=>name pairs extracted from the Wiktionary templates
        # normalize ISO 639-2 B and ISO 639-3 -> ISO 639-2
        if ($USE_WIKI_TEMPLATES) {
            my $key = $input;

            for my $iso2 (keys %$metadata) {
                if (exists $metadata->{$iso2}->{iso3} && $metadata->{$iso2}->{iso3} eq $input) {
                    $key = $iso2;
                } elsif (exists $metadata->{$iso2}->{iso2b} && $metadata->{$iso2}->{iso2b} eq $input) {
                    $key = $iso2;
                }
            }

            if (exists $g_enwikt{$input}) {
                $metadata->{$key}->{enwiktname} = $g_enwikt{$input};
            }

            # add code=>name pairs extracted from the Wikipedia templates
            if (exists $g_enwiki{$key}) {
                $metadata->{$key}->{enwikiname} = $g_enwiki{$input};
            }
        }

        # can we parallelize the next call with the previous call?  
        # the above logic can add an $input key to $metadata
        # we send the keys of $metadata to DBpedia but might we know these values before?
        # why do we get the keys from $metadata rather than just using $codes? (other than | vs , separator)

        if ($metadata) {
            if (scalar keys %$metadata) {
                # DBpedia metadata
                my $endpoint = 'http://dbpedia.org/sparql?default-graph-uri=http%3A%2F%2Fdbpedia.org&format=json&query=';
                my $query = 'PREFIX p: <http://dbpedia.org/property/> PREFIX t: <http://dbpedia.org/resource/Template:> SELECT DISTINCT ?lc,?fn,?fc WHERE{?lp p:wikiPageUsesTemplate t:infobox_language;p:iso ?lc;p:fam ?fp.?fp p:wikiPageUsesTemplate t:infobox_language_family;p:name ?fn.optional{?fp p:iso ?fc}.FILTER (regex(?lc,"^(' . join('|', keys %$metadata) . ')$"))}ORDER BY ?lc';
                my $uri = $endpoint . uri_escape($query);
                my @dbp;

                # TODO asynch? parallelize? use post_json_req()?
                if (my $json = get $uri) {
                    # TODO try/catch with eval in case $json does not contain legal JSON
                    my $data = $g_js->decode($json);
                    if (exists $data->{results} && exists $data->{results}->{bindings}) {
                        foreach my $b (@{$data->{results}->{bindings}}) {
                            my $l = {
                                lc => $b->{lc}->{value},
                                fc => exists $b->{fc}->{value} ? $b->{fc}->{value} : undef,
                                fn => $b->{fn}->{value} };
                            push @dbp, $l;
                        }
                    } else { print STDERR "** no results or bindings iin DBpedia JSON result\n"; }
                } else { print STDERR "** DBpedia HTTP get failed\n"; }

                foreach my $l (keys %$metadata) {
                    my $eng = metadata_to_english($l, $metadata->{$l}, \@dbp);
                    #use Data::Dumper; print Dumper { $l => $eng };
                    if ($eng) {
                        $ok = 1;
                        push @resps, $eng;
                    }
                }
            } else {
                # TODO only report which sources were actually checked since sitmatrix, wikt, langmetadata, etc may be broken individually
                @resps = ($input . ': can\'t find it in ISO 639-3, WikiMedia Sitematrix, or en.wiktionary language templates.');
            }
        } else {
            if ($@) {
                @resps = ('something went wrong: ' . $@);
            } else {
                @resps = ($input . ': can\'t find it in en.wiktionary language templates.');
            }
        }
    } else { print STDERR "** $http_code : ", defined $err ? $err : '(no err msg)', "\n"; }

    for my $resp (@resps) {
        # TODO generic yield privmsg sub
        print STDERR "** $resp\n";
        if (defined $langreq->{channel} && defined $langreq->{nick}) {
            $g_irc->yield( privmsg => $langreq->{channel}, $langreq->{nick} . ': ' . $resp );
        } elsif (defined $langreq->{channel}) {
            $g_irc->yield( privmsg => $langreq->{channel}, $resp );
        } elsif (defined $langreq->{nick}) {
            $g_irc->yield( privmsg => $langreq->{nick}, $resp );
        } else {
            print STDERR "** lang no channel or nick impossible!\n";
        }
    }
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
    if ($USE_WIKI_TEMPLATES) {
        if ($l->{enwiktname}) {
            $names{$l->{enwiktname}} = 1;
        }
        if ($l->{enwikiname}) {
            $names{$l->{enwikiname}} = 1;
        }
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
        if (exists $l->{iso2b}) {
            $resp .= ', ' . $l->{iso2b};
        }
        $resp .= ': '. join '; ', keys %names;

        if (exists $l->{fam} || exists $l->{geo} || scalar @$dbp) {
            $resp .= ', a';

            my $famcode;
            my $famname;

            if (exists $l->{fam}) {
                $famcode = $l->{fam};
                $famname = $g_fam{$famcode};
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
        } elsif ($USE_WIKI_TEMPLATES && exists $l->{enwiktname}) {
            $resp .= 'It\'s an en.wiktionary extension to ISO';
        } elsif ($USE_WIKI_TEMPLATES && exists $l->{enwikiname}) {
            $resp .= 'It\'s an en.wikipedia extension to ISO';
        } else {
            # hard-coded addittional info from langmetadata server
            $resp .= 'It\'s an extension to ISO';
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
    } else {
        $resp .= ' (' . @dat . ')';
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

# ASYNCHRONOUS
sub do_toc {
    my ( $kernel, $heap, $channel, $nick, $page ) = @_;

    my $uri = 'http://en.wiktionary.org/w/api.php?format=json&action=parse&prop=sections&page=' . $page;

    my $id = $g_toc_id ++;

    $heap->{toc}->[$id] = { channel => $channel, nick => $nick, page => $page };

    post_json_req(
        $kernel, $heap,
        'toc_response',
        GET ($uri),
        $id);

    return undef;
}

sub on_toc_response {
    my ($kernel, $heap, $id, $http_code, $ref, $err) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];

    my $tocreq = $heap->{toc}->[$id];
    my $page = $tocreq->{page};

    my $ok = 0;
    my $resp = $page . ': ';

    if (my $data = $ref) {
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
        } else {
            print STDERR "** toc: JSON data missing parse/sections fields\n";
        }
    } else { print STDERR "** toc: $http_code : $err\n"; }

    hippbotlog('toc', '', $ok);

    if (defined $tocreq->{channel} && defined $tocreq->{nick}) {
        $g_irc->yield( privmsg => $tocreq->{channel}, $tocreq->{nick} . ': ' . $resp );
    } elsif (defined $tocreq->{channel}) {
        $g_irc->yield( privmsg => $tocreq->{channel}, $resp );
    } elsif (defined $tocreq->{nick}) {
        $g_irc->yield( privmsg => $tocreq->{nick}, $resp );
    } else {
        print STDERR "** toc no channel or nick impossible!\n";
    }
}

# ASYNCHRONOUS
sub do_gf {
    my $kernel = shift;
    my $channel = shift;
    my $nick = shift;
    my $site = shift;
    my $force = shift;
    my $args= shift;
    my $ok = 0;
    my $resp = undef;

    if ($channel) {
        if (grep $_ eq 'know-it-all', $g_irc->channel_list($channel)) {
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

        # TODO use heap
        $g_googlefights{$g_googlefight_id} = {
            channel => $channel,
            nick => $nick,
            numterms => scalar keys %terms,
        };

        foreach my $term (keys %terms) {
            $term =~ s/  +/+/g;

            $kernel->post(
                'my-http', 'request',
                'gf_response',
                GET ('http://www.' . ($site eq 'g' ? 'google' : 'bing') . '.com/search?q=' . $term),
                $g_googlefight_id . '.' . $site . '.' . $term);
        }

        # TODO use heap
        ++ $g_googlefight_id;
    }

    hippbotlog('gf', '', $ok);

    return undef;
}

# handle an incoming googlefight response
sub on_gf_response {
    my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];

    my $gf_req_id     = $request_packet->[1];
    my $http_response = $response_packet->[0];

    $gf_req_id =~ /^(\d+)\.(.*?)\.(.*?)$/;
    my ($gf_id, $site, $term) = ($1, $2, $3);
    my $fight = $g_googlefights{$gf_id};    # TODO use heap

    # parse html
    my $pattern = $site eq 'g'
        ? '<div id=resultStats>\D* ([0-9,.]+) \D*<nobr>'
        : '<span class="sb_count" id="count">1-\d+ .*? ([0-9\.]+) .*?<\/span>';
    if ($http_response->decoded_content =~ /$pattern/) { # }
        $fight->{terms}->{$term} = [$1, $1];
        $fight->{terms}->{$term}->[1] =~ s/[,.]//g;
    } else {
        $fight->{terms}->{$term} = [0, 0];
    }

    -- $fight->{numterms};

    if ($fight->{numterms} == 0) {
        my $resp = $site eq 'g' ? 'Google' : 'Bing';
        $resp .= 'fight: ' . join(
            ', ',
            map {
                ($_ =~ /^".*"$/ ? $_ : '\'' . $_ . '\'') . ': ' . $fight->{terms}->{$_}->[0]
            } sort {
                $fight->{terms}->{$b}->[1] <=> $fight->{terms}->{$a}->[1]
            } keys %{$fight->{terms}});

        # TODO generic yield privmsg sub
        if (defined $fight->{channel} && defined $fight->{nick}) {
            $g_irc->yield( privmsg => $fight->{channel}, $fight->{nick} . ': ' . $resp );
        } elsif (defined $fight->{channel}) {
            $g_irc->yield( privmsg => $fight->{channel}, $resp );
        } elsif (defined $fight->{nick}) {
            $g_irc->yield( privmsg => $fight->{nick}, $resp );
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

    $kia = scalar grep $_ eq 'know-it-all', $g_irc->channel_list($channel);
    $cb = scalar grep $_ eq 'club_butler', $g_irc->channel_list($channel);

    # define doesn't work with /msg
    if ($channel) {
        if ($bot eq 'know-it-all') {
            if ($kia) {
                if ($channel ne '#wiktionary') {
                    push @g_kia_queue, $term;
                    $ok = 1;
                    print STDERR "KIA-DEFINE '$term' (", scalar @g_kia_queue, ")\n";
                }
            } elsif ($cb) {
                $resp = 'try ".?" instead of "define"';
            } else {
                $resp = 'too bad know-it-all isn\'t here';
            }
        } elsif ($bot eq 'club_butler') {
            if ($cb) {
                if ($channel ne '#wiktionary') {
                    push @g_cb_queue, $term;
                    $ok = 1;
                    print STDERR "CB-DEFINE '$term' (", scalar @g_cb_queue, ")\n";
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
    my $rawterm = shift;

    ## which scripts are used in this term

    my %script;

    my @ch = split //, $rawterm;
    for my $ch (@ch) {
        my $s = charscript(ord $ch);
        ++ $script{$s}
    }

    # heuristics to decide languages based on scripts
    # TODO use langmetadata server ?

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
    my $term = uri_escape_utf8($rawterm);

    # TODO use heap
    my $suggq = $g_suggests{$g_suggest_id} = {
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
            $g_suggest_id . '.' . 'g' . '-' . $lc . '-' . $term);

        ++ $suggq->{numresps};

        # English-only sites
        # merriam-webster.com
        if ($lc eq 'en') {
            $url = 'http://www.merriam-webster.com/dictionary/' . $term;

            $kernel->post(
                'my-http', 'request',
                'sugg_response',
                GET ($url),
                $g_suggest_id . '.' . 'mw' . '-' . $lc . '-' . $term);

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
                $g_suggest_id . '.' . 'mw' . '-' . $lc . '-' . $term);

            ++ $suggq->{numresps};
        }

        # Wiktionaries and Wikipedias
        for my $site (('wiktionary', 'wikipedia')) {
            $url = 'http://' . $lc . '.' . $site . '.org/w/api.php?format=json&action=query&list=search&srinfo=suggestion&srprop=&srlimit=1&srsearch='. $term;

            $kernel->post(
                'my-http', 'request',
                'sugg_response',
                GET ($url),
                $g_suggest_id . '.' . $site . '-' . $lc . '-' . $term);

            ++ $suggq->{numresps};
        }
    }

    # get previous and next terms across all language names
    $url = 'http://toolserver.org/~hippietrail/nearbypages.fcgi?langname=*&term=' . $term;

    $kernel->post(
        'my-http', 'request',
        'sugg_response',
        GET ($url),
        $g_suggest_id . '.' . 'nearby' . '-' . '*' . '-' . $rawterm);

    ++ $suggq->{numresps};

    $suggq->{allreqs} = 1;
    ++ $g_suggest_id;

    return undef;
}

# handle an incoming suggest response
sub on_sugg_response {
    my ($kernel, $heap, $request_packet, $response_packet) = @_[KERNEL, HEAP, ARG0, ARG1];

    my $sugg_req_id = $request_packet->[1];
    my $http_response = $response_packet->[0];

    $sugg_req_id =~ /^(\d+)\.(.*)-(.*)-(.*)$/;
    my ($sugg_id, $site, $lang, $term) = ($1, $2, $3, $4);
    my $fight = $g_suggests{$sugg_id};

    # PARSE $http_response->decoded_content

    # used by each suggestor
    my $json;
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
                # TODO try/catch with eval in case $json does not contain legal JSON
                my $res = $g_js->decode($json);
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
                my $res;
                eval {
                    # the logic of utf8() is reversed for decode() but correct for encode()!!
                    my $confusing = ! utf8::is_utf8($json);
                    $res = $g_js->utf8($confusing)->decode($json);  # works with charset => 'UTF-8' above
                };
                if ($@) {
                    print STDERR "** suggest/nearby got invalid JSON\n";
                } else {
                    if (exists $res->{prev}) {
                        $fight->{dym}->{$res->{prev}->[0]} += 0.5;
                    }
                    if (exists $res->{next}) {
                        $fight->{dym}->{$res->{next}->[0]} += 0.5;
                    }
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
                # TODO try/catch with eval in case $json does not contain legal JSON
                my $res = $g_js->decode($json);

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
            $resp = $term . ': did you mean ' . $sugg . ' ?';
            # IRC -> ANSI colour conversion
            $sugg =~ s/\00301/\e[0m/g; # IRC black / ANSI white
            $sugg =~ s/\00302/\e[34m/g; # red
            $sugg =~ s/\00304/\e[31m/g; # blue
        } else {
            $resp = 'I have little to suggest for "' . $term . '".';
        }

        # TODO generic yield privmsg sub
        if (defined $fight->{channel} && defined $fight->{nick}) {
            $g_irc->yield( privmsg => $fight->{channel}, $fight->{nick} . ': ' . $resp );
        } elsif (defined $fight->{channel}) {
            $g_irc->yield( privmsg => $fight->{channel}, $resp );
        } elsif (defined $fight->{nick}) {
            $g_irc->yield( privmsg => $fight->{nick}, $resp );
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

# SYNCHRONOUS
sub do_linky {
    my $channel = shift;
    my $msg = shift;
    my $resp = undef;

    if ($channel) {
        unless (grep $_ eq 'know-it-all', $g_irc->channel_list($channel)) {
            my @l = ($msg =~ /\[\[.*?\]\]/g);
            $resp = join(', ', map { 'http://en.wiktionary.org/wiki/' . uri_escape_utf8(substr $_, 2, -2) } @l);
        }
    }
    return $resp;
}

# ASYNCHRONOUS
sub do_whatis {
    my ( $kernel, $heap, $channel, $nick, $page ) = @_;

    my $uri = 'http://en.wiktionary.org/w/api.php?action=query&prop=revisions&rvlimit=1&rvprop=content&format=json&titles=' . $page;

    my $id = $g_whatis_id ++;

    $heap->{whatis}->[$id] = { channel => $channel, nick => $nick, page => $page };

    post_json_req(
        $kernel, $heap,
        'whatis_response',
        GET ($uri),
        $id);

    return undef;
}

sub on_whatis_response {
    my ($kernel, $heap, $id, $http_code, $ref, $err) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];

    my $whatisreq = $heap->{whatis}->[$id];
    my $page = $whatisreq->{page};

    my $ok = 0;
    my $resp = undef;

    if (my $data = $ref) {
        if (exists $data->{query} && exists $data->{query}->{pages}) {
            my $key = (keys %{$data->{query}->{pages}})[0];

            if ($key == -1) {
                $resp = do_suggest($kernel, $whatisreq->{channel}, $whatisreq->{nick}, $page);
            } else {
                my $ns = $data->{query}->{pages}->{$key}->{ns};

                if ($ns == 0) {
                    my $text = $data->{query}->{pages}->{$key}->{revisions}->[0]->{'*'};

                    my $langnum = 0;
                    my $langname = undef;
                    my $heading = undef;
                    my $depth = -1;
                    my $def = undef;

                    while ($text =~ /(.+)$/mg) {
                        my $l = $1;
                        if ($l =~ /^==\s*([^=]+?)\s*==\s*$/) {
                            ++ $langnum;
                            last if $langnum > 2;

                            $langname = $1;

                            $heading = undef;
                            $depth = -1;
                            $def = undef;
                        } elsif ($l =~ /^(===+)\s*([^=]+?)\s*\1\s*$/) {
                            $depth = length $1;
                            $heading = $2;
                            
                            $depth = -1;
                            $def = undef;
                        } elsif ($l =~ /^#\s*(.*?)\s*$/) {
                            if (defined $langname) {
                                $def = $1;
                                print "** ($langnum) $langname/$heading '$def'\n";

                                # get the first translingual def but keep looking
                                if ($langname eq 'Translingual') {
                                    if ($resp eq undef) {
                                        $resp = $page . ': ' . $langname . '/' . $heading . ': ' . $def;
                                        $ok = 1;
                                        print STDERR "** first translingual def\n";
                                    }
                                # get the first def of the first real language
                                } else {
                                    if ($langname eq 'English' || !defined $resp) {
                                        $resp = $page . ': ' . $langname . ' ' . $heading . ': ' . $def;
                                        $ok = 1;
                                        print STDERR "** first def that's not translingual\n";
                                        last;
                                    }
                                }
                            } else {
                                print STDERR "** found # line without language name: possibly a redirect\n";
                                $resp = $page . ': might be a redirect';
                            }
                        }
                    }
                } else {
                    $resp = $page . ': not a valid entry title';
                }
            }
        } else {
            print STDERR "** whatis: JSON data missing query/pages fields\n";
        }
    } else { print STDERR "** whatis: $http_code : $err\n"; }

    hippbotlog('whatis', '', $ok);

    if ($ok) {
        my $uri = 'http://en.wiktionary.org/w/api.php?format=json&action=parse&prop=text&disablepp&title=' . $page . '&text=' . $resp;

        my $id = $g_whatis_id_2 ++;

        $heap->{whatis_2}->[$id] = { channel => $whatisreq->{channel}, nick => $whatisreq->{nick}, page => $page };

        post_json_req(
            $kernel, $heap,
            'whatis_response_2',
            GET ($uri),
            $id);
    } else {
        if (defined $whatisreq->{channel} && defined $whatisreq->{nick}) {
            $g_irc->yield( privmsg => $whatisreq->{channel}, $whatisreq->{nick} . ': ' . $resp );
        } elsif (defined $whatisreq->{channel}) {
            $g_irc->yield( privmsg => $whatisreq->{channel}, $resp );
        } elsif (defined $whatisreq->{nick}) {
            $g_irc->yield( privmsg => $whatisreq->{nick}, $resp );
        } else {
            print STDERR "** whatis no channel or nick impossible!\n";
        }
    }
}

sub on_whatis_response_2 {
    my ($kernel, $heap, $id, $http_code, $ref, $err) = @_[KERNEL, HEAP, ARG0, ARG1, ARG2, ARG3];

    my $whatisreq_2 = $heap->{whatis_2}->[$id];
    my $page = $whatisreq_2->{page};

    my $ok = 0;
    my $resp = undef;

    if (my $data = $ref) {
        if (exists $data->{parse} && exists $data->{parse}->{text}) {
            my $html = $data->{parse}->{text}->{'*'};

            my $hs = HTML::Strip->new();
            my $plain = $hs->parse($html);

            $resp = $plain;
            $ok = 1;
        } else {
            print STDERR "** whatis: JSON data missing parse/text fields\n";
        }
    } else { print STDERR "** whatis_2: $http_code : $err\n"; }

    hippbotlog('whatis_2', '', $ok);

    if (defined $whatisreq_2->{channel} && defined $whatisreq_2->{nick}) {
        $g_irc->yield( privmsg => $whatisreq_2->{channel}, $whatisreq_2->{nick} . ': ' . $resp );
    } elsif (defined $whatisreq_2->{channel}) {
        $g_irc->yield( privmsg => $whatisreq_2->{channel}, $resp );
    } elsif (defined $whatisreq_2->{nick}) {
        $g_irc->yield( privmsg => $whatisreq_2->{nick}, $resp );
    } else {
        print STDERR "** whatis_2 no channel or nick impossible!\n";
    }
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

