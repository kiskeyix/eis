#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Displays last N lines from logs table
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Logs;
use strict;
use warnings;
$|++;

use CGI;

use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );

use EIS::Tables::Log;

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
        my $_msg = "Last 100 lines in the log file";
        my @lines = EIS::Tables::Log->retrieve_from_sql(
            qq{
	   1 = 1 ORDER BY date DESC LIMIT 100
	 }
        );

        #EIS::Tables::Log->retrieve_all();
        # refresh every 60 seconds
        $r->print(
                  $tt->output(
                              template => 'logs.tt',
                              'vars'   => {
                                         'lines'    => \@lines,
                                         'note'     => $_msg,
                                         'action'   => '/eis/Logs',
                                         'redirect' => '60',
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
