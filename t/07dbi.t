#!/usr/bin/perl -w
# vi: ft=perl :
# $Revision: 1.3 $
# my_name < email@example.com >
#
# DESCRIPTION: A simple test script
# Use this to test EIS::DBI.pm API
# USAGE: ./skeleton.t
# LICENSE: GPL
use strict;
use lib 'lib';
use Test::More qw(no_plan);

use EIS::DBI qw(:all);

my $obj = EIS::DBI->new('config_file' => 'etc/eis/eis.conf');
ok(defined $obj, 'EIS::DBI->new()');

is($obj->get_option('db_user'), 'eisadmin', 'default value for db_user');
#FIXME ok($obj->set_database(),'set_database()');
