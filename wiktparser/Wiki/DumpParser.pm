# vi: ts=4 sw=4 sts=4
package Wiki::DumpParser;

use strict;

# Format of MediaWiki dump file
# mediawiki: xmlns, xmlns:xsi, xsi:SchemaLocation, version, xml:lang
#  siteinfo
#   sitename
#   base
#   generator
#   case
#   namespaces
#    namespace: key
#    namespace...
# page
#  title
#  id
#  restrictions
#  revision
#   id
#   timestamp
#   contributor
#    username
#    id
#   minor
#   comment
#   text
# page...

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->{_namespaces} = {};
	$self->{_maxpages} = 0;
	$self->{_pagecount} = 0;
	return $self;
}

sub set_maxpages {
	my ($self, $mp) = @_;
	$self->{_maxpages} = $mp;
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

#
# With no argument returns total number of pages so far for all namespaces
# Otherwise returns total number of pages so far for given namespace only
#
# TODO support namespace by number of by name
#

sub get_pagecount {
	my ($self, $ns) = @_;

	return $self->{_pagecount};
}

############################################

sub parse {
	my $self = shift;
	my $xline = shift;

	# Skip stuff before the <namespaces> section

	while ($$xline = <STDIN>) {
		last if ($$xline =~ /<namespaces>/);
	}

	# We read everything and never found <namespaces>
	if ($$xline !~ /<namespaces>/) {
		print STDERR "** namespaces section not found\n";
		exit;
	}

	# Handle <namespaces>

	while ($$xline = <STDIN>) {
		if ($$xline =~ /<namespace key="(-?\d+)"(.*)>/) {
			my ($key, $rest) = ($1, $2);
			if ($rest =~ />(.*)<\/namespace/) {
				$self->{_namespaces}->{$1} = { 'key' => $key, 'count' => 0, 'name' => $1 };
			} else {
				$self->{_namespaces}->{''} = { 'key' => $key, 'count' => 0 };
			}
		} else {
			last;
		}
	}

	# Premature EOF
	if ($$xline !~ /<\/namespaces>/) {
		print STDERR "** end of namespaces section not found\n";
		exit;
	}

	#foreach my $ns (sort {$self->{_namespaces}->{$a}->{key} <=> $self->{_namespaces}->{$b}->{key}} keys %{$self->{_namespaces}}) {
	#	print STDERR "** '", $ns, '\' -> ', $self->{_namespaces}->{$ns}->{key}, "\n";
	#}

	# Build regex that can tell a namespaced title from other titles with colons
	# Also handles "pseudonamespaces"
	my $nsre = '^(' . join('|', 'webster 1913', keys %{$self->{_namespaces}}) . '):(.*)$';

	# After <namespaces> comes a huge series of <page>s

	# Each line of dump file
	while (1) {

		my $ns = '';
		my $title = '';

		# Skip anything before next <title>
		#  Currently </text> </revision> </page> <page>
		while ($$xline = <STDIN>) {
			if ($$xline =~ /<title>(.*)<\/title>/) {
				$title = $1;
				last;
			}
		}

		# EOF
		if ($$xline !~ /<title>.*<\/title>/) {
			print STDERR "** no more pages\n";
			return;
		}

		# Check namespace
		if ($title =~ /$nsre/o) {
			$ns = $1;
			$title = $2;
		}

		++$self->{_pagecount};
		++$self->{_namespaces}->{$ns}->{count};

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
			if ($self->{_maxpages} != 0 && $self->{_pagecount} >= $self->{_maxpages}) {
				print STDERR "** max number of pages parsed\n";
				print "</wiktionary>\n";
				return;
			}
		}
	} # Next line of dump file
}

1;

