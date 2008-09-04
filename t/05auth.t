#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple test script
# Use this to test Config.pm API
# USAGE: ./config.t
# LICENSE: GPL
use strict;

use lib 'lib';
use Test::More qw(no_plan);

use EIS::Auth qw(:all);

sub prompt
{

    #@param 0 string := question to prompt
    #returns answer
    print STDOUT "@_";
    my $rep = <STDIN>;
    chomp($rep);
    return $rep;
}

my $obj = EIS::Auth->new();
ok(defined $obj, 'obj->new()');

#$obj->{'AppConfig'}->_dump();

# TODO prompt for this values?
is($obj->get_option('ldap_host'), '127.0.0.1', 'ldap_host key');
is($obj->get_option('ldap_port'), '3268',          'ldap_port key');
is($obj->get_option('ldap_domain'), 'example.com',
    'ldap_domain key');

my $user     = prompt("Please enter your Active Directory username for ".$obj->get_option('ldap_host').": ");
my $password = prompt("Please enter your password: ");

ok($obj->connect($user, $password), 'Authentication');
if ($obj->{'ldap_result'})
{
    print "Full name [cn]: ".$obj->{'ldap_result'}->get_value('cn')."\n";
    print "Mail [mail]: ".$obj->{'ldap_result'}->get_value('mail')."\n";
    # TODO configurable uid/sAMaccountName field?
    print "User name [sAMAccountName]: ".$obj->{'ldap_result'}->get_value('sAMAccountName')."\n";
} else {
    print STDERR "Could not find user $user\n";
}

# test connection to LDAP host
