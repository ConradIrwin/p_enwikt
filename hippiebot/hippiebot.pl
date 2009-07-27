#!/usr/bin/perl

# This is a simple IRC bot that knows about languages. It responds to:
# "lang <code>", "dumps"

use warnings;
use strict;

use File::HomeDir;
use JSON;
use LWP::Simple;
use POE;
use POE::Component::IRC;
use Tie::TextDir;

# read dumped enwikt language code : name mappings
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
	cel => 'Celtic',
	cmc => 'Chamic',
	cus => 'Cushitic',
	day => 'Land Dayak',
	dra => 'Dravidian',
	fiu => 'Finno-Ugrian',
	gem => 'Germanic',
	ijo => 'Ijo',
	inc => 'Indic',
	ine => 'Indo-European',
	ira => 'Iranian',
	iro => 'Iroquoian',
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
	tup => 'Tupi',
	tut => 'Altaic',
	wak => 'Wakashan',
	wen => 'Sorbian',
	ypk => 'Yupik',
	znd => 'Zande',
);

my $js = JSON->new->utf8()->max_depth(10);

my %three2one;

my $json = get 'http://toolserver.org/~hippietrail/langmetadata.fcgi?fields=iso3';
my $iso3 = $js->allow_barekey->decode($json);

while (my ($k, $v) = each %$iso3) {
    $three2one{$v->{iso3}} = $k;
}

sub CHANNEL () { $ARGV[0] ? '#hippiebot' : '#wiktionary' }

# Create the component that will represent an IRC network.
my ($irc) = POE::Component::IRC->spawn();

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

    my $nick = $ARGV[0] ? 'hippiebot-d' : 'hippiebot';
    $irc->yield( connect =>
          { Nick => $nick,
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
    my ( $kernel, $who, $where, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    my $ts = scalar localtime;

    if ( my ($incode) = $msg =~ /^lang (.+)/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_lang($incode);

        # Send a response back to the server.
        $resp && $irc->yield( privmsg => CHANNEL, $resp );
    }

    elsif ( $msg =~ /^dumps$/ ) {
        print " [$ts] <$nick:$channel> $msg\n";

        my $resp = do_dumps();

        # Send a response back to the server.
        $resp && $irc->yield( privmsg => CHANNEL, $resp );
    }
}

# The bot has received a private message.  Parse it for commands, and
# respond to interesting things.
sub on_msg {
    my ( $kernel, $who, $where, $msg ) = @_[ KERNEL, ARG0, ARG1, ARG2 ];
    my $nick = ( split /!/, $who )[0];
    my $channel = $where->[0];

    my $ts = scalar localtime;
    print " [$ts] <$nick:$channel> $msg\n";

    if ( my ($incode) = $msg =~ /^lang (.+)/ ) {

        my $resp = do_lang($incode);

        # Send a response back to the asker.
        $resp && $irc->yield( privmsg => $nick, $resp );
    }

    elsif ( $msg =~ /^dumps$/ ) {

        my $resp = do_dumps();

        # Send a response back to the asker.
        $resp && $irc->yield( privmsg => $nick, $resp );
    }
}

sub do_lang {
    my $incode = shift;
    my $outcode = $incode;

    my $json = get 'http://toolserver.org/~hippietrail/langmetadata.fcgi?langs=' . $incode;
    my $ref = $js->allow_barekey->decode($json);

    if (exists $three2one{$incode}) {
        $outcode = $three2one{$incode};
        $json = get 'http://toolserver.org/~hippietrail/langmetadata.fcgi?langs=' . $outcode;
        $ref = $js->allow_barekey->decode($json);
    }

    my $resp;

    if ($ref) {
        if (exists $ref->{$outcode}) {
            my $l = $ref->{$outcode};
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
            if (exists $enwikt{$outcode}) {
                $names{$enwikt{$outcode}} = 1;
            }
            if (scalar keys %names) {
                $resp = $incode;

                if ($incode ne $outcode) {
                    $resp .= ', ' . $outcode;
                } elsif (exists $l->{iso3}) {
                    $resp .= ', ' . $l->{iso3};
                }
                $resp .= ': '. join '; ', keys %names;

                if (exists $l->{fam} || exists $l->{geo}) {
                    $resp .= ', a';
                    if (exists $l->{fam}) {
                        $resp .= 'n' if ($fam{$l->{fam}} =~ /^[aeiouAEIUO]/);
                        $resp .= ' ' . $fam{$l->{fam}};
                    }
                    $resp .= ' language';
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
                        $resp .= ' ';
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
        } else {
            $resp = $outcode . ': can\'t find it in ISO 639-3, WikiMedia Sitematrix, or en.wiktionary language templates.';
        }
    } elsif ($@) {
        $resp = 'something went wrong: ' . $@;
    }

    return $resp;
}

sub do_dumps {
    tie my %home, 'Tie::TextDir', home(), 'rw';  # Open in read/write mode

    my $last;
    if (exists $home{'.enwikt'}) {
        $last = $home{'.enwikt'}
    }

    my $last2;
    if (exists $home{'.enwikt2'}) {
        $last2 = $home{'.enwikt2'}
    }

    untie %home;

    my $resp = 'I don\'t know anything about the dumps right now.';
    if ($last || $last2) {
        $resp = 'The ';
        if ($last) {
            $resp .= "latest official dump is $last";

            $resp .= ', and the ';
        }
        if ($last2) {
            $resp .= "latest devtionary dump is $last2";
        }
        $resp .= '.';
    }
    return $resp;
}

# Run the bot until it is done.
$poe_kernel->run();
exit 0;

