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

# TODO it would be better to choose one from the list. this could change.
my $uname = `uname`;
chomp $uname;
my $default_locale = $uname eq 'SunOS' ? 'en_US.UTF-8' : 'en_US.utf8';

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
        #print STDERR "language code template rejected: '$c'\n";
    }
}
#use Data::Dumper; print Dumper \%langcodes;

# FastCGI loop

while (FCGI::accept >= 0) {
    my %opts = ('langname' => 'English');                    
    
    # get command line or cgi args
    CliOrCgiOptions(\%opts, qw{dumpsource langname term seq num numprev numnext callback}); 
        
    # process this request

    my $langname = '';
    my $inputterm = '';
    my $numprev = 0;
    my $numnext = 0;
    my $iscached = 0;
    my $words = undef;
    my $locale = '';

    if (exists $opts{dumpsource}) {
        $cli_retval = dumpsource();
        next;
    }

    if (!exists $opts{langname}) {
        $cli_retval = dumperror(1, 'no language name specified', $opts{callback});
    } elsif (!exists $opts{term}) {
        $cli_retval = dumperror(1, 'no term specified', $opts{callback});
    } elsif (exists $opts{num} && (exists $opts{numprev} || exists $opts{numnext})) {
        $cli_retval = dumperror(1, 'num cannot be used with numprev or numnext', $opts{callback});
    } else {
        $langname = $opts{langname};
        $inputterm = $opts{term};
        if (defined $opts{numprev} || defined $opts{numnext}) {
            $numprev = $opts{numprev} if defined $opts{numprev};
            $numnext = $opts{numnext} if defined $opts{numnext};
        } else {
            $numprev = $numnext = defined $opts{num} ? $opts{num} : 1;
        }

        # see if we have a locale for this language
        # TODO currently we pick the first locale for this language
        # TODO but wolfsbane Solaris has different collation orders for different
        # TODO locales of the same language. for "en" only "en_US" will order
        # TODO "treeline", "tree line", and "tree-line" near each other
        # TODO whereas on nightshade Linux all "en_??" locales sort the same
        my $key = undef;
        while (my ($k, $v) = each %langcodes) {
            if ($v->{enwiktname} eq $langname) {
                $key = $k;
                # XXX if we use last with each, each won't start from the beginning next time!
                #last;
            }
        }
        # normally we use the language code as the hash key
        # since the locale is keyed off the language code
        # but if we can find no language code we use the langauge name
        # as the hash key. This allows us to cache langauges for which
        # we have no language code
        $key = $langname unless (defined $key);

        $locale = exists $langcodes{$key}->{locale} ? $langcodes{$key}->{locale} : $default_locale;
        setlocale(LC_COLLATE, $locale);

        if (exists $langcodes{$key}->{words}) {
            $iscached = 1;
            $words = $langcodes{$key}->{words};
        # TODO for langname */Browse we need to sort and search on disk
        } elsif ($words = slurpsort($langname)) {
            $iscached = 0;
            $langcodes{$key}->{words} = $words;
        } else {
            $cli_retval = dumperror(1, "couldn't open word file for '$langname'", $opts{callback});
        }
    }

    if ($words) {
        my ($prev, $next) = bsearch($inputterm, $words);

        my (@prevs, $exists, @nexts);

        my ($a, $b);
        my ($c, $d);

        $a = $prev - $numprev + 1;
        $b = $a + $numprev;

        if ($a < 0) {
            $b += $a;
            $a = 0;
        }

        $c = $next;
        $d = $next + $numnext;

        if ($d > scalar @$words) {
            $d -= $d - scalar @$words;
        }

        my $results = {
            langname    => $langname,
            locale      => $locale,
            iscached    => $iscached,
            inputterm   => $inputterm,
            exists      => $next - $prev == 2
        };

        $results->{prev} = [@$words[$a .. $b-1]] if $a != $b;
        $results->{next} = [@$words[$c .. $d-1]] if $c != $d;

        $results->{seq} = $opts{seq} if exists $opts{seq};

        dumpresults($results, 'json', $opts{callback});

        $cli_retval = 0;
    }
}

