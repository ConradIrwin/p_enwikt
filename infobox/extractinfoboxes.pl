#!/usr/bin/perl

# look at writing system infoboxes on Wikipedia

use utf8;
use warnings;
use strict;

use JSON;
use LWP::Simple;
use XML::Easy::Text qw(xml10_read_document);

binmode STDOUT, 'utf8';

my $deep;
my $tdep;

my $js = JSON->new->utf8(10);

my $mode = undef;
my $etitle = undef;
my $filter = undef;

if (scalar @ARGV != 1 || $ARGV[0] !~ /^[lfs]$/) {
    die "usage: xmleasy [l|f|s]";
} else {
    $mode = $ARGV[0];

    if ($mode eq 'l') {
        $etitle = 'Language';
        $filter = 'fam\d|iso|name$|nativename$|script$';
    } elsif ($mode eq 'f') {
        $etitle = 'Language_family';
        $filter = 'child\d|iso|name$';
    } elsif ($mode eq 's') {
        $etitle = 'Writing_system';
        $filter = 'family|iso|languages|name$|type$';
    }
}

my $uri = 'http://en.wikipedia.org/w/api.php?' .
            'format=json' .
            '&action=query' .
            '&list=embeddedin' .
            '&eilimit=5000' .
            '&einamespace=0' .
            '&eititle=Template:Infobox_' . $etitle
            ;

my $jdata = get $uri;

if ($jdata) {
    my $pdata = $js->decode($jdata);

    if (exists $pdata->{query} && exists $pdata->{query}->{embeddedin}) {
        my $ei = $pdata->{query}->{embeddedin};

        my @pageids = map $_->{pageid}, @$ei;

        print "<infoboxen>\n";

        for (my $i = 0; $i < scalar @pageids; $i += 2) {
            my $uri = 'http://en.wikipedia.org/w/api.php' . 
                        '?format=json' .
                        '&action=query' .
                        '&prop=revisions' .
                        '&pageids=' . join('|', @pageids[$i..$i+1]) .
                        # TODO sometimes the infobox is not in s0, eg Tifinagh
                        '&rvsection=0' .
                        '&rvprop=content' .
                        '&rvgeneratexml'
                        ;

            #if ($pageids[$i] == 22666 || $pageids[$i+1] == 22666) {
            #    $uri .= '&revids=331707917';
            #} else {
            #    $uri .= '&pageids=' . join('|', @pageids[$i..$i+1]);
            #}

            my $jdata = get $uri;

            if ($jdata) {
                my $pdata = $js->decode($jdata);

                if (exists $pdata->{query} && exists $pdata->{query}->{pages}) {
                    my $ps = $pdata->{query}->{pages};

                    my $j = 0;
                    while (my ($k, $v) = each(%$ps)) {
                        my $xml = $v->{revisions}->[0]->{parsetree};

                        my $root_element = xml10_read_document($xml);

                        $deep = 0;
                        page($v->{title}, $root_element->content_twine);

                        print "\n\n";
                        ++ $j;
                    }
                }
            }
        }
        print "</infoboxen>\n";
    }
}

exit;

sub flatten_wikilinks {
    my $t = shift;

    # [[Image:Phoenician mem.svg|12px|𐤌‏]]
    # image links
    $t =~ s/\[\[Image:[^\|]*?\|[^\|]*?(?:\|([^\]]*?))?\]\]/$1/g;

    # normal links
    $t =~ s/\[\[(?:[^\]]*?\|)?([^\]]*?)\]\](\w*)?/$1$2/g;
    #$t =~ s/\[\[(?:(?:[a-z]+:)?[^\]]*?\|)?([^\]]*?)\]\](\w*)?/$1$2/g;

    return $t;
}

# handle XML elements inside a page

sub page {
    my $pagetitle = shift;
    my $t = shift;

    print "<page title=\"$pagetitle\">\n";

    while (my ($s, $x) = splice(@$t, 0, 2)) {
        my $s2 = $s;
        $s2 =~ s/^\s*(.*?)\s*$/$1/s;
        $s2 =~ s/\s+/ /gs;

        if ($x) {
            if ($x->type_name eq 'template') {
                page_template($x->content_twine);
            } elsif ($x->type_name eq 'comment') {
                #print '<comment>', substr($x->content_twine->[0], 4, -7), '</comment>';
            } elsif ($x->type_name eq 'ext') {
                # always has name attr inner close each with one text value which may be empty
                #print '<ext name="', $x->content_twine->[1]->content_twine->[0], '"/>';
                #my $extname = $x->content_twine->[1]->content_twine->[0];
                #my $extcont = $x->content_twine->[3]->content_twine->[0];
                #print "<ext-$extname>$extcont</ext-$extname>";
            } elsif ($x->type_name eq 'ignore') {
                #print '<ignore>', $x->content_twine->[0], '</ignore>';
            } else {
                print '##WEIRD<', $x->type_name, '>##';
                $tdep = -1;
                unexpected_xml($x->content_twine);
            }
        }
    }
    print "</page>\n";
}

