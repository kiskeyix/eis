#!/usr/bin/perl -w
# $Revision: 1.10 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple package that interfaces with Template Toolkit 2
# USAGE: see SYNOPSIS
# CONVENTIONS:
#               - functions starting with underscores (_) are local,
#                 private to this module
#               - options are configured with setters/getters
#                 for our configurable properties
# LICENSE: SEE LICENSE FILE

=pod

=head1 NAME

Template.pm - EIS::Template module 

=head1 SYNOPSIS

use EIS::Template;
my $obj = EIS::Template->new('template_path' => '/path/to/template_folder', 'debug' => 0);

my %args = ( template=>'header.tt' );
$obj->output(%args);

=head1 DESCRIPTION 

Teis module ...

=head1 FUNCTIONS

=over 8

=cut

package EIS::Template;

use 5.008000;
use strict;
use warnings;
use Carp qw(carp croak);    # croak dies nicely. carp warns nicely

use Template;
use CGI;

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
          template_option output
          )
    ],
    'minimal' => [
        qw(
          output
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
     
     template => "" # optional

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
    # TODO if template_path is given to us, set the option here
}

=pod

=item template_option()

@desc setter/getter for our configuration option template. configuration function to set hash variables or get their current value

@param $key string key name we are modifying

@param $value string value to assign to $key (optional)

@return current value

=cut

sub template_option
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

=item output()

@desc a simple function to generate output for a given template

@param %args arguments for Template: 'vars'=>[], 'site_name'=>""

@return undef if argument is missing

=cut

sub output
{
    my ($self, %args) = @_;
    return undef if (not ref $self);

    my $template_path = $self->get_option('template_path');

    my $tt = Template->new({'INCLUDE_PATH' => $template_path});
    my $tt_vars = $args{'vars'} || {};

    # sanity checks
    $tt_vars->{'site_name'} = 'site_name'
      if (not exists $tt_vars->{'site_name'});

    my $h      = CGI->new();
    my $header = $h->header();

    my $output;
    $tt->process($args{'template'}, $tt_vars, \$output)
      or croak($tt->error());
    return $header . $output;
}

=pod

=back

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut

1;
