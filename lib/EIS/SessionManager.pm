# Luis Mondesi <lemsx1@gmail.com>
# 2007-07-12 12:58 EDT
#
# simple session manager
package EIS::SessionManager;

use 5.008000;
use strict;
use warnings;
use Carp qw(carp croak);    # croak dies nicely. carp warns nicely
use CGI::Cookie ();
use Digest::MD5 qw( md5_base64 );

use EIS::Tables::Session;
use Data::Dumper qw(Dumper);    # to serialize variables in $sessiondata

#use Apache2::Const -compile => "OK";

require Exporter;

# inherit functions from these packages:
our @ISA = qw( Exporter );

# This allows declaration       use Foo::Bar ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
          set_cookie is_valid set_expiration get_session_id destroy_session
          save_session load_session
          )
    ],
    'minimal' => [
        qw(
          set_cookie is_valid save_session load_session
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
     
     _request => $r # required. This is the Apache (mod_perl2) request object
     _session_id => string # optional. This will be retrieved from a cookie or generated if not found

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

sub _define
{
    my $self = shift;
    unless (exists $self->{'_session_id'})
    {
        $self->{'_session_id'} = $self->get_session_id();
    }

    # make sure that our ID exists in the db:
    my $_sess = EIS::Tables::Session->retrieve($self->{'_session_id'});
    if (not defined $_sess)
    {
        EIS::Tables::Session->insert(
                                     {
                                      sessid  => $self->{'_session_id'},
                                      sessexp => 0
                                     }
                                    );
    }

    # here we should call _define() from e/a of the classes we imported @ISA
    for my $class (@ISA)
    {
        my $meth = $class . "::_define";
        $self->$meth(@_) if $class->can("_define");
    }
}

sub _generate_id
{
    my $self = shift;

    my $salt = "";

    # an ID is randomly generated
    if (open(RAND, "</dev/urandom"))
    {
        read(RAND, $salt, 32);
        close(RAND);
    }
    else
    {
        warn("Could not open random interface /dev/urandom. $!\n");
        $salt = $self->_gen_salt(32);
    }
    return md5_base64(time(), $salt);
}

sub _gen_salt
{
    my $self  = shift;
    my $count = shift;
    $count = 32 if (not defined $count);
    my @salt = ('.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z');
    my $_salt = undef;
    for (1 .. $count)
    {
        $_salt .= (@salt)[rand(@salt)];
    }
    return $_salt;
}

sub set_cookie
{
    my $self = shift;
    my $r    = shift;
    my $exp  = shift;
    $r = $self->{'_request'} if (not defined $r or not ref $r);
    return 0 if (not defined $r or not ref $r);

    if (not defined($exp))
    {
        $exp = 900;    # 15 minutes by default
    }
    else
    {
        $exp =~ s/[^0-9]//g;
    }

    # check that exp is not blank or greater than our limit (a year)
    $exp = 900 if ($exp !~ /^[0-9]+$/ or $exp > 31536000);

    my $cookie =
      CGI::Cookie->new(
                       -name    => 'eis_session',
                       -value   => $self->{'_session_id'},
                       -expires => "+${exp}s",
                      );

    $r->err_headers_out->add('Set-Cookie' => $cookie);

    return 1;
}

sub get_session_id
{
    my $self = shift;

    # our Session ID is the one set in the Cookie
    # we return $self->{'_session_id'} for testing purposes

    # sanity check:
    $self->{'_session_id'} = $self->_generate_id()
      if (not exists $self->{'_session_id'});

    my %cookies =
      (exists $self->{'_request'})
      ? CGI::Cookie->fetch($self->{'_request'})
      : ('eis_session' => 'SIMPLE');
    $self->{'_session_id'} = $cookies{'eis_session'}->value()
      if (exists $cookies{'eis_session'} and ref $cookies{'eis_session'});

    return $self->{'_session_id'};
}

sub is_valid
{
    my $self  = shift;
    my $_sess = EIS::Tables::Session->retrieve($self->get_session_id());

    if (defined $_sess)
    {
        return (time() <= $_sess->sessexp()) ? 1 : 0;
    }
    return 0;
}

sub set_expiration
{
    my $self  = shift;
    my $epoch = shift;
    $epoch = time() if (not defined $epoch);

    my $_sess = EIS::Tables::Session->retrieve($self->get_session_id());
    if (defined $_sess)
    {
        $_sess->sessexp($epoch);
        $_sess->update();
    }
    else
    {
        EIS::Tables::Session->insert(
                                     {
                                      sessid  => $self->get_session_id(),
                                      sessexp => $epoch
                                     }
                                    );
    }
}

sub destroy_session
{
    my $self = shift;
    return 0 if (not ref $self);
    my $_sess = EIS::Tables::Session->retrieve($self->get_session_id());

    if (defined $_sess)
    {
        $_sess->delete();
        return 1;
    }
    return 0;
}

# serializes variables in hashref $sessiondata
sub save_session
{
    my $self = shift;
    my $ref  = shift;
    return 0 if (not defined $ref or not ref $ref);

    my $dd = Data::Dumper->new([$ref], [qw(sessiondata)]);

    my $_sess = EIS::Tables::Session->retrieve($self->get_session_id());
    if (defined $_sess)
    {
        $_sess->sessdata($dd->Dump());
        $_sess->update();
    }
    else
    {
        EIS::Tables::Session->insert(
                                     {
                                      sessid   => $self->get_session_id(),
                                      sessdata => $dd->Dump()
                                     }
                                    );
    }
    return 1;
}

# returns session data for record
sub load_session
{
    my $self = shift;

    my $sessiondata;

    my $_sess = EIS::Tables::Session->retrieve($self->get_session_id());
    if (defined $_sess)
    {
        eval $_sess->sessdata();
    }
    return $sessiondata;
}

1;
