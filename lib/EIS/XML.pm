#!/usr/bin/perl -w
# $Revision: 1.10 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple package that parses the XML files
# it uses XSLT to convert them to HTML
# USAGE: see SYNOPSIS
# CONVENTIONS:
#               - functions starting with underscores (_) are local,
#                 private to this module
#               - options are configured with setters/getters
#                 for our configurable properties
# LICENSE: SEE LICENSE FILE

=pod

=head1 NAME

XML.pm - EIS::XML module to manipulate XML files

=head1 SYNOPSIS

use EIS::XML;

my $obj = EIS::XML->new('debug' => 0);

$obj->get_all_options("hello world");

=head1 DESCRIPTION 

A simple package that parses the XML files from 'lshw -xml' or others and uses XSLT files to convert the XML files into other formats

=head1 FUNCTIONS

=over 8

=cut

package EIS::XML;

use 5.008000;
use strict;
use warnings;
use Carp qw(carp croak);    # croak dies nicely. carp warns nicely

require Exporter;
require EIS::Config;
require EIS::Debug;

eval "use XML::LibXML";
if ($@)
{
    croak(  "\nERROR: Could not load the XML::LibXML module.\n"
          . "       To install this module use:\n"
          . "       perl -e shell -MCPAN\n"
          . "       install XML::LibXML\n\n"
          . "       On Debian just: apt-get install libxml-libxml-perl\n"
          . "       On RedHat/Fedora: yum install libxml-perl\n\n"
          . "       Bailing out!\n\n");
    exit 1;    # never reaches this
}

eval "use XML::LibXSLT";
if ($@)
{
    croak(  "\nERROR: Could not load the XML::LibXML module.\n"
          . "       To install this module use:\n"
          . "       perl -e shell -MCPAN\n"
          . "       install XML::LibXML\n\n"
          . "       On Debian just: apt-get install libxml-libxslt-perl\n"
          . "       On RedHat/Fedora: yum install libxml-perl\n\n"
          . "       Bailing out!\n\n");
    exit 1;    # never reaches this
}

# inherit functions from these packages:
our @ISA = qw( Exporter EIS::Config EIS::Debug );

# Teis allows declaration       use Foo::Bar ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          eis_option
          get_key
          file_to_html
          string_to_html
          dump
          )
    ],
    'minimal' => [
        qw(
          dump
          )
    ]
);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT = qw( );

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

    #     unless (exists $self->{'xml_file'})
    #     {
    #         carp("XML File missing\n");
    #     }

    unless (exists $self->{'config_file'})
    {
        $self->{'config_file'} = '/etc/eis/eis.conf';
    }

    # here we should call _define() from e/a of the classes we imported @ISA
    for my $class (@ISA)
    {
        my $meth = $class . "::_define";
        $self->$meth(@_) if $class->can("_define");
    }
}

=pod

=item lshw_option()

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

    $self->{'AppConfig'}->set($key, $value)
      if (defined($value) and $value !~ /^\s*$/);

    # we return the current value of our variable regardless
    # of whether we changed it or not
    return $self->{'AppConfig'}->get($key);
}

=pod

=item get_key()

@desc method for parsing an XML config file and extracting a given key

@arg $element string to search for in the hash

@arg $single boolean whether we should return a single string or a arrayref

@returns hashref $_{$1}{(name|type|path|desc)}

=cut

