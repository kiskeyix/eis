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

    #@param 0 string    := question to prompt
    #@param 1 flag      := hidden => 1
    #returns answer
    my $_str  = shift;
    my $_hide = shift || 0;
    my $rep   = "";
    if ($_hide)
    {
        system('stty', '-echo');
    }
    print STDOUT $_str;
    $rep = <STDIN>;
    if ($_hide)
    {
        system('stty', 'echo');
    }
    chomp($rep);
    return $rep;
}

my $obj = EIS::Auth->new('debug' => 0); # set to 1 to show debugging messages
ok(defined $obj, 'obj->new()');

#$obj->{'AppConfig'}->_dump();

is($obj->get_option('ldap_host'),   'ldap',   'ldap_host key');
is($obj->get_option('ldap_port'),   '3268',        'ldap_port key');
is($obj->get_option('ldap_domain'), 'example.com', 'ldap_domain key');
is($obj->get_option('ldap_type'),   'AD',          'ldap_type key');

my $user =
  prompt(  "Please enter your "
         . $obj->get_option('ldap_type')
         . " username for "
         . $obj->get_option('ldap_host')
         . ": ");
my $password = prompt("Please enter your password: ", 1);

ok($obj->connect($user, $password), 'Authentication');
if ($obj->{'ldap_result'})
{
    print "Full name [cn]: " . $obj->{'ldap_result'}->get_value('cn') . "\n";
    print "Mail [mail]: " . $obj->{'ldap_result'}->get_value('mail') . "\n";

    if ($obj->get_option('ldap_type') ne "AD")
    {
        print "User name [uid]: "
          . $obj->{'ldap_result'}->get_value('uid') . "\n";
    }
    else
    {
        print "User name [sAMAccountName]: "
          . $obj->{'ldap_result'}->get_value('sAMAccountName') . "\n";
    }
}
else
{
    print STDERR "Could not find user $user\n";
}

# test connection to LDAP host
