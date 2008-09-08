#!/usr/bin/perl -w
# $Revision: 0.1 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple test script
# Use this to test EIS::DBI.pm API
# USAGE: ./xml.t
# LICENSE: GPL
use strict;
use lib 'lib';
use Test::More qw(no_plan);

use_ok("EIS::Tables::XML");

ok( EIS::Tables::XML->retrieve(1));
ok( EIS::Tables::XML->search('id' => '1'));
my @_rec = EIS::Tables::XML->search('id' => '1');
is($_rec[0], 1, "record is 1");
print "Record output: \n";
print $_rec[0]->xmlcontent();
