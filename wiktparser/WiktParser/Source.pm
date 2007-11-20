# vi: ts=4 sw=4 sts=4
package WiktParser::Source;

use vars qw($line);

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
	my $self = shift;

	$self->{_line} = <STDIN>;
	return $self->{_line};
}

1;

