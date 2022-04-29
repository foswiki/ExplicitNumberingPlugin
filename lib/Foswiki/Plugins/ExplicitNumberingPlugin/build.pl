#!/usr/bin/env perl
BEGIN { unshift @INC, split( /:/, $ENV{FOSWIKI_LIBS} ); }
use Foswiki::Contrib::Build;

$build = new Foswiki::Contrib::Build('ExplicitNumberingPlugin');
$build->build( $build->{target} );