exit $cli_retval;

##########################################

# TODO for langname */Browse we need to sort and search on disk
sub slurpsort {
    my $retval;
    my $name = shift;

    if ($name ne '_Special') {
        my $filename = $name eq '*'
            ? '/mnt/user-store/enlatest-all.txt'
            : "/home/hippietrail/buxxo/$name.txt";

        if (open(FILE, "<:utf8", $filename)) {
            my @unsorted = <FILE>;
            close(FILE);

            chop @unsorted;

            my @sorted = sort @unsorted;
            $retval = \@sorted;
        } else {
            #print STDERR "can't find '$name.txt'\n";
        }
    } else {
        my $stuff = $mw->api( {
            action => 'query',
            meta => 'siteinfo',
            siprop => 'specialpagealiases'
        } ) || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

        my @unsorted;
        foreach my $sp (@{$stuff->{query}->{specialpagealiases}}) {
            push @unsorted, $sp->{aliases}->[0];
        }
        my @sorted = sort @unsorted;
        $retval = \@sorted;
    }

    return $retval;
}

# TODO for langname */Browse we need to sort and search on disk
sub bsearch {
    my ($x, $a) = @_;            # search for x in array a
    my ($l, $u) = (0, @$a - 1);  # lower, upper end of search interval
    my $i;                       # index of probe
    my $r = undef;

    while ($l <= $u) {
        $i = int(($l + $u)/2);
        my $d = $a->[$i] cmp $x;

        if ($d < 0) {
            $l = $i+1;
        } elsif ($d > 0) {
            $u = $i-1;
        } 
        else {
            $r = [$i-1, $i+1]; # found
            last;
        }
    }

    $r = [$l-1, $l] unless defined $r; # not found

    return @$r;
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
    my $r = shift;
    my $format = shift;
    my $callback = shift;
    our $sort = shift;      # XXX "my" doesn't work with fcgi!

    # we must output the HTTP headers to STDOUT before anything else
	binmode(STDOUT, 'utf8');
    $scriptmode eq 'cgi' && print "Content-type: text/plain; charset=UTF-8\n\n";

    # XXX "my" doesn't work with fcgi!
    # XXX it will be right in dumpresults context but wrong in dumpresults_json!
    our $indent = 0;
    our $fmt = $format =~ /fm$/ ? 1 : 0;
    our $qot = $format =~ /^json/ ? 1 : 0;

    $callback && print $callback, '(';
    dumpresults_json($r);
    $callback && print ')';

    sub dumpresults_json {
        my $r = shift;
        my $lhs = shift;

        if (ref($r) eq 'ARRAY') {
            print '[';
            for (my $i = 0; $i < scalar @$r; ++$i) {
                $i && print ',';
                $i && $fmt && print ' ';
                dumpresults_json($r->[$i]);
            }
            print ']';
        } elsif (ref($r) eq 'HASH') {
            print "{";
            $fmt && print "\n";
            ++$indent;
            my $i = 0;
            for my $h ($sort ? sort keys %$r : keys %$r) {
                $i && print ",";
                $i++ && $fmt && print "\n";
                my $k = $h;
                if ($qot || $h !~ /^[a-z]+$/) {
                    $k = '"' . $h . '"';
                }
                $fmt && print '  ' x $indent;
                print $k, ':';
                $fmt && print ' ';
                dumpresults_json($r->{$h}, $h);
            }
            $fmt && print "\n", '  ' x --$indent;
            print '}';
        # XXX don't use \d here or foreign digits will be unquoted
        } elsif ($r =~ /^-?[0-9]+$/ && $r != /^0[0-9]+/) {
            #if ($metadata_dtd{$lhs} eq 'bool') {
            #    print $r ? 'true' : 'false';
            #} else {
                print $r;
            #}
        } else {
            $r =~ s/\\/\\\\/g;
            $r =~ s/"/\\"/g;
            print '"', $r, '"';
        }
    }
}

sub dumperror {
    dumpresults( { error => { code => shift, info => shift} }, 'json', shift );

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
