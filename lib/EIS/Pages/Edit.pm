#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION: Displays information from XML file of hosts
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::Edit;
use strict;
use warnings;
$|++;

#use Carp qw(carp croak);    # croak dies nicely. carp warns nicely

use EIS::Template qw( :all );
use EIS::SessionManager qw( :all );
use EIS::Tables::Log;

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
        my $tt  = EIS::Template->new();
        my $cgi = CGI->new();
        my $_id = $cgi->param('id');

        # all of the things we can handle require an ID field
        if (!$_id)
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

        my $_sessdata = $session->load_session();
        {
            no warnings;
            EIS::Tables::Log->insert(
                                     {
                                          log => 'User '
                                        . $_sessdata->{'fullname'} . ' ('
                                        . $_sessdata->{'username'}
                                        . ') is editing host id '
                                        . $_id
                                        . ' from IP '
                                        . $r->connection->remote_ip()
                                     }
                                    );
        }

        my $parenthost   = 0;
        my $location     = undef;
        my $host         = undef;
        my $hostmeta     = undef;
        my @allhosts     = ();      # parents
        my $_currentip   = "";
        my @alllocations = ();
        {
            use EIS::Tables::Host;
            $host     = EIS::Tables::Host->retrieve($_id);
            @allhosts = EIS::Tables::Host->retrieve_all();

            my ($name, $aliases, $addrtype, $length, @addrs) =
              gethostbyname($host->hostname());

            if (scalar @addrs > 0)
            {
                $_currentip = join(".", unpack("C" . $length, $addrs[0]));
            }
            else
            {
                $_currentip = "NO IP FOUND";
            }
        }
        {
            use EIS::Tables::HostMeta;
            $hostmeta = EIS::Tables::HostMeta->retrieve(host => $_id);
        }
        {
            use EIS::Tables::Location;
            @alllocations = EIS::Tables::Location->retrieve_all();
        }
        {
            use EIS::Tables::Hostbyparent;
            my $_parenthost = EIS::Tables::Hostbyparent->retrieve($_id);
            if (defined $_parenthost)
            {
                $parenthost = $_parenthost->hostparentid();
            }
        }
        {
            use EIS::Tables::Hostbyloc;
            my $_location = EIS::Tables::Hostbyloc->retrieve($_id);
            if (defined $_location)
            {
                $location = $_location->locationid();
            }
        }

        #if ($hostmeta)
        {
            $r->print(
                      $tt->output(
                                  template => 'edit_host.tt',
                                  'vars'   => {
                                             'parenthost' => $parenthost,
                                             'location'   => $location,
                                             'host'       => $host,
                                             'hostlist'   => \@allhosts,
                                             'loclist'    => \@alllocations,
                                             'currentip'  => $_currentip,
                                             'hostmeta'   => $hostmeta,
                                            }
                                 )
                     );
        }
        @alllocations = ();
        undef @alllocations;
        @allhosts = ();
        undef @allhosts;
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