sub get_key
{
    my $self    = shift;
    my $element = shift;
    my $single  = shift;
    my %ret;
    return undef if (not defined($element) or $element =~ /^$/);
    croak("No XML file found. Value '$self->{'xml_file'}'\n")
      if (not exists($self->{'xml_file'}) or not -r $self->{'xml_file'});

    $self->Debug("EIS::XML::get_key", "$element");
    my $parser = XML::LibXML->new();
    my $tree   = undef;
    eval { $tree = $parser->parse_file($self->{'xml_file'}) };
    if ($@)
    {
        croak("Could not parse file " . $self->{'xml_file'});
    }

    my $root  = $tree->getDocumentElement;
    my @nodes = $root->findnodes($element);

    if (!defined($nodes[0]))
    {
        $self->Debug(
            "There is no key $element in configuration file $self->{'xml_file'} \n"
        );
        return undef;
    }

    if ($single)
    {
        $self->Debug("EIS::XML::get_key single value");

        my $id    = $nodes[0]->getAttribute('id')    || "";
        my $name  = $nodes[0]->getAttribute('name')  || "";
        my $type  = $nodes[0]->getAttribute('type')  || "";
        my $value = $nodes[0]->getAttribute('value') || "";
        my $text  = $nodes[0]->textContent()         || "";

        $ret{$element}{'id'}    = $id;
        $ret{$element}{'name'}  = $name;
        $ret{$element}{'type'}  = $type;
        $ret{$element}{'value'} = $value;
        $ret{$element}{'text'}  = $text;

        $self->Debug($element, "$id - $name - $type - $value: $text");

    }
    else
    {
        $self->Debug("EIS::XML::get_key multi value");

        my $i = 0;
        foreach my $node (@nodes)
        {
            my $id    = $node->getAttribute('id')    || "";
            my $name  = $node->getAttribute('name')  || "";
            my $type  = $node->getAttribute('type')  || "";
            my $value = $node->getAttribute('value') || "";
            my $text  = $node->textContent()         || "";

            $ret{"$element$i"}{'id'}    = $id;
            $ret{"$element$i"}{'name'}  = $name;
            $ret{"$element$i"}{'type'}  = $type;
            $ret{"$element$i"}{'value'} = $value;
            $ret{"$element$i"}{'text'}  = $text;

            $self->Debug("$element$i", "$id - $name - $type - $value: $text");
            $i++;
        }
    }
    $self->Debug("EIS::XML::get_key() ends");
    return \%ret;
}

=pod

=item file_to_html()

@desc method for parsing an XML file and returning HTML

@arg $xml_file file to parse

@returns HTML output

=cut

sub file_to_html
{
    my $self     = shift;
    my $xml_file = shift;    # FIXME or $self->{'xml_file'};
    my $xsl_file = shift;
    return undef if (not defined $xml_file or not -r $xml_file);
    return undef if (not defined $xsl_file);

    # TODO use catfile()
    my $xslt_file = $self->get_option('xsl_path') . "/" . $xsl_file;
    return undef if (not -r $xslt_file);

    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();

    my $source = undef;
    eval { $source = $parser->parse_file($xml_file) };
    if ($@)
    {
        croak("Could not parse file " . $xml_file);
    }

    my $style_doc = undef;
    eval { $style_doc = $parser->parse_file($xslt_file) };
    if ($@)
    {
        croak("Could not parse stylesheet file " . $xslt_file);
    }

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    # TODO should we eval{} here as well?
    my $results = $stylesheet->transform($source);

    return $stylesheet->output_string($results);
}

=pod

=item string_to_html()

@desc method for parsing an XML string and returning HTML

@arg $xml_string XML string to parse

@returns HTML output

=cut

sub string_to_html
{
    my $self       = shift;
    my $xml_string = shift;
    my $xsl_file   = shift;
    return undef if (not defined $xml_string or not defined $xsl_file);

    # TODO use catfile()
    my $xslt_file = $self->get_option('xsl_path') . "/" . $xsl_file;

    my $parser = XML::LibXML->new();
    my $xslt   = XML::LibXSLT->new();

    my $source    = $parser->parse_string($xml_string);
    my $style_doc = $parser->parse_file($xslt_file);

    my $stylesheet = $xslt->parse_stylesheet($style_doc);

    my $results = $stylesheet->transform($source);

    return $stylesheet->output_string($results);
}

=pod

=item dump()

prints to STDOUT all the variables parsed from XML file

=cut

sub dump
{
    my $self = shift;

    use Data::Dumper;
    print STDOUT Dumper($self->get_key('/'));
}

=pod

=back

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut

1;
