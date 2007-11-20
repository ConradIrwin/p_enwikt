# vi: ts=4 sw=4 sts=4
package WiktParser::Source;

use strict;

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->{_line} = '';
	return $self;
}

sub line {
	my $self = shift;

	return $self->{_line};
}

sub nextline {
	print STDERR "** called Source base class\n";

	return undef;
}

1;

package WiktParser::Source::Stdin;

use strict;

use vars qw(@ISA);

use WiktParser::Source;

@ISA = qw(WiktParser::Source);

sub new {
	my $class = shift;

	my $self = $class->SUPER::new();

	return $self;
}

sub nextline {
	my $self = shift;

	$self->{_line} = <STDIN>;
	return $self->{_line};
}

1;

package WiktParser::Source::String;

use strict;

use vars qw(@ISA);

use WiktParser::Source;

@ISA = qw(WiktParser::Source);

sub new {
	my $class = shift;

	my $self = $class->SUPER::new();

	$self->{string} = shift;

	return $self;
}

sub nextline {
	my $self = shift;

	$self->{string} =~ /^(.*)$/gm;
	$self->{_line} = $1;

	return $self->{_line};
}

1;

