#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Displays information from XML file of hosts
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Info;
use strict;
use warnings;
$|++;

use EIS::Tables::XML;
use EIS::Tables::HostMeta;
use EIS::Tables::Hostbyloc;
use EIS::Tables::Hostbyparent;

use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );
use EIS::XML qw( :all );

use CGI;
use Apache2::RequestRec ();
use Apache2::RequestIO  ();

use Apache2::Const -compile => qw(OK REDIRECT);

sub handler
{
    my $r = shift;
    my $session = EIS::SessionManager->new('_request' => $r);

    if ($session->is_valid())
    {
        my $tt  = EIS::Template->new();
        my $cgi = CGI->new();

        if ($cgi->param('id'))
        {
            my $_id = $cgi->param('id');

            my $parenthost = EIS::Tables::Hostbyparent->retrieve($_id);
            my $location   = EIS::Tables::Hostbyloc->retrieve($_id);
            my $host       = EIS::Tables::XML->retrieve(host => $_id);
            my $hostmeta   = EIS::Tables::HostMeta->retrieve(host => $_id);

            if (defined $host)
            {
                if ($cgi->param('raw') and $cgi->param('raw') > 0)
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
                    my $obj = EIS::XML->new();
                    my $_html_string =
                      $obj->string_to_html($host->xmlcontent(), 'lshw.xsl');
                    if ($hostmeta)
                    {
                        $r->print(
                                  $tt->output(
                                              template => 'info.tt',
                                              'vars'   => {
                                                    'id'       => $_id,
                                                    'host'     => $_html_string,
                                                    'meta'     => $hostmeta,
                                                    'location' => $location,
                                                    'parenthost' => $parenthost,
                                              }
                                             )
                                 );
                    }
                    else
                    {

                        # no metainformation yet
                        $r->print(
                                  $tt->output(
                                              template => 'info.tt',
                                              'vars'   => {
                                                        'id'   => $_id,
                                                        'host' => $_html_string,
                                              }
                                             )
                                 );
                    }
                }
            }
            else
            {
                my $_msg = "XML information not found for ID: " . $_id;
                $r->print(
                          $tt->output(
                                      template => 'status.tt',
                                      'vars'   => {
                                                 'action'   => '/eis/Info',
                                                 'type'     => 'error',
                                                 'redirect' => '10',
                                                 'status'   => $_msg,
                                                }
                                     )
                         );

            }
        }
        else
        {
            my $_msg = "No host requested";
            $r->print(
                      $tt->output(
                                  template => 'status.tt',
                                  'vars'   => {
                                             'action'   => '/eis/Info',
                                             'type'     => 'error',
                                             'redirect' => '10',
                                             'status'   => $_msg,
                                            }
                                 )
                     );
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
