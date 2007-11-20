# vi: ts=4 sw=4 sts=4
package Wiki::WiktParser;

use strict;

require WiktParser::Source;

# TODO should be member
my @scope;

#
# Constructor
#

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->{src} = undef;
	return $self;
}

sub set_source {
	my $self = shift;

	$self->{src} = shift;
}

#
# Handlers for various kinds of pages (by namespace)
#

sub set_article_handler {
	my ($self, $handler) = @_;

	$self->{article_handler} = $handler;
}

sub set_template_handler {
	my ($self, $handler) = @_;

	$self->{template_handler} = $handler;
}

#
# Handlers at the level-two / article / language / level
#

sub set_article_start_handler {
	my ($self, $handler) = @_;

	$self->{article_start_handler} = $handler;
}

sub set_langsection_handler {
	my ($self, $handler) = @_;

	$self->{langsection_handler} = $handler;
}

sub set_article_end_handler {
	my ($self, $handler) = @_;

	$self->{article_end_handler} = $handler;
}

#
# Parse wikitext of a Wiktionary page
#

sub parse {
	my $self = shift;
	my ($ns, $title) = @_;

	if ($ns eq '') {
		# Custom article handler
		if ($self->{article_handler}) {
			&{$self->{article_handler}}( $title );

		# Built-in article parser method
		} else {
			$self->parse_article( $title );
		}

	# TODO localize by using namespace numbers
	} elsif ($ns eq 'Template') {
		if ($self->{template_handler}) {
			&{$self->{template_handler}}();
		}
	}
}

#
# This is designed around the English Wiktionary format
#
# It expects structured nested headings
# It expects literal headings, not templated headings
#
# TODO separate various levels of functionality
#

sub parse_article {
	my $self = shift;
	my $title = shift;

	# Build a tree based on the heading levels
	my $pagetree = $self->parse_heading_structure($title);

	# TODO is there a clearer way?
	my $p = $pagetree->{raw}->{sections}[0];

	# Article start
	if ($self->{article_start_handler}) {
		&{$self->{article_start_handler}}($p);
	} else {
		$self->handle_article_start($p);
	}

	# Each language in this page
	foreach my $langsection (@{$p->{sections}}) {
		if ($self->{langsection_handler}) {
			&{$self->{langsection_handler}}( $langsection );
		}
	}

	# Article end
	if ($self->{article_end_handler}) {
		&{$self->{article_end_handler}}();
	} else {
		$self->handle_article_end();
	}
}

#
# Build a tree based on the heading levels
#

sub parse_heading_structure {
	my $self = shift;
	my $title = shift;

	my $pagetree;				# a page is an article

	$pagetree = {};
	$pagetree->{raw} = {};		# level 1 heading, root for tree of headings
	$pagetree->{cooked} = {};	# TODO not yet used

	@scope[0] = $pagetree->{raw};

	my $tline;					# line of wikitext to be parsed

	my $prevsection;
	my $section;				# each heading starts a new section

	my $entry;					# each language heading starts a new entry

	$pagetree->{title} = $title;

	$section = {};
	$section->{level} = 1;
	$section->{heading} = $title;
	$section->{lines} = [];
	$section->{sections} = [];

	$prevsection = $self->appendsection($section);

	# Parse the heading structure as used on the English Wiktionary

	# Each line of page wikitext
	while (1) {
		# TODO try to separate dump file stuff from wiktionary stuff
		$self->{src}->line() =~ /^\s*(?:<text xml:space="preserve">)?(.*?)(<\/text>)?$/;
		my ($tline, $post) = ($1, $2);

		# Heading
		if ($tline =~ /^(==+)\s*([^=]+?)\s*(==+)\s*$/) {
			$section = {};
			$section->{unbalanced} = (length($1) != length($3));

			my $level = length($1) < length($3) ? length($1) : length($3);
			$section->{level} = $level;

			my $headinglabel = $2;
			if ($headinglabel =~ /^\[\[\s*(?:.*\|)?(.*?)\s*\]\]$/) {
				$headinglabel = $1;
			}

			$section->{heading} = $headinglabel;
			$section->{lines} = [];
			$section->{sections} = [];

			# Flag sections more than 1 level deeper than its parent
			if ($prevsection->{level} - $level < -1) {
				$section->{toodeep} = 1;
			}

			$prevsection = $self->appendsection($section);
		}
		
		# Not heading, just plain lines
		else {
			push @{$section->{lines}}, $tline;
		}

		# TODO shouldn't this test be at the bottom of the loop?
		last if ($post ne '');

		last unless ($self->{src}->nextline());
	} # while (1)

	return $pagetree;
}

#######################################################

#
# @scope is a global, should be a member I guess
#

sub appendsection {
	my ($self, $section) = @_;

	# This make a circular reference which prevents garbage collection!
	#$section->{parent} = @scope[$section->{level} - 1];
	push @{@scope[$section->{level} - 1]->{sections}}, $section;

	for (my $l = $section->{level}; $l <= 7; ++$l) {
		@scope[$l] = $section;
	}

	return $section;
}

########################################################################

1;

