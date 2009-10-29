#!/usr/bin/perl

# This was a simple IRC bot that knows about languages.
# It originally responded to:
# "lang <code>", "dumps", "random <language code|language name>"

use warnings;
use strict;
use utf8; # needed due to literal unicode for stripping diacritics

use File::HomeDir;
use HTML::Entities;
use JSON -support_by_pp;
use LWP::Simple qw(get $ua);
use LWP::UserAgent;
use POE;
use POE::Component::IRC::Common qw(irc_to_utf8);
use POE::Component::IRC::State;
use Getopt::Std;
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

# set a useragent
$ua->agent('hippiebot');

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

$js = $js->utf8 if $LWP::Simple::VERSION < 5.827;

# ISO 639-3 to ISO 639-1 mapping: 3-letter to 2-letter
my %three2one;
my %name2code;

# TODO handle error
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

sub CHANNEL () { defined $opt_c ? $opt_c : defined $opt_d ? '#Wiktionarydev' : '#wiktionary' }
sub BOTNICK () { defined $opt_n ? $opt_n : defined $opt_d ? 'hippiebot-d' : 'hippiebot' }
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

my @dunno_it_all;

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC::State->spawn();

# Create the bot session.  The new() call specifies the events the bot
# knows about and the functions that will handle those events.
POE::Session->create(
    inline_states => {
        _start     => \&bot_start,
        irc_001    => \&on_connect,
        irc_public => \&on_public,
        irc_msg    => \&on_msg,
        feeds      => \&on_feeds,
    },
);

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
    my $kernel = $_[KERNEL];

    # feed stuff
    $kernel->delay( feeds => $feed_delay );

    # IRC stuff
    $irc->yield( register => "all" );

    $irc->yield( connect =>
          { Nick => BOTNICK,
            Username => 'hippiebot',
            Ircname  => 'POE::Component::IRC hippietrail bot',
            Server   => 'irc.freenode.net',
            Port     => '6667',
          }
    );
}

# The bot has successfully connected to a server.  Join a channel.
sub on_connect {
    $irc->yield( join => CHANNEL );
}

