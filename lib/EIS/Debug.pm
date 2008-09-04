#!/usr/bin/perl -w
# $Revision$
# $Date$
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION:  Generic debugging module for packages.
#               It prints messages to STDERR with DEBUG: in front when
#               --debug switch is found in the command line
#               ($DEBUG is greater than 0).
# CONVENTIONS:
#               - functions starting with underscores (_) are local, private to this module
#               - functions starting with c_ at like setters/getters for our configurable
#                 properties
# LICENSE: GPL
#    Teis program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    Teis program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# TODO
# - figure out a way to turn off Debug() from printing when using
#   the non-OO interface (without using globals)
#

=pod

=head1 SYNOPSIS

use EIS::Debug;

my $d = EIS::Debug->new( 'debug' => 1, 'colors' => 1 );

$d->Debug( "sample","foo" );
$d->set_debug_option('debug',0);
$d->Debug("sample3","foo"); # won't print anything

my $status = ( $d->get_debug_option('debug') ) ? "on" : "off";

print "Debug current status is $status";

=cut

package EIS::Debug;

use 5.008000;
use strict;
use warnings;
use Carp qw(carp croak);    # croak dies nicely. carp warns nicely

require Exporter;

our @ISA = qw(Exporter);

# Teis allows declaration       use Foo::Bar ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          Debug set_debug_option get_debug_option debug_option
          )
    ],
    'minimal' => [
        qw(
          Debug set_debug_option
          )
    ]
);
our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT  = qw(Debug);
our $VERSION = '0.03';

# colorize output by default using this color definitions
my $RED   = "\033[1;31m";
my $NORM  = "\033[0;39m";
my $GREEN = "\033[0;32m";
my $BLUE  = "\033[0;34m";

sub new
{
    my $self   = shift;
    my $class  = ref($self) || $self;
    my $object = {@_};
    bless $object, $class;

    $object->_define();    # initialize internal variables

    return $object;
}

sub _define
{
    my $self = shift;
    unless (exists $self->{'debug'})
    {
        $self->{'debug'} = 0;
    }
    unless (exists $self->{'colors'})
    {
        $self->{'colors'} = 1;
    }
}

=pod

=item Debug()

@desc Debug prints strings to STDERR

@param $foo string message

@param $bar string value of message ( prints: $foo = $bar)

@return 1 on success

=cut

sub Debug
{
    my $self = shift;
    my $foo  = shift;
    my $bar  = shift;
    
    return undef if not ref $self or not defined $foo;
    
    if (exists $self->{'debug'} and $self->get_debug_option('debug'))
    {
        if (exists $self->{'colors'} and !$self->get_debug_option('colors'))
        {
            $RED   = "";
            $NORM  = "";
            $GREEN = "";
            $BLUE  = "";
        }

        # Print debugging output
        print STDERR "$RED DEBUG $NORM: $GREEN $foo $NORM";
        print STDERR " = $BLUE" . $bar . "$NORM" if (defined($bar));
        print STDERR "\n";
        return 1;
    }
    return 0;
}

=pod

=item debug_option()

@desc setter/getter for our configuration option 'debug'. 
configuration function to set hash variables or get their current value

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current value

=cut

sub debug_option
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    return undef if (not ref $self or not defined $key);

    $self->{$key} = $value if (defined($value) and $value !~ /^\s*$/);

    # we return the current value of our variable regardless
    # of whether we changed it or not
    return (exists $self->{$key}) ? $self->{$key} : undef;
}

=pod

=item get_debug_option()

@desc convenience function to get the value of a given key

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current value for $key

=cut

sub get_debug_option
{
    my $self = shift;
    my $key  = shift;

    return $self->debug_option($key);
}

=pod

=item set_debug_option()

@desc convenience function to set the value of a given key

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current value for $key

=cut

sub set_debug_option
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    return $self->debug_option($key, $value);
}

=pod

=back

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut

1;
