# vi: ts=4 sw=4 sts=4
package WiktParser::Source;

use vars qw($line);

use strict;

sub nextline {
	$line = <STDIN>;
	return $line;
}

1;

