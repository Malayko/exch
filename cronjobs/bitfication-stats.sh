#! /bin/sh

cd /home/webapp/bitfication
RAILS_ENV=production rake bitfication:stats #2>&1 > /dev/null