# The bot has received a public message.  Parse it for commands, and
# respond to interesting things.
sub on_public {
    my ( $kernel, $who, $where, $msg, $nickserv ) = @_[ KERNEL, ARG0, ARG1, ARG2, ARG3 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    $msg = irc_to_utf8($msg);

    my $ts = scalar localtime;

    if ( my ($incode) = $msg =~ /^lang (.+)/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resps = do_lang($incode);
        foreach (@$resps) {
            $irc->yield( privmsg => CHANNEL, $_ );
        }
    }

    elsif ( $msg =~ /^dumps$/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_dumps();

        $resp && $irc->yield( privmsg => CHANNEL, $resp );
    }

    elsif ( my ($lang) = $msg =~ /^random (.+)$/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_random($lang);

        $resp && $irc->yield( privmsg => CHANNEL, $resp );
    }

    elsif ( my ($page) = $msg =~ /^toc (.+)$/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_toc($page);

        $resp && $irc->yield( privmsg => CHANNEL, $resp );
    }

    elsif ( my ($force, $args) = $msg =~ /^gf(!)? (.+)$/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_gf($channel, $force, $args);

        $resp && $irc->yield( privmsg => CHANNEL, $resp );
    }

    elsif ( my ($term) = $msg =~ /^define (.+)$/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_define($channel, $term);

        $resp && $irc->yield( privmsg => CHANNEL, $resp );
    }

    elsif ( $nick eq 'hippietrail' && $nickserv ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_hippietrail($msg);

        $resp && $irc->yield( privmsg => CHANNEL, $resp );
    }

    elsif ( $nick eq 'know-it-all' ) {
        my ($defineresp, $known);

        if ( $msg =~ '^This page doesnt seem to exist.' ) {
            $defineresp = 1;
            $known = 0;

        # long definitions are cut short so don't check for the final full stop
        } elsif ( $msg =~ /^'.*' is .*: / ) {
            $defineresp = 1;
            $known = 1;
        }

        if ($defineresp) {
            print " [$ts] <$nick:$channel> $msg\n";

            my $term = shift @dunno_it_all;

            my $resp;
            
            unless ($known) {
                my $html;
                my $json;
                my $res;
                my @a;
                my %dym;

                my %script;

                my @ch = split //, $term;
                for my $ch (@ch) {
                    my $s = charscript(ord $ch);
                    ++ $script{$s}
                }

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
                        ++ $names{$_} for ('Greek', 'Ancient Gree');
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
                    } elsif ($s eq 'Lao') {
                        ++ $codes{$_} for ('lo');
                        ++ $names{$_} for ('Lao');
                    } elsif ($s eq 'Latin') {
                        ++ $codes{$_} for ('en', 'de', 'fr', 'es');
                        ++ $names{$_} for ('English', 'German', 'French', 'Spanish');
                    } elsif ($s eq 'Thai') {
                        ++ $codes{$_} for ('th');
                        ++ $names{$_} for ('Thai');
                    } else {
                        print STDERR "** unhandled script: $s\n";
                    }
                }

                $term = uri_escape_utf8($term);

                for my $lc (keys %codes) {
                    print STDERR "g-$lc\n";
                    $html = get 'http://www.google.com.au/search?hl=' . $lc . '&q=' . $term;

                    if ($html =~ /class="?spell"?><b><i>(.*?)<\/i><\/b><\/a>/) {
                        my $t = decode_entities($1);
                        print STDERR "\t$t\n";
                        ++ $dym{$t};
                    }

                    if ($lc eq 'en') {
                        print STDERR "mw-$lc\n";
                        $html = get 'http://www.merriam-webster.com/dictionary/' . $term;

                        if ($html =~ /class="franklin-spelling-help">((?: \t<li><a href=".*?">.*?<\/a><\/li>)+) <\/ol>/) {
                            if (@a = $1 =~ / \t<li><a href=".*?">(.*?)<\/a><\/li>/g) {
                                for (@a) {
                                    print STDERR "\t$_\n";
                                    $dym{$_} += 0.5;
                                }
                            }
                        }

                        print STDERR "enc-$lc\n";
                        $html = get 'http://encarta.msn.com/dictionary_/' . $term . '.html';

                        if (@a = $html =~ /<tr><td class="NoResultsSuggestions"><a href=".*?">(.*?)<\/a><\/td><\/tr>/g) {
                            for (@a) {
                                print STDERR "\t$_\n";
                                ++ $dym{$_};
                            }
                        }
                    }

                    for my $site (('wiktionary', 'wikipedia')) {
                        print STDERR "$site-$lc\n";
                        $json = get 'http://' . $lc . '.' . $site . '.org/w/api.php?format=json&action=query&list=search&srinfo=suggestion&srprop=&srlimit=1&srsearch='. $term;

                        if ($json) {
                            $res = $js->decode($json);
                            if (exists $res->{query} && exists $res->{query}->{searchinfo} && exists $res->{query}->{searchinfo}->{suggestion}) {
                                print STDERR "\t$res->{query}->{searchinfo}->{suggestion}\n";
                                ++ $dym{$res->{query}->{searchinfo}->{suggestion}};
                            }
                        }
                    }
                }

                for my $ln (keys %names) {
                    print STDERR "near-$ln\n";
                    $json = get 'http://toolserver.org/~hippietrail/nearbypages.fcgi?langname=' . $ln . '&term=' . $term;

                    if ($json) {
                        $res = $js->decode($json);

                        if (exists $res->{prev}) {
                            print "\t$res->{prev}->[0]\n";
                            $dym{$res->{prev}->[0]} += 0.5;
                        }
                        if (exists $res->{next}) {
                            print "\t$res->{next}->[0]\n";
                            $dym{$res->{next}->[0]} += 0.5;
                        }
                    }
                }

                # now check which of these are blue links on enwikt
                my $sugg = '';
                if (%dym) {
                    print STDERR "bluelink-check\n";
                    $json = get 'http://en.wiktionary.org/w/api.php?format=json&action=query&titles=' . join('|', keys %dym);

                    my %col;

                    if ($json) {
                        $res = $js->decode($json);

                        if (exists $res->{query} && exists $res->{query}->{pages}) {
                            for my $d (values %{$res->{query}->{pages}}) {
                                my $t = $d->{title};
                                print "\t$t\n";
                                if (exists $d->{missing}) {
                                    $col{$t} = '04';     # red
                                } else {
                                    $dym{$t} += 2;
                                    $col{$t} = '02';     # blue
                                }
                            }
                        }
                    }

                    # let's see how they rated
                    for my $t (sort {$dym{$b} <=> $dym{$a}} keys %dym) {
                        print STDERR "$dym{$t} -> '$t' ($col{$t})\n";
                        if (length $sugg < 48) {
                            $sugg .= ", " if $sugg ne '';
                            $sugg .= "\003$col{$t}$t\00301";
                        }
                    }
                }

                if ($sugg) {
                    $resp = 'did you mean ' . $sugg . ' ?';
                } else {
                    $resp = 'I have little to suggest.';
                }
            }

            $resp && $irc->yield( privmsg => CHANNEL, $resp );
        }
    }
}

