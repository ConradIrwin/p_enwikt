<?php

define( RESULTS_DIR, "/home/project/e/n/w/enwikt/feedback/results/" );

function main() {

	if( !isset( $_GET['action'] ) ) {
		return print_usage();
	}

	switch( $_GET['action'] ) {
		case 'code':
			highlight_file( __FILE__ );
			break;

		case 'feedback':
			if( isset( $_GET['feedback'] ) || isset( $_GET['title'] ) || isset( $_GET['wiki'] ) ) {
				store_feedback( $_GET['feedback'], $_GET['title'], $_GET['wiki'] );
				break;
			}
		case 'results':
			if(! isset( $_GET['wiki'] ) ) {
				list_wikis();
				break;
			}
			if(! isset( $_GET['week'] ) ) {
				list_weeks( $_GET['wiki'] );
				break;
			}
			display_results( $_GET['wiki'], $_GET['week'] );
			break;
		default:
			print_usage();
	}
}

function valid_wiki( $wiki ) {
	return preg_match( '/^[a-z-]{1,10}\.(wiktionary|wiki(pedia|books|versity|species|source|quote))$/', $wiki );
}
function valid_week( $week ) {
	return preg_match( '/[0-9]{4}-W[0-9]{1,2}/', $week );
}
function valid_title( $title ) {
	return preg_match( '/[^\n\t]{1,255}/', $title );
}
function valid_feedback( $feedback ) {
	return preg_match( '/[^\n\t]{1,255}/', $feedback );
}

function store_feedback( $feedback, $title, $wiki ) {

	// Sanity checks
	if(! valid_wiki( $wiki ) ) {
		return print_error( "Invalid wikiname: e.g. 'en.wiktionary'" );
	}
	if(! valid_feedback( $feedback ) ) {
		return print_error( "Feedback is too long" );
	}
	if(! valid_title( $title ) ) {
		return print_error( "Title is too long" );
	}

	$dir =  RESULTS_DIR . $wiki;
	if( !is_dir( $dir ) ) {
		if( !mkdir( $dir ) ) {
			return print_error( "Could not create directory '$dir'" );
		}
	}

	$file = fopen( $dir . '/' . date( "Y-\\WW" ), 'a');
	if (! $file ) {
		return print_error( "Could not open the file to append to" );
	}
	$line = date("Y-m-d H:00") . "\t" . $title . "\t" . $feedback . "\n";
	fwrite( $file, $line );
	fclose( $file );

	header( 'Content-type: application/javascript; charset=utf-8' );
	echo "// Successfully inserted: $line";

	return true;
}

function list_wikis() {
	print_html( "<p>View results for:</p><ul>" . implode(array_map( 'format_dir', scandir( RESULTS_DIR ) ) ) . "</ul>" );
}

function format_dir( $d ) {
	if ( $d{0} == "." ) {
		return "";
	} else {
		$d = htmlspecialchars( $d );
		return "<li><a href=\"?action=results&amp;wiki=$d\">$d</a></li>\n";
	}
}

function list_weeks( $wiki ) {

	if(! valid_wiki( $wiki ) ) {
		return print_error("Invalid wiki name");
	}
	$dir = RESULTS_DIR . $wiki;
	if (!is_dir( $dir ) ) {
		return print_error("Invalid wiki name");
	} else {
		print_html( "<p>View results for $wiki during:</p><ul>" . implode( array_map( 'format_week', scandir( $dir ) ) ) . "</ul>" );
	}
}

function format_week( $d ) {
	if ( $d{0} == "." ) {
		return "";
	} else {
		$d = htmlspecialchars( $d );
		$w = htmlspecialchars( $_GET['wiki'] );
		return "<li><a href=\"?action=results&wiki=$w&week=$d\">$d</a>";
	}
}

function display_results( $wiki, $week ) {
	if(! valid_wiki( $wiki ) ) {
		return print_error("Invalid wiki name");
	}
	if(! valid_week( $week ) ) {
		return print_error("Invalid week number");
	}

	$file = RESULTS_DIR . $wiki . "/" . $week;
	$lines = file( $file, FILE_IGNORE_NEW_LINES );
	if (! $lines ) {
		return print_error( "Could not open '$file'" );
	}
	$fbs = array_map( 'extract_feedback', $lines );
	$result = array_count_values( $fbs );
	$table = array_map( 'format_result', array_keys( $result ), array_values( $result ) );
	arsort( $table );
	$table = implode( $table );
	$raw = "<a href=\"results/$wiki/$week\">raw</a>";
	$week = "<b>$week</b>";
	$wiki = "<a href=\"?action=results&amp;wiki=$wiki\">$wiki</a>";
	return print_html( "<p>Summary of counts for $wiki in $week ($raw):</p><table><tr><th>Count</th><th>Comment</th></tr>\n$table</table>" );
}

function extract_feedback( $line ) {
	$parts = explode( "\t", $line);
	if( count( $parts ) == 3 ) {
		return $parts[2];
	}
	return "invalid";
}

function format_result( $fb, $count ) {
	$fb = htmlspecialchars($fb);
	return "<tr><td>$count</td><td>$fb</td></tr>\n";
}

function print_html( $html ) {

	header( 'Content-type: text/html; charset=utf-8' );
	?>
	<html>
	<head>
		<title>Feedback</title>
		<style>
			body { font-family: sans-serif; }
			.error { color: red; }
			.footer { font-size: smaller; }
			h3 a { text-decoration: none; }
		</style>
	</head>
	<body>
		<h3><a href="http://toolserver.org/~enwikt/feedback/">Feedback</a></h3>
		<?php echo $html; ?>
		<hr/>
		<p class="footer">For more English Wiktionary tools, see <a href="http://toolserver.org/~enwikt/">http://toolserver.org/~enwikt/</a></p>

	</body>
	</html>
	<?php
}
function print_usage() {
	print_html( <<<HTML
		<p>This script stores user feedback from en.wikt.</p>
		<p>To view the agregated results, visit <a href="?action=results">?action=results</a></p>
		<p>To view the source code, visit <a href="?action=code">?action=code</a></p>
		<p>The API for leaving feedback is <code>?action=feedback&wiki=en.wiktionary&feedback=TEST&title=TEST</code>
		<p>Dumps of past feedback may be made available in the future.</p>
		<p>There is a javascript interface for this at <a href="http://en.wiktionary.org/wiki/User:Conrad.Irwin/feedback.js">http://en.wiktionary.org/wiki/User:Conrad.Irwin/feedback.js</a></p>
HTML
	);
	return true;
}

function print_error( $error ) {
	print_html( '<p class="error">' . htmlspecialchars( $error ) . '</p>' );
	return false;
}

main();
