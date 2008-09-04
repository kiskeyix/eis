#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Handles all HTML content
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Logout;
use strict;
use warnings;
$|++;

use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );
use EIS::Tables::Log;

use Apache2::Connection ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();

use Apache2::Const -compile => qw(OK REDIRECT);

sub handler
{
    my $r = shift;

    my $session = EIS::SessionManager->new();

    $session->set_cookie($r, 'now');    # expire cookie
    $session->destroy_session();        # remove session from db

    $r->content_type('text/html');      # redirect to Login (main) page
    $r->headers_out->{'Location'} = '/eis/';

    EIS::Tables::Log->insert(
         {
          'log' => "User with IP " . $r->connection->remote_ip() . " logged out"
         }
    );

    return Apache2::Const::REDIRECT;
}
1;