# handle XML template elements directly inside a page

sub page_template {
    my $tmp = shift;

    my $title = $tmp->[1]->content_twine->[0];
    $title =~ s/^\s*(.*?)\s*$/$1/s;

    if ($title =~ /^[iI]nfobox[ _](.*)$/) {
        infobox($tmp, $1);
    }
}

sub infobox {
    my $ib = shift;
    my $kind = shift;

    print "<infobox>\n";

    for (my $i = 3; $i < scalar @$ib; $i += 2) {
        my $p = $ib->[$i];
        my $j = ($i - 3) / 2;

        # TODO some parts have an index in the attrs instead of a name
        my $name = $p->content_twine->[1]->content_twine->[0];
        my $num = undef;

        $name =~ s/^\s*(.*?)\s*$/$1/s if $name;

        $name = 'ib-part' if $name eq '';

        $name =~ s/\s+/-/g;

        if ($name =~ /$filter/) {
            # handle numbered fields
            if ($name =~ /^(.*?)(\d+)$/) {
                unless ($1 eq 'iso') {
                    $name = $1;
                    $num = $2;
                }
            }

            my $attr = '';
            $attr .= " n=\"$num\"" if ($num);
            #$attr .= " i=\"$j\"";

            my $open = "<$name$attr>";

            my $close = "</$name>";

            # value calls other templates?
            if (scalar @{$p->content_twine->[3]->content_twine} > 1) {
                print $open;
                xml_inside_infobox($p->content_twine->[3]->content_twine);
                print "$close\n";
            } else {
                my $value = $p->content_twine->[3]->content_twine->[0];
                $value =~ s/^\s*(.*?)\s*$/$1/s if $value;

                $value = flatten_wikilinks($value);

                if ($value ne '') {
                    print "$open$value$close\n";
                }
            }
        }
    }
    print "</infobox>\n";
}

sub xml_inside_infobox {
    my $t = shift;

    while (my ($s, $x) = splice(@$t, 0, 2)) {
        my $s2 = $s;
        $s2 =~ s/^\s*(.*?)\s*$/$1/s;
        $s2 =~ s/\s+/ /gs;

        $s2 = flatten_wikilinks($s2);

        print $s2;

        if ($x) {
            if ($x->type_name eq 'template') {
                template_inside_infobox($x->content_twine);
            } elsif ($x->type_name eq 'comment') {
                #print '<comment>', $x->content_twine->[0], '</comment>';
            } elsif ($x->type_name eq 'ext') {
                # always has name attr inner close each with one text value which may be empty
                #print '<ext name="', $x->content_twine->[1]->content_twine->[0], '"/>';
                my $extname = $x->content_twine->[1]->content_twine->[0];
                if ($extname eq 'nowiki') {
                    my $extcont = $x->content_twine->[5]->content_twine->[0];
                    print $extcont;
                } else {
                    #print "<ext-$extname/>";
                }
            } else {
                print '##WEIRD<', $x->type_name, '>##';
                $tdep = -1;
                unexpected_xml($x->content_twine);
            }
        }
    }
}

