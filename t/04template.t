#!/usr/bin/perl -w
# $Revision: 0.1 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple test script
# Use this to test Config.pm API
# USAGE: ./template.t
# LICENSE: GPL
use strict;

use lib 'lib';
use Test::More qw(no_plan);

use EIS::Tables::Host;
use EIS::Tables::XML;
use EIS::Template qw(:all);

#my $config = EIS::Config->new('config_file' => '../etc/eis/eis.conf');
#ok(defined $config, 'config->new()');
#is($config->get_option('config_file'), '../etc/eis/eis.conf',
#    'config_file key set to value');

my $obj = EIS::Template->new();
#$config->get_option('template_path'));
ok(defined $obj, 'obj->new()');
is($obj->get_option('template_path'), '../includes/templates','template_path key');

# test some common files
ok($obj->output('template'=>'header.tt','vars'=>{'foo'=>'test'}),'header.tt');
ok($obj->output('template'=>'footer.tt','vars'=>{'foo'=>'test'}),'footer.tt');
ok($obj->output('template'=>'login.tt','vars'=>{'page_title'=>'test'}),'login.tt');

my @hosts = EIS::Tables::Host->retrieve_all();
@hosts = sort { $a->hostname() cmp $b->hostname() } @hosts;
ok($obj->output('template'=>'hosts_list.tt','vars'=>{'hosts'=>\@hosts}),'hosts_list.tt');

my $xml = EIS::Tables::XML->retrieve(1);
ok($obj->output('template'=>'info.tt','vars'=>{'xmlcontent'=>$xml}),'info.tt');

print "Login content:\n";
print $obj->output('template'=>'login.tt','vars'=>{'foo'=>'test'});

print "Hosts list: \n";
print $obj->output('template'=>'hosts_list.tt','vars'=>{'hosts'=>\@hosts});

print "XML Content:\n";
print $obj->output('template'=>'info.tt','vars'=>{'xmlcontent'=>$xml->xmlcontent()});

