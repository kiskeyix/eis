#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: delete locations after confirmation dialog
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::DeleteLocation;
use strict;
use warnings;
$|++;

use EIS::Tables::Location;
use EIS::Tables::Locbyparent;
use EIS::Tables::Hostbyloc;
use EIS::Tables::Log;

use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );

use CGI;
use Apache2::Connection ();
use Apache2::RequestRec ();
use Apache2::RequestIO  ();

use Apache2::Const -compile => qw(OK REDIRECT);

sub handler
{
    my $r       = shift;
    my $session = EIS::SessionManager->new('_request' => $r);

    if ($session->is_valid())
    {
        my $tt           = EIS::Template->new();
        my $cgi          = CGI->new();
        my $_id          = undef;
        my @alllocations = ();
        @alllocations = EIS::Tables::Location->retrieve_all();

        # all of the things we can handle require an ID field
        if ($cgi->param('id'))
        {
            $_id = $cgi->param('id');
            my $loc = EIS::Tables::Location->retrieve($_id);

            if ($cgi->param('confirm'))
            {
                if ($cgi->param('confirm') eq 'Yes')
                {

                    # delete location
                    if (defined($loc))
                    {

                        $loc->delete();
                    }

                    # delete our own parent relationship
                    my $locparent = EIS::Tables::Locbyparent->retrieve($_id);
                    if (defined($locparent))
                    {
                        $locparent->delete();
                    }

                    #lastly, delete all possible children references that we might have:
                    EIS::Tables::Locbyparent->search('locparentid' => $_id)
                      ->delete_all();

                    EIS::Tables::Hostbyloc->search('locationid' => $_id)
                      ->delete_all();

                    my $_msg = "Location delete successfully!";
                    $r->print(
                              $tt->output(
                                          template => 'status.tt',
                                          'vars'   => {
                                                   'action' => '/eis/Locations',
                                                   'type'   => 'success',
                                                   'redirect' => '2',
                                                   'status'   => $_msg,
                                          }
                                         )
                             );
                    my $_sessdata = $session->load_session();

                    {
                        no warnings;
                        EIS::Tables::Log->insert(
                                         {
                                              log => 'User '
                                            . $_sessdata->{'fullname'} . ' ('
                                            . $_sessdata->{'username'}
                                            . ') deleted location id '
                                            . $_id
                                            . ' from IP '
                                            . $r->connection->remote_ip()
                                         }
                        );
                    }
                }
                else
                {
                    my $_msg = "Delete aborted";
                    $r->print(
                              $tt->output(
                                          template => 'status.tt',
                                          'vars'   => {
                                                   'action' => '/eis/Locations',
                                                   'type'   => 'error',
                                                   'redirect' => '10',
                                                   'status'   => $_msg,
                                          }
                                         )
                             );
                }
            }
            else
            {

                # print confirmation dialog
                if (defined($loc))
                {
                    my $locparent = EIS::Tables::Locbyparent->retrieve($_id);
                    my $parent    = undef;

                    if (defined($locparent))
                    {
                        $parent =
                          EIS::Tables::Location->retrieve(
                                                     $locparent->locparentid());
                    }
                    $r->print(
                              $tt->output(
                                          template => 'delete_location.tt',
                                          'vars'   => {
                                                    'note' => "Delete Location",
                                                    'location' => $loc,
                                                    'parent'   => $parent,
                                          }
                                         )
                             );
                }
            }
        }
        else
        {
            my $_msg = "ID missing";
            $r->print(
                      $tt->output(
                                  template => 'status.tt',
                                  'vars'   => {
                                             'action'   => '/eis/Locations',
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
