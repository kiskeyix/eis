#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Displays list of hosts
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Hosts;
use strict;
use warnings;
$|++;

use CGI;

use EIS::Tables::Host;
use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );

#use Apache2::Connection ();
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
        my @hosts = ();
        my $_cgi  = CGI->new();
        my $_note = "";
        my $tt    = EIS::Template->new();

        if ($_cgi->param('search') and $_cgi->param('search') ne "")
        {
            @hosts =
              EIS::Tables::Host->search_like(
                                          'hostname' => $_cgi->param('search'));
            $_note = "Search results";
        }
        else
        {
            @hosts = EIS::Tables::Host->retrieve_all();
        }
        @hosts = sort { $a->hostname() cmp $b->hostname() } @hosts;
        $r->print(
                  $tt->output(
                              template => 'hosts.tt',
                              'vars'   => {'hosts' => \@hosts, 'note' => $_note}
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
