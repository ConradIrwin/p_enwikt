#!/usr/bin/perl

# mycontribs

use strict;

use JSON;
use LWP::Simple;
use URI::Escape;

binmode STDOUT, 'utf8';

my $lang = 'en';
my $proj = 'wiktionary';
my $user = 'Hippietrail';
my $limit = 100;

if (scalar @ARGV == 1 && $ARGV[0] =~ /^\d+$/) {
    $limit = $ARGV[0];
}

my $apiurl = 'http://' . $lang . '.' . $proj . '.org/w/api.php?format=json';
my $js = JSON->new->utf8(0);
print STDERR "contributions...\n";
my $json = get $apiurl . '&action=query&list=usercontribs&ucprop=flags|title|ids|timestamp&ucuser=' . $user . '&uclimit=' . $limit;
my $contribs = $js->decode($json);

my %seen;
my @modded;

if ($contribs) {
    if (exists $contribs->{query}) {
        if (exists $contribs->{query}->{usercontribs}) {
            foreach my $uc (@{$contribs->{query}->{usercontribs}}) {
                push @modded, $uc unless exists $uc->{top} || exists $seen{$uc->{title}};
                ++$seen{$uc->{title}};
            }
        }
    }
}

print STDERR "revisions...\n";
for my $uc (@modded) {
    my $json = get $apiurl . '&action=query&prop=revisions&titles=' .
        uri_escape_utf8($uc->{title}) . '&rvprop=user&rvend=' . $uc->{timestamp};
    my $revs = $js->decode($json);

    if ($revs) {
        if (exists $revs->{query}) {
            if (exists $revs->{query}->{pages}) {
                if (exists $revs->{query}->{pages}->{$uc->{pageid}}) {
                    if (exists $revs->{query}->{pages}->{$uc->{pageid}}->{revisions}) {
                        print "$uc->{title}\n" if
                            grep { !/^(AutoFormat|Interwicket|Tbot|$user)$/ }
                            map $_->{user}, @{$revs->{query}->{pages}->{$uc->{pageid}}->{revisions}};
                    }
                }
            }
        }
    }
}

