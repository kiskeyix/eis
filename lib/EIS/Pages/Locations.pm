#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Displays information about location
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Locations;
use strict;
use warnings;
$|++;

use EIS::Tables::Location;
use EIS::Tables::Locbyparent;

use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );

use CGI;
use Apache2::RequestRec ();
use Apache2::RequestIO  ();

use Apache2::Const -compile => qw(OK REDIRECT);

sub handler
{
    my $r       = shift;
    my $session = EIS::SessionManager->new('_request' => $r);

    if ($session->is_valid())
    {
        my $tt  = EIS::Template->new();
        my $cgi = CGI->new();

        if ($cgi->param('id'))
        {
            my $_id         = $cgi->param('id');
            my $loc         = EIS::Tables::Location->retrieve($_id);
            my $parent      = EIS::Tables::Locbyparent->retrieve($_id);
            my $parent_desc = undef;

            if (defined $parent)
            {
                $parent_desc =
                  EIS::Tables::Location->retrieve($parent->locparentid);
            }

            if (defined $loc)
            {
                $r->print(
                          $tt->output(
                                      template => 'info_location.tt',
                                      'vars'   => {
                                                 'location' => $loc,
                                                 'parent'   => $parent_desc
                                                }
                                     )
                         );
            }
            else
            {
                $r->print("Location information not found for ID: " . $_id);
            }
        }
        else
        {
            my @locations = EIS::Tables::Location->retrieve_all();
            $r->print(
                      $tt->output(
                                  template => 'locations.tt',
                                  'vars'   => {'locations' => \@locations,}
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
