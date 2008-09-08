#!/usr/bin/perl -w
# $Revision: 0.1 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple test script
# Use this to test EIS::DBI.pm API
# USAGE: ./dbi.t
# LICENSE: GPL
use strict;
use lib 'lib';
use Test::More qw(no_plan);

use EIS::DBI qw(:all);

my $obj = EIS::DBI->new('config_file' => '../etc/eis/eis.conf');
ok(defined $obj, 'EIS::DBI->new()');

is($obj->get_option('db_user'), 'eisadmin', 'default value for db_user');
