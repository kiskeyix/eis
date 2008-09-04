#!/usr/bin/perl -w
# $Revision: 1.10 $
# $Date: 2007-05-03 20:37:08 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION:
# USAGE:
# LICENSE: ___

=pod

=head1 NAME

skeleton.pl - skeleton script for Perl

=head1 DESCRIPTION 

    Teis script ...

=cut

use strict;

my $revision = '$Revision: 1.10 $';    # version
$revision =~ s/(\\|Revision:|\s|\$)//g;

# standard Perl modules
use IO::Handle;
STDOUT->autoflush(1);                  # same as: $| = 1;
STDERR->autoflush(1);

use Getopt::Long;
Getopt::Long::Configure('bundling');
use POSIX;                    # cwd() ... man POSIX
use File::Spec::Functions;    # abs2rel() and other dir/filename specific
use File::Copy;
use File::Find;               # find();
use File::Basename;           # basename() && dirname()
use FileHandle;               # for progressbar

#eval "use My::Module";
#if ($@)
#{
#    print STDERR "\nERROR: Could not load the Image::Magick module.\n" .
#    "       To install this module use:\n".
#    "       perl -e shell -MCPAN\n".
#    "       On Debian just: apt-get install perlmagic \n\n".
#    "       FALLING BACK to 'convert'\n\n";
#    print STDERR "$@\n";
#    exit 1;
#}

# Args:
my $PVERSION = 0;
my $HELP     = 0;
my $USAGE    = 0;
my $DEBUG    = 0;
my $FORCE    = 0;

=pod

=head1 SYNOPSIS

B<skeleton.pl>  [-v,--version]
                [-D,--debug] 
                [-h,--help]
                [-U,--usage]

=head1 OPTIONS

=over 8

=item -v,--version

Prints version and exits

=item -D,--debug

Enables debug mode

=item -h,--help

Prints this help and exits

=item -U,--usage

Prints usage information and exits

=back

=cut

# get options
GetOptions(

    # flags
    'v|version' => \$PVERSION,
    'h|help'    => \$HELP,
    'D|debug'   => \$DEBUG,
    'U|usage'   => \$USAGE,
    'f|force'   => \$FORCE,

    # strings
    #'o|option=s'       =>  \$NEW_OPTION,
    # numbers
    #'a|another-option=i'      =>  \$NEW_ANOTHER_OPTION,
);

if ($HELP)
{
    use Pod::Text;
    my $parser = Pod::Text->new(sentence => 0, width => 78);
    $parser->parse_from_file($0, \*STDOUT);
    exit 0;
}

sub _usage
{
    use Pod::Usage;
    pod2usage(1);
}

if ($USAGE)
{
    _usage();
    exit 0;    # never reaches here
}

if ($PVERSION) { print STDOUT ($revision, "\n"); exit 0; }

use lib '/usr/local/lib/site_perl';
use EIS::Setup;

my $obj = EIS::Setup->new();
$obj->setup_db($FORCE);

=pod

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut

