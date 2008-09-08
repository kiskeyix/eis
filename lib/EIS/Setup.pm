#!/usr/bin/perl -w
# $Revision: 1.10 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple package that interfaces with DBI to setup the database
# USAGE: see SYNOPSIS
# CONVENTIONS:
#               - functions starting with underscores (_) are local,
#                 private to this module
#               - options are configured with setters/getters
#                 for our configurable properties
# LICENSE: SEE LICENSE FILE

=pod

=head1 NAME

Setup.pm - EIS::Setup module to setup the database properly

=head1 SYNOPSIS

use EIS::Setup;

my $obj = EIS::Setup->new('debug' => 0);

$obj->setup_db(0);

=head1 DESCRIPTION 

A simple package that interfaces with DBI to setup the database

=head1 FUNCTIONS

=over 8

=cut

package EIS::Setup;

use 5.008000;
use strict;
use warnings;
use Carp qw(carp croak);    # croak dies nicely. carp warns nicely
use DBI;

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
          setup_db
          )
    ],
    'minimal' => [
        qw(
          setup_db
          )
    ]
);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT = qw( );

our $VERSION = '0.02';

# Hash for table creation SQL - keys are the names of the tables,
# values are SQL statements to create the corresponding tables.
my %sql = (
    host => qq{
          CREATE TABLE host (
              id   int(10) unsigned NOT NULL auto_increment,
              hostname  varchar(200) UNIQUE,
              PRIMARY KEY (id)
          )
      },
    hostbyparent => qq{
          CREATE TABLE hostbyparent (
              id int(10) unsigned NOT NULL,                         # references host.id
              hostparentid  int(10) unsigned NOT NULL DEFAULT 0,    # references host.id
              PRIMARY KEY (id)
          )
      },
    hostbyloc => qq{
          CREATE TABLE hostbyloc (
              id int(10) unsigned NOT NULL,                         # references host.id
              locationid  int(10) unsigned NOT NULL DEFAULT 0,      # references location.id
              PRIMARY KEY (id)
          )
      },
    xml => qq{
          CREATE TABLE xml (
              id            int(10) unsigned NOT NULL auto_increment,
              xmlcontent    LONGTEXT,
              host          int(10) unsigned,                       # references host.id
              PRIMARY KEY (id)
          )
      },
    hostmeta => qq{
          CREATE TABLE hostmeta (
              id            int(10) unsigned NOT NULL auto_increment,
              host          int(10) unsigned,                       # references host.id
              ip            VARCHAR(255),
              ipv6          VARCHAR(255),
              description   TEXT,
              owner         VARCHAR(255),
              console       VARCHAR(255),
              application   VARCHAR(255),
              contract      VARCHAR(255),
              expires       VARCHAR(255),
              maintenance   VARCHAR(255),
              businesscontact       VARCHAR(255),
              techcontact   VARCHAR(255),
              vendorcontact VARCHAR(255),
              notes         TEXT,
              PRIMARY KEY (id)
          )
      },
    software => qq{
          CREATE TABLE software (
              id            int(10) unsigned NOT NULL auto_increment,
              xmlcontent    LONGTEXT,
              host          int(10) unsigned,                       # references host.id
              PRIMARY KEY (id)
          )
      },
    service => qq{
          CREATE TABLE service (
              id            int(10) unsigned NOT NULL auto_increment,
              xmlcontent    LONGTEXT,
              host          int(10) unsigned,                       # references host.id
              PRIMARY KEY (id)
          )
      },
    location => qq{
          CREATE TABLE location (
              id   int(10) unsigned NOT NULL auto_increment,
              locname  varchar(200) NOT NULL UNIQUE,
              locdesc  varchar(255) NOT NULL,                       # human-readable explanation
              PRIMARY KEY (id),
              INDEX (locname),
              INDEX (locdesc)
          )
      },
    locbyparent => qq{
          CREATE TABLE locbyparent (
              id int(10) unsigned NOT NULL,                         # references location.id
              locparentid  int(10) unsigned NOT NULL,
              PRIMARY KEY (id)
          )
      },
    eis_log => qq{
          CREATE TABLE eis_log (
              id bigint(12) unsigned NOT NULL auto_increment,
              date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
              log text NOT NULL default '',
              PRIMARY KEY (id)
          )
    },
    user => qq{
          CREATE TABLE user (
              id            int(10) unsigned NOT NULL auto_increment,
              uname         VARCHAR(255),
              PRIMARY KEY (id)
              )
    },
    permission => qq{
          CREATE TABLE permission (
              id            int(10) unsigned NOT NULL auto_increment,
              permname      VARCHAR(255),
              members       LONGTEXT,
              PRIMARY KEY (id)
          )
    },
    session => qq{
          CREATE TABLE session (
              sessid        VARCHAR(255),                           # kept in a cookie
              sessexp       int(15),                                # when we expire in UNIX epoch
              sessdata      TEXT,
              PRIMARY KEY (sessid)
          )
    },
);

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
}

=pod 

=item setup_db()

@desc a simple function to setup the database tables

@return undef if argument is missing

=cut

sub setup_db
{
    my $self        = shift;
    my $force_clear = shift;
    return undef if (not ref $self);

    my $database = $self->get_option('db_name');
    my $user     = $self->get_option('db_user');
    my $password = $self->get_option('db_pw');
    my $host     = $self->get_option('db_host');# or "localhost" ?

    print "Database:\t$database\n";
    print "User:\t\t$user\n";
    print "Password:\t****\n";    #$password;
    print "Host:\t\t$host\n\n";

    my $dsn = "dbi:mysql:$database;host=$host";
    my $dbh =
      DBI->connect($dsn, $user, $password, {RaiseError => 1, AutoCommit => 0});

    #my @tables = $dbh->tables(undef,undef,undef,undef);
    #print "Existing Tables:\n".join("\n",@tables)."\n";

    foreach (keys %sql)
    {
        if ($force_clear > 0)
        { 
            print "Attempting to drop table $_\n";
            my $sth = $dbh->prepare("DROP TABLE IF EXISTS $_");
            $sth->execute();
            $sth->finish();
        }
        print "Creating table $_\n";
        print "$sql{$_}\n";
        my $sth = $dbh->prepare($sql{$_});
        $sth->execute();
        $sth->finish();
    }
    $dbh->disconnect();
}

=pod

=back

=head1 AUTHORS

Luis Mondesi <lemsx1@gmail.com>

=cut

1;
