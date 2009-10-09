#!/usr/bin/perl

# This is a simple IRC bot that knows about languages. It responds to:
# "lang <code>", "dumps", "random <language code|language name>"

use warnings;
use strict;
use utf8; # needed due to literal unicode for stripping diacritics

use File::HomeDir;
use JSON;
use LWP::Simple;
use LWP::UserAgent;
use POE;
use POE::Component::IRC::Common qw(irc_to_utf8);
use POE::Component::IRC::State;
use Tie::TextDir;
use Time::Duration;
use URI::Escape;

binmode STDOUT, ':utf8';

# slurp dumped enwikt language code : name mappings
open(IN, '<:encoding(utf8)', 'enwiktlangs.txt') or die "$!"; # Input as UTF-8
my $enwikt = do { local $/; <IN> }; # Read file contents into scalar
close(IN);

my %enwikt;
eval '%enwikt = (' . $enwikt . ');';

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

my $js = JSON->new->utf8(10);

# ISO 639-3 to ISO 639-1 mapping: 3-letter to 2-letter
my %three2one;
my %name2code;

# TODO handle error
my $json = get 'http://toolserver.org/~hippietrail/langmetadata.fcgi?fields=iso3,isoname,n';

unless ($json) {
    print STDERR "couldn't get data on language names and ISO 639-3 codes from langmetadata sever\n";
} else {
    my $data = $js->allow_barekey->decode($json);

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

sub CHANNEL () { $ARGV[0] ? '#hippiebot' : '#wiktionary' }
sub BOTNICK () { $ARGV[0] ? 'hippiebot-d' : 'hippiebot' }

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
    },
);

# The bot session has started.  Register this bot with the "magnet"
# IRC component.  Select a nickname.  Connect to a server.
sub bot_start {
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

    elsif ( my ($args) = $msg =~ /^gf (.+)$/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_gf($channel, $args);

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
        my $resp = do_gf(undef, $args);

        $resp && $irc->yield( privmsg => $nick, $resp );
    }

    elsif ( my ($term) = $msg =~ /^define (.+)$/ ) {
        my $resp = do_define(undef, $term);

        $resp && $irc->yield( privmsg => $nick, $resp );
    }
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
        $metadata = $js->allow_barekey->decode($json);
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
            $resp .= 'It\'s a WikiMedi extension to ISO';
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

    my $uri = 'http://en.wiktionary.org/w/api.php?format=json&action=parse&prop=sections&page=';

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
    my $args= shift;
    my $ok = 0;
    my $resp = undef;

    if ($channel) {
        if (grep $_ eq 'know-it-all', $irc->channel_list($channel)) {
            # gf know it all
        } else {
            $ok = 1;
            # gf no know it all
        }
    } else {
        $ok = 1;
    }

    if ($ok) {
        #my $uri = 'http://en.wiktionary.org/w/api.php?format=json&action=parse&prop=sections&page=';
        #my $goo1 = get 'http://www.google.com.au/search?q=shrimp+cocktail';
#print "$!\n";
        #if (open(GFH, ">google1.html")) {
        #    print GFH $goo1;
        #    close(GFH);
        #}
        $resp = 'I\'m still looking for a googlefight API';
        $ok = 0;
    } else {
        # gf not ok
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
            # define know it all
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
    $n = lc $n;
    $n =~ s/[- '()!\.\/=ʼ’]//g;
    $n =~ tr/àáâãäåçèéêëìíîñóôõöùúüāīṣṭ/aaaaaaceeeeiiinoooouuuaist/;
    return $n;
}

# Run the bot until it is done.
$poe_kernel->run();
exit 0;

