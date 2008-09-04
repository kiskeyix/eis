#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Handles all HTML content
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Login;
use strict;
use warnings;
$|++;

use EIS::Template qw( :all );
use EIS::Auth qw( :all );
use EIS::SessionManager qw( :all );
use EIS::Tables::Log;

use CGI;
use Apache2::Connection ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();

use Apache2::Const -compile => qw(OK REDIRECT);

sub handler
{
    my $r       = shift;
    my $session = EIS::SessionManager->new('_request' => $r);
    my $cgi     = CGI->new();

    my $expiration = 900;

    if ($cgi->param())
    {

        # handle auth form

        my $username = $cgi->param('username');
        my $password = $cgi->param('password');

        $expiration = $cgi->param('expire');

        # sanity check
        $expiration =~ s/[^0-9]//g;
        $expiration = 900
          if (   not defined $expiration
              or not $expiration
              or $expiration > 31536000);    # 365*24*60*60 seconds in a year
        EIS::Tables::Log->insert({'log' => "Attempting to login as $username"});

        my $obj = EIS::Auth->new();
        $obj->connect($username, $password);
        if (exists $obj->{'ldap_result'} and $obj->{'ldap_result'})
        {
            my %_sessdata = (
                           'username' => $username,
                           'fullname' => $obj->{'ldap_result'}->get_value('cn'),
                           'email' => $obj->{'ldap_result'}->get_value('mail')
            );

            #             print "User name [sAMAccountName]: "
            #               . $obj->{'ldap_result'}->get_value('sAMAccountName') . "\n";
            $session->set_expiration(time() + $expiration);
            $session->save_session(\%_sessdata);

            EIS::Tables::Log->insert(
                                     {
                                          'log' => "Session for $username ("
                                        . $r->connection->remote_ip()
                                        . ") is ready"
                                     }
                                    );
        }
        else
        {
            my $_msg = "Could not find user $username\n";
            print STDERR $_msg;
            EIS::Tables::Log->insert({'log' => $_msg});
        }
    }

    $session->set_cookie($r, $expiration);
    $r->content_type('text/html');

    # are we authorized already? go to the requested object
    # else print login form
    if ($session->is_valid())
    {

        # TODO use pnotes() to redirect to a better place
        $r->headers_out->{'Location'} =
          ($r->pnotes('redirect')) ? $r->pnotes('redirect') : '/eis/Hosts';
        return Apache2::Const::REDIRECT;
    }
    else
    {
        EIS::Tables::Log->insert(
                                 {
                                      'log' => "User with IP "
                                    . $r->connection->remote_ip()
                                    . " failed to login"
                                 }
                                );
        my $tt = EIS::Template->new();
        $r->print($tt->output(template => 'login.tt', vars => {foo => 'test'}));
    }

    return Apache2::Const::OK;
}
1;
