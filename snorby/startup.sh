#!/bin/bash
#https://github.com/Snorby/snorby/blob/master/README.md

export PATH=$PATH:/usr/local/rvm/rubies/ruby-2.2.1-p85/bin

mysql -u $DB_USER -p $DB_PASSWORD -h $DB_HOST < $SNORBY_PATH/snorby_setup.sql

#Modify Configs
sed -i 's/$DB_HOST/'$DB_HOST'/g' $SNORBY_PATH/config/database.yml
sed -i 's/$DB_PORT/'$DB_PORT'/g' $SNORBY_PATH/config/database.yml
sed -i 's/$DB_USER/'$DB_USER'/g' $SNORBY_PATH/config/database.yml
sed -i 's/$DB_PASSWORD/'$DB_PASSWORD'/g' $SNORBY_PATH/config/database.yml

#Snort Rules at some point...

#Setup Snorby
cd $SNORBY_PATH
/bin/bash -l -c bundle exec rake snorby:setup

SNORBY_START="rails server -e production"

# GO!
cd $SNORBY_PATH
$SNORBY_START

#Delayed Jobs start
/bin/bash -l -c rails runner "Snorby::Worker.start"
/bin/bash -l -c rails runner "Snorby Cache Jobs"
