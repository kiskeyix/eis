#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: adds locations
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::NewLocation;
use strict;
use warnings;
$|++;

use EIS::Tables::Location;
use EIS::Tables::Locbyparent;
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
        my $tt       = EIS::Template->new();
        my $cgi      = CGI->new();
        my $_locname = undef;
        my $_locdesc = undef;

        # all of the things we can handle require a name and description
        if (    $cgi->param('locname')
            and $_locdesc = $cgi->param('locdesc'))
        {
            $_locname = $cgi->param('locname');
            $_locdesc = $cgi->param('locdesc');

            my $loc = EIS::Tables::Location->retrieve(locname => $_locname);

            if (defined($loc))
            {

                # a location already exists. bail out
                my $_msg = "Location with Name '$_locname' already exists";
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
            else
            {
                my $_loc =
                  EIS::Tables::Location->insert(
                                                {
                                                 locname => $_locname,
                                                 locdesc => $_locdesc,
                                                }
                                               );

                my $_id = $_loc->id();
                if ($cgi->param('locparentid'))
                {
                    my $_locparentid = $cgi->param('locparentid');
                    if ($_locparentid > 0)
                    {
                        my $locparent =
                          EIS::Tables::Locbyparent->retrieve($_id);

                        if (defined($locparent))
                        {

                            # how come this already exist?
                            # reparent
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
                }

                $r->print(
                          $tt->output(
                                 template => 'status.tt',
                                 'vars'   => {
                                     'action'   => '/eis/Locations',
                                     'redirect' => '2',
                                     'type'     => 'success',
                                     'status' => 'Location added successfully!',
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
                                            . ') created location id '
                                            . $_id
                                            . ' from IP '
                                            . $r->connection->remote_ip()
                                         }
                    );
                }
            }
        }
        else
        {
            my $_msg = "";
            $_msg .= "ID missing<br />"          if (!$cgi->param('id'));
            $_msg .= "Name missing<br />"        if (!$cgi->param('locname'));
            $_msg .= "Description missing<br />" if (!$cgi->param('locdesc'));

            $r->print(
                      $tt->output(
                                  template => 'status.tt',
                                  'vars'   => {
                                             'action'   => '/eis/Locations',
                                             'redirect' => '10',
                                             'type'     => 'error',
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
