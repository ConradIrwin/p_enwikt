# vi: ts=4 sw=4 sts=4
package Wiki::DumpParser;

use strict;

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	return $self;
}

sub set_title_handler {
	my ($self, $handler) = @_;

	$self->{title_handler} = $handler;
}

sub set_text_start_handler {
	my ($self, $handler) = @_;

	$self->{text_start_handler} = $handler;
}

sub set_text_end_handler {
	my ($self, $handler) = @_;

	$self->{text_end_handler} = $handler;
}

sub set_text_handler {
	my ($self, $handler) = @_;

	$self->{text_handler} = $handler;
}

sub parse {
	my $self = shift;
	my ($xline) = @_;

	my $maxpages = 0;
	my $pagecounter = 0;

	my %langnamestocodes;
	my %namespaces;
	my %titles;

	while ($$xline = <STDIN>) {
		last if ($$xline =~ /<namespaces>/);
	}

	if ($$xline !~ /<namespaces>/) {
		print STDERR "** namespaces section not found\n";
		exit;
	}

	print STDERR "** found namespaces\n";

	while ($$xline = <STDIN>) {
		if ($$xline =~ /<namespace key="-?\d+"(.*)>/) {
			my $rest = $1;
			if ($rest =~ />(.*)<\/namespace/) {
				$namespaces{$1} = 1;
			}
		} else {
			last;
		}
	}

	if ($$xline !~ /<\/namespaces>/) {
		print STDERR "** end of namespaces section not found\n";
		exit;
	}

	print STDERR "** namespaces done\n";

	my $nsre = '^(' . join('|', 'webster 1913', keys %namespaces) . '):(.*)$';

	print "<wiktionary>\n";

	# Each line of dump file
	while (1) {

		my $title = '';

		while ($$xline = <STDIN>) {
			if ($$xline =~ /<title>(.*)<\/title>/) {
				$title = $1;
				last;
			}
		}

		if ($$xline !~ /<title>.*<\/title>/) {
			print STDERR "** no more pages";
			return;
		}

		my $ns = '';

		# Check namespace
		if ($title =~ /$nsre/o) {
			$ns = $1;
			$title = $2;
		}

		if ($self->{title_handler}) {
			&{$self->{title_handler}}( $ns, $title );
		}

		# Skip to start of wikitext
		while ($$xline = <STDIN>) {
			last if ($$xline =~ /<text xml:space="preserve">/);
		}

		# If we ever had an article record without a text record
		if ($$xline =~ /<title>.*<\/title>/) {
			print STDERR "** $title has no text field\n";
			exit;
		}

		if ($$xline !~ /<text xml:space="preserve">/) {
			print STDERR "** unexpected end of file while looking for $title's text field\n";
			exit;
		}

		if ($self->{text_handler}) {
			&{$self->{text_handler}}();
		}

		# Skip remainder of page
		while ($$xline = <STDIN>) {
			last if ($$xline =~ /<\/page>/);
		}
		if ($$xline !~ /<\/page>/) {
			print STDERR "** unexpected end of file in $title\n";
			exit;
		}

		# Enough pages processed?
		if ($ns eq '') {
			if ($maxpages != 0 && $pagecounter >= $maxpages) {
				print STDERR "** max number of pages parsed\n";
				print "</wiktionary>\n";
				return;
			}
		}
	} # Next line of dump file
}

1;

