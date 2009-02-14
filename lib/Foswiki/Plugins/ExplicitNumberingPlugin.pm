# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2000-2003 Andrea Sterbini, a.sterbini@flashnet.it
# Copyright (C) 2001-2003 Peter Thoeny, peter@thoeny.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html
#
# =========================
#

# =========================
package Foswiki::Plugins::ExplicitNumberingPlugin;

# =========================
use vars qw(
  $web $topic $user $installWeb 
  $debug
);

use strict;
use warnings;

our $NO_PREFS_IN_TOPIC = 1;

# This should always be $Rev$ so that Foswiki can determine the checked-in
# status of the plugin. It is used by the build automation tools, so
# you should leave it alone.
our $VERSION = '$Rev$';

# This is a free-form string you can use to "name" your own plugin version.
# It is *not* used by the build automation tools, but is reported as part
# of the version number in PLUGINDESCRIPTIONS.
our $RELEASE = 'Foswiki 1.0';

# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
our $SHORTDESCRIPTION =
'Use the ==#<nop>#.,== ==#<nop>#..== etc. notation to insert outline numbering sequences (1, 1.1, 2, 2.1) in topic\'s text. Also support numbered headings.';

my $maxLevels = 6;    # Maximum number of levels
my %Sequences;        # Numberings, addressed by the numbering name
my $lastLevel = $maxLevels - 1;    # Makes the code more readable
my @alphabet  = (
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
);

# =========================
sub initPlugin {
    ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    $debug = Foswiki::Func::getPreferencesFlag("EXPLICITNUMBERINGPLUGIN_DEBUG");

    # Plugin correctly initialized
    ##Foswiki::Func::writeDebug( "- Foswiki::Plugins::${pluginName}::initPlugin( $web.$topic ) is OK" ) if $debug;

    return 1;
}

# =========================
# Need to move =makeExplicitNumber= into =commonTagsHandler= to support
# auto-numbering of heading levels, otherwise the TOC lines will have
# different number than the heading line (must be done before TOC).

sub preRenderingHandler {    # SMELL:  This breaks numbered headings!
#sub commonTagsHandler {
### my ( $text ) = @_;   # do not uncomment, use $_[0] instead

    ##Foswiki::Func::writeDebug( "- ${pluginName}::commonTagsHandler( $web.$topic )" ) if $debug;

    %Sequences = ();

    $_[0] =~ s/(^---+\+*)(\#+)([0-9]*)/$1.&makeHeading(length($2), $3)/gem;
    $_[0] =~
s/\#\#(\w+\#)?([0-9]+)?\.(\.*)([a-zA-Z]?)/&makeExplicitNumber($1,$2,length($3),$4)/ge;
}

# =========================

sub makeHeading {
    my ( $level, $init ) = @_;

    $init = '' unless defined $init;

    my $result   = '';
    my $numlevel = '';
    for ( my $i = 0 ; $i < $level ; $i++ ) {
        $result   .= '+';
        $numlevel .= '.';
    }

    return $result . '##' . $init . $numlevel . ' ';
}

# Build the explicit outline number
sub makeExplicitNumber {
    my ( $name, $init, $level, $alist ) = @_;

    ##Foswiki::Func::writeDebug( "- ${pluginName}::makeExplicitNumber( $_[0], $_[1], $_[2], $_[3] )" ) if $debug;

    $name  = '-default-' unless defined $name;
    $alist = ''          unless defined $alist;
    $level++ if $alist ne '';

    #...Truncate the level count to maximum allowed
    if ( $level > $lastLevel ) { $level = $lastLevel; }

    #...Initialize a new, or get the current, numbering from the Sequences
    my @Numbering = ();
    if ( !defined( $Sequences{$name} ) ) {
        for my $i ( 0 .. $lastLevel ) { $Numbering[$i] = 0; }
    }
    else {
        @Numbering = @{ $Sequences{$name} };

        #...Re-initialize the sequence
    }

    if ( defined $init ) {
        $init = ( int $init );
        $Numbering[$level] = $init - 1;
    }

    #...Increase current level number
    $Numbering[$level] += 1;

    #...Reset all higher level counts
    if ( $level < $lastLevel ) {
        for my $i ( ( $level + 1 ) .. $lastLevel ) { $Numbering[$i] = 0; }

    }

    #...Save the altered numbering
    $Sequences{$name} = \@Numbering;

    #...Construct the number
    my $text = '';
    if ( $alist eq '' ) {
        for my $i ( 0 .. $level ) {
            $text .= "$Numbering[$i]";
            $text .= '.' if ( $i < $level );
        }
    }
    else {

        #...Level is 1-origin, indexing is 0-origin
        if ( $alist =~ /[A-Z]/ ) {
            $text .= uc $alphabet[ $Numbering[$level] - 1 ];
        }
        else {
            $text .= $alphabet[ $Numbering[$level] - 1 ];
        }
    }

    return $text;
}

# =========================

1;
