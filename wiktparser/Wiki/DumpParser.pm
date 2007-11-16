# vi: ts=4 sw=4 sts=4
package Wiki::DumpParser;

use strict;

require WiktParser::Source;

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

	# Skip stuff before the <namespaces> section

	while (WiktParser::Source::nextline()) {
		last if ($WiktParser::Source::line =~ /<namespaces>/);
	}

	# We read everything and never found <namespaces>
	if ($WiktParser::Source::line !~ /<namespaces>/) {
		print STDERR "** namespaces section not found\n";
		exit;
	}

	# Handle <namespaces>

	while (WiktParser::Source::nextline()) {
		if ($WiktParser::Source::line =~ /<namespace key="(-?\d+)"(.*)>/) {
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
	if ($WiktParser::Source::line !~ /<\/namespaces>/) {
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
		while (WiktParser::Source::nextline()) {
			if ($WiktParser::Source::line =~ /<title>(.*)<\/title>/) {
				$title = $1;
				last;
			}
		}

		# EOF
		if ($WiktParser::Source::line !~ /<title>.*<\/title>/) {
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
		while (WiktParser::Source::nextline()) {
			last if ($WiktParser::Source::line =~ /<text xml:space="preserve">/);
		}

		# If we ever had an article record without a text record
		if ($WiktParser::Source::line =~ /<title>.*<\/title>/) {
			print STDERR "** $title has no text field\n";
			exit;
		}

		if ($WiktParser::Source::line !~ /<text xml:space="preserve">/) {
			print STDERR "** unexpected end of file while looking for $title's text field\n";
			exit;
		}

		if ($self->{text_handler}) {
			&{$self->{text_handler}}();
		}

		# Skip remainder of page
		while (WiktParser::Source::nextline()) {
			last if ($WiktParser::Source::line =~ /<\/page>/);
		}
		if ($WiktParser::Source::line !~ /<\/page>/) {
			print STDERR "** unexpected end of file in $title\n";
			exit;
		}

		# Enough pages processed?
		if ($ns eq '') {
			if ($self->{_maxpages} != 0 && $self->{_pagecount} >= $self->{_maxpages}) {
				print STDERR "** max number of pages parsed\n";
				return;
			}
		}
	} # Next line of dump file
}

sub show_page_counts {
	my $self = shift;

	print STDERR 'Total pages scanned: ', $self->{_pagecount}, "\n";

	foreach my $ns (sort {$self->{_namespaces}->{$a}->{key} <=> $self->{_namespaces}->{$b}->{key}} keys %{$self->{_namespaces}}) {
		if ($self->{_namespaces}->{$ns}->{count}) {
			print STDERR $ns ? $ns : 'Default namespace', ' pages scanned: ', $self->{_namespaces}->{$ns}->{count}, "\n";
		}
	}
}

1;

