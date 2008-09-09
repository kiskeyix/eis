#!/usr/bin/perl -w
# $Revision: 1.2 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: A simple test script
# Use this to test Config.pm API
# USAGE: ./config.t
# LICENSE: GPL

use lib 'lib';
use Test::More no_plan;
use EIS::Config qw(:all);

my $obj = EIS::Config->new('config_file' => '../etc/eis/eis.conf');
ok(defined $obj, 'config->new()');

#$obj->{'AppConfig'}->_dump();

# test default value for config key
is($obj->get_option('config_file'), '../etc/eis/eis.conf',
    'default value for config worked');

# create a new hash key
#is($obj->{'dummy'}, 'dummy_value', "dummy == dummy_value");
is($obj->get_option('site_name'),'Enterprise Inventory System','default site_name option');
is($obj->get_option('template_path'), '../includes/templates', 'default template_path option');
is($obj->get_option('eis_collection_dir'), '/var/lib/eis', 'default_eis_collection_dir option');

# test wrappers for config API
ok($obj->set_option('site_name', 'My Site'), 'setter worked');
is($obj->get_option('site_name'), 'My Site', 'getter worked');

# test without wrapper
is($obj->config_option('site_name', 'Other Name'), 'Other Name',
    'setter/getter worked');


