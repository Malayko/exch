#! /bin/sh

cd /home/webapp/bitfication
RAILS_ENV=production rake notifications:trades #2>&1 > /dev/null
