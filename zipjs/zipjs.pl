#!/usr/bin/perl

# Download and zip all MediaWiki Wiktionary and User JavaScript pages

use strict;

use DBI;
use File::Basename;
use File::Path;
use LWP::Simple;
use MediaWiki::API;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use constant TESTDIR => 'enwiktcodenew';
use constant BATCHSIZE => 32;

my %nsmap = (
    2 => 'User',
    4 => 'Wiktionary',
    8 => 'MediaWiki'
);

print STDERR "getting wiki page titles...\n";
my $dbh = DBI->connect(
   'DBI:mysql:' .
        'database=enwiktionary_p;' .
        'host=enwiktionary-p.db.toolserver.org;' .
        'mysql_read_default_group=client;' .
        'mysql_read_default_file=/home/hippietrail/.my.cnf',
        undef, undef
    ) or die "error: $DBI::errstr";

my $statement = 'SELECT page_namespace, page_title FROM page WHERE page_namespace IN (2,4,8) AND page_title REGEXP "\\\\.(css|js)$" AND page_is_redirect = 0';

my $ref = $dbh->selectall_arrayref($statement);
print STDERR "got wiki page titles...\n";

my $mw = MediaWiki::API->new();
$mw->{config}->{api_url} = 'http://en.wiktionary.org/w/api.php';

my @allpages = map $nsmap{$_->[0]} . ':' . $_->[1], @$ref;

my $numpages = scalar @allpages;

for (my $i = 0; $i < $numpages; $i += BATCHSIZE) {
    my $u = $i + BATCHSIZE-1;
    $u = $numpages-1 if ($u >= $numpages);
    my @slice = @allpages[$i..$u];
    print STDERR "getting pages $slice[0] to $slice[-1]...\n";

    my $titles = join('|', @slice);

    $titles =~ tr/_/ /;
    utf8::decode($titles);

    my $stuff = $mw->api( {
        action => 'query',
        prop => 'revisions',
        rvprop => 'content',
        titles => $titles } );

    if ($stuff) {
        #print STDERR "got pages...\n";
        foreach my $id (keys %{$stuff->{query}->{pages}}) {
            my $title = $stuff->{query}->{pages}->{$id}->{title};
            my $content = $stuff->{query}->{pages}->{$id}->{revisions}->[0]->{'*'};

            my $fullname = TESTDIR . '/' . $title;
            my $dirname = dirname($fullname);
            my $basename = basename($fullname);

            # avoid .js in directory names - yes people really do that
            $dirname =~ s/\.js\b/_js/g;

            $fullname = $dirname . '/' . $basename;

            mkpath($dirname);

            if (open (FH, '>:encoding(utf8)', $fullname)) {
                print FH $content;
                close (FH);
            } else {
                print STDERR "** couldn't create file ", $fullname, " ($!)\n";
            }
        }
    } else {
        print STDERR '** api error: ', $mw->{error}->{code} . ': ' . $mw->{error}->{details}, "\n";
    }
}

