#!/usr/bin/perl

# output language metadata structure as JSON, optionally formatted

# On Toolserver you can find all script templates on Wiktionary
# sql enwiktionary_p
# SELECT page_title FROM page WHERE page_title REGEXP "^([a-z][a-z][a-z]?-)?[A-Z][a-z][a-z][a-z]$" AND page_namespace = 10;

# With the API you can get a mapping of all language codes and language names
# http://en.wiktionary.org/w/api.php?generator=categorymembers&gcmtitle=Category:Language_templates&gcmnamespace=10&action=query&prop=revisions&rvprop=content&rvexpandtemplates

# With the API you can get a list of which language codes have Wiktionaries
# http://en.wiktionary.org/w/api.php?action=sitematrix

# A machine readable ISO 639 file can is available at http://www.sil.org/ISO639-3/iso-639-3_Name_Index_20090210.tab

use strict;

use FCGI;
use Getopt::Long;
use LWP::Simple;
use MediaWiki::API;

my $scriptmode = 'cli';

# hw    has wiktionary      MediaWiki specific
# sc    script(s)           ISO 15924
# wsc   Wiktionary script   EnglishWiktionary specific
# g     genders             string subset of 'mfnc' or empty string
# p     has plural          1 true or 0 false
# alt   has optional marks  1 true or 0 false
#                           Arabic, Hebrew, Latin, Old English, Turkish
# n     name(s)             in English
# anc   is ancient          1 true or 0 false whether it has mother tongue speakers
# fam   language family     most basic/generic family classification
#                           including 'Isolate' or 'Constructed'
# geo   country(ies)        ISO 3166-1 only

my %metadata_dtd = (
	iso3	 => 'string',
	iso2b	 => 'string',
	iso2t	 => 'string',
	iso1	 => 'string',
	isoscope => 'string',
	isotype	 => 'string',
	isoname	 => 'string',

    mw  => 'bool',

    hw  => 'bool',
    sc  => 'soa',       # string or array of them
    wsc => 'string',
    g   => 'string',
    p   => 'bool',
    alt => 'bool',
    n   => 'soa',       # string or array of them
    anc => 'bool',
    fam => 'string',
    geo => 'soa',       # string or array of them

    altmapfrom  => 'string',
    altmapto    => 'string',
    altmapstrip => 'string'
);

