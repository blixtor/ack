#!perl

use warnings;
use strict;

use Test::More tests => 71;

use lib 't';
use Util;

prep_environment();

NO_STARTDIR: {
    my $regex = 'non';

    my @files = qw( t/foo/non-existent );
    my @args = ( '-g', $regex );
    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );

    is( scalar @{$stdout}, 0, 'No STDOUT for non-existent file' );
    is( scalar @{$stderr}, 1, 'One line of STDERR for non-existent file' );
    like( $stderr->[0], qr/non-existent: No such file or directory/,
        'Correct warning message for non-existent file' );
}


NO_METACHARCTERS: {
    my @expected = qw(
        t/swamp/Makefile
        t/swamp/Makefile.PL
    );
    my $regex = 'Makefile';

    my @files = qw( t/ );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


METACHARACTERS: {
    my @expected = qw(
        t/swamp/html.htm
        t/swamp/html.html
    );
    my $regex = 'swam.......htm';

    my @files = qw( t/ );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


FRONT_ANCHOR: {
    my @expected = qw(
        t/standalone.t
    );
    my $regex = '^t.st';

    my @files = qw( t );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


BACK_ANCHOR: {
    my @expected = qw(
        t/swamp/moose-andy.jpg
    );
    my $regex = 'pg$';

    my @files = qw( t );
    my @args = ( '-a', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}


# -i no longer applies to regex given by -g
NOT_CASE_INSENSITIVE: {
    my @expected = qw();
    my $regex = 'PIPE';

    my @files = qw( t/swamp );
    my @args = ( '-i', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for -i -g $regex " );
}


# ... but can be emulated with (?i:regex)
CASE_INSENSITIVE: {
    my @expected = qw(
        t/swamp/pipe-stress-freaks.F
    );
    my $regex = '(?i:PIPE)';

    my @files = qw( t/swamp );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex" );
}

FILE_ON_COMMAND_LINE_IS_ALWAYS_SEARCHED: {
    my @expected = ( 't/swamp/#emacs-workfile.pl#' );
    my $regex = 'emacs';

    my @files = ( 't/swamp/#emacs-workfile.pl#' );
    my @args = ( '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'File on command line is always searched' );
}

FILE_ON_COMMAND_LINE_IS_ALWAYS_SEARCHED_EVEN_WITH_WRONG_TYPE: {
    my @expected = qw(
        t/swamp/parrot.pir
    );
    my $regex = 'parrot';

    my @files = qw( t/swamp/parrot.pir );
    my @args = ( '--html', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, 'File on command line is always searched, even with wrong type.' );
}

ONLY_MAKEFILES: {
    my @expected = (
        't/swamp/Makefile:1:# This Makefile is for the ack extension to perl.',
        't/swamp/Makefile:4:# 6.30 (Revision: Revision: 4535 ) from the contents of',
    );
    my $content_regex = 'the';
    my $file_regex = 'Makefile';

    my @files = qw( t/swamp );
    my @args = ( '-G', $file_regex, $content_regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex in files matching $file_regex" );
}

PERL_TEST_CASE_INSENSITIVE_CONTENT: {
    my @expected = qw(
        t/swamp/perl-test.t
    );
    my $content_regex = 'ack';
    my $file_regex = '\.t$';

    my @files = qw( t/swamp );
    my @args = ( '--perl', '-G', $file_regex, '-i', $content_regex, '-l' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex (case insensitive) in files matching $file_regex" );
}

PERL_TEST_CASE_INSENSITIVE_CONTENT_SWAPPED: {
    # order of arguments doesn't change anything
    my @expected = qw(
        t/swamp/perl-test.t
    );
    my $content_regex = 'ack';
    my $file_regex = '\.t$';

    my @files = qw( t/swamp );
    my @args = ( '--perl', '-i', '-G', $file_regex, $content_regex, '-l' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex (case insensitive) in files matching $file_regex" );
}


PERL_TEST_CASE_INSENSITIVE_FILE_NOT: {
    my @expected = qw();
    my $content_regex = 'ack';
    my $file_regex = '\.T$';

    my @files = qw( t/swamp );
    my @args = ( '--perl', '-i', '-G', $file_regex, $content_regex, '-l' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex in files matching $file_regex" );
}

PERL_TEST_CASE_INSENSITIVE_FILE_AND_CONTENT_NOT: {
    my @expected = qw();
    my $content_regex = 'ack';
    my $file_regex = '\.T$';

    my @files = qw( t/swamp );
    my @args = ( '--perl', '-i', '-G', $file_regex, '-i', $content_regex, '-l' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex in files matching $file_regex (both case insensitive)" );
}

ALL_AND_DASH_G_INTERACTION: {
    my @expected = qw(
        t/swamp/file.bar
        t/swamp/file.foo
    );
    my $content_regex = 'file';
    my $file_regex = 'swamp.*[fb][oa][or]';

    my @files = qw( t/swamp );
    my @args = ( '-a', '-G', $file_regex, $content_regex, '-l' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex in all files matching $file_regex" );
}

UNRESTRICTED_AND_DASH_G_INTERACTION: {
    my @expected = (
        't/swamp/#emacs-workfile.pl#',
        't/swamp/options.pl',
        't/swamp/options.pl.bak',
    );
    my $content_regex = 'file';
    my $file_regex = 'swamp[\\\\/][^\\\\/]+\.pl';

    my @files = qw( t/swamp );
    my @args = ( '-u', '-G', $file_regex, $content_regex, '-l' );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex in unrestricted files matching $file_regex" );
}

QUOTEMETA_FILE_NOT: {
    # -Q does nothing for -g regex
    my @expected = qw(
        t/ack-g.t
    );
    my $regex = 'ack-g.t$';

    my @files = qw( t );
    my @args = ( '-Q', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex with quotemeta." );
}

QUOTEMETA_CONTENT: {
    my @expected = qw( t/ack-print0.t );
    my $file_regex = 'print0.t$';
    my $content_regex = '...';

    my @files = qw( t );
    my @args = ( '-l', '-G', $file_regex, '-Q', $content_regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex (quotemeta) in files matching $file_regex." );
}

QUOTEMETA_CONTENT_SWAPPED: {
    my @expected = qw( t/ack-print0.t );
    my $file_regex = 'print0.t$';
    my $content_regex = '...';

    my @files = qw( t );
    my @args = ( '-l', '-Q', $content_regex, '-G', $file_regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $content_regex (quotemeta) in files matching $file_regex - swapped." );
}

WORDS_FILE_NOT: {
    # -w does nothing for -g regex
    my @expected = qw(
        t/text/freedom-of-choice.txt
    );
    my $regex = 'free';

    my @files = qw( t/text/ );
    my @args = ( '-a', '-w', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for $regex with '-w'." );
}

INVERT_MATCH_FILE_NOT: {
    # -v does nothing for -g regex
    my @expected = qw(
        t/text/4th-of-july.txt
        t/text/freedom-of-choice.txt
        t/text/science-of-myth.txt
    );
    my $regex = 'of';

    my @files = qw( t/text/ );
    my @args = ( '-a', '-v', '-g', $regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for filenames NOT matching $regex." );
}

INVERT_MATCH_CONTENT: {
    my @expected = qw(
        t/text/freedom-of-choice.txt
    );
    my $file_regex = 'of';
    my $content_regex = 'are';

    my @files = qw( t/text/ );
    my @args = ( '-a', '-l', '-G', $file_regex, '-v', $content_regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for files without $content_regex in files matching $file_regex" );
}

INVERT_MATCH_CONTENT_SWAPPED: {
    my @expected = qw(
        t/text/freedom-of-choice.txt
    );
    my $file_regex = 'of';
    my $content_regex = 'are';

    my @files = qw( t/text/ );
    my @args = ( '-a', '-l', '-v', $content_regex, '-G', $file_regex );
    my @results = run_ack( @args, @files );

    sets_match( \@results, \@expected, "Looking for files without $content_regex in files matching $file_regex - swapped" );
}

G_WITH_REGEX: {
    # specifying both -g and a regex should result in an error
    my @files = qw( t/text );
    my @args = qw( -g boy --match Sue );

    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );
    isnt( get_rc(), 0, 'Specifying both -g and --match must lead to an error RC' );
    is( scalar @{$stdout}, 0, 'No normal output' );
    is( scalar @{$stderr}, 1, 'One line of stderr output' );
    like( $stderr->[0], qr/\(Sue\)/, 'Error message must contain "(Sue)"' );
}

F_WITH_REGEX: {
    # specifying both -f and a regex should result in an error
    my @files = qw( t/text );
    my @args = qw( -f --match Sue );

    my ($stdout, $stderr) = run_ack_with_stderr( @args, @files );
    isnt( get_rc(), 0, 'Specifying both -f and --match must lead to an error RC' );
    is( scalar @{$stdout}, 0, 'No normal output' );
    is( scalar @{$stderr}, 1, 'One line of stderr output' );
    like( $stderr->[0], qr/\(Sue\)/, 'Error message must contain "(Sue)"' );
}

# all following test cases are written in such a way that have exactly one line
# of output as the result -> $expected as scalar
sub test_option {
    my ($option, $expected, @args) = @_;

    ack_sets_match( \@args, [ $expected ], "Testing option $option: ack @args" );
}

TEST_E: {
    my @test_cases = (
        # $option, $expected, @rest_args_and_files
        [ qw{ -E t/swamp/sample.rake        -E [.]t$     jruby -l t/ } ],     # -E normal
        [ qw{ -E t/swamp/sample.rake        -E sample    jruby -l t/swamp/sample.rake } ], # do not exclude files given as starting point
        [ qw{ -E t/etc/core.2112            -E xxx$      -f    -u t/etc } ],  # -u must find core file but exclude files ending in xxx
        [ qw{ -E t/text/science-of-myth.txt -E [ey].txt$ -f    -a t/text } ], # -a must find text file but exclude files ending in [ey].txt
    );

    test_option(@{$_}) for @test_cases;
}

TEST_E_AND_G: {
    my @test_cases = (
        # $option, $expected, @rest_args_and_files
        [ '-E and -G', qw{ t/pipe.t                   -E swamp   -G pipe jruby -l t/ } ], # -E and -G normal
        [ '-E and -G', qw{ t/pipe.t                   -E swamp   -g pipe          t/ } ], # -E and -g
        [ '-E and -G', qw{ t/swamp/groceries/CVS/meat -E another -g CVS/me -u     t/ } ], # -u must find files in CVS dir but exclude nevertheless
        [ '-E and -G', qw{ t/text/science-of-myth.txt -E up      -g /s     -a     t/text } ], # -a must find text files but exclude nevertheless
    );

    test_option(@{$_}) for @test_cases;
}