sub template_inside_infobox {
    my $tmp = shift;
    my $apn = 0;    # anonymous template part number

    my $title = $tmp->[1]->content_twine->[0];
    $title =~ s/^\s*(.*?)\s*$/$1/s;
    my $htitle = $title;
    $htitle =~ s/\s+/-/g;

    if ($htitle =~ /^(?:AUT|CRO|SRB|SVK)$/) {
        #
    } elsif ($htitle =~ /^(?:Citation-needed|Fact)$/) {
        #

    } elsif ($htitle eq 'ndash') {
        print '–';
    } elsif ($htitle eq 'okina') {
        print 'ʻ';

    } elsif ($htitle eq 'Audio') {
        txt_field_from_template($tmp, $htitle, 1);
    } elsif ($htitle eq 'Coptic') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle eq 'cuneiform') {
        txt_field_from_template($tmp, $htitle, 1);
    } elsif ($htitle eq 'Hebrew') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle =~ /^IAST2?$/) {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle =~ /^IPA2?$/) {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle eq 'IPA-all') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle eq 'IPA-en') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle =~ /^[lL]ang$/) {
        txt_field_from_template($tmp, $htitle, 1);
    } elsif ($htitle eq 'lang-Assamese2') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle eq 'lang-la') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle eq 'Nastaliq') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle eq 'nowrap') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle eq 'Polytonic') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle eq 'rtl-lang') {
        txt_field_from_template($tmp, $htitle, 1);
    } elsif ($htitle eq 'script') {
        txt_field_from_template($tmp, $htitle, 1);
    } elsif ($htitle eq 'sm') {
        template_sm($tmp);
    } elsif ($htitle eq 'transl') {
        txt_field_from_template($tmp, $htitle, (((scalar @$tmp)-3)/2)-1);  # 2 or 1, the last argument!
    } elsif ($htitle eq 'translit-Assamese2') {
        txt_field_from_template($tmp, $htitle, 0);
    } elsif ($htitle =~ /^[uU]nicode$/) {
        txt_field_from_template($tmp, $htitle, 0);
    }

    else {
        print "<template-$htitle>";

        for (my $i = 3; $i < scalar @$tmp; $i += 2) {
            my $p = $tmp->[$i];
            my $j = ($i - 3) / 2;

            # TODO some parts have an index in the attrs instead of a name
            my $n = $p->content_twine->[1]->content_twine->[0];
            $n =~ s/^\s*(.*?)\s*$/$1/s;

            $n = 'part' if $n eq '';

            my $attr = '';
            #$attr .= " i=\"$j\"";
            $attr .= ' apn="' . $apn++ . '"';

            my $open = "<$n$attr>";

            my $close = "</$n>";

            if (scalar @{$p->content_twine->[3]->content_twine} > 1) {
                # value calls other templates
                print $open;
                xml_inside_infobox($p->content_twine->[3]->content_twine);
                print $close;
            } else {
                my $v = $p->content_twine->[3]->content_twine->[0];
                $v =~ s/^\s*(.*?)\s*$/$1/s;

                if ($v ne '') {
                    print $open, $v, $close;
                }
            }
        }
        print "</template-$htitle>";
    }
}

sub txt_field_from_template {
    my $tmp = shift;
    my $name = shift;
    my $i = shift;

    my $p = $tmp->[$i * 2 + 3];

    # XXX fails for "Egyptian language"
    # XXX Can't call method "content_twine" on an undefined value
    #print STDERR "txt_field_from_template <$name> $i of ", ((scalar @$tmp) - 3) / 2, "\n";
    if (scalar @{$p->content_twine->[3]->content_twine} > 1) {
        # value calls other templates
        #print "<$name-deep>";
        xml_inside_infobox($p->content_twine->[3]->content_twine);
        #print "</$name-deep>";
    } else {
        my $v = $p->content_twine->[3]->content_twine->[0];
        $v =~ s/^\s*(.*?)\s*$/$1/s;

        $v = flatten_wikilinks($v);

        print $v;
    }
}

sub template_sm {
    my $tmp = shift;

    my $p = $tmp->[0 * 2 + 3];

    if (scalar @{$p->content_twine->[3]->content_twine} > 1) {
        # value calls other templates
        print "<sm-deep>";
        xml_inside_infobox($p->content_twine->[3]->content_twine);
        print "</sm-deep>";
    } else {
        my $v = $p->content_twine->[3]->content_twine->[0];
        $v =~ s/^\s*(.*?)\s*$/$1/s;

        print uc $v;
    }
}

# only used when unexpected XML is hit

sub unexpected_xml {
    my $t = shift;
    ++$deep;
    while (my ($s, $x) = splice(@$t, 0, 2)) {
        my $s2 = $s;
        $s2 =~ s/^\s*(.*?)\s*$/$1/s;
        $s2 =~ s/\s+/ /gs;
        if ($s2 ne '' && defined $tdep && $deep >= $tdep) {
            print '(' x $deep, $s2, ')' x $deep;
        }
        if ($x) {
            if ($x->type_name eq 'template') {
                if (!defined $tdep) {
                    $tdep = $deep;
                    print "{{";
                }
            }
            if (defined $tdep && $deep >= $tdep) {
                print "\n", '<' x $deep, $x->type_name, scalar keys %{$x->attributes} ? '[' . join(',', keys %{$x->attributes}) . ']' : '', '>' x $deep;
            }
            unexpected_xml ( $x->content_twine );
        }
    }
    --$deep;
    if (defined $tdep && $deep <= $tdep) {
        $tdep = undef;
        print "}}";
    }
}