# generic metadata
# TODO names could be extracted from ISO 639-3
my $metadata = {
    aa=>{sc=>['Latn','Ethi'],n=>'Afar',fam=>'Cushitic',geo=>['ET','ER','DJ']},
    ab=>{sc=>['Cyrl','Latn','Geor'],n=>['Abkhaz','Abkhazian'],fam=>'Caucasian',geo=>['GE','TR']},
    af=>{sc=>'Latn',g=>'',p=>1,n=>'Afrikaans',fam=>'Germanic',geo=>['ZA','NA']},
    ak=>{n=>'Akan',fam=>'Niger-Congo',geo=>'GH'},
    akk=>{sc=>'Xsux',g=>'mf',p=>1,n=>'Akkadian',anc=>1,fam=>'Semitic'}, # dual
    als=>{n=>'Tosk Albanian',fam=>'Albanian',geo=>'AL'},
    am=>{sc=>'Ethi',g=>'mf',p=>1,n=>'Amharic',fam=>'Semitic',geo=>'ET'},
    an=>{sc=>'Latn',n=>'Aragonese',fam=>'Romance',geo=>'ES'},
    ang=>{sc=>'Latn',g=>'mfn',p=>1,alt=>1,n=>['Old English','Anglo-Saxon'],anc=>1,fam=>'Germanic'},
    ar=>{sc=>'Arab',g=>'mf',p=>1,alt=>1,n=>'Arabic',fam=>'Semitic'},
    arc=>{sc=>'Hebr',g=>'mf',p=>1,n=>'Aramaic',fam=>'Semitic'}, # dual
    arz=>{sc=>'Arab',g=>'mf',p=>1,alt=>1,n=>'Egyptian Arabic',fam=>'Semitic',geo=>'EG'},
    as=>{sc=>'Beng',n=>'Assamese',fam=>'Indo-Aryan',geo=>'IN'},
    ast=>{sc=>'Latn',g=>'mf',p=>1,n=>'Asturian',fam=>'Romance',geo=>'ES'},
    av=>{sc=>'Cyrl',n=>'Avar',geo=>'RU'},
    ay=>{n=>'Aymara',geo=>['BO','CL','PE']},
    az=>{sc=>['Latn','Cyrl','Arab'],g=>'',alt=>0,n=>['Azeri','Azerbaijani'],fam=>'Turkic',geo=>'AZ'},
    ba=>{sc=>'Cyrl',n=>'Bashkir',fam=>'Turkic',geo=>'RU'},
    bar=>{sc=>'Latn',n=>'Bavarian',fam=>'Germanic',geo=>['DE','AT']},
    be=>{sc=>['Cyrl','Latn'],g=>'mfn',p=>1,n=>'Belarusian',fam=>'Slavic',geo=>'BY'},
    bg=>{sc=>'Cyrl',g=>'mfn',p=>1,n=>'Bulgarian',fam=>'Slavic',geo=>'BG'},
    bh=>{n=>'Bihari',fam=>'Indo-Aryan',geo=>'IN'},
    bhb=>{sc=>'Deva',n=>'Bhili',fam=>'Indo-Aryan',geo=>'IN'},
    bi=>{sc=>'Latn',n=>'Bislama',fam=>'Creole',geo=>'VU'},
    bm=>{sc=>['Latn','Nkoo','Arab'],n=>'Bambara',fam=>'Niger-Congo',geo=>'ML'},
    bn=>{sc=>'Beng',g=>'',n=>'Bengali',fam=>'Indo-Aryan',geo=>['BD','IN']},
    bo=>{sc=>'Tibt',n=>'Tibetan',fam=>'Sino-Tibetan',geo=>['CN','IN']},
    br=>{sc=>'Latn',g=>'mf',n=>'Breton',fam=>'Celtic',geo=>'FR'},
    bs=>{sc=>'Latn',n=>'Bosnian',fam=>'Slavic',geo=>'BA'},
    ca=>{sc=>'Latn',g=>'mf',p=>1,n=>'Catalan',fam=>'Romance',geo=>['AD','ES','FR']},
    ch=>{sc=>'Latn',n=>'Chamorro',fam=>'Austronesian',geo=>['GU','MP']},
    chr=>{sc=>'Cher',n=>'Cherokee',fam=>'Iroquoian',geo=>'US'},
    co=>{sc=>'Latn',n=>'Corsican',fam=>'Romance',geo=>['FR','IT']},
    cr=>{sc=>'Cans',n=>'Cree',fam=>'Algonquian',geo=>'CA'},
    crh=>{sc=>'Latn',g=>'',alt=>0,n=>'Crimean Tatar',fam=>'Turkic',geo=>'UZ'},
    cs=>{sc=>'Latn',g=>'mfn',p=>1,n=>'Czech',fam=>'Slavic',geo=>'CZ'},
    csb=>{n=>'Kashubian',fam=>'Slavic',geo=>'PL'},
    cu=>{sc=>['Cyrs','Glag'],g=>'mfn',p=>1,n=>'Old Church Slavonic',anc=>1,fam=>'Slavic'},    # dual
    cv=>{sc=>'Cyrl',g=>'',alt=>0,n=>'Chuvash',fam=>'Turkic',geo=>'RU'},
    cy=>{sc=>'Latn',g=>'mf',p=>1,n=>'Welsh',fam=>'Celtic',geo=>'GB'},
    da=>{sc=>'Latn',g=>'cn',p=>1,n=>'Danish',fam=>'Germanic',geo=>'DK'},
    de=>{sc=>'Latn',g=>'mfn',p=>1,n=>'German',fam=>'Germanic',geo=>['DE','AT','CH']},
    dv=>{sc=>'Thaa',p=>1,n=>'Dhivehi',fam=>'Indo-Aryan',geo=>'MV'},
    dz=>{sc=>'Tibt',n=>'Dzongkha',fam=>'Sino-Tibetan',geo=>'BT'},
    el=>{sc=>'Grek',g=>'mfn',p=>1,n=>'Greek',geo=>'GR'},
    en=>{sc=>'Latn',g=>'',p=>1,n=>'English',fam=>'Germanic',geo=>['AU','GB','IN','NZ','US','ZA']},
    eo=>{sc=>'Latn',g=>'',p=>1,n=>'Esperanto',fam=>'Constructed'},
    es=>{sc=>'Latn',g=>'mf',p=>1,alt=>0,n=>['Spanish','Castilian'],fam=>'Romance',geo=>['ES','MX']},
    et=>{sc=>'Latn',g=>'',p=>1,alt=>0,n=>'Estonian',geo=>'EE'},
    ett=>{sc=>'Ital',p=>1,n=>'Etruscan',anc=>1},
    eu=>{sc=>'Latn',g=>'',p=>1,alt=>0,n=>'Basque',fam=>'Isolate',geo=>['ES','FR']},
    fa=>{sc=>'Arab',g=>'',n=>['Persian','Farsi'],geo=>'IR'},
    fi=>{sc=>'Latn',g=>'',p=>1,n=>'Finnish',geo=>'FI'},
    fil=>{sc=>'Latn',g=>'',p=>0,n=>['Filipino','Pilipino'],geo=>'PH'},
    fj=>{sc=>'Latn',n=>'Fijian',fam=>'Austronesian',geo=>'FJ'},
    fo=>{sc=>'Latn',g=>'mfn',n=>['Faroese','Faeroese'],fam=>'Germanic',geo=>'FO'},
    fr=>{sc=>'Latn',g=>'mf',p=>1,alt=>0,n=>'French',fam=>'Romance',geo=>['FR','CH','BE']},
    fy=>{sc=>'Latn',n=>'West Frisian',fam=>'Germanic',geo=>'NL'},
    ga=>{sc=>'Latn',n=>'Irish',fam=>'Celtic',geo=>'IE'},
    gd=>{sc=>'Latn',n=>'Scottish Gaelic'},
    gez=>{sc=>'Ethi',n=>'Geez'},
    gl=>{sc=>'Latn',n=>'Galician',fam=>'Romance',geo=>'PT'},
    gmy=>{sc=>'Linb',n=>'Mycenaean Greek',anc=>1},
    gn=>{n=>'Guaraní'},
    got=>{sc=>'Goth',n=>'Gothic'},
    grc=>{sc=>'Grek',g=>'mfn',p=>1,n=>'Ancient Greek',anc=>1},
    gu=>{sc=>'Gujr',n=>'Gujarati',geo=>'IN'},
    gv=>{n=>'Manx'},
    ha=>{n=>'Hausa'},
    har=>{sc=>'Ethi',n=>'Harari'},
    he=>{sc=>'Hebr',g=>'mf',p=>1,alt=>1,n=>'Hebrew',fam=>'Semitic',geo=>'IL'},
    hi=>{sc=>'Deva',g=>'mf',p=>1,n=>'Hindi',geo=>'IN'},
    hit=>{sc=>'Xsux',n=>'Hittite'},
    hr=>{sc=>'Latn',g=>'mfn',p=>1,alt=>1,n=>'Croatian',fam=>'Slavic',geo=>'HR'},
    hsb=>{n=>'Upper Sorbian'},
    hu=>{sc=>'Latn',g=>'',p=>1,alt=>0,n=>'Hungarian',geo=>'HU'},
    hy=>{sc=>'Armn',g=>'',alt=>0,n=>'Armenian',geo=>'AM'},
    ia=>{sc=>'Latn',g=>'',alt=>0,n=>'Interlingua',fam=>'Constructed'},
    id=>{sc=>'Latn',n=>'Indonesian',geo=>'Indonesia'},
    ie=>{sc=>'Latn',g=>'',alt=>0,n=>'Interlingue',fam=>'Constructed'},
    ik=>{n=>'Inupiak'},
    ims=>{sc=>'Ital',n=>'Marsian'},
    io=>{n=>'Ido'},
    is=>{sc=>'Latn',g=>'mfn',p=>1,alt=>0,n=>'Icelandic',fam=>'Germanic',geo=>'IS'},
    it=>{sc=>'Latn',g=>'mf',p=>1,alt=>0,n=>'Italian',fam=>'Romance',geo=>['IT','CH']},
    iu=>{n=>'Inuktitut'},
#    iw=>{sc=>'Hebr'},
    ja=>{sc=>'Jpan',g=>'',p=>0,alt=>0,n=>'Japanese',geo=>'JP'},  # kana
    jbo=>{sc=>'Latn',n=>'Lojban'},
    jv=>{n=>'Javanese'},
    ka=>{sc=>'Geor',g=>'',alt=>0,n=>'Georgian',geo=>'GE'},
    kjh=>{sc=>'Cyrl',n=>'Khakas'},
    kk=>{sc=>'Cyrl',g=>'',alt=>0,n=>'Kazakh',fam=>'Turkic',geo=>'AZ'},
    kl=>{n=>'Greenlandic'},
    km=>{sc=>'Khmr',n=>['Khmer','Cambodian'],geo=>'KH'},
    kn=>{sc=>'Knda',n=>'Kannada',fam=>'Dravidian',geo=>'IN'},
    ko=>{sc=>'Kore',g=>'',p=>0,alt=>0,n=>'Korean',geo=>['KR','KP']},
    ks=>{sc=>['Arab','Deva'],n=>'Kashmiri'},
    ku=>{sc=>'Arab',n=>'Kurdish'},
    kw=>{n=>'Cornish'},
    ky=>{sc=>'Cyrl',g=>'',alt=>0,n=>'Kyrgyz',fam=>'Turkic',geo=>'KG'},
    la=>{sc=>'Latn',g=>'mfn',p=>1,alt=>1,n=>'Latin',anc=>1,fam=>'Romance'},
    lez=>{sc=>'Cyrl',n=>'Lezgi'},
    lo=>{sc=>'Laoo',g=>'',p=>0,alt=>0,n=>'Lao',geo=>'LA'},
    lt=>{sc=>'Latn',g=>'mf',p=>1,alt=>1,n=>'Lithuanian',fam=>'Baltic',geo=>'LT'},
    lv=>{sc=>'Latn',g=>'mf',p=>1,alt=>0,n=>'Latvian',fam=>'Baltic',geo=>'LV'},
#    ma=>{sc=>'Deva'},
    mk=>{sc=>'Cyrl',n=>'Macedonian'},
    ml=>{sc=>'Mlym',g=>'',n=>'Malayalam',fam=>'Dravidian',geo=>'IN'},
    mn=>{sc=>'Cyrl',g=>'',alt=>0,n=>'Mongolian',geo=>'MN'},
    mr=>{sc=>'Deva',g=>'mfn',n=>'Marathi',geo=>'IN'},
    ne=>{sc=>'Deva',n=>'Nepali',geo=>'NP'},
    nl=>{sc=>'Latn',g=>'mfn',p=>1,alt=>0,n=>'Dutch',fam=>'Germanic',geo=>['NL','BE']},
    nn=>{sc=>'Latn',g=>'mfn',p=>1,alt=>0,n=>'Nynorsk',fam=>'Germanic',geo=>'NO'},
    no=>{sc=>'Latn',g=>'mfn',p=>1,alt=>0,n=>'Norwegian',fam=>'Germanic',geo=>'NO'},
    os=>{sc=>'Cyrl',g=>'',alt=>0,n=>'Ossetian',geo=>'GE'},
    osc=>{sc=>'Ital',n=>'Oscan'},
    ota=>{sc=>'Arab',n=>'Ottoman Turkish'},
    pa=>{sc=>['Guru','Arab'],n=>['Punjabi','Panjabi'],g=>'mf',p=>1},
    peo=>{sc=>'Xpeo',n=>'Old Persian'},
    phn=>{sc=>'Phnx',n=>'Phoenician'},
    pl=>{sc=>'Latn',g=>'mfn',p=>1,n=>'Polish',fam=>'Slavic',geo=>'PL'},
    ps=>{sc=>'Arab',n=>['Pashto','Pushto']},
    pt=>{sc=>'Latn',g=>'mf',p=>1,alt=>0,n=>'Portuguese',fam=>'Romance',geo=>['PT','BR']},
    ro=>{sc=>'Latn',g=>'mfn',p=>1,n=>'Romanian',fam=>'Romance',geo=>'RO'},
    ru=>{sc=>'Cyrl',g=>'mfn',p=>1,alt=>1,n=>'Russian',fam=>'Slavic',geo=>'RU'},
    rw=>{sc=>'Latn',n=>'Kinyarwanda',fam=>'Bantu',geo=>'RW'},
    sa=>{sc=>'Deva',g=>'mfn',p=>1,n=>'Sanskrit',geo=>'IN'},
    sd=>{sc=>'Arab',n=>'Sindhi'},
    si=>{sc=>'Sinh',n=>['Sinhala','Sinhalese'],geo=>'LK'},
    sk=>{sc=>'Latn',g=>'mfn',p=>1,n=>['Slovak','Slovakian'],fam=>'Slavic',geo=>'SK'},
    sl=>{sc=>'Latn',g=>'mfn',p=>1,n=>['Slovene','Slovenian'],fam=>'Slavic',geo=>'SI'},  # dual
    spx=>{sc=>'Ital',n=>'South Picene'},
    sq=>{sc=>'Latn',g=>'mf',alt=>0,n=>'Albanian',geo=>'AL'},
    sr=>{sc=>['Cyrl','Latn'],g=>'mfn',p=>1,n=>'Serbian',fam=>'Slavic',geo=>'RS'},
    sux=>{sc=>'Xsux',n=>'Sumerian'},
    sv=>{sc=>'Latn',g=>'nc',p=>1,alt=>0,n=>'Swedish',fam=>'Germanic',geo=>'SE'},
    sw=>{sc=>'Latn',g=>'',alt=>0,n=>'Swahili'},  # noun classes
    syr=>{sc=>'Syrc',n=>'Syriac'},
    ta=>{sc=>'Taml',g=>'',alt=>0,n=>'Tamil',fam=>'Dravidian',geo=>['IN','LK']},
    te=>{sc=>'Telu',g=>'',alt=>0,n=>'Telugu',fam=>'Dravidian',geo=>'IN'},
    tg=>{sc=>'Cyrl',g=>'',alt=>0,n=>'Tajik',geo=>'TJ'},
    th=>{sc=>'Thai',g=>'',p=>0,alt=>0,n=>'Thai',geo=>'TH'},
    ti=>{sc=>'Ethi',n=>'Tigrinya'},
    tig=>{sc=>'Ethi',n=>'Tigre'},
    tk=>{sc=>'Latn',g=>'',alt=>0,n=>'Turkmen',fam=>'Turkic',geo=>'TM'},
    tl=>{sc=>['Latn','Tglg'],g=>'',p=>0,n=>'Tagalog',geo=>'PH'},
    tmr=>{sc=>'Hebr',n=>'Talmudic Aramaic'},
    tr=>{sc=>'Latn',g=>'',p=>1,alt=>1,n=>'Turkish',fam=>'Turkic',geo=>'TR'},
    tt=>{sc=>'Cyrl',g=>'',alt=>0,n=>'Tatar',fam=>'Turkic',geo=>'RU'},
    ug=>{sc=>'Arab',n=>['Uyghur','Uighur']},
    uga=>{sc=>'Ugar',n=>'Ugaritic'},
    uk=>{sc=>'Cyrl',g=>'mfn',p=>1,n=>'Ukrainian',fam=>'Slavic',geo=>'UA'},
    ur=>{sc=>'Arab',g=>'mf',p=>1,n=>'Urdu',geo=>['PK','IN']},
    uz=>{sc=>'Latn',g=>'',alt=>0,n=>'Uzbek',fam=>'Turkic',geo=>'UZ'},
    vi=>{sc=>'Latn',g=>'',p=>0,n=>'Vietnamese',geo=>'VN'},
    xae=>{sc=>'Ital',n=>'Aequian'},
    xcr=>{sc=>'Cari',n=>'Carian'},
    xfa=>{sc=>'Ital',n=>'Faliscan'},
    xlc=>{sc=>'Lyci',n=>'Lycian'},
    xld=>{sc=>'Lydi',n=>'Lydian'},
    xlu=>{sc=>'Xsux',n=>'Luwian'},
    xrr=>{sc=>'Ital',n=>'Raetic'},
    xst=>{sc=>'Ethi',n=>'Silt\'e'},
    xum=>{sc=>'Ital',n=>'Umbrian'},
    xve=>{sc=>'Ital',n=>'Venetic'},
    xvo=>{sc=>'Ital',n=>'Volscian'},
    yi=>{sc=>'Hebr',g=>'mfn',p=>1,n=>'Yiddish',fam=>'Germanic'},
    yua=>{sc=>'Latn',p=>1,alt=>1,n=>'Yucatec Maya',geo=>'MX'},
    zh=>{sc=>'Hani',g=>'',p=>0},
    zu=>{sc=>'Latn',n=>'Zulu'}
};

