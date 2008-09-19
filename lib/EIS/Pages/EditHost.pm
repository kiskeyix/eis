#!/usr/bin/perl -w
# $Revision: 1.7 $
# $Date: 2006/11/11 15:09:33 $
# Luis Mondesi < lemsx1@gmail.com >
#
# DESCRIPTION:
# USAGE: N/A
# LICENSE: SEE LICENSE FILE

package EIS::Pages::EditHost;
use strict;
use warnings;
$|++;

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

        my $_sessdata     = $session->load_session();
        my $_hostparentid = $cgi->param('hostparentid');
        my $_locationid   = $cgi->param('locationid');

        if ($_hostparentid and $_hostparentid > 0)
        {
            use EIS::Tables::Hostbyparent;
            my $host = EIS::Tables::Hostbyparent->retrieve($_id);
            if (defined($host))
            {
                if ($cgi->param('delhostparentid'))
                {
                    $host->delete();
                    {
                        no warnings;
                        EIS::Tables::Log->insert(
                                         {
                                              log => 'User '
                                            . $_sessdata->{'fullname'} . ' ('
                                            . $_sessdata->{'username'}
                                            . ') deleted host id '
                                            . $_id
                                            . ' from IP '
                                            . $r->connection->remote_ip()
                                         }
                        );
                    }
                }
                else
                {
                    $host->hostparentid($_hostparentid);
                    $host->update();
                }
            }
            else
            {
                EIS::Tables::Hostbyparent->insert(
                                           {
                                            'id'           => $_id,
                                            'hostparentid' => $_hostparentid,
                                           }
                );
            }
        }
        if ($_locationid and $_locationid > 0)
        {
            use EIS::Tables::Hostbyloc;
            my $host = EIS::Tables::Hostbyloc->retrieve($_id);
            if (defined($host))
            {
                if ($cgi->param('dellocationid'))
                {
                    $host->delete();
                }
                else
                {
                    $host->locationid($_locationid);
                    $host->update();
                }
            }
            else
            {
                EIS::Tables::Hostbyloc->insert(
                                               {
                                                id         => $_id,
                                                locationid => $_locationid,
                                               }
                                              );
            }
        }

        # meta info
        use EIS::Tables::HostMeta;
        my $_metafields = EIS::Tables::HostMeta->get_hostmeta_fields();
        my $hostmeta    = EIS::Tables::HostMeta->retrieve(host => $_id);
        my %_metaargs   = ('host' => $_id);

        # get information from CGI
        foreach my $_m (@$_metafields)
        {

            #print STDERR ("$_m: " . $cgi->param($_m) . "<br />\n");
            if ($cgi->param($_m))
            {
                $_metaargs{$_m} = $cgi->param($_m);  # HTML form prepends 'host'
            }
        }

        # insert or update host meta info
        if (defined($hostmeta))
        {
            foreach my $_field (keys %_metaargs)
            {
                $hostmeta ->${_field}($_metaargs{$_field});
            }
            $hostmeta->update();
        }
        else
        {
            EIS::Tables::HostMeta->insert(\%_metaargs);
        }

        # print success and redirect to /eis/Hosts or so
        my $_msg = "Host edited successfully!";
        $r->print(
                  $tt->output(
                              template => 'status.tt',
                              'vars'   => {
                                         'action'   => '/eis/Edit?id=' . $_id,
                                         'type'     => 'success',
                                         'redirect' => '2',
                                         'status'   => $_msg,
                                        }
                             )
                 );
        {
            no warnings;
            EIS::Tables::Log->insert(
                                     {
                                          log => 'User '
                                        . $_sessdata->{'fullname'} . ' ('
                                        . $_sessdata->{'username'}
                                        . ') modified host id '
                                        . $_id
                                        . ' from IP '
                                        . $r->connection->remote_ip()
                                     }
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
