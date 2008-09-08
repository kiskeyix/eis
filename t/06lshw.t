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
use EIS::XML qw(:all);

my $obj =
 EIS::XML->new('config_file' => 'etc/eis/eis.conf',
                 'xml_file'    => 't/morpheus-00.xml');
ok(defined $obj, 'config->new()');

#$obj->{'AppConfig'}->_dump();

# test default value for config key
is($obj->get_option('config_file'),
    'etc/eis/eis.conf', 'default value for config_file');

# create a new hash key
#is($obj->{'dummy'}, 'dummy_value', "dummy == dummy_value");
is($obj->get_option('site_name'), 'EIS', 'default site_name option');
is($obj->get_option('template_path'),
    '/auto/www/html/eis/includes/templates',
    'default template_path option');
is($obj->get_option('xsl_path'),
    '/auto/www/html/eis/includes/xsl',
    'default xsl_path option');
is($obj->get_option('eis_collection_dir'),
    '/var/lib/eis', 'default_eis_collection_dir option');

# test wrappers for config API
ok($obj->set_option('site_name', 'My Site'), 'setter worked');
is($obj->get_option('site_name'), 'My Site', 'getter worked');

# test without wrapper
is($obj->config_option('site_name', 'Other Name'),
    'Other Name', 'setter/getter worked');

# print information parsed
#ok($obj->dump());

# convert file to HTML
#FIXME ok($obj->file_to_html(), 'HTML convertion default file');
ok($obj->file_to_html('t/morpheus-00.xml','lshw.xsl'), 'HTML convertion');