# The bot has received a private message.  Parse it for commands, and
# respond to interesting things.
sub on_msg {
    my ( $kernel, $who, $where, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    $msg = irc_to_utf8($msg);

    my $ts = scalar localtime;
    print " [$ts] <$nick:$channel> $msg\n";

    if ( my ($incode) = $msg =~ /^lang (.+)/ ) {
        my $resps = do_lang($incode);
        foreach (@$resps) {
            $irc->yield( privmsg => $nick, $_ );
        }
    }

    elsif ( $msg =~ /^dumps$/ ) {
        my $resp = do_dumps();

        $resp && $irc->yield( privmsg => $nick, $resp );
    }

    elsif ( my ($lang) = $msg =~ /^random (.+)$/ ) {
        my $resp = do_random($incode);

        $resp && $irc->yield( privmsg => $nick, $resp );
    }

    elsif ( my ($page) = $msg =~ /^toc (.+)$/ ) {
        my $resp = do_toc($page);

        $resp && $irc->yield( privmsg => $nick, $resp );
    }

    elsif ( my ($args) = $msg =~ /^gf (.+)$/ ) {
        my $resp = do_gf(undef, undef, $args);

        $resp && $irc->yield( privmsg => $nick, $resp );
    }

    elsif ( my ($term) = $msg =~ /^define (.+)$/ ) {
        my $resp = do_define(undef, $term);

        $resp && $irc->yield( privmsg => $nick, $resp );
    }
}

sub on_feeds {
    my $kernel = $_[KERNEL];

    my $feed = $feeds[ $tick_num % scalar @feeds ];

    my $xml = get $feed->{url};

    if ($xml) {
        my $in = 0;
        my $txt;
        my @titles;
        my $parser = XML::Parser::Lite->new(
            Handlers => {
                Start => sub {
                    my (undef, $tag) = @_;
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
                        push @titles, $txt;
                    }
                    $in -= $tag eq 'entry' || $tag eq 'item';
                    $txt = '';
                }
            }
        );

        $parser->parse($xml);

        for (my $i = 0; $i < scalar @titles; ++$i) {
            my $t = $titles[$i];
            $t =~ s/(\s|\r|\n)+/ /sg;
            $t =~ s/\s+$//;
            decode_entities($t);
            $t =~ s/<(?:[^>'"]*|(['"]).*?\1)*>//gs;

            my $announce = 0;

            # when starting up, the newist item, unless -F
            # after that, all *new* items

            if ($tick_num < scalar @feeds) {
                $announce = $i == 0 && !$opt_F;
            } else {
                $announce = ! exists $feed->{hash}->{$t};
            }

            $opt_d && !$opt_F && print STDERR 'tick: ', $tick_num, ' ', $feed->{name}, ' item: ', $i, ' title: \'', $t, '\'', $announce ? ' ANNOUNCE' : '', "\n";

            $announce && $irc->yield( privmsg => CHANNEL, $feed->{name} . ': ' . $t );

            $feed->{hash}->{$t} = 1;
        }

    } else {
        print STDERR "didn't get feed '$feed->{name}' ($!)\n";
    }

    $kernel->delay( feeds => $feed_delay );
    ++ $tick_num;
}

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
            foreach my $l (%$metadata) {
                my $eng = metadata_to_english($l, $metadata->{$l});
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

        if (exists $l->{fam} || exists $l->{geo}) {
            $resp .= ', a';
            if (exists $l->{fam}) {
                my $famcode = $l->{fam};
                my $famname = $fam{$famcode};
                $famname = '"' . $famcode . '"' unless ($famname);
                if ($famcode eq 'Isolate') {
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

sub do_toc {
    my $page = shift;
    my $ok = 0;
    my $resp = $page . ': ';

    my $uri = 'http://en.wiktionary.org/w/api.php?action=parse&prop=sections&page=';

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

sub do_gf {
    my $channel = shift;
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
        my %searches;

        $searches{$_}=undef for ($args =~ /(".*?"|\S+)/g);

        foreach my $term (keys %searches) {
            $term =~ s/  +/+/g;

            my $html = get 'http://www.google.com.au/search?q=' . $term;

            if ($html =~ /Results <b>1<\/b> - <b>\d+<\/b> of about <b>([0-9,]+)<\/b> for <b>/) {
                $searches{$term} = [$1, $1];
                $searches{$term}->[1] =~ s/,//g;
            }
        }
        $resp = 'Googlefight: ' . join(
            ', ',
            map {
                ($_ =~ /^".*"$/ ? $_ : '\'' . $_ . '\'') . ': ' . $searches{$_}->[0]
            } sort {
                $searches{$b}->[1] <=> $searches{$a}->[1]
            } keys %searches);
    }

    hippbotlog('gf', '', $ok);

    return $resp;
}

sub do_define {
    my $channel = shift;
    my $term = shift;
    my $ok = 0;
    my $resp = undef;

    if ($channel) {
        if (grep $_ eq 'know-it-all', $irc->channel_list($channel)) {
            push @dunno_it_all, $term;
        } else {
            $ok = 1;
            # define no know it all
        }
    } else {
        $ok = 1;
    }

    if ($ok) {
        $resp = 'too bad know-it-all isn\'t here';
        $ok = 0;
    } else {
        # define not ok
    }

    hippbotlog('define', '', $ok);

    return $resp;
}

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