#### language codes from the ISO standard

my $isolangurl = 'http://www.sil.org/iso639-3/iso-639-3_20090210.tab';

print STDERR "getting isolang...\n";
my $isolangcontent = get $isolangurl;
die "Couldn't get isolang $isolangurl" unless defined $isolangcontent;
print STDERR "got isolang.\n";

# strip table headings (including BOM)
$isolangcontent =~ s/^.*?\n//;

while ($isolangcontent =~ /^(\w\w\w)\t(\w\w\w)?\t(\w\w\w)?\t(\w\w)?\t(\w)\t(\w)\t([^\t]+)/gm) {
    # ($iso3, $iso2b, $iso2t, $iso1, $scope, $type, $name
    # ($1,    $2,     $3,     $4,    $5,     $6,    $7);

    my $c = $4 ? $4 : $1;

    $metadata->{$c}{iso2b} = $2 if ($2 && $2 ne $3);
    if ($c eq $4) {
        $metadata->{$c}{iso3} = $1;
    #} elsif ($4) {
    #    $metadata->{$c}{iso1} = $4;
    }
    $metadata->{$c}{isoscope} = $5;
    $metadata->{$c}{isotype} = $6;
    $metadata->{$c}{isoname} = $7;
}

# WikiMedia metadata
my $wmmetadata = {
    'bat-smg'=>{n=>'Samogitian'},
    'be-x-old'=>{sc=>'Cyrl',n=>'Belarusian (Tarashkevitsa)'},
    bh=>{sc=>'Deva',n=>'Bihari',fam=>'Indo-Aryan',geo=>'IN'},
    'cbk-zam'=>{n=>'Zamboanga Chavacano'},
    eml=>{n=>'Emiliano-Romagnolo'},
    'fiu-vro'=>{n=>'Võro'},
    'map-bms'=>{n=>'Banyumasan'},
    'mo'=>{sc=>'Cyrl',n=>'Moldavian'}, # locked
    nah=>{n=>'Nahuatl'},
    'nds-nl'=>{n=>'Dutch Low Saxon'},
    'roa-rup'=>{n=>'Aromanian'},
    'roa-tara'=>{n=>'Tarantino'},
    simple=>{sc=>'Latn',n=>'Simple English'},
    tokipona=>{n=>'Toki Pona'},
    'zh-classical'=>{sc=>'Hant',n=>'Old Chinese'},
    'zh-min-nan'=>{sc=>'Latn',n=>'Min Nan'},
    'zh-yue'=>{sc=>'Hani',n=>'Cantonese'}
};

