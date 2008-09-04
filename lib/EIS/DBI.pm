#!/usr/bin/perl -w
# $Revision: 1.10 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple package that interfaces with DBI::Class::mysql
# USAGE: see SYNOPSIS
# CONVENTIONS:
#               - functions starting with underscores (_) are local,
#                 private to this module
#               - options are configured with setters/getters
#                 for our configurable properties
# LICENSE: SEE LICENSE FILE

=pod

=head1 NAME

DBI.pm - Interface to DBI::Class::mysql

=head1 SYNOPSIS

use EIS::DBI;
my $obj = EIS::DBI->new('debug' => 0);
$obj->set_database();

=head1 DESCRIPTION 

A simple package that interfaces with DBI::Class::mysql

=head1 FUNCTIONS

=over 8

=cut

package EIS::DBI;

use 5.008000;
use strict;
use warnings;
use Carp qw(carp croak);    # croak dies nicely. carp warns nicely

require EIS::Debug;
require EIS::Config;

use base "Class::DBI::mysql";

# inherit functions from these packages:
our @ISA = qw( Exporter Class::DBI::mysql EIS::Config EIS::Debug );

# Teis allows declaration       use Foo::Bar ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          set_database
          )
    ],
    'minimal' => [
        qw(
          )
    ]
);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});
our @EXPORT    = qw( );
our $VERSION   = '0.02';

sub new
{
    my $self   = shift;
    my $class  = ref($self) || $self;    # works for Objects or class name
    my $object = {@_};                   # remaining args are attributes
    bless $object, $class;

    $object->_define();                  # initialize internal variables

    return $object;
}

sub _define
{
    my $self = shift;

    # here we should call _define() from e/a of the classes we imported @ISA
    for my $class (@ISA)
    {
        my $meth = $class . "::_define";
        $self->$meth(@_) if $class->can("_define");
    }
}

my $config = EIS::Config->new('config_file' => "/etc/eis/eis.conf");

# FIXME get user/pass from config file. See set_database
__PACKAGE__->set_db("Main",
                    "dbi:mysql:" . $config->get_option("db_name"),
                    $config->get_option("db_user"),
                    $config->get_option("db_pw"));

#sub set_database
#{
#    my $self = shift;
#
#    __PACKAGE__->set_db(
#        "Main",
#        "dbi:mysql:".$self->get_option("db_name"),
#        $self->get_option("db_user"),
#        $self->get_option("db_pw")
#    );
#}

=pod

=back

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut

1;
