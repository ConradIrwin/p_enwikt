#!/usr/bin/perl -I/home/hippietrail/lib

# nearbypages <language name> <term>

use utf8;
use strict;

use CGI;
use FCGI;
use Getopt::Long;
use locale;
use MediaWiki::API;
use POSIX;
use URI::Escape;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

my $scriptmode = 'cli';

# initialize
my $cli_retval = -1; # fail by default

# initialize MediaWiki API
my $mw = MediaWiki::API->new();
$mw->{config}->{api_url} = 'http://en.wiktionary.org/w/api.php';

# which language codes do we have locale support for?
my %langcodes;
my @locales = `locale -a`;
foreach (@locales) {
    if (/^([a-z][a-z][a-z]?)(_[AZ]+)?.*[uU][tT][fF].*$/) {
        $langcodes{$1}->{locale} = $& unless ($langcodes{$1}->{locale});
    }
}

my $stuff = $mw->api( {
    action => 'expandtemplates',
    text => join ';;;', map "$_: {{$_}}", keys %langcodes } )
    || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

my @pairs = split ';;;', $stuff->{expandtemplates}->{'*'};

foreach (@pairs) {
    my $ok = 0;
    /^([^:]+): /g;
    my $c = $1;
    if (/\G(?:(?:\[\[)?([^];]*)(?:]])?(?: \((.*)\))?)$/s) {
        if ($1 && $1 !~ /^:Template:/ && $1 !~ /[[|<*]/s && $1 ne "\n") {  # catch false positives
            $ok = 1;
        }
    }
    if ($ok) {
        my $langname = $2 ? $1 . ' (' . $2 . ')' : $1;
        $langcodes{$c}->{enwiktname} = $langname;
        $langcodes{$c}->{hasfile} = -e "/home/hippietrail/buxxo/$langname.txt";
    } else {
        print STDERR "language code template rejected: '$c'\n";
    }
}
#use Data::Dumper; print Dumper \%langcodes;

# FastCGI loop

while (FCGI::accept >= 0) {
    my %opts = ('langname' => 'English');                    
    
    # get command line or cgi args
    CliOrCgiOptions(\%opts, qw{langname term}); 
        
    # process this request

    my $langname = '';
    my $inputterm = '';
    my $iscached = 0;
    my $words = undef;
    my $locale = '';

    if (!exists $opts{langname}) {
        $cli_retval = dumperr('no language name specified');
    } elsif (!exists $opts{term}) {
        $cli_retval = dumperr('no term specified');
    } else {
        $langname = $opts{langname};
        $inputterm = $opts{term};

        # see if we have a locale for this language
        my $key = undef;
        while (my ($k, $v) = each %langcodes) {
            if ($v->{enwiktname} eq $langname) {
                $key = $k;
                $locale = $v->{locale};
                if (exists $v->{locale}) {
                    setlocale(LC_COLLATE, $v->{locale});
                    print STDERR "locale set to '$v->{locale}'\n";
                }
            }
        }
        # normally we use the language code as the hash key
        # since the local is keyed off the language code
        # but if we can find no language code we use the langauge name
        # as the hash key. This allows us to cache langauges for which
        # we have no language code
        $key = $langname unless (defined $key);

        if (exists $langcodes{$key}->{words}) {
            $iscached = 1;
            $words = $langcodes{$key}->{words};
        } elsif ($words = slurpsort($langname, $langcodes{$key}->{locale})) {
            $iscached = 0;
            $langcodes{$key}->{words} = $words;
        } else {
            $cli_retval = dumperr("couldn't open word file for '$langname'");
        }
    }

    if ($words) {
        my $r = bsearch($locale, $inputterm, $words);

        my $w = '';
        for (my $o = 0; $o < 3; ++$o) {
            my $i = defined $r->[$o] ? $r->[$o] : undef;
            if (defined $i) {
                $w .= ($o-1). ' '. $i. ' '. $words->[$i]. "\n";
            }
        }
        my $prev = $words->[$r->[0]];
        my $exists = defined $r->[1];
        my $next = $words->[$r->[2]];

        $cli_retval = dumpresults($langname, $iscached, $inputterm, $prev, $exists, $next);
    }
}

exit $cli_retval;

##########################################

sub slurpsort {
    my $name = shift;
    my $locale;
    my $retval;

    if (open(FILE, "<:utf8", "/home/hippietrail/buxxo/$name.txt")) {
        my @unsorted = <FILE>;
        close(FILE);

        chop @unsorted;

        setlocale(LC_COLLATE, $locale) if ($locale);
        my @sorted = sort @unsorted;
        $retval = \@sorted;
    } else {
        print STDERR "can't find '$name.txt'\n";
    }

    return $retval;
}

sub bsearch {
    my ($locale, $x, $a) = @_;            # search for x in array a
    my ($l, $u) = (0, @$a - 1);  # lower, upper end of search interval
    my $i;                       # index of probe

    setlocale(LC_COLLATE, $locale) if ($locale);

    while ($l <= $u) {
        $i = int(($l + $u)/2);
        my $d = $a->[$i] cmp $x;

        if ($d < 0) {
            $l = $i+1;
        } elsif ($d > 0) {
            $u = $i-1;
        } 
        else {
            return [$i-1, $i, $i+1]; # found
        }
    }

    return [$l-1, undef, $l];         # not found
}

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
    utf8::decode($opts->{term});
}

sub dumpresults {
    my $langname = shift;
    my $iscached = shift;
    my $inputword = shift;
    my $prev = shift;
    my $exists = shift;
    my $next = shift;

    # we must output the HTTP headers to STDOUT before anything else
    $scriptmode eq 'cgi' && print "Content-type: text/plain; charset=UTF-8\n\n";

    print "{\n";
    print "\t\"langname\": \"$langname\",\n";
    print "\t\"iscached\": \"$iscached\",\n";
    print "\t\"inputterm\": \"$inputword\",\n";
    print "\t\"prev\": \"$prev\",\n";
    print "\t\"exists\": \"$exists\",\n";
    print "\t\"next\": \"$next\",\n";
    print "}\n";

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
