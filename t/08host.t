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

use_ok("EIS::Tables::Host");

my $id = EIS::Tables::Host->search('hostname'=>"foo");
is($id,"0","Fake ID");

# my @hosts = $obj->retrieve_all();
# print "Host list: \n";
# foreach (@hosts)
# {
#     print "ID: ".$_->id()."\n";
#     print("Hostname: ".$_->hostname()."\n");
# }
