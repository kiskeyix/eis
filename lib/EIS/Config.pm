#!/usr/bin/perl -w
# $Revision: 1.10 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple package that interfaces with AppConfig
# USAGE: see SYNOPSIS
# CONVENTIONS:
#               - functions starting with underscores (_) are local,
#                 private to this module
#               - options are configured with setters/getters
#                 for our configurable properties
# LICENSE: SEE LICENSE FILE

=pod

=head1 NAME

Config.pm - EIS::Config module 

=head1 SYNOPSIS

use EIS::Config;
my $obj = EIS::Config->new('config' => 1, 'debug' => 0);

$obj->get_all_options("hello world");

=head1 DESCRIPTION 

this module ...

=head1 FUNCTIONS

=over 8

=cut

package EIS::Config;

use 5.008000;
use strict;
use warnings;
use Carp qw(carp croak);    # croak dies nicely. carp warns nicely
use AppConfig;

require Exporter;

# inherit functions from these packages:
our @ISA = qw ( Exporter );

# this allows declaration       use Foo::Bar ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          get_all_options
          config_option get_option set_option
          )
    ],
    'minimal' => [
        qw(
            get_option set_option
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
     
     config => "" # optional

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
    unless (exists $self->{'config_file'})
    {
        $self->{'config_file'} =
          '/etc/eis/eis.conf';
    }

    # here we should call _define() from e/a of the classes we imported @ISA
    for my $class (@ISA)
    {
        my $meth = $class . "::_define";
        $self->$meth(@_) if $class->can("_define");
    }

    $self->{'AppConfig'} = AppConfig->new();
    # variables that we allow from our configuration file:
    my @vars = (
        'debug',
        'site_name',
        'domain',
        'template_path',
        'xsl_path',
        'db_name',
        'db_user',
        'db_pw',
        'db_host',
        'db_usesocket',
        'ldap_type',
        'ldap_base',
        'ldap_host',
        'ldap_port',
        'ldap_domain',
        'config_file',
        'eis_collection_dir',
    );
    foreach(@vars)
    {
        $self->{'AppConfig'}->define($_ => {DEFAULT=>'',ARGCOUNT=>1});
    }
    $self->{'AppConfig'}->file($self->{'config_file'});
    $self->set_option('config_file',$self->{'config_file'});
}

=pod

=item config_option()

@desc setter/getter for our configuration option config. configuration function to set hash variables or get their current value

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current value

=cut

sub config_option
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;
    return undef if (not ref $self or not defined $key);

    $self->{'AppConfig'}->set($key,$value) 
        if (defined($value) and $value !~ /^\s*$/);

    # we return the current value of our variable regardless
    # of whether we changed it or not
    return $self->{'AppConfig'}->get($key);
}

=pod

=item get_option()

@desc convenience function to get the value of a given key

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current value for $key

=cut

sub get_option
{
    my $self = shift;
    my $key  = shift;

    return $self->config_option($key);
}

=pod

=item set_option()

@desc convenience function to set the value of a given key

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current value for $key

=cut

sub set_option
{
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    return $self->config_option($key, $value);
}

=pod 

=item get_all_options()

@desc a simple function to print a string

@param $str string to print

@return undef if argument is missing

=cut

sub get_all_options
{
    my $self = shift;
    my $str  = shift;
    return undef if (not ref $self or not defined $str);
    return $str;
}

=pod

=back

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut

1;