# read which language wiktionaries exist from noc.wikimedia.org
# TODO use the sitematrix code from langcodes.pl
# TODO native names can also be extracted from sitematrix

my $wmlangcontent = get 'http://noc.wikimedia.org/conf/all.dblist';

if (defined $wmlangcontent) {
    while ($wmlangcontent =~ /(\w+)wiktionary/g) {
        my $code = $1;
        $code =~ tr/_/-/;
        $wmmetadata->{$code}{hw} = 1;
    }
}

#my $mw = MediaWiki::API->new();
#$mw->{config}->{api_url} = 'http://en.wiktionary.org/w/api.php';
#
#print STDERR "getting sitematrixlang...\n";
#my $stuff = $mw->api( {
#    action => 'sitematrix' } )
#    || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
#print STDERR "got sitematrixlang.\n";
#
#for (my $prefixnum = 0; 1; ++$prefixnum) {
#    last if (!exists $stuff->{sitematrix}->{$prefixnum});
#
#    my $langcode = $stuff->{sitematrix}->{$prefixnum}->{code};
#    my $site = $stuff->{sitematrix}->{$prefixnum}->{site};
#
#    if (scalar @$site) {
#        $wmmetadata->{$langcode}{wm} = 1;
#
#        $wmmetadata->{$langcode}{hw} = 1 if (grep $_->{code} eq 'wiktionary', @$site);
#    }
#}

