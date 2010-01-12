#!/usr/bin/perl

# find all language templates in the English Wikipedia
# and extract code:name pairs

use strict;

use DBI;
use MediaWiki::API;

binmode STDOUT, ':utf8';

use constant BATCHSIZE => 200;

use constant {
    FROM_CAT    => 1,
    BY_PAT      => 2,
    ENW_ACC     => 4,
    ENW_REJ     => 8,
};

my $statement;

my $dbh = DBI->connect(
   'DBI:mysql:' .
        'database=enwiki_p;' .
        'host=enwiki-p.db.toolserver.org;' .
        'mysql_read_default_group=client;' .
        'mysql_read_default_file=/home/hippietrail/.my.cnf',
        undef, undef
    ) or die "error: $DBI::errstr";

# Use [[Category:ISO 639 name from code templates]] to find language codes even if they have
# non ISO suffixes or are more than 3 characters
# TODO filter out Category:ISO 639 name from code templates without a category
$statement = 'SELECT page_title FROM page'. 
    ' JOIN categorylinks ON cl_from = page_id' .
    ' WHERE cl_to = "ISO_639_name_from_code_templates" AND page_title REGEXP "^ISO_639_name_[a-z][a-z]"';

print STDERR "getting enwiki lang codes from Category:ISO 639 name from code templates...\n";
my $langs_from_cat = $dbh->selectcol_arrayref($statement);
print STDERR "got enwiki lang codes from Category:ISO 639 name from code templates.\n";

# Find all templates which are 2 or 3 lowercase ASCII letters even if they are
# not in [[Category:ISO 639 name from code templates]]
$statement = 'SELECT page_title FROM page WHERE page_namespace = 10' .
    ' AND page_title REGEXP "^ISO_639_name_[a-z][a-z][a-z]?$"';

print STDERR "getting enwiki lang codes by pattern...\n";
my $langs_by_pat = $dbh->selectcol_arrayref($statement);
print STDERR "got enwiki lang codes by pattern.\n";

my %hash = ();

foreach my $e (@$langs_from_cat) {
    $hash{$e}->{f} |= FROM_CAT;
}

foreach my $e (@$langs_by_pat) {
    $hash{$e}->{f} |= BY_PAT;
}

my @diff;

@diff = grep(($hash{$_}->{f} & 3) == FROM_CAT, keys %hash);
print STDERR 'in category but not 2-3 letters only: ', join(', ', sort @diff), "\n";

@diff = grep(($hash{$_}->{f} & 3) == BY_PAT, keys %hash);
print STDERR '2-3 letters only but not in category: ', join(', ', sort @diff), "\n";

my $mw = MediaWiki::API->new();
$mw->{config}->{api_url} = 'http://en.wikipedia.org/w/api.php';

my @allcodes = sort keys %hash;

my $numcodes = scalar @allcodes;

for (my $i = 0; $i < $numcodes; $i += BATCHSIZE) {
    my $u = $i + BATCHSIZE-1;
    $u = $numcodes-1 if ($u >= $numcodes);
    my @slice = @allcodes[$i..$u];
    print STDERR "getting templates $slice[0] to $slice[-1]...\n";
    mwapi(\%hash, \@slice);
}
print STDERR "got templates...\n";

@diff = grep(($hash{$_}->{f} & 8) == ENW_REJ, keys %hash);
print STDERR 'rejected codes: ', join(', ', sort @diff), "\n";

foreach (sort keys %hash) {
    if ($hash{$_}->{enwikiname}) {
        my $n = $hash{$_}->{enwikiname};
        my $k = substr($_, 13);
        if ($ARGV[0] eq 'json') {
            $n =~ s/([\\"])/\\$1/g;
            print "\"$k\":\t\"$n\",\n";
        } elsif ($ARGV[0] eq 'js') {
            $n =~ s/([\\"])/\\$1/g;
            print "$k:\t\"$n\",\n";
        } else { # perl
            my $c = $k;
            if (index($c, '-') != -1) {
                $c = '\'' . $c . '\'';
            }
            $n =~ s/([\\'])/\\$1/g;
            print "$c\t=> '$n',\n";
        }
    }
}

exit;

sub mwapi {
    my $hash = shift;
    my $codes = shift;

    my $text = join ';;;', map "$_: {{$_}}", @$codes;

    my $stuff = $mw->api( {
        action => 'expandtemplates',
        text => $text } )
        || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

    my @pairs = split ';;;', $stuff->{expandtemplates}->{'*'};

    foreach (@pairs) {
        my $ok = 0;
        /^([^:]+): /g;
        my $c = $1;
        if (/\G(?:(?:\[\[)?([^];]*)(?:]])?(?: \((.*)\))?)$/s) {
            if ($1 && $1 !~ /[[|<*]/s && $1 ne "\n") {  # catch false positives
                $ok = 1;
            }
        }
        if ($ok) {
            $hash->{$c}->{enwikiname} = $2 ? $1 . ' (' . $2 . ')' : $1;
            $hash->{$c}->{f} |= ENW_ACC;
        } else {
            $hash->{$c}->{f} |= ENW_REJ;
        }
    }
}

