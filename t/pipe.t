#!perl

use warnings;
use strict;

use Test::More tests => 3;
use File::Next ();

use lib 't';
use Util;

prep_environment();

# this tests the behavior of ack when piped into

NORMAL: {
    my $expected = '1';
    my $file = "t/swamp/sample.rake";
    my @args = qw( jruby --count );
    my @results = pipe_into_ack( $file, @args );

    lists_match( \@results, [$expected], 'normal case: output matches' );
}

EXPLICIT_FILTER: {
    my $expected = '1';

    my $file = "t/swamp/sample.rake";
    # explicitly giving the --filter option doesn't change the result
    my @args = qw( jruby --count --filter);
    my @results = pipe_into_ack( $file, @args );

    lists_match( \@results, [$expected], 'with explict --filter: output matches' );
}

EXPLICIT_NOFILTER: {
    my $expected = File::Next::reslash( 't/swamp/sample.rake:1' );

    my $file = "t/swamp/sample.rake";
    # explicitly giving the --nofilter option leads to different result. We
    # need the -l option as well, as we'd get lots of 0 count output otherwise.
    # Furthermore, restrict to t/swamp as otherwise we'd also get matches in
    # this file.
    my @args = qw( jruby --count -l --nofilter t/swamp);
    my @results = pipe_into_ack( $file, @args );

    lists_match( \@results, [$expected], 'with explict --nofilter: output matches' );
}