# English Wiktionary metadata
# TODO extract code/name pairs using the code from enwiktlangs.pl
# TODO xx-Yyyy style script templates could be discovered too

my $enwiktmetadata = {
    ang=>{altmapfrom=>'ĀāǢǣĊċĒēĠġĪīŌōŪūȲȳ',altmapto=>'AaÆæCcEeGgIiOoUuYy'},
    aoq=>{n=>'Ammonite'},
    ar=>{altmapstrip=>'\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652'},
    'ast-leo'=>{n=>'Leonese'},
    'el-it'=>{n=>'Salentine Greek'},
    'eml-rom'=>{n=>'Romagnolo'},
    fa=>{wsc=>'fa-Arab'},
    'fr-ca'=>{n=>'Canadian French'},
    'fr-nng'=>{n=>'Guernésiais'},
    'fr-nnj'=>{n=>'Jèrriais'},
    'fr-nnx'=>{n=>'Norman'},
    grc=>{wsc=>'polytonic'},
    he=>{altmapstrip=>'\u05B0\u05B1\u05B2\u05B3\u05B4\u05B5\u05B6\u05B7\u05B8\u05B9\u05BA\u05BB\u05BC\u05BD\u05BF\u05C1\u05C2'},
    hr=>{altmapfrom=>'ȀȁÀàȂȃÁáĀāȄȅÈèȆȇÉéĒēȈȉÌìȊȋÍíĪīȌȍÒòȎȏÓóŌōȐȑȒȓŔŕȔȕÙùȖȗÚúŪū',altmapto=>'AaAaAaAaAaEeEeEeEeEeIiIiIiIiIiOoOoOoOoOoRrRrRrUuUuUuUuUu',altmapstrip=>'\u030F\u0300\u0311\u0301\u0304'},
    ks=>{wsc=>'ks-Arab'},   # TODO needs 'Deva' too since wsc overrides sc but the wsc code cannot handle array
    ku=>{wsc=>'ku-Arab'},
    la=>{altmapfrom=>'ĀāĂăĒēĔĕĪīĬĭŌōŎŏŪūŬŭ',altmapto=>'AaAaEeEeIiIiOoOoUuUu'},
    lt=>{altmapfrom=>'áãàéẽèìýỹñóõòúù',altmapto=>'aaaeeeiyynooouu',altmapstrip=>'\u0340\u0301\u0303'},  # unchecked, from cirwin's code
    mol=>{sc=>'Cyrl',n=>'Moldavian'},
    'nap-cal'=>{n=>'Calabrese'},
    'no-rik'=>{n=>'Norwegian Riksmål'},
    ota=>{wsc=>'ota-Arab'},
    # pa-Arab
    ps=>{wsc=>'ps-Arab'},
    sd=>{wsc=>'sd-Arab'},
    ru=>{altmapstrip=>'\u0301'},    # combining acute
    sfk=>{n=>'Safwa'},
    'sr-mon'=>{n=>'Montenegrin'},
    suh=>{n=>'Suba'},
    szk=>{n=>'Sizaki'},
    tr=>{altmapfrom=>'ÂâÛû',altmapto=>'AaUu'},
    'twf-pic'=>{n=>'Picuris'},
    ug=>{wsc=>'ug-Arab'},
    ur=>{wsc=>'ur-Arab'},
    wwg=>{n=>'Woiwurrung'},
    yi=>{wsc=>'yi-Hebr'},
    'zh-cn'=>{n=>'Simplified Chinese'},
    'zh-tw'=>{n=>'Traditional Chinese'},
    zkm=>{n=>'Maikoti'}
};

