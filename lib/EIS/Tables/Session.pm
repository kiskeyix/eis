#!/usr/bin/perl -w
# $Revision: 1.12 $
# Luis Mondesi <lemsx1@gmail.com>
#
# LICENSE: GPL

package EIS::Tables::Session;
use base 'EIS::DBI';
use strict;

__PACKAGE__->set_up_table("session");

1;
