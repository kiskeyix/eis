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

use_ok("EIS::SessionManager");

my @_tests_ids = ('TEST0', 'TEST1');    #, 'TEST2', 'TEST3');

foreach (@_tests_ids)
{
    my $_session = EIS::SessionManager->new('_session_id' => $_);

    is($_session->get_session_id(), $_, 'get_session_id');
    ok($_session->set_expiration(time() + 10), 'set_expiration');
    ok($_session->is_valid(),                  'is_valid');
    ok($_session->destroy_session(),           'destroy_session');
}

# test auto-generated IDs and some functions
my $_sess = EIS::SessionManager->new();

isnt($_sess->_generate_id(), 'SIMPLE', '_generate_id');
isnt($_sess->_gen_salt(),    'SIMPLE', '_gen_salt');
ok($_sess->destroy_session(), 'destroy_session');