# get the superset of all language codes from ISO, MediaWiki, and en.wiktionary
my %langsuperset = map {$_, 1} (keys %$metadata, keys %$wmmetadata, keys %$enwiktmetadata);

# FastCGI loop

while (FCGI::accept >= 0) {
    my %custommetadata = ();

    my %opts = ('format' => 'json');
    
    # get command line or cgi args
    CliOrCgiOptions(\%opts, qw{format langs fields callback has match}); 
        
    my %langs = map { $_ => 1 } split ',', $opts{langs} if ($opts{langs});
    my %fields = map { $_ => 1 } split ',', $opts{fields} if ($opts{fields});

    # build the subset of the metadata to serve
    my $get_all_langs = (scalar keys %langs == 0);
    my $get_all_fields = (scalar keys %fields == 0);

    # each language
    foreach my $l (keys %langsuperset) {
        my %row;
        my $emit = 1;

        foreach my $set ($metadata, $wmmetadata, $enwiktmetadata) {
            foreach my $f (keys %{$set->{$l}}) {
                $row{$f} = $set->{$l}->{$f};
            }            
        }
    
        if ($opts{match}) {
            $emit = 0;
            my ($k, $v) = split ':', $opts{match};
            if (ref($row{$k}) eq 'ARRAY' && grep($_ eq $v, @{$row{$k}})) {
                $emit = 1;
            } elsif ($metadata_dtd{$k} eq 'bool' && $row{$k} == $v) {
                $emit = 1;
            } elsif ($row{$k} eq $v) {
                $emit = 1;
            }
        }

        elsif ($opts{has}) {
            $emit = exists $row{$opts{has}};
        }

        if ($emit) {
            if ($get_all_langs || exists $langs{$l}) {
                # each field
                foreach my $f (keys %metadata_dtd) {
                    if ($get_all_fields || exists $fields{$f}) {
                        if (exists $row{$f}) {
                            $custommetadata{$l}->{$f} = $row{$f};
                        }
                    }
                }
            }
        }
    }
 
    dumpresults(\%custommetadata, $opts{format}, $opts{callback});
}

