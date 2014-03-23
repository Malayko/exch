#! /bin/sh

cd /home/webapp/bitfication
RAILS_ENV=production rake bitcoin:synchronize_transactions #2>&1 > /dev/null
