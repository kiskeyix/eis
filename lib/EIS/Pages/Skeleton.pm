#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Displays list of users
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Users;
use strict;
use warnings;
$|++;

use CGI;

use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );

use EIS::Tables::User;
use EIS::Tables::Permission;

use Apache2::RequestRec ();
use Apache2::RequestIO  ();

use Apache2::Const -compile => qw(OK REDIRECT);

sub handler
{
    my $r       = shift;
    my $session = EIS::SessionManager->new('_request' => $r);

    $r->content_type('text/html');

    if ($session->is_valid())
    {
        my $tt   = EIS::Template->new();
        my $_msg = "No users yet";
        $r->print(
                  $tt->output(
                              template => 'status.tt',
                              'vars'   => {
                                         'action'   => '/eis/Hosts',
                                         'type'     => 'error',
                                         'redirect' => '10',
                                         'status'   => $_msg,
                                        }
                             )
                 );

    }
    else
    {
        $r->content_type('text/html');
        $r->headers_out->{'Location'} = "/eis/Login";
        return Apache2::Const::REDIRECT;
    }

    return Apache2::Const::OK;
}
1;
