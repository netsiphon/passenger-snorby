#!/bin/bash
#https://github.com/Snorby/snorby/blob/master/README.md

mysql -u $DB_USER -p $DB_PASSWORD -h $DB_HOST < $SNORBY_PATH/snorby_setup.sql

#Modify Configs
sed -i 's/$DB_HOST/'$DB_HOST'/g' /usr/local/src/snorby/config/database.yml
sed -i 's/$DB_PORT/'$DB_PORT'/g' /usr/local/src/snorby/config/database.yml
sed -i 's/$DB_USER/'$DB_USER'/g' /usr/local/src/snorby/config/database.yml
sed -i 's/$DB_PASSWORD/'$DB_PASSWORD'/g' /usr/local/src/snorby/config/database.yml

#Snort Rules at some point...

#Setup Snorby
cd $SNORBY_PATH
bundle exec rake snorby:setup

SNORBY_START="rails server -e production"

# GO!
cd $SNORBY_PATH
$SNORBY_START

#Delayed Jobs start
rails runner "Snorby::Worker.start"
rails runner "Snorby Cache Jobs"
