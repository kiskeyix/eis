#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: edits locations
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::EditLocation;
use strict;
use warnings;
$|++;

use EIS::Tables::Location;
use EIS::Tables::Locbyparent;

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
            my $_locname     = $cgi->param('locname');
            my $_locdesc     = $cgi->param('locdesc');
            my $_locparentid = $cgi->param('locparentid');

            my $locparent = EIS::Tables::Locbyparent->retrieve($_id);

            # we are editing
            if ($_locparentid and $_locparentid > 0)
            {
                if (defined($locparent))
                {
                    $locparent->locparentid($_locparentid);
                    $locparent->update();
                }
                else
                {
                    $locparent =
                      EIS::Tables::Locbyparent->insert(
                                             {
                                              'id'          => $_id,
                                              'locparentid' => $_locparentid,
                                             }
                      );
                }
            }

            my $loc = EIS::Tables::Location->retrieve($_id);

            if (defined($loc))
            {
                if ($_locname)
                {
                    $loc->locname($_locname);
                }
                if ($_locdesc)
                {
                    $loc->locdesc($_locdesc);
                }
                $loc->update();
            }
            else
            {
                EIS::Tables::Location->insert(
                                              {
                                               id      => $_id,
                                               locname => $_locname,
                                               locdesc => $_locdesc,
                                              }
                                             );
            }
            $r->print(
                      $tt->output(
                                  template => 'edit_location.tt',
                                  'vars'   => {
                                             'note'      => "Edit Location",
                                             'location'  => $loc,
                                             'locparent' => $locparent,
                                             'loclist'   => \@alllocations,
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
                                            . ') modified location id '
                                            . $_id
                                            . ' from IP '
                                            . $r->connection->remote_ip()
                                         }
                                        );
            }
        }
        else
        {

            # id missing. we are creating a new location
            $r->print(
                      $tt->output(
                                  template => 'edit_location.tt',
                                  'vars'   => {
                                             'note'    => "New Location",
                                             'action'  => "NewLocation",
                                             'loclist' => \@alllocations,
                                            }
                                 )
                     );
            @alllocations = ();
            undef @alllocations;
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
