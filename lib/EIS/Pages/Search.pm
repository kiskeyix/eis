#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Allows searching for hosts using a more advance form
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Search;
use strict;
use warnings;
$|++;

use CGI;

use EIS::Tables::Host;
use EIS::Tables::Service;
use EIS::Tables::Software;

use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );

use Apache2::RequestRec ();
use Apache2::RequestIO  ();

use Apache2::Const -compile => qw(OK REDIRECT);

sub handler
{
    my $r = shift;
    my $session = EIS::SessionManager->new('_request' => $r);

    $r->content_type('text/html');

    if ($session->is_valid())
    {
        my $tt = EIS::Template->new();
        my @hosts = ();
        my $_cgi  = CGI->new();
        my $_note = "";
        if ($_cgi->param('search') ne "")
        {
            my $_matches = 0;    # simple flag
            $_note = "Search results";
            $r->print(
                      $tt->output(
                                  template => 'header.tt',
                                  'vars'   => {'note' => $_note, 'cgi' => $_cgi}
                                 )
                     );
            @hosts =
              EIS::Tables::Host->search_like(
                                          'hostname' => $_cgi->param('search'));
            if (scalar @hosts > 0)
            {
                $_matches++;
                @hosts = sort { $a->hostname() cmp $b->hostname() } @hosts;
                $r->print(
                        $tt->output(
                            template => 'hosts_list.tt',
                            'vars'   =>
                              {'hosts' => \@hosts, 'note' => "Hostname matches"}
                        )
                );
            }

            # be greedy when matching for Service and Software. We are matching partial
            # strings in a huge XML file:

            @hosts =
              EIS::Tables::Service->search_like(
                            'xmlcontent' => $_cgi->param('search'));
            if (scalar @hosts > 0)
            {
                $_matches++;
                @hosts =
                  sort { $a->host->hostname() cmp $b->host->hostname() } @hosts;
                $r->print(
                          $tt->output(
                                      template => 'hosts_list.tt',
                                      'vars'   => {
                                                'hosts'   => \@hosts,
                                                'service' => 1,
                                                'note' => "Service name matches"
                                      }
                                     )
                         );
            }
            @hosts =
              EIS::Tables::Software->search_like(
                            'xmlcontent' => $_cgi->param('search'));
            if (scalar @hosts > 0)
            {
                $_matches++;

                @hosts = sort { $a->host->hostname() cmp $b->host->hostname() } @hosts;
                $r->print(
                          $tt->output(
                                      template => 'hosts_list.tt',
                                      'vars'   => {
                                               'hosts'    => \@hosts,
                                               'software' => 1,
                                               'note' => "Software name matches"
                                      }
                                     )
                         );
            }
            unless ($_matches)
            {
                $r->print("<h1>No matches</h1><p class='smalltext'>Hint: try searching for: %".$_cgi->param('search')."%</p>\n");

            }
            $r->print(
                      $tt->output(
                                  template => 'footer.tt',
                                  'vars'   => {'note' => $_note}
                                 )
                     );

        }
        else
        {
            my $_msg = "Nothing to search for";
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
