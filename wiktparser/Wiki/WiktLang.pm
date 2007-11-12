# vi: ts=4 sw=4 sts=4
package Wiki::WiktLang;

use strict;

my @langs = (
	{ 'code' => 'ar',	'pattern' => '^Arabic$',			'genders' => 'mf' },
	{ 'code' => 'ang',	'pattern' => '^Old English$',		'genders' => 'mfn' },
	{ 'code' => 'bg',	'pattern' => '^Bulgarian$',			'genders' => 'mfn' },
	{ 'code' => 'ca',	'pattern' => '^Catalan$',			'genders' => 'mf' },
	{ 'code' => 'cs',	'pattern' => '^Czech$',				'genders' => 'mfn' },
	{ 'code' => 'cy',	'pattern' => '^Welsh$',				'genders' => 'mf' },
	{ 'code' => 'da',	'pattern' => '^Danish$',			'genders' => 'cn' },
	{ 'code' => 'de',	'pattern' => '^German$',			'genders' => 'mfn' },
	{ 'code' => 'el',	'pattern' => '^Greek$',				'genders' => 'mfn' },
	{ 'code' => 'eo',	'pattern' => '^Esperanto$',			'genders' => undef },
	{ 'code' => 'es',	'pattern' => '^Spanish$',			'genders' => 'mf' },
	{ 'code' => 'et',	'pattern' => '^Estonian$',			'genders' => undef },
	{ 'code' => 'fa',	'pattern' => '^(Persian|Farsi)$',	'genders' => undef },
	{ 'code' => 'fi',	'pattern' => '^Finnish$',			'genders' => undef },
	{ 'code' => 'fr',	'pattern' => '^French$',			'genders' => 'mf' },
	{ 'code' => 'he',	'pattern' => '^Hebrew$',			'genders' => 'mf' },
	{ 'code' => 'hi',	'pattern' => '^Hindi$',				'genders' => 'mf' },
	{ 'code' => 'hr',	'pattern' => '^Croatian$',			'genders' => 'mfn' },
	{ 'code' => 'hu',	'pattern' => '^Hungarian$',			'genders' => undef },
	{ 'code' => 'is',	'pattern' => '^Icelandic$',			'genders' => 'mfn' },
	{ 'code' => 'ja',	'pattern' => '^Japanese$',			'genders' => undef },
	{ 'code' => 'ko',	'pattern' => '^Korean$',			'genders' => undef },
	{ 'code' => 'la',	'pattern' => '^Latin$',				'genders' => 'mfn' },
	{ 'code' => 'lt',	'pattern' => '^Lithuanian$',		'genders' => 'mf' },
	{ 'code' => 'lv',	'pattern' => '^Latvian$',			'genders' => 'mf' },
	{ 'code' => 'mi',	'pattern' => '^M[aā]ori$',			'genders' => undef },
	{ 'code' => 'mn',	'pattern' => '^Mongolian$',			'genders' => undef },
	{ 'code' => 'nl',	'pattern' => '^Dutch$',				'genders' => 'mfn' },
	{ 'code' => 'no',	'pattern' => '^Norwegian$',			'genders' => 'mfn' },
	{ 'code' => 'pl',	'pattern' => '^Polish$',			'genders' => 'mfn' },
	{ 'code' => 'pt',	'pattern' => '^Portuguese$',		'genders' => 'mf' },
	{ 'code' => 'ro',	'pattern' => '^R[ou]manian$',		'genders' => 'mfn' },
	{ 'code' => 'ru',	'pattern' => '^Russian$',			'genders' => 'mfn' },
	{ 'code' => 'sk',	'pattern' => '^Slovak(?:ian)?$',	'genders' => 'mfn' },
	{ 'code' => 'sl',	'pattern' => '^Sloven(?:e|ian)$',	'genders' => 'mfn' },
	{ 'code' => 'sr',	'pattern' => '^Serbian$',			'genders' => 'mfn' },
	{ 'code' => 'sv',	'pattern' => '^Swedish$',			'genders' => 'cn' },
	{ 'code' => 'sw',	'pattern' => '^(?:Ki[sS]|S)wahili$','genders' => undef },
	{ 'code' => 'th',	'pattern' => '^Thai$',				'genders' => undef },
	{ 'code' => 'tr',	'pattern' => '^Turkish$',			'genders' => undef },
	{ 'code' => 'ur',	'pattern' => '^Urdu$',				'genders' => 'mf' },
	{ 'code' => 'vi',	'pattern' => '^Vietnamese$',		'genders' => undef },
	{ 'code' => 'yi',	'pattern' => '^Yiddish$',			'genders' => 'mfn' },
);

#
# No constructor. This class is just static data
#

sub bycode {
	my $code = shift;

	for my $l (@langs) {
		if ($l->{code} eq $code) {
			return $l;
		}
	}
	return undef;
}

sub byname {
	my $name = shift;

	for my $l (@langs) {
		if ($name =~ /$l->{pattern}/) {
			return $l;
		}
	}
	return undef;
}

1;

