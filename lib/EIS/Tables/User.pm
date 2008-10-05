#!/usr/bin/perl -w
# $Revision: 1.12 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple package that exports ...
# USAGE: see SYNOPSIS
# CONVENTIONS:
#               - functions starting with underscores (_) are local,
#                 private to this module
#               - options are configured with setters/getters
#                 for our configurable properties
# LICENSE: GPL
# NOTES:
#  * The reason behind using "our" for @ISA, %EXPORT_TAGS,
#    and @EXPORT_OK is that it makes things simpler when inheriting
#    methods/variables from base classes. All you need to do really
#    is add the module names to 'our @ISA = qw()' and all the methods
#    exported by that module will be accessible.
#    This creates the problem, then, that if you have 2 classes created
#    by this file with the set_option/get_option (which have the same
#    name), these will be seen by Perl as "redefined" and an error will
#    be croak'd. To fix this glitch simply substitute "our" with "my"
#    to make the scope of those methods local to their own objects.
#

package EIS::Tables::User;
use base 'EIS::DBI';
use strict;

__PACKAGE__->set_up_table("user");
#__PACKAGE__->has_many("session"=>"EIS::Tables::Session");

1;
