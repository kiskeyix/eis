#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Displays list of software installed on system
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Software;
use strict;
use warnings;
$|++;

use CGI;

use EIS::Tables::Software;
use EIS::Template qw( :all );
use EIS::XML qw( :all );
use EIS::SessionManager qw( :all );

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
        my $tt    = EIS::Template->new();
        my $_cgi  = CGI->new();
        my $_note = "";
        if ($_cgi->param('id') and $_cgi->param('id') > 0)
        {
            my $host =
              EIS::Tables::Software->retrieve(host => $_cgi->param('id'));
            my $xml = EIS::XML->new();
            if (defined $host)
            {
                if ($_cgi->param("raw") and $_cgi->param("raw") > 0)
                {
                    $r->content_type('text/xml');
                    $r->print(
                             $tt->output(
                                 template => 'xml.tt',
                                 'vars' => {'xmlcontent' => $host->xmlcontent()}
                             )
                    );
                }
                else
                {
                    $_note = "Software on host";

                    $r->print(
                              $tt->output(
                                     template => 'software.tt',
                                     'vars'   => {
                                         'host' => $host,
                                         'note' => $_note,
                                         'html' =>
                                           $xml->string_to_html(
                                             $host->xmlcontent(), 'software.xsl'
                                           ),
                                     }
                              )
                             );
                }
            }
            else
            {
                my $_msg = "ID not found in database";
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
                return Apache2::Const::OK;
            }
        }
        else
        {

            # id missing throw error and redirect to whence you came from
            my $_msg = "ID Missing";
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
            return Apache2::Const::OK;
        }
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
