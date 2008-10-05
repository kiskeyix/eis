#!/bin/sh
# $Revision: 1.3 $
# $Date: 2007-03-01 21:41:46 $
# Luis Mondesi <lemsx1@gmail.com>
#
# DESCRIPTION: This is a simple script to import all files from /var/lib/eis into the Hardware Inventory System (EIS) database
# USAGE:
# LICENSE: GPL

PATH=/usr/local/bin:/bin:/usr/bin:$PATH

. /etc/eis/eis.conf

test ! -d ${eis_collection_dir:=/var/lib/eis}/archive && mkdir -p ${eis_collection_dir:=/var/lib/eis}/archive
for i in ${eis_collection_dir:=/var/lib/eis}/*.xml; do eis-import-file $i > /dev/null 2>&1; test $? = 0 && mv $i ${eis_collection_dir:=/var/lib/eis}/archive ; done