exit;

##########################################

sub CliOrCgiOptions {
    my $opts = shift;
    my @optnames = @_;
    
    if (exists($ENV{'QUERY_STRING'})) {
        $scriptmode = 'cgi';

        my %q = map { split('=') } split('&', $ENV{'QUERY_STRING'});

        foreach my $o (@optnames) {
            $opts->{$o} = $q{$o} if (exists $q{$o});
        }
    } else {
        GetOptions($opts, map { $_ . '=s', } @optnames);
    }
}

sub dumpresults {
    my $r = shift;
    my $format = shift;
    my $callback = shift;

    # we must output the HTTP headers to STDOUT before anything else
    $scriptmode eq 'cgi' && print "Content-type: text/plain; charset=UTF-8\n\n";

    # XXX my doesn't work for these two line with fcgi!
    # XXX it will be right in dumpresults context but wrong in dumpresults_json!
    our $indent = 0;
    our $fmt = $format eq 'jsonfm' ? 1 : 0;

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
            for my $h (keys %$r) {
                $i && print ",";
                $i++ && $fmt && print "\n";
                my $k = $h;
                unless ($h =~ /^[a-z]+$/) {
                    $k = '"' . $h . '"';
                }
                $fmt && print '  ' x $indent;
                print $k, ':';
                $fmt && print ' ';
                dumpresults_json($r->{$h}, $h);
            }
            $fmt && print "\n", '  ' x --$indent;
            print '}';
        } elsif ($r =~ /^-?\d+$/) {
            if ($metadata_dtd{$lhs} eq 'bool') {
                print $r ? 'true' : 'false';
            } else {
                print $r;
            }
        } else {
            print '"', $r, '"';
        }
    }
}

sub dumperror {
    dumpresults( { error => { code => shift, info => shift} } );

    exit;
}

