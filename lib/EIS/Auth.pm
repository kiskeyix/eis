#!/usr/bin/perl -w
# $Revision: 1.10 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple package that authenticates agains Active Directory using Net::LDAP
# USAGE: see SYNOPSIS
# CONVENTIONS:
#               - functions starting with underscores (_) are local,
#                 private to this module
#               - options are configured with setters/getters
#                 for our configurable properties
# LICENSE: SEE LICENSE FILE

=pod

=head1 NAME

Auth.pm - EIS::Auth module 

=head1 SYNOPSIS

use EIS::Auth;
my $obj = EIS::Auth->new('debug' => 0);

$obj->connect($user,$password); # returns 0 if false, N > 0 if true

=head1 DESCRIPTION 

Teis module inherits from EIS::Config. The purpose is to connect to an Active Directory server and validate the account

=head1 FUNCTIONS

=over 8

=cut

package EIS::Auth;

use 5.008000;
use strict;
use warnings;
use Carp qw(carp croak);    # croak dies nicely. carp warns nicely
use Net::LDAP;

use EIS::Tables::User;

require Exporter;
require EIS::Config;

# inherit functions from these packages:
our @ISA = qw( Exporter EIS::Config );

# Teis allows declaration       use Foo::Bar ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          auth_option connect
          )
    ],
    'minimal' => [
        qw(
          connect
          )
    ]
);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT = qw ( );

our $VERSION = '0.02';

=pod

=item new()

@desc allows new objects to be created and blessed. this allows for inheritance

@arg anonymous hash. Possible values:
     
@return blessed object

=cut

sub new
{
    my $self   = shift;
    my $class  = ref($self) || $self;    # works for Objects or class name
    my $object = {@_};                   # remaining args are attributes
    bless $object, $class;

    $object->_define();                  # initialize internal variables

    return $object;
}

=pod

=item _define() [PRIVATE]

@desc internal function to setup our anonymous hash

@arg object/hash with values to initialize private hash with defaults

=cut

sub _define
{
    my $self = shift;

    # here we should call _define() from e/a of the classes we imported @ISA
    for my $class (@ISA)
    {
        my $meth = $class . "::_define";
        $self->$meth(@_) if $class->can("_define");
    }

    unless (exists $self->{'ldap_domain'})
    {
        $self->{'ldap_domain'} = $self->get_option('ldap_domain');
        if (not $self->{'ldap_domain'})
        {
            croak("Active Directory domain missing\n");
        }
    }
}

=pod

=item auth_option()

@desc setter/getter for our configuration option auth. configuration function to set hash variables or get their current value

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current value

=cut

sub auth_option
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    return undef if (not ref $self or not defined $key);

    $self->{'AppConfig'}->set($key, $value)
      if (defined($value) and $value !~ /^\s*$/);

    # we return the current value of our variable regardless
    # of whether we changed it or not
    return $self->{'AppConfig'}->get($key);
}

=pod

@desc search for users in our directory server

@param $ldap Net::LDAP object resulting from bind()

@param $searchString filter to use when search for user. i.e.: mail='foo*'

@param $attrs containers to return when information is found. i.e.: cn, mail, etc...

@param $base base to start our search from: dc=example,dc=com

@return Net::LDAP search structure

=cut

sub search
{
    my ($self, $ldap, $searchString, $attrs, $base) = @_;
    my $_base = $base || $self->get_option('ldap_base');

    # TODO
    # reconnect to LDAP server if missing:
    # $self->connect() or create an anonymous connection

    # if they dont pass an array of attributes...
    # set up something for them
    if (!$attrs) { $attrs = ['cn', 'mail', 'sAMAccountName']; }
    my $result =
      $ldap->search(
                    'base'   => $_base,
                    'scope'  => "sub",
                    'filter' => $searchString,
                    'attrs'  => $attrs
                   );
    return $result;
}

=pod

=item connect()

@desc function to establish a connection to a Active Directory (LDAP) server

@param $user user portion of the authentication string. Teis does not include '@'+ldap_domain. We will get this from from EIS::Config

@param $password plain text password to use

@return true on success. $self->{'ldap_result'} contains information about the user found.

=cut

sub connect
{
    my $self     = shift;
    my $user     = shift;
    my $password = shift;
    return 0
      if (not ref $self or not defined $user or not defined $password);

    my $_domain      = $self->get_option('ldap_domain');
    my $_ldap_server = $self->get_option('ldap_host');
    my $_ldap_port   = $self->get_option('ldap_port') || '389';

    my $ldap = Net::LDAP->new($_ldap_server, 'version' => 3);
    unless ($ldap)
    {
        return 0;
    }
    my $bind_mesg = $ldap->bind(
                                'dn'       => "$user\@$_domain",
                                'password' => $password,
                                'version'  => '3',
                                'port'     => $_ldap_port,
                               );

    if ($bind_mesg and !$bind_mesg->code)
    {

        $self->_insert_user($user);    # helps tracking session

        my $result_search =
          $self->search($ldap, "userPrincipalName=$user\@$_domain");
        if ($result_search->count() >= 1)
        {
            my @entries = $result_search->entries;
            $self->{'ldap_result'} = $entries[0];
        }

        # perhaps we don't want to disconnect here
        $self->_close_ldap($ldap);
        return 1;
    }
    else
    {
        print STDERR $bind_mesg->error;
    }
    $self->_close_ldap($ldap);
    return 0;
}

sub _insert_user
{
    my $self = shift;
    my $user = shift;

    my $uid = EIS::Tables::User->retrieve(uname => $user);

    if (!defined($uid))
    {
        EIS::Tables::User->insert({'uname' => $user});
    }
}

sub _close_ldap
{
    my $self = shift;
    my $ldap = shift;
    return undef if (not ref $self or not defined $ldap);

    $ldap->unbind();
    $ldap->disconnect();
}

=pod

=back

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut

1;
